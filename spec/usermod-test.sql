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

select plan(15);

-- schema tests
select has_schema('users', 'There should be a schema for users.');

-- user table tests
select has_table('users', 'user', 'There should be a users table.');

select has_column('users', 'user', 'name', 'Need a column of user names.');
select col_type_is('users', 'user', 'name', 'text', 'User name needs to be text');
select col_is_pk('users', 'user', 'name', 'The user name is the primary key');

-- session table tests
select has_table('users', 'session', 'There should be a session linking users to sessions.');

select has_column('users', 'session', 'sess_id', 'sessions needs to have a session id.');
select col_is_pk('users', 'session', 'sess_id', 'Session ids need to be the primary key.');
select col_is_fk('users', 'session', 'sess_id', 'Should be foreign key to web.session.');

select has_column('users', 'session', 'name', 'Session needs a user column.');
select col_is_fk('users', 'session', 'name', 'Should be foreign key to user name.');

-- make sure there is an entry for the anonymous user.
select results_eq(
	$$select name from users.user where name = 'anonymous'$$,
	$$values ('anonymous')$$,
	'There should be an anonymous user installed with the database'
);

-- New sessesions should be assigned an anonymous user.
select web.clear_sessions();
select web.set_session_data('flintstone', 'fred', now() + interval '1 day');
select results_eq(
	$$select sess_id, name from users.session where sess_id = 'flintstone'$$,
	$$values ('flintstone', 'anonymous')$$,
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

select * from finish();

rollback;