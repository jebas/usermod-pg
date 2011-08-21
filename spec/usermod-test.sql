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

select plan(126);

-- schema tests
select has_schema('users', 'There should be a schema for users.');

-- user table tests
select has_table('users', 'user', 'There should be a users table.');

select has_column('users', 'user', 'id', 'Needs to have a unique user id.');
select col_type_is('users', 'user', 'id', 'uuid', 'User id needs to ba a UUID.');
select col_is_pk('users', 'user', 'id', 'The user id is the primary key');

select has_column('users', 'user', 'active', 'Need a column of user status.');
select col_type_is('users', 'user', 'active', 'boolean', 'Active user is boolean.');
select col_not_null('users', 'user', 'active', 'User active column cannot be null.');
select col_default_is('users', 'user', 'active', 'false', 'Active column should default to false');

select has_column('users', 'user', 'name', 'Need a column of user names.');
select col_type_is('users', 'user', 'name', 'text', 'User name needs to be text');
select col_not_null('users', 'user', 'name', 'User name column cannot be null.');

select has_column('users', 'user', 'password', 'Needs a password column');
select col_type_is('users', 'user', 'password', 'text', 'Password needs to have a text input.');
select col_not_null('users', 'user', 'password', 'User passwork cannot be null.');

select has_column('users', 'user', 'email', 'Needs an email column.');
select col_type_is('users', 'user', 'email', 'text', 'Email needs to have a text input.');
select col_not_null('users', 'user', 'email', 'User email column cannot be null.');

select has_column('users', 'user', 'icon', 'Needs an icon column.');
select col_type_is('users', 'user', 'icon', 'text', 'Icon needs to have a text input.');
select col_is_null('users', 'user', 'icon', 'User icon column can be null.');

select has_column('users', 'user', 'introduction', 'Needs an introduction column.');
select col_type_is('users', 'user', 'introduction', 'text', 'Introduction needs to have a text input.');
select col_is_null('users', 'user', 'introduction', 'User introduction column can be null.');

select results_eq(
	$$select * from users.user where name = 'anonymous'$$,
	$$values (uuid_nil(), true, 'anonymous', '', '', null, null)$$,
	'There should be an anonymous user with an all zeros id.'
);

select results_eq(
	$$select active, name from users.user where name = 'admin'$$,
	$$values (true, 'admin')$$,
	'There should be an admin user.'
);

select throws_like(
	$$insert into users.user (id, name, password, email) 
	values (uuid_generate_v4(), 'ADMIN', 'admin', '')$$,
	'%violates unique constraint%',
	'User names should be unique, and case insensitive'
);

-- session table tests
select has_table('users', 'session', 'There should be a session linking users to sessions.');

select has_column('users', 'session', 'sess_id', 'sessions needs to have a session id.');
select col_is_pk('users', 'session', 'sess_id', 'Session ids need to be the primary key.');
select col_is_fk('users', 'session', 'sess_id', 'Should be foreign key to web.session.');

select has_column('users', 'session', 'user_id', 'Session needs a user column.');
select col_is_fk('users', 'session', 'user_id', 'Should be foreign key to user name.');

select web.clear_sessions();
select web.set_session_data('flintstone', 'fred', now() + interval '1 day');
select results_eq(
	$$select sess_id, user_id from users.session where sess_id = 'flintstone'$$,
	$$values ('flintstone', uuid_nil())$$,
	'New sessions should be assigned to the anonymous user.'
);

select web.clear_sessions();
select web.set_session_data('flintstone', 'fred', now() + interval '1 day');
select web.set_session_data('rubble', 'barney', now() + interval '1 day');
select web.set_session_data('slade', 'mister', now() + interval '1 day');
select results_eq(
	$$select sess_id, user_id from users.session$$,
	$$values ('flintstone', uuid_nil()), ('rubble', uuid_nil()), ('slade', uuid_nil())$$,
	'There should be three sessions for the anonymous user.'
);
select web.clear_sessions();
select results_eq(
	'select cast(count(*) as int) from users.session',
	'values (0)',
	'There should have been no user sessions available.'
);

-- Testing user info function.  
select has_function('users', 'info', array['text', 'text'], 'Needs an user info function.');
select is_definer('users', 'info', array['text', 'text'], 'info should have definer security.');
select function_returns('users', 'info', array['text', 'text'], 'userinfo', 'Info needs to return user information.');

select web.clear_sessions();
select web.set_session_data('session1', '{}', now() + interval '1 day');
select results_eq(
	$$select username from users.info('session1', 'admin')$$,
	$$values ('admin')$$,
	'User info should return information about any user.'	
);

select has_function('users', 'info', array['text'], 'Needs an user info function for session.');
select is_definer('users', 'info', array['text'], 'info should have definer security.');
select function_returns('users', 'info', array['text'], 'userinfo', 'Info needs to return user information.');

select web.clear_sessions();
select web.set_session_data('session1', '{}', now() + interval '1 day');
select results_eq(
	$$select username from users.info('session1')$$,
	$$values ('anonymous')$$,
	'The short users.info should return information about the session owner.'	
);

-- Tests for user login.
select has_function('users', 'login', array['text', 'text', 'text'], 'Needs an user login function.');
select is_definer('users', 'login', array['text', 'text', 'text'], 'login should have definer security.');
select function_returns('users', 'login', array['text', 'text', 'text'], 'void', 'login uses errors for bad logins.');

select web.clear_sessions();
select throws_ok(
	$$select users.login('session1', 'admin', 'admin')$$,
	'P0001',
	'Not Authorized',
	'Login cannot occur if session does not exist.'
);

select web.clear_sessions();
select web.set_session_data('session1', '{}', now() + interval '1 day');
select throws_ok(
	$$select users.login('session1', 'admin', 'wrong')$$,
	'P0001',
	'Invalid username or password',
	'Only the anonymous user can use the login function.'
);

select web.clear_sessions();
select web.set_session_data('session1', '{}', now() + interval '1 day');
select users.login('session1', 'admin', 'admin');
select results_eq(
	$$select user_id from users.session where sess_id = 'session1'$$,
	$$select id from users.user where name = 'admin'$$,
	'The user session must be assigned to the logged in user.'
);

select web.clear_sessions();
select web.set_session_data('session1', '{}', now() + interval '1 day');
select users.login('session1', 'ADMIN', 'admin');
select results_eq(
	$$select user_id from users.session where sess_id = 'session1'$$,
	$$select id from users.user where name = 'admin'$$,
	'User login must be case independent.'
);

select web.clear_sessions();
select web.set_session_data('session1', '{}', now() + interval '1 day');
select users.login('session1', 'admin', 'admin');
select throws_ok(
	$$select users.login('session1', 'admin', 'admin')$$,
	'P0001',
	'Not Authorized',
	'Only the anonymous user can use the login function.'
);

select web.clear_sessions();
delete from users.user where name = 'testuser'; 
select web.set_session_data('session1', '{}', now() + interval '1 day');
select users.add('session1', 'testuser', 'password', 'tester@test.com');
select throws_ok(
	$$select users.login('session1', 'testuser', 'password')$$,
	'P0001',
	'Not Authorized',
	'Only active/validated users can log in.'
);

-- logout function tests
select has_function('users', 'logout', array['text'], 'Needs an user logout function.');
select is_definer('users', 'logout', array['text'], 'logout should have definer security.');
select function_returns('users', 'logout', array['text'], 'void', 'logout should not return anything.');

select web.clear_sessions();
select web.set_session_data('session1', '{}', now() + interval '1 day');
select users.login('session1', 'admin', 'admin');
select users.logout('session1');
select results_eq(
	$$select user_id from users.session where sess_id = 'session1'$$,
	$$values (uuid_nil())$$,
	'Logout should set the session back to anonymous'
);

select web.clear_sessions();
select web.set_session_data('session1', '{}', now() + interval '1 day');
select throws_ok(
	$$select users.logout('session1')$$,
	'P0001',
	'Not Authorized',
	'The anonymous user cannot log out.'
);

-- Group table tests
select has_table('users', 'group', 'There should be a group table.');

select has_column('users', 'group', 'id', 'There should be a group id column');
select col_type_is('users', 'group', 'id', 'uuid', 'The group id column should be a uuid');
select col_is_pk('users', 'group', 'id', 'Groups id column needs to be the primary key');

select has_column('users', 'group', 'name', 'Group needs a column for names.');
select col_type_is('users', 'group', 'name', 'text', 'Group name needs to be text');
select col_not_null('users', 'group', 'name', 'Group name column cannot be null.');

select results_eq(
	'select name from users.group',
	$$values ('admin'), ('everyone'), ('authenticated')$$,
	'Must have the three basic groups.'	
);

select throws_like(
	$$insert into users.group (id, name) values (uuid_generate_v4(), 'ADMIN')$$,
	'%violates unique constraint%',
	'Group names should be case insensetive unique.'
);

-- Group user link table tests
select has_table('users', 'group_user_link', 'There should be a table linking users to groups.');

select has_column('users', 'group_user_link', 'group_id', 'Group user link should have a group link.');
select col_is_fk('users', 'group_user_link', 'group_id', 'This is a foreign key to the group name.');

select has_column('users', 'group_user_link', 'user_id', 'Group user link should have a user link.');
select col_is_fk('users', 'group_user_link', 'user_id', 'This is a foreign key to the user name.');

select col_is_pk('users', 'group_user_link', array['group_id', 'user_id'], 'Allow only one individual user entry per group');

select bag_has	(
	$$
	select 
		users.group.name as gname, 
		users.user.name as uname
	from
		users.user,
		users.group,
		users.group_user_link
	where
		users.user.id = users.group_user_link.user_id
		and users.group.id = users.group_user_link.group_id
	$$,
	$$
	values
		('admin', 'admin'),
		('authenticated', 'admin'),
		('everyone', 'admin'),
		('everyone', 'anonymous')
	$$,
	'Needs to assign users to groups.'
);

-- Tests for the function name table.
select has_table('users', 'function', 'There should be a function table.');

select has_column('users', 'function', 'id', 'There should be a function id column');
select col_type_is('users', 'function', 'id', 'uuid', 'The function id column should be a uuid');
select col_is_pk('users', 'function', 'id', 'function id column needs to be the primary key');

select has_column('users', 'function', 'name', 'function needs a column for names.');
select col_type_is('users', 'function', 'name', 'text', 'function name needs to be text');
select col_not_null('users', 'function', 'name', 'function name column cannot be null.');

select has_function('users', 'add_function', array['text'], 'Needs an user add function function.');
select is_definer('users', 'add_function', array['text'], 'add function should have definer security.');
select function_returns('users', 'add_function', array['text'], 'void', 'add function should not return anything.');

select users.add_function('testing_function');
select results_eq(
	$$select name from users.function where name = 'testing_function'$$,
	$$values ('testing_function')$$,
	'Add function should add function to the database.'
);

select throws_like(
	$$select users.add_function('TESTING_FUNCTION')$$,
	'%violates unique constraint%',
	'Function names should be case insensetive unique.'
);
delete from users.function where name = 'testing_function';

select bag_has(
	'select name from users.function',
	$$values ('users.login'), ('users.logout'), ('users.info')$$,
	'Need to add the user functions '
);

-- Funtion user table link tests
select has_table('users', 'function_user_link', 'Needs a table that links function to users and objects');

select has_column('users', 'function_user_link', 'function_id', 'Function user link should have a function link.');
select col_is_fk('users', 'function_user_link', 'function_id', 'This is a foreign key to the function id.');

select has_column('users', 'function_user_link', 'user_obj', 'Function user link should have a user link.');
select col_is_fk('users', 'function_user_link', 'user_obj', 'This is a foreign key to the user id.');

select has_column('users', 'function_user_link', 'user_id', 'Function user link should have a user link.');
select col_is_fk('users', 'function_user_link', 'user_id', 'This is a foreign key to the user id.');

select col_is_pk('users', 'function_user_link', array['function_id', 'user_obj', 'user_id'], 'Allow only one individual user entry per function.');

select bag_has(
	$$
		select 
			users.function_user_link.*
		from 
			users.function,
			users.function_user_link
		where
			users.function.id = users.function_user_link.function_id
			and users.function.name = 'users.login'
	$$,
	$$
		select 
			users.function_user_link.*
		from 
			users.function,
			users.function_user_link
		where
			users.function.id = users.function_user_link.function_id
			and users.function.name = 'users.login'
			and users.function_user_link.user_id = uuid_nil()
	$$,
	'anonymous needs to be the only one that can login.'
);

-- Funtion group table link tests
select has_table('users', 'function_group_link', 'Needs a table that links function to users and objects');

select has_column('users', 'function_group_link', 'function_id', 'Function user link should have a function link.');
select col_is_fk('users', 'function_group_link', 'function_id', 'This is a foreign key to the function id.');

select has_column('users', 'function_user_link', 'user_obj', 'Function user link should have a user link.');
select col_is_fk('users', 'function_user_link', 'user_obj', 'This is a foreign key to the user id.');

select has_column('users', 'function_group_link', 'group_id', 'Function user link should have a group link.');
select col_is_fk('users', 'function_group_link', 'group_id', 'This is a foreign key to the group id.');

select col_is_pk('users', 'function_group_link', array['function_id', 'user_obj', 'group_id'], 'Allow only one group user entry per function.');

select bag_has(
	$$
		select
			users.function.name as fname,
			users.user.name as uname,
			users.group.name as gname
		from 
			users.function,
			users.user,
			users.group,
			users.function_group_link
		where
			users.function.id = users.function_group_link.function_id
			and users.user.id = users.function_group_link.user_obj
			and users.group.id = users.function_group_link.group_id
	$$,
	$$values 
		('users.logout', 'anonymous', 'authenticated'),
		('users.info', 'admin', 'everyone'),
		('users.info', 'anonymous', 'everyone')
	$$,
	'logout and info need to be given to authenticated and everyone.'
);

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
select col_default_is('users', 'unconfirmed', 'expire', $$(now() + '7 days'::interval)$$, 'Needs to expire in seven days.');

-- Testing add users functions
select has_function('users', 'add', array['text', 'text', 'text', 'text'], 'Needs an add user function.');
select is_definer('users', 'add', array['text', 'text', 'text', 'text'], 'add should be definer security.');
select function_returns('users', 'add', array['text', 'text', 'text', 'text'], 'uuid', 'Add needs to return a verification link.');

select web.clear_sessions();
delete from users.user where name = 'testuser';
select web.set_session_data('session1', '{}', now() + interval '1 day');
select users.add('session1', 'testuser', 'password', 'tester@test.com');
select bag_has(
	$$select active, name, email from users.user where name = 'testuser'$$,
	$$values (false, 'testuser', 'tester@test.com')$$,
	'Add should add a user to the database.'
);

select web.clear_sessions();
delete from users.user where name = 'four';  
select web.set_session_data('session1', '{}', now() + interval '1 day');
select throws_like(
	$$select users.add('session1', 'four', 'secret', 'four@numbers.org')$$,
	'%"user_name_check"',
	'User names need to be five or more characters.'
);

select web.clear_sessions();
delete from users.user where name = 'testuser';  
select web.set_session_data('session1', '{}', now() + interval '1 day');
select throws_like(
	$$select users.add('session1', 'testuser', 'four', 'four@numbers.org')$$,
	'%"user_password_check"',
	'User password need to be five or more characters.'
);

select web.clear_sessions();
delete from users.user where name = 'testuser';
select web.set_session_data('session1', '{}', now() + interval '1 day');
create temp table newuserlink as select users.add('session1', 'testuser', 'password', 'tester@test.com');
select results_eq(
	'select add from newuserlink',
	$$select 
		users.unconfirmed.link 
	from 
		users.unconfirmed,
		users.user
	where
		users.user.id = users.unconfirmed.user_id
		and users.user.name = 'testuser'$$,
	'Add user function should create and return a confirmation link.'
);
select results_ne(
	$$select password from users.user where name = 'testuser'$$,
	$$values ('password')$$,
	'user password needs to be encrypted'
);
select results_eq(
	$$select expire > now() from users.unconfirmed where link = (select add from newuserlink)$$,
	'values (true)',
	'Confirmation expiration must be in the future.'
);
select bag_has(
	$$
		select
			users.function.name as fname,
			users.user.name as uname
		from 
			users.function_user_link,
			users.function,
			users.user
		where
			users.function.id = users.function_user_link.function_id
			and users.user.id = users.function_user_link.user_id
			and users.function_user_link.user_obj = 
				(select users.user.id from users.user 
					where name = 'testuser')
	$$,
	$$
		values 
			('users.login', 'anonymous'),
			('users.logout', 'testuser')
	$$,
	'Adding a users means setting up the function access.'
);
select bag_has(
	$$
		select
			users.function.name as fname,
			users.group.name as gname
		from 
			users.function_group_link,
			users.function,
			users.group
		where
			users.function.id = users.function_group_link.function_id
			and users.group.id = users.function_group_link.group_id
			and users.function_group_link.user_obj = 
				(select users.user.id from users.user 
					where name = 'testuser')
	$$,
	$$
		values 
			('users.info', 'everyone')
	$$,
	'Adding a users means setting up the function access.'
);



/*
-- set password function
select has_function('users', 'set_password', array['text', 'text', 'text', 'text'], 'Needs an user set password function.');
select is_definer('users', 'set_password', array['text', 'text', 'text', 'text'], 'logout should have definer security.');
select function_returns('users', 'set_password', array['text', 'text', 'text', 'text'], 'void', 'logout should not return anything.');



select plan(105);

-- 

-- Tests for the login function


-- group table


-- user group link table

-- Make sure that the admin group belongs to and is owned by the admin user.  
select results_eq(
	$$select users.group.name 
		from
			users.user,
			users.group,
			users.user_group_link
		where
			users.user.id = users.user_group_link.user_id and
			users.group.id = users.user_group_link.group_id and
			users.user.name = 'admin' and
			users.user_group_link.owner = true$$,
	$$values ('admin')$$,
	'Make sure admin owns and is part of the admin group'
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

-- has a login function
select has_function('users', 'login', array['text', 'text', 'text'], 'Needs an login function.'); 
select is_definer('users', 'login', array['text', 'text', 'text'], 'login should be definer security.');
select function_returns('users', 'login', array['text', 'text', 'text'], 'boolean', 'Login needs to return the login status.');

-- login should return failed if a bad user is chosen.  
delete from users.user where name = 'flintstone'; 
select web.set_session_data('session1', 'fred', now() + interval '1 day');
select results_eq(
	$$select users.login('session1', 'flintstone', 'secret')$$,
	'values (false)',
	'A bad user login should return false.'
);

-- There should be a get_user function.  
select has_function('users', 'get_user', array['text'], 'Needs an get user function.');
select is_definer('users', 'get_user', array['text'], 'get_user should be definer security.');
select function_returns('users', 'get_user', array['text'], 'text', 'get_user needs to return a user name.');

-- get_user should return anonymous for new sessions.
select web.clear_sessions();
select web.set_session_data('session1', 'fred', now() + interval '1 day');
select results_eq(
	$$select users.get_user('session1')$$,
	$$values ('anonymous')$$,
	'New sessions should return anonymous'
);

-- get_user should return the username of the logged in user.
select web.clear_sessions();
delete from users.user where name = 'flintstone'; 
select users.validate(users.add('flintstone', 'secret', 'flintstone@bedrock.com'));
select web.set_session_data('session1', 'fred', now() + interval '1 day');
select users.login('session1', 'flintstone', 'secret');
select results_eq(
	$$select users.get_user('session1')$$,
	$$values ('flintstone')$$,
	'New sessions should return anonymous'
);

-- get_user should return anonymous for a bad session key.
select web.clear_sessions();
select results_eq(
	$$select users.get_user('session1')$$,
	$$values ('anonymous')$$,
	'A bad sessions should return anonymous'
);

-- There should be a function for getting owned groups.  
select has_function('users', 'get_groups', array['text'], 'Needs a get groups you own function.');
select is_definer('users', 'get_groups', array['text'], 'get groups should be definer security.');
select function_returns('users', 'get_groups', array['text'], 'setof text', 'needs to return a list of groups.');

select web.clear_sessions();
select web.set_session_data('session1', 'fred', now() + interval '1 day');
select users.login('session1', 'admin', 'admin');
select results_eq(
	$$select users.get_groups('session1')$$,
	$$values ('admin')$$,
	'Get Groups should return the groups owned by the logged in user'
);
*/
select * from finish();

rollback;