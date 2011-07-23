\set ECHO
\set QUIET 1

\pset format unaligned
\pset tuples_only true
\pset pager

\set ON_ERROR_ROLLBACK 1
\set ON_ERROR_STOP true
\set QUIET 1

begin;

\i pgtap.sql

select plan(52);

-- schema tests
select has_schema('users', 'There should be a schema for users.');

-- user table tests
select has_table('users', 'user', 'There should be a users table.');

select has_column('users', 'user', 'id', 'Needs to have a unique user id.');
select col_type_is('users', 'user', 'id', 'uuid', 'User id needs to ba a UUID.');
select col_is_pk('users', 'user', 'id', 'The user name is the primary key');

select has_column('users', 'user', 'active', 'Needs to have an Active users column.');
select col_type_is('users', 'user', 'active', 'boolean', 'Active needs to be boolean.');
select col_has_default('users', 'user', 'active', 'Active needs a default value.');

select has_column('users', 'user', 'name', 'Need a column of user names.');
select col_type_is('users', 'user', 'name', 'text', 'User name needs to be text');

select has_column('users', 'user', 'password', 'Needs a password column');
select col_type_is('users', 'user', 'password', 'text', 'Password needs to have a text input.');

select has_column('users', 'user', 'email', 'Needs an email column.');
select col_type_is('users', 'user', 'email', 'text', 'Email needs to have a text input.');

-- session table tests
select has_table('users', 'session', 'There should be a session linking users to sessions.');

select has_column('users', 'session', 'sess_id', 'sessions needs to have a session id.');
select col_is_pk('users', 'session', 'sess_id', 'Session ids need to be the primary key.');
select col_is_fk('users', 'session', 'sess_id', 'Should be foreign key to web.session.');

select has_column('users', 'session', 'user_id', 'Session needs a user column.');
select col_is_fk('users', 'session', 'user_id', 'Should be foreign key to user name.');

-- unconfirmed users table
select has_table('users', 'unconfirmed', 'There should be an unconfirmed users table.');

select has_column('users', 'unconfirmed', 'link', 'The unconfirmed table needs a link column');
select col_type_is('users', 'unconfirmed', 'link', 'uuid', 'link column needs to be a UUID.');
select col_is_pk('users', 'unconfirmed', 'link', 'link needs to be primary key.');

select has_column('users', 'unconfirmed', 'user_id', 'There should be a column for the user id.');
select col_is_fk('users', 'unconfirmed', 'user_id', 'Should be a foreign key to user name.');

select has_column('users', 'unconfirmed', 'expire', 'There should be an expiration column');
select col_type_is('users', 'unconfirmed', 'expire', 'timestamp with time zone', 'expire should be a timestamp.');
select col_has_default('users', 'unconfirmed', 'expire', 'expiration needs a default setting.');

-- make sure there is an entry for the anonymous user.
select results_eq(
	$$select * from users.user where name = 'anonymous'$$,
	$$values (uuid_nil(), true, 'anonymous', '', '')$$,
	'There should be an anonymous user installed with the database'
);

-- New sessesions should be assigned an anonymous user.
select web.clear_sessions();
select web.set_session_data('flintstone', 'fred', now() + interval '1 day');
select results_eq(
	$$select sess_id, user_id from users.session where sess_id = 'flintstone'$$,
	$$values ('flintstone', uuid_nil())$$,
	'New sessions should be assigned to the anonymous user.'
);

-- User sessions should clear out with the web sessions.
select web.clear_sessions();
select web.set_session_data('flintstone', 'fred', now() + interval '1 day');
select web.set_session_data('rubble', 'barney', now() + interval '1 day');
select web.set_session_data('slade', 'mister', now() + interval '1 day');
select results_eq(
	'select cast(count(*) as int) from users.session',
	'values (3)',
	'There should have been three user sessions available.'
);
select web.clear_sessions();
select results_eq(
	'select cast(count(*) as int) from users.session',
	'values (0)',
	'There should have been no user sessions available.'
);

-- Testing add users functions
select has_function('users', 'add', array['text', 'text', 'text'], 'Needs an add user function.');
select is_definer('users', 'add', array['text', 'text', 'text'], 'add should be definer security.');
select function_returns('users', 'add', array['text', 'text', 'text'], 'uuid', 'Add needs to return a verification link.');

-- add user function should store information into the users table.
delete from users.user where name = 'flintstone';  
create temp table newuserlink as select users.add('flintstone', 'secret', 'flintstone@bedrock.com');
select results_eq(
	$$select active from users.user where name = 'flintstone'$$,
	'values (false)',
	'users.add should make an inactive user.'
);
select results_eq(
	$$select name from users.user where name = 'flintstone'$$,
	$$values ('flintstone')$$,
	'users.add should add to the database'
);
select results_ne(
	$$select password from users.user where name = 'flintstone'$$,
	$$values (null)$$,
	'user password should not be null'
);
select results_ne(
	$$select password from users.user where name = 'flintstone'$$,
	$$values ('secret')$$,
	'user password needs to be encrypted'
);
select results_eq(
	$$select email from users.user where name = 'flintstone'$$,
	$$values ('flintstone@bedrock.com')$$,
	'user email should in the database.'
);
select results_eq(
	$$select user_id from users.unconfirmed where link = (select add from newuserlink)$$,
	$$select id from users.user where name = 'flintstone'$$,
	'Need to create an unconfirmed entry for new users.'
);
select results_eq(
	$$select expire > now() from users.unconfirmed where link = (select add from newuserlink)$$,
	'values (true)',
	'Confirmation expiration must be in the future.'
);

-- add user function should fail if the username is less that 5 characters.
delete from users.user where name = 'four';  
select throws_like(
	$$select users.add('four', 'secret', 'four@numbers.org')$$,
	'%"user_name_check"',
	'There should be an error for short usernames.'
);

-- testing validate user functions
select has_function('users', 'validate', array['uuid'], 'Needs an validate user function.');
select is_definer('users', 'validate', array['uuid'], 'validate should be definer security.');
select function_returns('users', 'validate', array['uuid'], 'boolean', 'Validate returns pass or fail.');

-- validate returns false if link is bad.
select results_eq(
	'select users.validate(uuid_nil())',
	'values (false)',
	'Validate should return a false for nonexistent links.'
);

-- validate returns true for valid links.
delete from users.user where name = 'flintstone';  
select results_eq(
	$$select users.validate(users.add('flintstone', 'secret', 'flintstone@bedrock.com'))$$,
	'values (true)',
	'Validate should return true for existing links.'
);

-- valid links should activate a user.
select results_eq(
	$$select active from users.user where name = 'flintstone'$$,
	'values (true)',
	'Validate should activate the user.'
);

-- valid links should remove user from the unconfirmed table.
select results_eq(
	$$select cast(count(*) as int) from users.unconfirmed 
		where user_id = (select id from users.user where name = 'flintstone')$$,
	$$values (0)$$,
	'Validate should remove entries from unconfirmed table.'
);

-- unconfirmed users should be deleted after they time out.  
delete from users.user where name = 'flintstone'; 
select web.clear_sessions();
select users.add('flintstone', 'secret', 'flintstone@bedrock.com');
update users.unconfirmed set expire = now() - interval '1 day' 
	where user_id = (select id from users.user where name = 'flintstone');
select web.set_session_data('flintstone', 'fred', now() + interval '1 day');
select results_eq(
	$$select cast(count(*) as int) from users.user where name = 'flintstone'$$,
	$$values (0)$$,
	'Expired unconfirmed users should be deleted with each session change.'
);

select * from finish();

rollback;