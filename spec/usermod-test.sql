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

select plan(86);

-- schema tests
select has_schema('users', 'There should be a schema for users.');

-- user table tests
select has_table('users', 'user', 'There should be a users table.');

select has_column('users', 'user', 'id', 'Needs to have a unique user id.');
select col_type_is('users', 'user', 'id', 'uuid', 'User id needs to ba a UUID.');
select col_is_pk('users', 'user', 'id', 'The user id is the primary key');

select has_column('users', 'user', 'name', 'Need a column of user names.');
select col_type_is('users', 'user', 'name', 'text', 'User name needs to be text');
select col_not_null('users', 'user', 'name', 'User name column cannot be null.');

select has_column('users', 'user', 'password', 'Needs a password column');
select col_type_is('users', 'user', 'password', 'text', 'Password needs to have a text input.');
select col_not_null('users', 'user', 'password', 'User passwork cannot be null.');

select results_eq(
	$$select * from users.user where name = 'anonymous'$$,
	$$values (uuid_nil(), 'anonymous', '')$$,
	'There should be an anonymous user with an all zeros id.'
);

select results_eq(
	$$select name from users.user where name = 'admin'$$,
	$$values ('admin')$$,
	'There should be an admin user.'
);

select throws_like(
	$$insert into users.user (id, name, password) 
	values (uuid_generate_v4(), 'ADMIN', 'admin')$$,
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
select has_function('users', 'info', array['text'], 'Needs an user info function.');
select is_definer('users', 'info', array['text'], 'info should have definer security.');
select function_returns('users', 'info', array['text'], 'setof record', 'Info needs to return user information.');

select web.clear_sessions();
select web.set_session_data('session1', '{}', now() + interval '1 day');
select results_eq(
	$$select username from users.info('session1')$$,
	$$values ('anonymous')$$,
	'New web sessions should return the anonymous user.'	
);

-- Tests for user login.
select has_function('users', 'login', array['text', 'text', 'text'], 'Needs an user login function.');
select is_definer('users', 'login', array['text', 'text', 'text'], 'login should have definer security.');
select function_returns('users', 'login', array['text', 'text', 'text'], 'void', 'login uses errors for bad logins.');

select web.clear_sessions();
select throws_ok(
	$$select users.login('session1', 'admin', 'admin')$$,
	'P0001',
	'Invalid session',
	'Only the anonymous user can use the login function.'
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
select users.login('session1', 'admin', 'admin');
select throws_ok(
	$$select users.login('session1', 'admin', 'admin')$$,
	'P0001',
	'Already logged in',
	'Only the anonymous user can use the login function.'
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
	$$select username from users.info('session1')$$,
	$$values ('anonymous')$$,
	'Logout should set the session back to anonymous'
);

select web.clear_sessions();
select web.set_session_data('session1', '{}', now() + interval '1 day');
select throws_ok(
	$$select users.logout('session1')$$,
	'P0001',
	'Already logged out',
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
			users.function.name as fname,
			users.user.name as oname,
			users.user.name as uname
		from 
			users.user,
			users.function,
			users.function_user_link
		where
			users.function.id = users.function_user_link.function_id
			and users.user.id = users.function_user_link.user_obj
			and users.user.id = users.function_user_link.user_id
			and users.function.name = 'users.login'
	$$,
	$$values ('users.login', 'anonymous', 'anonymous')$$,
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

/*
-- set password function
select has_function('users', 'set_password', array['text', 'text', 'text', 'text'], 'Needs an user set password function.');
select is_definer('users', 'set_password', array['text', 'text', 'text', 'text'], 'logout should have definer security.');
select function_returns('users', 'set_password', array['text', 'text', 'text', 'text'], 'void', 'logout should not return anything.');



select plan(105);

select has_column('users', 'user', 'active', 'Needs to have an Active users column.');
select col_type_is('users', 'user', 'active', 'boolean', 'Active needs to be boolean.');
select col_has_default('users', 'user', 'active', 'Active needs a default value.');


select has_column('users', 'user', 'email', 'Needs an email column.');
select col_type_is('users', 'user', 'email', 'text', 'Email needs to have a text input.');

-- function list table tests
select has_table('users', 'function', 'There should be a table for available functions');

select has_column('users', 'function', 'id', 'Needs to have a unique function id.');
select col_type_is('users', 'function', 'id', 'uuid', 'function id needs to ba a UUID.');
select col_is_pk('users', 'function', 'id', 'The function id is the primary key');

select has_column('users', 'function', 'code', 'Code a column of function names.');
select col_type_is('users', 'function', 'code', 'text', 'Function code needs to be text');
select col_not_null('users', 'function', 'code', 'Function code cannot be null');

select has_column('users', 'function', 'args', 'Args a column of function names.');
select col_type_is('users', 'function', 'args', 'integer', 'Function args needs to be int');
select col_not_null('users', 'function', 'args', 'Function args cannot be null');

insert into users.function (id, code, args) values 
	(uuid_generate_v4(), 'some code', 0);
select throws_like(
	$$insert into users.function (id, code, args) values 
		(uuid_generate_v4(), 'SOME CODE', 0)$$,
	'%violates unique constraint%',
	'Function code should be unique and case insensitive.'
);
delete from users.function where code = 'some code' or code = 'SOME CODE';

-- 

-- Tests for the login function
select web.clear_sessions();
delete from users.user where name = 'flintstone'; 
select web.set_session_data('session1', 'fred', now() + interval '1 day');
select users.validate(users.add('flintstone', 'secret', 'flintstone@bedrock.com'));
select results_eq(
	$$select users.login('session1', 'flintstone', 'super secret')$$,
	'values (false)',
	'A bad user login should return false.'
);

select web.clear_sessions();
delete from users.user where name = 'flintstone'; 
select web.set_session_data('session1', 'fred', now() + interval '1 day');
select users.add('flintstone', 'secret', 'flintstone@bedrock.com');
select results_eq(
	$$select users.login('session1', 'flintstone', 'secret')$$,
	'values (false)',
	'login should fail if the user is inactive.'
);

select web.clear_sessions();
delete from users.user where name = 'flintstone'; 
select web.set_session_data('session1', 'fred', now() + interval '1 day');
select users.validate(users.add('flintstone', 'secret', 'flintstone@bedrock.com'));
select results_eq(
	$$select users.login('session1', 'flintstone', 'secret')$$,
	'values (true)',
	'A good username and password should pass.'
);

select web.clear_sessions();
delete from users.user where name = 'flintstone'; 
select users.validate(users.add('flintstone', 'secret', 'flintstone@bedrock.com'));
select web.set_session_data('session1', 'fred', now() + interval '1 day');
select users.login('session1', 'flintstone', 'secret');
select results_eq(
	$$select user_id from users.session where sess_id = 'session1'$$,
	$$select id from users.user where name = 'flintstone'$$,
	'Session id should be associated with the user.'
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

-- group table


-- user group link table
select has_table('users', 'user_group_link', 'There needs to be a table that links users to groups.');

select has_column('users', 'user_group_link', 'group_id', 'Group link needs a group id column.');
select col_is_fk('users', 'user_group_link', 'group_id', 'Group id needs to link to groups id.');

select has_column('users', 'user_group_link', 'owner', 'Needs tell if user is the owner of the group.');
select col_type_is('users', 'user_group_link', 'owner', 'boolean', 'Group owner needs to be boolean.');
select col_has_default('users', 'user_group_link', 'owner', 'Group ownder needs a default value.');

select has_column('users', 'user_group_link', 'user_id', 'Group link needs a user id column.');
select col_is_fk('users', 'user_group_link', 'user_id', 'User id needs to link to user id.');

select throws_like(
	$$insert into users.user_group_link (group_id, owner, user_id) values
		((select id from users.group where name = 'admin'),
		true,
		(select id from users.user where name = 'admin'))$$,
	'%violates unique constraint%',
	'Allow group link to only have one user per group'
);

-- Make sure the admin, everyone, and authenticated groups are created.
select results_eq(
	$$select name from users.group$$,
	$$values ('admin'), ('everyone'), ('authenticated')$$,
	'There must be the initial three groups'
);

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