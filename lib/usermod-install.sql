-- Database installation program for the user module.  

-- Functions for helping tests.  
create or replace function get_unused_test_group_name()
returns text as $$
	declare
		new_name	text;
		holder_id	uuid;
	begin
		loop
			select md5(random()::text) into new_name;
			select into holder_id id from users.group
				where name = lower(new_name);
			exit when not found;
		end loop;
		return new_name;
	end
$$ language plpgsql;

create or replace function get_test_group(
	out		id			uuid,
	out		name		text)
as $$
	begin
		select into name get_unused_test_group_name
			from get_unused_test_group_name();
		select into id create_group
			from users.create_group(name);
	end
$$ language plpgsql;

create or replace function get_test_user(
	out		id			uuid,
	out		name		text,
	out		password	text)
as $$
	begin
		select into name get_unused_test_group_name
			from get_unused_test_group_name();
		select md5(random()::text) into password;
		select into id create_user
			from users.create_user(name, password);
	end
$$ language plpgsql;

create or replace function get_logged_in_test_user(
	out		sess_id			text,
	out		sess_user_id	uuid,
	out		sess_user_name	text,
	out		sess_password	text)
as $$
	begin
		select into sess_id create_test_session
			from create_test_session();
		select into sess_user_id, sess_user_name, sess_password
			id, name, password from get_test_user();
		perform users.login(sess_id, sess_user_name, sess_password);
	end
$$ language plpgsql;

-- Schema tests
create or replace function test_users_schema_exists()
returns setof text as $test$
	begin
		return next has_schema('users',
			'There should be a special schema for users.');
	end 
$test$ language plpgsql;

-- Tests for support libraries
create or replace function test_users_for_uuid_ossp_installation()
returns setof text as $test$
	begin 
		return next isnt(
			findfuncs('public', '^uuid_'),
			'{}',
			'uuid-ossp needs to be installed into public.');
	end
$test$ language plpgsql;

create or replace function test_users_for_pgcrypto_installation()
returns setof text as $test$
	begin 
		return next isnt(
			findfuncs('public', '^crypt'),
			'{}',
			'pgcrypto needs to be installed into public.');
	end;
$test$ language plpgsql;

-- Tests for the group table
create or replace function test_users_table_group_exists()
returns setof text as $test$
	begin
		return next has_table('users', 'group', 'There should be a group table.');
	end
$test$ language plpgsql;

create or replace function test_users_table_group_col_id_exists()
returns setof text as $test$
	begin
		return next has_column('users', 'group', 'id', 
			'Group id must exist.');
	end
$test$ language plpgsql;

create or replace function test_users_table_group_col_id_is_pk()
returns setof text as $test$
	begin
		return next col_is_pk('users', 'group', 'id', 
			'Group id needs to be the primary key.');
	end
$test$ language plpgsql;

create or replace function test_users_table_group_col_name_exists()
returns setof text as $test$
	begin
		return next has_column('users', 'group', 'name',
			'Group name must exist.');
	end
$test$ language plpgsql;	

create or replace function test_users_table_group_col_special_exists()
returns setof text as $test$
	begin
		return next has_column('users', 'group', 'special',
			'Group table special column must exist.');
	end
$test$ language plpgsql;

create or replace function test_users_table_group_col_special_has_default()
returns setof text as $test$
	begin
		return next col_default_is('users', 'group', 'special', 'false',
			'Users.group.special must default to false.');
	end
$test$ language plpgsql;

create or replace function test_users_table_group_index_name_exists()
returns setof text as $$
	begin 
		return next has_index('users', 'group', 'groupname', 
			'lower(name)', 
			'Users.group.name must be lowercase.');
		return next index_is_unique('users', 'group', 'groupname',
			'Users.group.name must be unique.');
	end;
$$ language plpgsql;

-- Tests for the user table
create or replace function test_users_table_user_exists()
returns setof text as $test$
	begin
		return next has_table('users', 'user', 'There should be a user table.');
	end
$test$ language plpgsql;

create or replace function test_users_table_user_col_id_exists()
returns setof text as $test$
	begin
		return next has_column('users', 'user', 'id', 
			'User id must exist.');
	end
$test$ language plpgsql;

create or replace function test_users_table_user_col_id_is_fk()
returns setof text as $test$
	begin
		return next fk_ok('users', 'user', 'id',
			'users', 'group', 'id',
			'User id is a foreign key to the group id.');
	end
$test$ language plpgsql;

create or replace function test_users_table_user_col_password_exists()
returns setof text as $test$
	begin
		return next has_column('users', 'user', 'password',
			'User needs a password column.');
	end
$test$ language plpgsql;

-- Tests for the subgroup table
create or replace function test_users_table_subgroup_exists()
returns setof text as $test$
	begin
		return next has_table('users', 'subgroup', 
			'There should be a subgroup table.');
	end
$test$ language plpgsql;

create or replace function test_users_table_subgroup_col_parentid_exists()
returns setof text as $test$
	begin
		return next has_column('users', 'subgroup', 'parent_id',
			'Subgroup should have a parent id.');
	end
$test$ language plpgsql;

create or replace function test_users_table_subgroup_col_parentid_is_fk()
returns setof text as $test$
	begin
		return next fk_ok('users', 'subgroup', 'parent_id',
			'users', 'group', 'id',
			'Subgroup parent id should be a foreign key to group id.');
	end
$test$ language plpgsql;

create or replace function test_users_table_subgroup_col_parentid_deletes()
returns setof text as $test$
	declare
		user_name		text;
		group_name		text;
	begin
		select into user_name name
			from get_test_user();
		select into group_name name
			from get_test_group();
		perform users.add_group_member(group_name, user_name);
		return next lives_ok(
			$$select users.delete_group('$$ || group_name || $$')$$,
			'There should be no error when a group is deleted.'
		);
		return next is_empty(
			$$select name, is_group
				from users.group_members('$$ || group_name || $$')$$,
			'This should members to the group.');
	end
$test$ language plpgsql;

create or replace function test_users_table_subgroup_col_childid_exists()
returns setof text as $test$
	begin
		return next has_column('users', 'subgroup', 'child_id',
			'Subgroup should have a child id.');
	end
$test$ language plpgsql;

create or replace function test_users_table_subgroup_col_childid_is_fk()
returns setof text as $test$
	begin
		return next fk_ok('users', 'subgroup', 'child_id',
			'users', 'group', 'id',
			'Subgroup child id should be a foreign key to group id.');
	end
$test$ language plpgsql;

create or replace function test_users_table_subgroup_col_childid_deletes()
returns setof text as $test$
	declare
		user_name		text;
		group_name		text;
	begin
		select into user_name name
			from get_test_user();
		select into group_name name
			from get_test_group();
		perform users.add_group_member(group_name, user_name);
		return next lives_ok(
			$$select users.delete_group('$$ || user_name || $$')$$,
			'There should be no error when a group is deleted.'
		);
		return next results_eq(
			$$select name, is_group
				from users.group_members('$$ || group_name || $$')$$,
			$$values ('$$ || group_name || $$', true)$$,
			'The user should be removed.');
	end
$test$ language plpgsql;

-- Tests for the web session table.  
create or replace function test_web_table_session_col_userid_exists()
returns setof text as $test$
	begin
		return next has_column('web', 'session', 'user_id',
			'The session table needs to be linked to the user.');
	end
$test$ language plpgsql;

create or replace function test_web_table_session_col_userid_is_fk()
returns setof text as $test$
	begin
		return next fk_ok('web', 'session', 'user_id',
			'users', 'group', 'id',
			'Web user id is a foreign key to the group id.');
	end
$test$ language plpgsql;

create or replace function test_web_table_session_col_userid_default()
returns setof text as $test$
	begin
		return next col_default_is(
			'web', 'session', 'user_id', 'uuid_nil()',
			'Sessions should default to the anonymous user.');
	end
$test$ language plpgsql;

create or replace function test_web_table_session_deletes_with_user()
returns setof text as $test$
	declare
		user_id			uuid;
		user_name		text;
	begin
		select into user_id, user_name sess_user_id, sess_user_name
			from get_logged_in_test_user();
		perform users.delete_user(user_name);
		return next is_empty(
			$$select * from web.session
				where user_id = '$$ || user_id || $$'$$,
			'The session should delete with the attached user.');
	end
$test$ language plpgsql;

-- Tests for special users and groups
create or replace function test_users_special_user_anonymous_exists()
returns setof text as $test$
	begin
		return next results_eq(
			$$select users.group.id, users.group.name, users.user.password
				from users.group, users.user
				where users.group.id = users.user.id
					and users.group.name = 'anonymous'$$,
			$$values (uuid_nil(), 'anonymous', '')$$,
			'There should be an anonymous user.');
	end
$test$ language plpgsql;

create or replace function test_users_special_user_anonymous_cannot_delete()
returns setof text as $test$
	begin
		return next throws_ok(
			$$select users.delete_user('anonymous')$$,
			'P0001', 'Cannot change special groups.',
			'The Anonymous user cannot be deleted.');                                                                                                            
		return next throws_ok(
			$$delete from users.user 
				where id = uuid_nil()$$,
			'P0001', 'Anonymous cannot be changed.',
			'The Anonymous password cannot be deleted.');
	end
$test$ language plpgsql;

create or replace function test_users_special_user_anonymous_cannot_change()
returns setof text as $test$
	declare 
		new_name		text;
	begin
		select into new_name get_unused_test_group_name
			from get_unused_test_group_name();
		return next throws_ok(
			$$select users.change_user_name('anonymous', 
				'$$ || new_name || $$')$$,
			'P0001', 'Cannot change special groups.',
			'The anonymous user cannot change it''s name.');
	end
$test$ language plpgsql;

create or replace function test_users_special_user_anonymous_has_empty_password()
returns setof text as $test$
	begin
		return next throws_ok(
			$$select users.change_password('anonymous', 'different')$$,
			'P0001', 'Anonymous cannot be changed.',
			'The anonymous user cannot change password.');
	end
$test$ language plpgsql;

create or replace function test_users_special_group_admin_exists()
returns setof text as $test$
	begin
		return next results_eq(
			$$select name, special from users.group
				where id = users.get_special_group_id('admin')$$,
			$$values ('admin', true)$$,
			'Admin should exist as a special group.');
	end
$test$ language plpgsql;

create or replace function test_users_special_group_authenticated_exists()
returns setof text as $test$
	begin
		return next results_eq(
			$$select name, special from users.group
				where id = users.get_special_group_id('authenticated')$$,
			$$values ('authenticated', true)$$,
			'Authenticated should exist as a special group.');
	end
$test$ language plpgsql;

create or replace function test_users_special_group_allusers_exists()
returns setof text as $test$
	begin
		return next results_eq(
			$$select name, special from users.group
				where id = users.get_special_group_id('all users')$$,
			$$values ('all users', true)$$,
			'All users should exist as a special group.');
	end
$test$ language plpgsql;

-- Tests for get special group ids
create or replace function test_users_function_getspecialgroupid_exists()
returns setof text as $test$
	begin 
		return next function_returns('users', 'get_special_group_id', 
			array['text'], 'uuid', 
			'There needs to be a get special group id function.');
		return next is_definer('users', 'get_special_group_id',
			array['text'], 
			'Get special group id needs to security definer access.');
	end;
$test$ language plpgsql;

create or replace function test_users_function_getspecialgroupid_adds_data()
returns setof text as $test$
	declare
		special_name		text;
	begin
		select into special_name get_unused_test_group_name
			from get_unused_test_group_name();
		return next results_eq(
			$$select * from users.get_special_group_id(
				'$$ || special_name || $$')$$,
			$$select * from uuid_generate_v5(public.uuid_ns_x500(), 
				'$$ || special_name || $$')$$,
			'This should return the id of the special group.');
	end
$test$ language plpgsql;

-- Test for creating special groups.
create or replace function test_users_function_createspecialgroup_exists()
returns setof text as $test$
	begin 
		return next function_returns('users', 'create_special_group', 
			array['text'], 'void', 
			'There needs to be a create special group function.');
		return next is_definer('users', 'create_special_group', 
			array['text'], 
			'Create special group needs to security definer access.');
	end;
$test$ language plpgsql;

create or replace function test_users_function_createspecialgroup_adds_data()
returns setof text as $test$
	declare
		group_name		text;
	begin
		select into group_name get_unused_test_group_name
			from get_unused_test_group_name();
		perform users.create_special_group(group_name);
		return next results_eq(
			$$select id, name, special
				from users.group
				where name = '$$ || group_name || $$'$$,
			$$values (uuid_generate_v5(public.uuid_ns_x500(),
				'$$ || group_name || $$'), '$$ || group_name || $$',
				true)$$,
			'Create special group should create the entry.');
	end
$test$ language plpgsql;

create or replace function test_users_table_group_special_groups_cannot_delete()
returns setof text as $test$
	declare
		group_name		text;
	begin
		select into group_name get_unused_test_group_name
			from get_unused_test_group_name();
		perform users.create_special_group(group_name);
		return next throws_ok(
			$$select users.delete_group('$$ || group_name || $$')$$,
			'P0001', 'Cannot change special groups.',
			'Special groups cannot be deleted.');
	end
$test$ language plpgsql;

create or replace function test_users_table_group_special_groups_cannot_modify()
returns setof text as $test$
	declare
		group_name		text;
	begin
		select into group_name get_unused_test_group_name
			from get_unused_test_group_name();
		perform users.create_special_group(group_name);
		return next throws_ok(
			$$update users.group set special = false 
				where name = '$$ || group_name || $$'$$,
			'P0001', 'Cannot change special groups.',
			'Special groups cannot be changed.');
	end
$test$ language plpgsql;

create or replace function test_users_table_group_special_groups_cannot_be_user()
returns setof text as $test$
	declare
		group_name		text;
	begin
		select into group_name get_unused_test_group_name
			from get_unused_test_group_name();
		perform users.create_special_group(group_name);
		return next throws_ok(
			$$insert into users.user (id, password) values
				(users.get_special_group_id('$$ || group_name || $$'),
				'password')$$,
			'P0001', 'Special groups cannot be users.',
			'Special groups cannot be made into users.');
	end
$test$ language plpgsql;

create or replace function test_users_table_group_special_groups_cannot_have_password()
returns setof text as $test$
	declare
		user_id			uuid;
		group_name		text;
	begin
		select into user_id id
			from get_test_user();
		select into group_name get_unused_test_group_name
			from get_unused_test_group_name();
		perform users.create_special_group(group_name);
		return next throws_ok(
			$$update users.user 
				set id = users.get_special_group_id('$$ || group_name || $$')
				where id = '$$ || user_id || $$'$$,
			'P0001', 'Special groups cannot be users.',
			'Existing user passwords cannot be assigned to special groups.');
	end 
$test$ language plpgsql;

-- Tests for the create group function
create or replace function test_users_function_creategroup_exists()
returns setof text as $test$
	begin 
		return next function_returns('users', 'create_group',
			array['text'], 'uuid', 
			'There needs to be a create group function.');
		return next is_definer('users', 'create_group', 
			array['text'], 
			'Create group needs to security definer access.');
	end;
$test$ language plpgsql;

create or replace function test_users_function_creategroup_adds_data()
returns setof text as $test$
	declare
		new_name	text;
		holder_id	uuid;
	begin
		select into new_name get_unused_test_group_name
			from get_unused_test_group_name();
		select into holder_id create_group 
			from users.create_group(new_name);
		return next results_eq(
			$$select id, name from users.group
				where name = '$$ || new_name || $$'$$,
			$$values ('$$ || holder_id || $$'::uuid, 
				'$$ || new_name || $$')$$,
			'Create group should enter data into the table.');
	end
$test$ language plpgsql;

-- Tests for the delete group function
create or replace function test_users_function_deletegroup_exists()
returns setof text as $test$
	begin 
		return next function_returns('users', 'delete_group',
			array['text'], 'void', 
			'There needs to be a delete group function.');
		return next is_definer('users', 'delete_group', 
			array['text'], 
			'Delete group needs to security definer access.');
	end;
$test$ language plpgsql;

create or replace function test_users_function_deletegroup_removes_data()
returns setof text as $test$
	declare
		new_name	text;
	begin
		select into new_name name
			from get_test_group();
		perform users.delete_group(new_name);
		return next is_empty(
			$$select * from users.group
				where name = '$$ || new_name || $$'$$,
			'Delete group should remove data.');
	end
$test$ language plpgsql;

create or replace function test_users_function_deletegroup_not_case_sensitive()
returns setof text as $test$
	declare
		new_name	text;
	begin
		select into new_name name
			from get_test_group();
		perform users.delete_group(upper(new_name));
		return next is_empty(
			$$select * from users.group
				where name = '$$ || new_name || $$'$$,
			'Delete group should remove data.');
	end
$test$ language plpgsql;

-- Tests for changing the group name
create or replace function test_users_function_changegroupname_exists()
returns setof text as $test$
	begin 
		return next function_returns('users', 'change_group_name',
			array['text', 'text'], 'void', 
			'There needs to be a change group name function.');
		return next is_definer('users', 'change_group_name', 
			array['text', 'text'], 
			'Change group name needs to security definer access.');
	end;
$test$ language plpgsql;

create or replace function test_users_function_changegroupname_updates()
returns setof text as $test$
	declare
		user_id			uuid;
		old_name		text;
		new_name		text;
	begin
		select into old_name name
			from get_test_group();
		select into new_name get_unused_test_group_name
			from get_unused_test_group_name();
		select into user_id id
			from users.group
			where name = lower(old_name);
		perform users.change_group_name(old_name, new_name);
		return next results_eq(
			$$select name from users.group
				where id = '$$ || user_id || $$'$$,
			$$values ('$$ || new_name || $$')$$,
			'Change name should change the group name.');
	end
$test$ language plpgsql;

create or replace function test_users_function_changegroupname_case_insensitive()
returns setof text as $test$
	declare
		user_id			uuid;
		old_name		text;
		new_name		text;
	begin
		select into old_name name
			from get_test_group();
		select into new_name get_unused_test_group_name
			from get_unused_test_group_name();
		select into user_id id
			from users.group
			where name = lower(old_name);
		perform users.change_group_name(upper(old_name), new_name);
		return next results_eq(
			$$select name from users.group
				where id = '$$ || user_id || $$'$$,
			$$values ('$$ || new_name || $$')$$,
			'Change name should change the group name.');
	end
$test$ language plpgsql;

create or replace function test_users_function_changegroupname_gives_error()
returns setof text as $test$
	declare
		old_name		text;
		new_name		text;
	begin
		select into old_name get_unused_test_group_name
			from get_unused_test_group_name();
		select into new_name get_unused_test_group_name
			from get_unused_test_group_name();
		return next throws_ok(
			$$select users.change_group_name('$$ || old_name || $$',
				'$$ || new_name || $$')$$,
				'P0001', 'User does not exist',
				'Change group should throw error if user does not exist.');
	end
$test$ language plpgsql;

-- Tests for create user function
create or replace function test_users_function_createuser_exists()
returns setof text as $test$
	begin 
		return next function_returns('users', 'create_user',
			array['text', 'text'], 'uuid', 
			'There needs to be a create user function.');
		return next is_definer('users', 'create_user', 
			array['text', 'text'], 
			'Create user needs to security definer access.');
	end;
$test$ language plpgsql;

create or replace function test_users_function_createuser_adds_data()
returns setof text as $test$
	declare
		user_id		uuid;
		user_name	text;
	begin
		select into user_name get_unused_test_group_name
			from get_unused_test_group_name();
		select into user_id create_user
			from users.create_user(user_name, 'password');
		return next results_eq(
			$$select id, name from users.group
				where name = '$$ || user_name || $$'$$,
			$$values ('$$ || user_id || $$'::uuid, 
				'$$ || user_name || $$')$$,
			'Create user should create the user''s group.');
		return next results_eq(
			$$select id from users.user
				where id = '$$ || user_id || $$'$$,
			$$values ('$$ || user_id || $$'::uuid)$$,
			'The password information needs to be stored in the user table.');
		return next results_ne(
			$$select password from users.user
				where id = '$$ || user_id || $$'$$,
			$$values ('password')$$,
			'User password should be encrypted.');
	end
$test$ language plpgsql;

-- Tests for the delete user function
create or replace function test_users_function_deleteuser_exists()
returns setof text as $test$
	begin 
		return next function_returns('users', 'delete_user',
			array['text'], 'void', 
			'There needs to be a delete user function.');
		return next is_definer('users', 'delete_user', 
			array['text'], 
			'Delete user needs to security definer access.');
	end
$test$ language plpgsql;

create or replace function test_users_function_deleteuser_removes_data()
returns setof text as $test$
	declare
		user_id		uuid;
		user_name	text;
	begin
		select into user_name get_unused_test_group_name
			from get_unused_test_group_name();
		select into user_id create_user
			from users.create_user(user_name, 'password');
		perform users.delete_user(user_name);
		return next is_empty(
			$$select * from users.group
				where id = '$$ || user_id || $$'$$,
			'Delete user should remove the associated group.');
		return next is_empty(
			$$select * from users.user
				where id = '$$ || user_id || $$'$$,
			'Delete user should remove the user information.');
	end
$test$ language plpgsql;

-- Tests for the change user name function
create or replace function test_users_function_changeusername_exists()
returns setof text as $test$
	begin 
		return next function_returns('users', 'change_user_name',
			array['text', 'text'], 'void', 
			'There needs to be a change user name function.');
		return next is_definer('users', 'change_user_name', 
			array['text', 'text'], 
			'Change user name needs to security definer access.');
	end
$test$ language plpgsql;

create or replace function test_users_function_changeusername_updates()
returns setof text as $test$
	declare
		user_id			uuid;
		old_name		text;
		new_name		text;
	begin
		select into old_name name
			from get_test_group();
		select into new_name get_unused_test_group_name
			from get_unused_test_group_name();
		select into user_id id
			from users.group
			where name = lower(old_name);
		perform users.change_user_name(old_name, new_name);
		return next results_eq(
			$$select name from users.group
				where id = '$$ || user_id || $$'$$,
			$$values ('$$ || new_name || $$')$$,
			'Change name should change the user name.');
	end
$test$ language plpgsql;

-- Tests for the login function
create or replace function test_users_function_login_exists()
returns setof text as $test$
	begin 
		return next function_returns('users', 'login',
			array['text', 'text', 'text'], 'void', 
			'There needs to be a login function.');
		return next is_definer('users', 'login', 
			array['text', 'text', 'text'], 
			'Login needs to security definer access.');
	end
$test$ language plpgsql;

create or replace function test_users_function_login_logs_in()
returns setof text as $test$
	declare
		session_id		text;
		user_name		text;
		passwd			text;
	begin
		select into session_id create_test_session
			from create_test_session();
		select into user_name, passwd name, password
			from get_test_user();
		perform users.login(session_id, user_name, passwd);
		return next results_eq(
			$$select user_id from web.session
				where sess_id = '$$ || session_id || $$'$$,
			$$select id from users.group
				where name = '$$ || user_name || $$'$$,
			'Login should set the user for the session.');
	end
$test$ language plpgsql;

create or replace function test_users_function_login_not_case_sensitive()
returns setof text as $test$
	declare
		session_id		text;
		user_name		text;
		passwd			text;
	begin
		select into session_id create_test_session
			from create_test_session();
		select into user_name, passwd name, password
			from get_test_user();
		perform users.login(session_id, upper(user_name), passwd);
		return next results_eq(
			$$select user_id from web.session
				where sess_id = '$$ || session_id || $$'$$,
			$$select id from users.group
				where name = '$$ || user_name || $$'$$,
			'Login should set the user for the session.');
	end
$test$ language plpgsql;

create or replace function test_users_function_login_errors_on_failure()
returns setof text as $test$
	declare
		session_id		text;
		user_name		text;
		passwd			text:='wrong';
	begin
		select into session_id create_test_session
			from create_test_session();
		select into user_name name
			from get_test_user();
		return next throws_ok(
			$$select users.login('$$ || session_id || $$', 
				'$$ || user_name || $$', 
				'$$ || passwd || $$')$$,
			'P0001', 'Invalid user name or password',
			'Login should error if user name or password is bad.');
	end
$test$ language plpgsql;

create or replace function test_users_function_login_errors_on_sessionid()
returns setof text as $test$
	declare
		session_id		text;
		user_name		text;
		passwd			text;
	begin
		select into session_id new_session_id
			from new_session_id();
		select into user_name, passwd name, password
			from get_test_user();
		return next throws_ok(
			$$select users.login('$$ || session_id || $$', 
				'$$ || user_name || $$', 
				'$$ || passwd || $$')$$,
			'P0001', 'Invalid session id',
			'Login should error if user name or password is bad.');
	end
$test$ language plpgsql;

-- Tests for the logout function
create or replace function test_users_function_logout_exists()
returns setof text as $test$
	begin 
		return next function_returns('users', 'logout',
			array['text'], 'void', 
			'There needs to be a logout function.');
		return next is_definer('users', 'logout', 
			array['text'], 
			'Logout needs to security definer access.');
	end
$test$ language plpgsql;

create or replace function test_users_function_logout_logs_out()
returns setof text as $test$
	declare
		session_id		text;
	begin
		select into session_id sess_id
			from get_logged_in_test_user();
		perform users.logout(session_id);
		return next results_eq(
			$$select user_id from web.session
				where sess_id = '$$ || session_id || $$'$$,
			'values (uuid_nil())',
			'Logout should reset the session user back to anonymous.');
	end
$test$ language plpgsql;

create or replace function test_users_function_logout_errors_on_bad_id()
returns setof text as $test$
	declare
		session_id		text;
	begin
		select into session_id new_session_id
			from new_session_id();
		return next throws_ok(
			$$select users.logout('$$ || session_id || $$')$$,
			'P0001', 'Invalid session id',
			'Logout should throw an error for an invalid session.');
	end
$test$ language plpgsql;

-- Tests for change password function.
create or replace function test_users_function_changepasword_exists()
returns setof text as $test$
	begin 
		return next function_returns('users', 'change_password',
			array['text', 'text'], 'void', 
			'There needs to be a change password function.');
		return next is_definer('users', 'change_password', 
			array['text', 'text'], 
			'Change password needs to security definer access.');
	end
$test$ language plpgsql;

create or replace function test_users_function_changepassword_changes_password()
returns setof text as $test$
	declare
		session_id		text;
		user_name		text;
	begin
		select into session_id create_test_session
			from create_test_session();
		select into user_name name
			from get_test_user();
		perform users.change_password(user_name, 'different');
		return next lives_ok(
			$$select users.login('$$ || session_id || $$',
				'$$ || user_name || $$', 'different')$$,
			'Change password should change the password.');
	end
$test$ language plpgsql;

create or replace function test_users_function_changepassword_case_independent()
returns setof text as $test$
	declare
		session_id		text;
		user_name		text;
	begin
		select into session_id create_test_session
			from create_test_session();
		select into user_name name
			from get_test_user();
		perform users.change_password(upper(user_name), 'different');
		return next lives_ok(
			$$select users.login('$$ || session_id || $$',
				'$$ || user_name || $$', 'different')$$,
			'Change password should be case independent user name.');
	end
$test$ language plpgsql;

create or replace function test_users_function_changepassword_throws_error()
returns setof text as $test$
	declare
		user_name		text;
	begin
		select into user_name get_unused_test_group_name
			from get_unused_test_group_name();
		return next throws_ok(
			$$select users.change_password('$$ || user_name || $$', 'different')$$,
			'P0001', 'Invalid user name',
			'Should throw an error if the user name is invalid.');
	end
$test$ language plpgsql;

-- Tests for add group members
create or replace function test_users_function_addgroupmember_exists()
returns setof text as $test$
	begin 
		return next function_returns('users', 'add_group_member',
			array['text', 'text'], 'void', 
			'There needs to be a add group members function.');
		return next is_definer('users', 'add_group_member', 
			array['text', 'text'], 
			'Add group members needs to security definer access.');
	end
$test$ language plpgsql;

create or replace function test_users_function_addgroupmember_adds_member()
returns setof text as $test$
	declare
		user_name		text;
		group_name		text;
	begin
		select into user_name name
			from get_test_user();
		select into group_name name
			from get_test_group();
		perform users.add_group_member(group_name, user_name);
		return next set_eq(
			$$select name, is_group
				from users.group_members('$$ || group_name || $$')$$,
			$$values ('$$ || group_name || $$', true),
				('$$ || user_name || $$', false)$$,
			'This should members to the group.');
	end
$test$ language plpgsql;

create or replace function test_users_function_addgroupmember_no_duplicates()
returns setof text as $test$
	declare
		user_name		text;
		group_name		text;
	begin
		select into user_name name
			from get_test_user();
		select into group_name name
			from get_test_group();
		perform users.add_group_member(group_name, user_name);
		return next throws_ok(
			$$select users.add_group_member('$$ || group_name || $$',
				'$$ || user_name || $$')$$,
			'23505', 'duplicate key value violates unique constraint "subgroup_pkey"',
			'There should be no duplicates subgroups.');
	end
$test$ language plpgsql;

create or replace function test_users_function_addgroupmember_case_insensitive()
returns setof text as $test$
	declare
		user_name		text;
		group_name		text;
	begin
		select into user_name name
			from get_test_user();
		select into group_name name
			from get_test_group();
		perform users.add_group_member(upper(group_name), upper(user_name));
		return next set_eq(
			$$select name, is_group
				from users.group_members('$$ || group_name || $$')$$,
			$$values ('$$ || group_name || $$', true),
				('$$ || user_name || $$', false)$$,
			'This should members to the group.');
	end
$test$ language plpgsql;

-- Test for removing a group member.
create or replace function test_users_function_removegroupmember_exists()
returns setof text as $test$
	begin 
		return next function_returns('users', 'remove_group_member',
			array['text', 'text'], 'void', 
			'There needs to be a remove group members function.');
		return next is_definer('users', 'remove_group_member', 
			array['text', 'text'], 
			'Remove group members needs to security definer access.');
	end
$test$ language plpgsql;

create or replace function test_users_function_removegroupmember_removes_member()
returns setof text as $test$
	declare
		user_name		text;
		group_name		text;
	begin
		select into user_name name
			from get_test_user();
		select into group_name name
			from get_test_group();
		perform users.add_group_member(group_name, user_name);
		perform users.remove_group_member(group_name, user_name);
		return next set_eq(
			$$select name, is_group
				from users.group_members('$$ || group_name || $$')$$,
			$$values ('$$ || group_name || $$', true)$$,
			'This should remove members to the group.');
	end
$test$ language plpgsql;

create or replace function test_users_function_removegroupmember_group_case()
returns setof text as $test$
	declare
		user_name		text;
		group_name		text;
	begin
		select into user_name name
			from get_test_user();
		select into group_name name
			from get_test_group();
		perform users.add_group_member(group_name, user_name);
		perform users.remove_group_member(upper(group_name), user_name);
		return next set_eq(
			$$select name, is_group
				from users.group_members('$$ || group_name || $$')$$,
			$$values ('$$ || group_name || $$', true)$$,
			'This should remove members to the group.');
	end
$test$ language plpgsql;

create or replace function test_users_function_removegroupmember_member_case()
returns setof text as $test$
	declare
		user_name		text;
		group_name		text;
	begin
		select into user_name name
			from get_test_user();
		select into group_name name
			from get_test_group();
		perform users.add_group_member(group_name, user_name);
		perform users.remove_group_member(group_name, upper(user_name));
		return next set_eq(
			$$select name, is_group
				from users.group_members('$$ || group_name || $$')$$,
			$$values ('$$ || group_name || $$', true)$$,
			'This should remove members to the group.');
	end
$test$ language plpgsql;

-- Tests for view group members
create or replace function test_users_function_groupmembers_exists()
returns setof text as $test$
	begin 
		return next function_returns('users', 'group_members',
			array['text'], 'setof record', 
			'There needs to be a view group members function.');
		return next is_definer('users', 'group_members', 
			array['text'], 
			'View group members needs to security definer access.');
	end
$test$ language plpgsql;

create or replace function test_users_function_groupmembers_returns_group()
returns setof text as $test$
	declare
		group_name		text;
	begin
		select into group_name name
			from get_test_group();
		return next results_eq(
			$$select name, is_group 
				from users.group_members('$$ || group_name || $$')$$,
			$$values ('$$ || group_name || $$', true)$$,
			'An empty group should return itself and identify itself as a group.');
	end
$test$ language plpgsql;

create or replace function test_users_function_groupmembers_returns_user()
returns setof text as $test$
	declare
		user_name		text;
	begin
		select into user_name name
			from get_test_user();
		return next results_eq(
			$$select name, is_group 
				from users.group_members('$$ || user_name || $$')$$,
			$$values ('$$ || user_name || $$', false)$$,
			'A user should return itself and identify itself as not a group.');
	end
$test$ language plpgsql;

create or replace function test_users_function_groupmembers_get_all_members()
returns setof text as $test$
	declare
		user_id			uuid;
		user_name		text;
		group_id		uuid;
		group_name		text;
		parent_id		uuid;
		parent_name		text;
	begin
		select into user_id, user_name id, name
			from get_test_user();
		select into group_id, group_name id, name
			from get_test_group();
		select into parent_id, parent_name id, name
			from get_test_group();
		perform users.add_group_member(group_name, user_name);
		perform users.add_group_member(parent_name, group_name);
		return next set_eq(
			$$select name, is_group
				from users.group_members('$$ || parent_name || $$')$$,
			$$values ('$$ || group_name || $$', true),
				('$$ || user_name || $$', false),
				('$$ || parent_name || $$', true)$$,
			'This should report all of the group members.');
	end
$test$ language plpgsql;

create or replace function test_users_function_groupmembers_get_no_infinite_loop()
returns setof text as $test$
	declare
		user_id			uuid;
		user_name		text;
		group_id		uuid;
		group_name		text;
		parent_id		uuid;
		parent_name		text;
	begin
		select into user_id, user_name id, name
			from get_test_user();
		select into group_id, group_name id, name
			from get_test_group();
		select into parent_id, parent_name id, name
			from get_test_group();
		perform users.add_group_member(group_name, user_name);
		perform users.add_group_member(parent_name, group_name);
		perform users.add_group_member(user_name, parent_name);
		return next set_eq(
			$$select name, is_group
				from users.group_members('$$ || parent_name || $$')$$,
			$$values ('$$ || group_name || $$', true),
				('$$ || user_name || $$', false),
				('$$ || parent_name || $$', true)$$,
			'This should report all of the group members.');
	end
$test$ language plpgsql;

create or replace function test_users_function_groupmembers_case_insensitive()
returns setof text as $test$
	declare
		user_id			uuid;
		user_name		text;
		group_id		uuid;
		group_name		text;
		parent_id		uuid;
		parent_name		text;
	begin
		select into user_id, user_name id, name
			from get_test_user();
		select into group_id, group_name id, name
			from get_test_group();
		select into parent_id, parent_name id, name
			from get_test_group();
		perform users.add_group_member(group_name, user_name);
		perform users.add_group_member(parent_name, group_name);
		return next set_eq(
			$$select name, is_group
				from users.group_members('$$ || upper(parent_name) || $$')$$,
			$$values ('$$ || group_name || $$', true),
				('$$ || user_name || $$', false),
				('$$ || parent_name || $$', true)$$,
			'This should report all of the group members.');
	end
$test$ language plpgsql;

-- Installation/Update function
create or replace function correct_users()
returns setof text as $func$
	begin
		-- Creating Schemas
		if failed_test('test_users_schema_exists') then
			create schema users;
			return next 'Created users schema';
		end if;
		
		-- Creating tables
		if failed_test('test_users_table_group_exists') then
			create table users.group();
			return next 'Created the group table.';
		end if;
		if failed_test('test_users_table_group_col_id_exists') then
			alter table users.group
				add column id uuid;
			return next 'Added the users.group.id column.';
		end if;
		if failed_test('test_users_table_group_col_id_is_pk') then
			alter table users.group
				add primary key (id);
			return next 'Made users.group.id the primary key.';
		end if;
		if failed_test('test_users_table_group_col_name_exists') then
			alter table users.group
				add column name text;
			return next 'Added the users.group.name column.';
		end if;
		if failed_test('test_users_table_group_col_special_exists') then
			alter table users.group
				add column special boolean;
			return next 'Added the users.group.special column.';
		end if;
		if failed_test('test_users_table_group_col_special_has_default') then
			alter table users.group
				alter column special set default false;
			return next 'Set users.group.special default to false.';
		end if;
		
		if failed_test('test_users_table_group_index_name_exists') then
			drop index if exists users.groupname;
			create unique index groupname 
				on users.group (lower(name));
			return next 'Created users.group.name index.';
		end if;
		
		if failed_test('test_users_table_subgroup_exists') then
			create table users.subgroup();
			return next 'Created the subgroup table.';
		end if;
		if failed_test('test_users_table_subgroup_col_parentid_exists') then
			alter table users.subgroup
				add column parent_id uuid;
			return next 'Added the users.subgroup.parent_id column.';
		end if;
		if failed_test('test_users_table_subgroup_col_parentid_is_fk') 
			or failed_test('test_users_table_subgroup_col_parentid_deletes') then
			alter table users.subgroup
				drop constraint if exists subgroup_parentid;
			alter table users.subgroup
				add constraint subgroup_parentid
				foreign key (parent_id)
				references users.group (id)
				on delete cascade;
			return next 'Created the subgroup foreign key for parent id.';
		end if;
		if failed_test('test_users_table_subgroup_col_childid_exists') then
			alter table users.subgroup
				add column child_id uuid;
			return next 'Added the users.subgroup.child_id column.';
		end if;
		if failed_test('test_users_table_subgroup_col_childid_is_fk')
			or failed_test('test_users_table_subgroup_col_childid_deletes') then
			alter table users.subgroup
				drop constraint if exists subgroup_childid;
			alter table users.subgroup
				add constraint subgroup_childid
				foreign key (child_id)
				references users.group (id)
				on delete cascade;
			return next 'Created the subgroup foreign key for child id.';
		end if;
		if failed_test('test_users_function_addgroupmember_no_duplicates') then
			alter table users.subgroup
				add primary key (parent_id, child_id);
		end if;
		
		if failed_test('test_users_table_user_exists') then
			create table users.user();
			return next 'Created the user table.';
		end if;
		if failed_test('test_users_table_user_col_id_exists') then
			alter table users.user
				add column id uuid;
			return next 'Added the users.user.id column.';
		end if;
		if failed_test('test_users_table_user_col_id_is_fk') then
			alter table users.user
				drop constraint if exists group_user_id;
			alter table users.user
				add constraint group_user_id
				foreign key (id)
				references users.group (id)
				on delete cascade;
			return next 'Setup the user and group id foreign keys.';
		end if;
		if failed_test('test_users_table_user_col_password_exists') then
			alter table users.user
				add column password text;
			return next 'Added the users.user.password column.';
		end if;
		
		if failed_test('test_web_table_session_col_userid_exists') then
			alter table web.session
				add column user_id uuid;
			return next 'Added the web.session.user_id column.';
		end if;
		if failed_test('test_web_table_session_col_userid_is_fk') then
			alter table web.session
				drop constraint if exists session_user_id;
			alter table web.session
				add constraint session_user_id
				foreign key (user_id)
				references users.group (id)
				on delete cascade;
			return next 'Added the session user id foreign key.';
		end if;
		if failed_test('test_web_table_session_col_userid_default') then
			alter table web.session 
				alter column user_id set default uuid_nil();
			return next 'Set sessions to start with the anonymous user.';
		end if;
		
		-- Create database views
		create or replace view users.grouplist as 
			select users.group.id,
				users.group.name,
				users.subgroup.child_id,
				case
					when users.user.id is null then true
					else false
				end as is_group
			from users.group
			left outer join users.subgroup
				on (users.group.id = users.subgroup.parent_id)
			left outer join users.user
				on (users.group.id = users.user.id);
		return next 'Create the users.grouplist view';
		
		-- Drop triggers so they can be updated
		drop trigger if exists protect_anonymous_password on users.user;
		drop trigger if exists protect_special_groups on users.group;
		drop trigger if exists prevent_special_users on users.user;

		-- Create trigger functions
		create or replace function users.protect_anonymous()
		returns trigger as $$
			begin
				if OLD.id = public.uuid_nil() then 
					raise 'Anonymous cannot be changed.';
				end if;
				if TG_OP = 'UPDATE' then
					return NEW;
				end if;
				if TG_OP = 'DELETE' then
					return OLD;
				end if;
			end;
		$$ language plpgsql security definer
		set search_path = users, pg_temp;
		return next 'Created trigger function users.protect_anonymous.';
		
		create or replace function users.protect_special_groups()
		returns trigger as $$
			begin
				if OLD.special 
				or OLD.id = public.uuid_nil() then
					raise 'Cannot change special groups.';
				end if;
				if TG_OP = 'UPDATE' then
					return NEW;
				end if;
				if TG_OP = 'DELETE' then
					return OLD;
				end if;
			end
		$$ language plpgsql security definer
		set search_path = users, pg_temp;
		return next 'Created trigger function users.protect_special_groups.';
		
		create or replace function users.prevent_special_users()
		returns trigger as $$
			declare
				user_name		text;
			begin
				select into user_name name
					from users.group
					where users.group.id = NEW.id
						and users.group.special = true;
				if found then
					raise 'Special groups cannot be users.';
				end if;
				return NEW;
			end
		$$ language plpgsql security definer
		set search_path = users, pg_temp;
		return next 'Created trigger function users.prevent_special_users.';
		
		-- Create triggers
		create trigger protect_anonymous_password
			before update or delete
			on users.user
			for each row execute procedure users.protect_anonymous();
		return next 'Created the protect anonymous password trigger.';
		
		create trigger protect_special_groups
			before update or delete
			on users.group
			for each row execute procedure users.protect_special_groups();
		return next 'Created the protect special groups trigger.';
		
		create trigger prevent_special_users
			before insert or update
			on users.user
			for each row execute procedure users.prevent_special_users();
		return next 'Created the prevent special users trigger.';

		-- Create functions
		create or replace function users.get_special_group_id(
			group_name		text)
		returns uuid as $$
			begin
				return public.uuid_generate_v5(public.uuid_ns_x500(), group_name);
			end 
		$$ language plpgsql security definer
		set search_path = users, pg_temp;
		return next 'Created function users.get_special_group_id.';
		
		create or replace function users.create_special_group(
			group_name		text)
		returns void as $$
			begin
				insert into users.group (id, name, special) values
					(users.get_special_group_id(group_name), 
						group_name, true);
			end
		$$ language plpgsql security definer
		set search_path = users, pg_temp;
		return next 'Created function users.create_special_group.';
		
		create or replace function users.create_group(
			group_name		text)
		returns uuid as $$
			declare
				new_id		uuid;
				holder_id	uuid;
			begin
				loop
					select into new_id uuid_generate_v4
						from public.uuid_generate_v4();
					select into holder_id id from users.group
						where id = new_id;
					exit when not found;
				end loop;
				insert into users.group (id, name) values
					(new_id, group_name);
				return new_id;
			end
		$$ language plpgsql security definer
		set search_path = users, pg_temp;
		return next 'Created function users.create_group.';
		
		create or replace function users.delete_group(
			group_name		text)
		returns void as $$
			begin
				delete from users.group
					where name = lower(group_name);
			end
		$$ language plpgsql security definer
		set search_path = users, pg_temp;
		return next 'Created function users.delete_group.';
		
		create or replace function users.create_user(
			user_name		text,
			password		text)
		returns uuid as $$
			declare
				user_id		uuid;
			begin
				select into user_id create_group
					from users.create_group(user_name);
				insert into users.user (id, password) values
					(user_id, public.crypt(password, public.gen_salt('bf')));
				return user_id;
			end
		$$ language plpgsql security definer
		set search_path = users, pg_temp;
		return next 'Created function users.create_user.';
		
		create or replace function users.delete_user(
			user_name		text)
		returns void as $$
			begin
				perform users.delete_group(user_name);
			end
		$$ language plpgsql security definer
		set search_path = users, pg_temp;
		return next 'Created function users.delete_user.';
		
		create or replace function users.change_group_name(
			old_user_name	text,
			new_user_name	text)
		returns void as $$
			begin
				update users.group set name = new_user_name
					where name = lower(old_user_name);
				if not found then
					raise 'User does not exist';
				end if;
			end
		$$ language plpgsql security definer
		set search_path = users, pg_temp;
		return next 'Created function users.change_group_name.';
		
		create or replace function users.change_user_name(
			old_user_name	text,
			new_user_name	text)
		returns void as $$
			begin
				perform users.change_group_name(old_user_name, new_user_name);
			end
		$$ language plpgsql security definer
		set search_path = users, pg_temp;
		return next 'Created function users.change_user_name.';
		
		create or replace function users.login(
			session_id		text,
			user_name		text,
			user_password	text)
		returns void as $$
			declare
				new_user_id		uuid;
			begin
				select into new_user_id users.group.id
					from users.group, users.user
					where users.group.id = users.user.id
						and users.group.name = lower(user_name)
						and users.user.password = 
							public.crypt(user_password, users.user.password);
				if not found then
					raise 'Invalid user name or password';
				end if;
				update web.session set user_id = new_user_id
					where sess_id = session_id;
				if not found then
					raise 'Invalid session id';
				end if;
			end
		$$ language plpgsql security definer
		set search_path = users, pg_temp;
		return next 'Created function users.login.';
		
		create or replace function users.logout(
			session_id		text)
		returns void as $$
			begin
				update web.session set user_id = public.uuid_nil()
					where sess_id = session_id;
				if not found then
					raise 'Invalid session id';
				end if;
			end
		$$ language plpgsql security definer
		set search_path = users, pg_temp;
		return next 'Created function users.logout.';
		
		create or replace function users.change_password(
			user_name		text,
			new_password	text)
		returns void as $$
			begin
				update users.user 
					set password = public.crypt(new_password, public.gen_salt('bf'))
					where id =
						(select id 
							from users.group 
							where name = lower(user_name));
				if not found then
					raise 'Invalid user name';
				end if;
			end
		$$ language plpgsql security definer
		set search_path = users, pg_temp;
		return next 'Created function users.change_password.';
		
		create or replace function users.add_group_member(
			group_name		text,
			member_name		text)
		returns void as $$
			begin
				insert into users.subgroup (parent_id, child_id)
					values (
						(select id from users.group
							where name = lower(group_name)), 
						(select id from users.group
							where name = lower(member_name)));
			end
		$$ language plpgsql security definer
		set search_path = users, pg_temp;
		return next 'Created function users.add_group_member.';
		
		create or replace function users.remove_group_member(
			group_name		text,
			member_name		text)
		returns void as $$
			begin
				delete from users.subgroup 
					where parent_id = (select id from users.group
						where name = lower(group_name))
					and child_id = (select id from users.group
						where name = lower(member_name));
			end
		$$ language plpgsql security definer
		set search_path = users, pg_temp;
		return next 'Created function users.remove_group_member.';
		
		create or replace function users.group_members(
			group_name		text)
		returns table(
			name 			text, 
			is_group 		boolean)
		as $$
			begin
				return query 
					with recursive grouping(id, name, child_id, is_group)
					as (
						select users.grouplist.id, 
							users.grouplist.name, 
							users.grouplist.child_id, 
							users.grouplist.is_group
						from users.grouplist
						where users.grouplist.name = lower(group_name)
						union
						select users.grouplist.id,
							users.grouplist.name,
							users.grouplist.child_id,
							users.grouplist.is_group
						from 
							users.grouplist,
							grouping
						where
							grouping.child_id = users.grouplist.id
						)
					select grouping.name, grouping.is_group from grouping;
			end
		$$ language plpgsql security definer
		set search_path = users, pg_temp;
		return next 'Created function users.group_members.';		
				
		-- Set permissions
		revoke all on function
			-- triggers
			users.protect_anonymous(),
			users.protect_special_groups(),
			users.prevent_special_users(),
			-- Admin functions
			users.get_special_group_id(
				group_name		text),
			users.create_group(
				group_name		text),
			users.delete_group(
				group_name		text),
			users.create_user(
				user_name		text,
				password		text),
			users.delete_user(
				user_name		text),
			users.change_group_name(
				old_user_name	text,
				new_user_name	text),
			users.change_user_name(
				old_user_name	text,
				new_user_name	text),
			users.change_password(
				user_name		text,
				new_password	text),
			users.add_group_member(
				group_name		text,
				member_name		text),
			users.remove_group_member(
				group_name		text,
				member_name		text),
			users.group_members(
				group_name		text),
			-- Node functions
			users.login(
				session_id		text,
				user_name		text,
				user_password	text),
			users.logout(
				session_id		text)
		from public;
		
		grant execute on function 
			users.login(
				session_id		text,
				user_name		text,
				user_password	text),
			users.logout(
				session_id		text)
		to nodepg;

		grant usage on schema users to nodepg;
		
		return next 'Premissions set';

		-- Create special users and groups
		if failed_test('test_users_special_user_anonymous_exists') then
			insert into users.group (id, name) values
				(uuid_nil(), 'anonymous');
			insert into users.user (id, password) values
				(uuid_nil(), '');
			return next 'Added the anonymous user.';
		end if;
		
		if failed_test('test_users_special_group_admin_exists') then
			perform users.create_special_group('admin');
			return next 'Created the admin group.';
		end if;
		
		if failed_test('test_users_special_group_authenticated_exists') then
			perform users.create_special_group('authenticated');
			return next 'Created the authenticated group.';
		end if;

		if failed_test('test_users_special_group_allusers_exists') then
			perform users.create_special_group('all users');
			return next 'Created the all users group.';
		end if;		
				
	end
$func$ language plpgsql;



/*
-- Database installation program for user module.
create or replace function get_new_test_user(
	out newusername		text,
	out newpassword		text,
	out newemail 		text)
as $test$
	declare
		idholder		uuid;
	begin
		loop
			select md5(random()::text) into newusername;
			select md5(random()::text) into newemail;
			select id into idholder from users.user
				where name = newusername
					or email = newemail;
			exit when not found;
		end loop;
		select md5(random()::text) into newpassword;
	end;
$test$ language plpgsql;

create or replace function get_inactive_test_user(
	out inactusername		text,
	out inactpassword		text,
	out inactemail 			text,
	out validationlink		uuid)
as $test$
	begin
		select into inactusername, inactpassword, inactemail
			newusername, newpassword, newemail
			from get_new_test_user();
		select into validationlink validlink from 
			users.add_user(inactusername, inactpassword, inactemail);
	end;
$test$ language plpgsql;

create or replace function get_logged_out_test_user(
	out loggedoutusername	text,
	out loggedoutpassword	text,
	out loggedoutemail		text)
as $test$
	declare
		validation 			uuid;
	begin
		select into loggedoutusername, loggedoutpassword, loggedoutemail,
			validation inactusername, inactpassword, inactemail, validationlink
			from get_inactive_test_user();
		perform users.validate_user(validation);
	end;
$test$ language plpgsql;

create or replace function get_logged_in_test_user(
	out loggedinusername	text,
	out loggedinpassword	text,
	out loggedinemail		text,
	out loggedinsession		text)
as $test$
	begin
		select into loggedinusername, loggedinpassword, loggedinemail
			loggedoutusername, loggedoutpassword, loggedoutemail
			from get_logged_out_test_user();
		select into loggedinsession sess_id 
			from create_test_session();
		perform users.login(loggedinsession, loggedinusername, loggedinpassword);
	end;
$test$ language plpgsql;

create or replace function test_users_schema()
returns setof text as $$
	begin 
		return next has_schema('users', 'There should be a users schema.');
	end;
$$ language plpgsql;

create or replace function test_users_for_uuid_ossp_installation()
returns setof text as $test$
	begin 
		return next isnt(
			findfuncs('public', '^uuid_'),
			'{}',
			'uuid-ossp needs to be installed into public.');
	end;
$test$ language plpgsql;

create or replace function test_users_for_pgcrypto_installation()
returns setof text as $test$
	begin 
		return next isnt(
			findfuncs('public', '^crypt'),
			'{}',
			'pgcrypto needs to be installed into public.');
	end;
$test$ language plpgsql;

create or replace function test_users_user_exists()
returns setof text as $$
	begin
		return next has_table('users', 'user', 'There should be a user table.');
	end;
$$ language plpgsql;

create or replace function test_users_table_user_column_id_exists()
returns setof text as $$
	begin
		return next has_column('users', 'user', 'id', 
			'Needs a user id column');
	end;
$$ language plpgsql;

create or replace function test_users_table_user_column_id_is_uuid()
returns setof text as $$
	begin
		return next col_type_is('users', 'user', 'id', 'uuid', 
			'Users id must be UUID.');
	end;
$$ language plpgsql;

create or replace function test_users_table_user_column_id_is_pk()
returns setof text as $$
	begin
		return next col_is_pk('users', 'user', 'id', 
			'User id needs to be the primary key.');
	end;
$$ language plpgsql;

create or replace function test_users_table_user_column_active_exists()
returns setof text as $$
	begin
		return next has_column('users', 'user', 'active',
			'Needs a column to show user status.');
	end;
$$ language plpgsql;

create or replace function test_users_table_user_column_active_is_bool()
returns setof text as $$
	begin
		return next col_type_is('users', 'user', 'active', 'boolean',
			'Users user active column needs to be boolean.');
	end;
$$ language plpgsql;

create or replace function test_users_table_user_column_active_is_not_null()
returns setof text as $$
	begin 
		return next col_not_null('users', 'user', 'active', 
			'User active column cannot be null.');
	end;
$$ language plpgsql;

create or replace function test_users_table_user_column_active_defaults_false()
returns setof text as $$
	begin 
		return next col_default_is('users', 'user', 'active',  'false', 
			'Active column should default to false');
	end;
$$ language plpgsql;

create or replace function test_users_table_user_column_name_exists()
returns setof text as $$
	begin 
		return next has_column('users', 'user', 'name', 
			'Need a column of user names.');
	end;
$$ language plpgsql;

create or replace function test_users_table_user_column_name_is_text()
returns setof text as $$
	begin 
		return next col_type_is('users', 'user', 'name', 'text', 
			'User name needs to be text');
	end;
$$ language plpgsql;

create or replace function test_users_table_user_column_name_is_not_null()
returns setof text as $$
	begin 
		return next col_not_null('users', 'user', 'name', 
			'User name column cannot be null.');
	end;
$$ language plpgsql;

create or replace function test_users_function_add_user_name_length()
returns setof text as $test$
	begin
		return next throws_ok(
			$$insert into users.user (id, name, password, email) values
				(uuid_generate_v1(), 'four', 'password', 
				md5(random()::text))$$,
			'23514', 
			'new row for relation "user" violates check constraint "name_len"',
			'User name must be a minimum of 5 characters.');
	end;
$test$ language plpgsql;

create or replace function test_users_table_user_column_password_exists()
returns setof text as $$
	begin 
		return next has_column('users', 'user', 'password', 
			'Needs a password column');
	end;
$$ language plpgsql;

create or replace function test_users_table_user_column_password_is_text()
returns setof text as $$
	begin
		return next col_type_is('users', 'user', 'password', 'text', 
			'Password needs to have a text input.');
	end;
$$ language plpgsql;

create or replace function test_users_table_user_column_password_is_not_null()
returns setof text as $$
	begin 
		return next col_not_null('users', 'user', 'password', 
			'User passwork cannot be null.');
	end;
$$ language plpgsql;

create or replace function test_users_table_user_column_email_exists()
returns setof text as $$
	begin 
		return next has_column('users', 'user', 'email', 
			'Needs an email column.');
	end;
$$ language plpgsql;

create or replace function test_users_table_user_column_email_is_text()
returns setof text as $$
	begin 
		return next col_type_is('users', 'user', 'email', 'text', 
			'Email needs to have a text input.');
	end;
$$ language plpgsql;

create or replace function test_users_table_user_column_email_is_not_null()
returns setof text as $$
	begin 
		return next col_not_null('users', 'user', 'email', 
			'User email column cannot be null.');
	end;
$$ language plpgsql;

create or replace function test_users_table_user_index_name_exists()
returns setof text as $$
	begin 
		return next has_index('users', 'user', 'username', 
			'lower(name)', 
			'Users.user.name must be lowercase unique');
		return next index_is_unique('users', 'user', 'username',
			'Users.user.name must be unique.');
	end;
$$ language plpgsql;

create or replace function test_users_table_user_index_email_exists()
returns setof text as $$
	begin 
		return next has_index('users', 'user', 'useremail', 
			'lower(email)', 
			'Users.user.email must have a lowercase index.');
		return next index_is_unique('users', 'user', 'useremail',
			'Users.user.email must be unique.');
	end;
$$ language plpgsql;

create or replace function test_users_has_anonymous_user()
returns setof text as $test$
	begin 
		return next results_eq(
			$$select * from users.user where name = 'anonymous'$$,
			$$values (uuid_nil(), true, 'anonymous', '', '')$$,
			'There should be an anonymous user with an all zeros id.');
	end;
$test$ language plpgsql;

create or replace function test_users_table_validate_exists()
returns setof text as $test$
	begin 
		return next has_table('users', 'validate',
			'Need a table for unvalidated users.');
	end;
$test$ language plpgsql;

create or replace function test_users_table_validate_column_link_exists()
returns setof text as $test$
	begin 
		return next has_column('users', 'validate', 'link',
			'Needs a validation link column.');
	end;
$test$ language plpgsql;

create or replace function test_users_table_validate_column_link_is_uuid()
returns setof text as $test$
	begin
		return next col_type_is('users', 'validate', 'link', 'uuid',
			'The validation link needs to be a uuid.');
	end;
$test$ language plpgsql;

create or replace function test_users_table_validate_column_link_is_pk()
returns setof text as $test$
	begin 
		return next col_is_pk('users', 'validate', 'link',
			'Validate needs link to be the primary key.');
	end;
$test$ language plpgsql;

create or replace function test_users_table_validate_column_userid_exists()
returns setof text as $test$
	begin
		return next has_column('users', 'validate', 'user_id',
			'Validate needs a link to the user table.');
	end; 
$test$ language plpgsql;

create or replace function test_users_table_validate_column_userid_is_uuid()
returns setof text as $test$
	begin 
		return next col_type_is('users', 'validate', 'user_id', 'uuid',
			'Validation user id needs to be uuid.');
	end;
$test$ language plpgsql;

create or replace function test_users_table_validate_column_userid_is_fk()
returns setof text as $test$
	begin
		return next fk_ok('users', 'validate', 'user_id',
			'users', 'user', 'id',
			'Validate user id needs to link to the user.');
	end;
$test$ language plpgsql;

create or replace function test_users_table_validate_column_expire_exists()
returns setof text as $test$
	begin 
		return next has_column('users', 'validate', 'expire',
			'Validate needs an expriration column.');
	end;
$test$ language plpgsql;

create or replace function test_users_table_validate_column_expire_is_timestamp()
returns setof text as $test$
	begin
		return next col_type_is('users', 'validate', 'expire',
			'timestamp with time zone',
			'Needs to know when the unvalidated user expires.');
	end;
$test$ language plpgsql;

create or replace function test_users_table_validate_cloumn_expire_is_not_null()
returns setof text as $test$
	begin
		return next col_not_null('users', 'validate', 'expire',
			'Validate expire cannot be null.');
	end;
$test$ language plpgsql;

create or replace function test_users_table_validate_column_expire_has_default()
returns setof text as $test$
	begin
		return next col_default_is('users', 'validate', 'expire',
			$$(now() + '7 days'::interval)$$,
			'Validate expire needs to be set to the future.');
	end;
$test$ language plpgsql;

create or replace function test_users_table_validate_column_expire_is_indexed()
returns setof text as $test$
	begin
		return next has_index('users', 'validate', 'valid_expire',
			'expire', 'Validate''s expire column needs an index.');
	end;
$test$ language plpgsql;

create or replace function test_users_table_validateemail_exists()
returns setof text as $test$
	begin 
		return next has_table('users', 'validate_email',
			'Need a table for unvalidated email addresses.');
	end;
$test$ language plpgsql;

create or replace function test_users_table_validateemail_column_link_exists()
returns setof text as $test$
	begin 
		return next has_column('users', 'validate_email', 'link',
			'Needs a validation link column.');
	end;
$test$ language plpgsql;

create or replace function test_users_table_validateemail_column_link_is_uuid()
returns setof text as $test$
	begin
		return next col_type_is('users', 'validate_email', 'link', 'uuid',
			'The validation link needs to be a uuid.');
	end;
$test$ language plpgsql;

create or replace function test_users_table_validateemail_column_userid_exists()
returns setof text as $test$
	begin
		return next has_column('users', 'validate_email', 'user_id',
			'Validate needs a link to the user table.');
	end; 
$test$ language plpgsql;

create or replace function test_users_table_validateemail_column_userid_is_uuid()
returns setof text as $test$
	begin 
		return next col_type_is('users', 'validate_email', 'user_id', 'uuid',
			'Validation user id needs to be uuid.');
	end;
$test$ language plpgsql;

create or replace function test_users_table_validateemail_column_expire_exists()
returns setof text as $test$
	begin 
		return next has_column('users', 'validate_email', 'expire',
			'Validate needs an expriration column.');
	end;
$test$ language plpgsql;

create or replace function test_users_table_validateemail_column_expire_is_timestamp()
returns setof text as $test$
	begin
		return next col_type_is('users', 'validate_email', 'expire',
			'timestamp with time zone',
			'Needs to know when the unvalidated user expires.');
	end;
$test$ language plpgsql;

create or replace function test_users_table_validateemail_cloumn_expire_is_not_null()
returns setof text as $test$
	begin
		return next col_not_null('users', 'validate_email', 'expire',
			'Validate expire cannot be null.');
	end;
$test$ language plpgsql;

create or replace function test_users_table_validateemail_column_expire_has_default()
returns setof text as $test$
	begin
		return next col_default_is('users', 'validate_email', 'expire',
			$$(now() + '7 days'::interval)$$,
			'Validate expire needs to be set to the future.');
	end;
$test$ language plpgsql;

create or replace function test_users_table_validateemail_column_email_exists()
returns setof text as $test$
	begin 
		return next has_column('users', 'validate_email', 'email',
			'Need a column for the new email in validate email.');
	end;
$test$ language plpgsql;

create or replace function test_users_table_validateemail_column_email_is_text()
returns setof text as $test$
	begin
		return next col_type_is('users', 'validate_email', 'email', 'text',
			'Needs to know when the unvalidated user expires.');
	end;
$test$ language plpgsql;

create or replace function test_users_table_validateemail_cloumn_email_is_not_null()
returns setof text as $test$
	begin
		return next col_not_null('users', 'validate_email', 'email',
			'Validate expire cannot be null.');
	end;
$test$ language plpgsql;

create or replace function test_users_table_validaterequest_exists()
returns setof text as $test$
	begin 
		return next has_table('users', 'validate_request',
			'Need a table for unvalidated requests.');
	end;
$test$ language plpgsql;

create or replace function test_users_table_validaterequest_column_link_exists()
returns setof text as $test$
	begin 
		return next has_column('users', 'validate_request', 'link',
			'Needs a validation request link column.');
	end;
$test$ language plpgsql;

create or replace function test_users_table_validaterequest_column_link_is_uuid()
returns setof text as $test$
	begin
		return next col_type_is('users', 'validate_request', 'link', 'uuid',
			'The validation request link needs to be a uuid.');
	end;
$test$ language plpgsql;

create or replace function test_users_table_validaterequest_column_userid_exists()
returns setof text as $test$
	begin
		return next has_column('users', 'validate_request', 'user_id',
			'Validate request needs a link to the user table.');
	end; 
$test$ language plpgsql;

create or replace function test_users_table_validaterequest_column_userid_is_uuid()
returns setof text as $test$
	begin 
		return next col_type_is('users', 'validate_request', 'user_id', 'uuid',
			'Validation request user id needs to be uuid.');
	end;
$test$ language plpgsql;

create or replace function test_users_table_validaterequest_column_expire_exists()
returns setof text as $test$
	begin 
		return next has_column('users', 'validate_request', 'expire',
			'Validate request needs an expriration column.');
	end;
$test$ language plpgsql;

create or replace function test_users_table_validaterequest_column_expire_is_timestamp()
returns setof text as $test$
	begin
		return next col_type_is('users', 'validate_request', 'expire',
			'timestamp with time zone',
			'Needs to know when the unvalidated requests expires.');
	end;
$test$ language plpgsql;

create or replace function test_users_table_validaterequest_cloumn_expire_is_not_null()
returns setof text as $test$
	begin
		return next col_not_null('users', 'validate_request', 'expire',
			'Validate request expire cannot be null.');
	end;
$test$ language plpgsql;

create or replace function test_users_table_validaterequest_column_expire_has_default()
returns setof text as $test$
	begin
		return next col_default_is('users', 'validate_request', 'expire',
			$$(now() + '7 days'::interval)$$,
			'Validate request expire needs to be set to the future.');
	end;
$test$ language plpgsql;

create or replace function test_users_function_adduser_exists()
returns setof text as $test$
	begin
		return next function_returns('users', 'add_user', 
			array['text', 'text', 'text'], 'record',
			'There needs to be an add user function.');
		return next is_definer('users', 'add_user', 
			array['text', 'text', 'text'],
			'Add user should have definer security.');
	end;
$test$ language plpgsql;

create or replace function test_users_function_adduser_inserts_data()
returns setof text as $test$
	declare
		user1			text;
		password1		text;
		email1			text;
		theemail		text;
		thelink			uuid;
	begin
		select into user1, password1, email1 newusername, newpassword, newemail
			from get_new_test_user();
		select into theemail, thelink emailaddr, validlink
			from users.add_user(user1, password1, email1);
		return next is(theemail, email1,
			'User add needs to return the user''s email address.');
		return next results_eq(
			$$select active, name, email from users.user 
				where name = '$$ || user1 || $$'$$,
			$$values (false, '$$ || user1 || $$', 
				'$$ || email1 || $$')$$,
			'add_user needs to add the user to users.user.');
		return next results_ne(
			$$select password from users.user
				where name = '$$ || user1 || $$'$$,
			$$values ('$$ || password1 || $$')$$,
			'User''s password needs to be encrypted.');
		return next results_eq(
			$$select users.validate.link
				from users.validate, users.user
				where users.user.id = users.validate.user_id
					and users.user.name = '$$ || user1 || $$'$$,
			$$values (cast('$$ || thelink || $$' as uuid))$$,
			'User add must output the validation link');
	end;
$test$ language plpgsql;

create or replace function test_users_function_add_user_password_length()
returns setof text as $test$
	declare
		user1			text;
		email1			text;
	begin
		select into user1, email1 newusername, newemail
			from get_new_test_user();
		return next throws_ok(
			$$select users.add_user( 
				'$$ || user1 || $$',
				'four', '$$ || email1 || $$')$$,
			'23514', 
			'new row for relation "user" violates check constraint "passwd_len"',
			'User password must be a minimum of 5 characters.');
	end;
$test$ language plpgsql;

create or replace function test_users_function_validate_exists()
returns setof text as $test$
	begin
		return next function_returns('users', 'validate_user',
			array['uuid'], 'text',
			'There needs to be a function that validates new users.');
		return next is_definer('users', 'validate_user', 
			array['uuid'], 
			'Validate user needs to have security definer access.');
	end;
$test$ language plpgsql;

create or replace function test_users_function_validate_activates_user()
returns setof text as $test$
	declare
		user1				text;
		thelink				uuid;
		validateduser		text;
	begin
		select into user1, thelink inactusername, validationlink
			from get_inactive_test_user();
		select into validateduser username from users.validate_user(thelink);
		return next is(validateduser, user1,
			'Validation function needs to return the user name.');
		return next results_eq(
			$$select active from users.user
				where name = '$$ || user1 || $$'$$,
			'values (true)',
			'Validate must make the user active.');
		return next is_empty(
			$$select * from users.validate
				where link = '$$ || thelink || $$'$$,
				'Validate must remove the validation link information.');
	end;
$test$ language plpgsql;

create or replace function test_users_function_removeunvalidated_exists()
returns setof text as $test$
	begin
		return next function_returns('users', 'delete_unvalidated',
			'trigger',
			'There needs to be a function that removes unvalidated users.');
		return next is_definer('users', 'delete_unvalidated', 
			'Remove unvalidated user needs to have security definer access.');
	end;
$test$ language plpgsql;

create or replace function test_users_trigger_removeunvalidated_exists()
returns setof text as $test$
	begin
		return next trigger_is('users', 'user', 'delete_unvalidated',
			'users', 'delete_unvalidated',
			'There needs to be a remove unvalidated trigger.');
	end;
$test$ language plpgsql;

create or replace function test_users_trigger_removeunvalidated_removes_unvalidated()
returns setof text as $test$
	declare
		user1				text;
	begin
		select into user1 inactusername
			from get_inactive_test_user();
		update users.validate set expire = now() - interval '1 day'
			where user_id = (select id from users.user 
				where name = user1);
		update users.user set password = 'password'
			where name = user1;
		return next is_empty(
			$$select * from users.user 
				where name = '$$ || user1 || $$'$$,
			'Need to remove unvalidated users if they have expired.');
	end;
$test$ language plpgsql;

create or replace function test_users_function_protect_anonymous()
returns setof text as $test$
	begin 
		return next function_returns('users', 'protect_anonymous',
			'trigger', 
			'There needs to be a function to protect anonymous');
		return next is_definer('users', 'protect_anonymous',
			'Needs to securite definer access.');
	end;
$test$ language plpgsql;

create or replace function test_users_user_anonymous_trigger()
returns setof text as $test$
	begin
		return next trigger_is('users', 'user', 'protect_anonymous',
			'users', 'protect_anonymous',
			'Needs a trigger to protect the anonymous user.');
	end;
$test$ language plpgsql;

create or replace function test_users_user_anonymous_cant_be_changed()
returns setof text as $test$
	begin 
		return next throws_ok(
			$$update users.user set password = 'wrong'
				where name = 'anonymous'$$,
			'P0001', 'Anonymous cannot be changed.',
			'The Anonymous user cannot be changed.');
	end;
$test$ language plpgsql;

create or replace function test_users_user_anonymous_cant_be_deleted()
returns setof text as $test$
	begin 
		return next throws_ok(
			$$delete from users.user where name = 'anonymous'$$,
			'P0001', 'Anonymous cannot be changed.',
			'The Anonymous user cannot be changed.');
	end;
$test$ language plpgsql;

create or replace function test_web_table_session_column_userid_exists()
returns setof text as $test$
	begin
		return next has_column('web', 'session', 'user_id',
			'Web sessions needs an attached user.');
	end;
$test$ language plpgsql;

create or replace function test_web_table_session_column_userid_is_uuid()
returns setof text as $test$
	begin 
		return next col_type_is('web', 'session', 'user_id', 'uuid',
			'Web session user id needs to be uuid.');
	end;
$test$ language plpgsql;

create or replace function test_web_table_session_column_userid_default()
returns setof text as $test$
	begin 
		return next col_default_is('web', 'session', 'user_id', 
			'uuid_nil()', 
			'The default user for a new session is anonymous.');
	end;
$test$ language plpgsql;

create or replace function test_web_table_session_column_userid_is_fk()
returns setof text as $test$
	begin 
		return next fk_ok('web', 'session', 'user_id',
			'users', 'user', 'id',
			'Sessions need to be linked to users.');
	end;
$test$ language plpgsql;

create or replace function test_web_table_session_column_userid_not_null()
returns setof text as $test$
	begin
		return next col_not_null('web', 'session', 'user_id',
			'Session''s user id cannot be null.');
	end;
$test$ language plpgsql;

create or replace function test_users_function_login_exists()
returns setof text as $test$
	begin 
		return next function_returns('users', 'login',
			array['text', 'text', 'text'], 'void', 
			'There needs to be a function to log in.');
		return next is_definer('users', 'login', 
			array['text', 'text', 'text'], 
			'Login needs to securite definer access.');
	end;
$test$ language plpgsql;

create or replace function test_users_function_login_changes_session_owner()
returns setof text as $test$
	declare
		user1				text;
		password1			text;
		session1			text;
	begin
		select into user1, password1 loggedoutusername, loggedoutpassword
			from get_logged_out_test_user();
		select into session1 sess_id from create_test_session();
		perform users.login(session1, user1, password1);
		return next results_eq(
			$$select users.user.name 
				from users.user,
					web.session
				where users.user.id = web.session.user_id
					and web.session.sess_id = '$$ || session1 || $$'$$,
			$$values ('$$ || user1 || $$')$$,
			'Login should update the session to the user.');
	end;
$test$ language plpgsql;

create or replace function test_users_function_login_username_case_insensitive()
returns setof text as $test$
	declare
		user1				text;
		password1			text;
		session1			text;
	begin
		select into user1, password1 loggedoutusername, loggedoutpassword
			from get_logged_out_test_user();
		select into session1 sess_id from create_test_session();
		perform users.login(session1, upper(user1), password1);
		return next results_eq(
			$$select users.user.name 
				from users.user,
					web.session
				where users.user.id = web.session.user_id
					and web.session.sess_id = '$$ || session1 || $$'$$,
			$$values ('$$ || user1 || $$')$$,
			'The case of the user name should not matter');
	end;
$test$ language plpgsql;

create or replace function test_users_function_login_fails_for_incorrect_values()
returns setof text as $test$
	declare
		user1				text;
		session1			text;
	begin
		select into user1 loggedoutusername
			from get_logged_out_test_user();
		select into session1 sess_id from create_test_session();
		return next throws_ok(
			$$select users.login('$$ || session1 || $$', '$$ || user1 || $$',
				'wrong')$$,
			'P0001', 'Bad username or password.',
			'Failed login needs to throw an error.');
	end;
$test$ language plpgsql;

create or replace function test_users_function_login_username_only_active()
returns setof text as $test$
	declare
		user1				text;
		password1			text;
		session1			text;
	begin
		select into user1, password1 inactusername, inactpassword
			from get_inactive_test_user();
		select into session1 sess_id from create_test_session();
		return next throws_ok(
			$$select users.login('$$ || session1 || $$', '$$ || user1 || $$',
				'$$ || password1 || $$')$$,
			'P0001', 'Bad username or password.',
			'Inactive users cannot log in.');
	end;
$test$ language plpgsql;

create or replace function test_users_function_logout_exists()
returns setof text as $test$
	begin 
		return next function_returns('users', 'logout',
			array['text'], 'void', 
			'There needs to be a function to log out.');
		return next is_definer('users', 'logout', 
			array['text'], 
			'Logout needs to securite definer access.');
	end;
$test$ language plpgsql;

create or replace function test_users_function_logout_returns_to_anonymous()
returns setof text as $test$
	declare
		session1		text;
	begin 
		select into session1 loggedinsession
			from get_logged_in_test_user();
		perform users.logout(session1);
		return next results_eq(
			$$select user_id from web.session 
				where sess_id = '$$ || session1 || $$'$$,
			$$values (public.uuid_nil())$$,
			'Logout should reset session to anonymous');
	end;
$test$ language plpgsql;

create or replace function test_users_function_changename_exists()
returns setof text as $test$
	begin 
		return next function_returns('users', 'change_name',
			array['text', 'text', 'text'], 'void', 
			'There needs to be a function to change user name.');
		return next is_definer('users', 'change_name', 
			array['text', 'text', 'text'], 
			'Change user name needs to securite definer access.');
	end;
$test$ language plpgsql;

create or replace function test_users_function_changename_changes_name()
returns setof text as $test$
	declare
		password1		text;
		session1		text;
		newname			text;
	begin 
		select into password1, session1 loggedinpassword, loggedinsession
			from get_logged_in_test_user();
		select into newname newusername
			from get_new_test_user();
		perform users.change_name(session1, newname, password1);
		return next results_eq(
			$$select users.user.name
				from users.user,
					web.session
				where users.user.id = web.session.user_id
					and web.session.sess_id = '$$ || session1 || $$'$$,
			$$values ('$$ || newname || $$')$$,
			'Change name needs to change the user''s name.');
	end;
$test$ language plpgsql;

create or replace function test_users_function_changename_fails_with_wrong_password()
returns setof text as $test$
	declare
		session1		text;
		newname			text;
	begin 
		select into session1 loggedinsession
			from get_logged_in_test_user();
		select into newname newusername
			from get_new_test_user();
		return next throws_ok(
			$$select users.change_name('$$ || session1 || $$', 
				'$$ || newname || $$', 'wrong')$$,
			'P0001', 'Password was incorrect',
			'Must use correct password to change name.');
	end;
$test$ language plpgsql;

create or replace function test_users_function_changepassword_exists()
returns setof text as $test$
	begin 
		return next function_returns('users', 'change_password',
			array['text', 'text', 'text'], 'void', 
			'There needs to be a function to change user password.');
		return next is_definer('users', 'change_password', 
			array['text', 'text', 'text'], 
			'Change user name needs to securite definer access.');
	end;
$test$ language plpgsql;

create or replace function test_users_function_changepassword_changes_password()
returns setof text as $test$
	declare
		password1		text;
		session1		text;
	begin 
		select into password1, session1 loggedinpassword, loggedinsession
			from get_logged_in_test_user();
		perform users.change_password(session1, 'password', password1);
		return next results_eq(
			$$select users.user.password = public.crypt('password', users.user.password)
				from users.user,
					web.session
				where users.user.id = web.session.user_id
					and web.session.sess_id = '$$ || session1 || $$'$$,
			'values (true)',
			'Change password should change password.');
	end;
$test$ language plpgsql;

create or replace function test_users_function_changepassword_fails_with_wrong_password()
returns setof text as $test$
	declare
		session1		text;
	begin 
		select into session1 loggedinsession
			from get_logged_in_test_user();
		return next throws_ok(
			$$select users.change_password('$$ || session1 || $$', 
				'password', 'wrong')$$,
			'P0001', 'Password was incorrect',
			'Must use correct password to change name.');
	end;
$test$ language plpgsql;

create or replace function test_users_function_changepassword_fails_for_short_passwords()
returns setof text as $test$
	declare
		password1		text;
		session1		text;
	begin 
		select into password1, session1 loggedinpassword, loggedinsession
			from get_logged_in_test_user();
		return next throws_ok(
			$$select users.change_password('$$ || session1 || $$', 
				'four', '$$ || password1 || $$')$$,
			'23514', 
			'new row for relation "user" violates check constraint "passwd_len"',
			'User password must be a minimum of 5 characters.');
	end;
$test$ language plpgsql;

create or replace function test_users_function_changeemail_exists()
returns setof text as $test$
	begin 
		return next function_returns('users', 'change_email',
			array['text', 'text', 'text'], 'record', 
			'There needs to be a function to change user password.');
		return next is_definer('users', 'change_email', 
			array['text', 'text', 'text'], 
			'Change user name needs to securite definer access.');
	end;
$test$ language plpgsql;

create or replace function test_users_function_changeemail_saves_data()
returns setof text as $test$
	declare
		user1			text;
		password1		text;
		session1		text;
		newuseremail	text;
		thelink			uuid;
		theemail		text;
	begin 
		select into user1, password1, session1 
			loggedinusername, loggedinpassword, loggedinsession
			from get_logged_in_test_user();
		select into newuseremail newemail
			from get_new_test_user();
		select into theemail, thelink emailaddr, validlink
			from users.change_email(session1, newuseremail, password1);
		return next is(theemail, newuseremail,
			'Change email should return the new email address.');
		return next results_eq(
			$$select users.validate_email.link,
				users.validate_email.email
				from users.user,
					users.validate_email
				where users.user.id = users.validate_email.user_id
					and users.user.name = '$$ || user1 || $$'$$,
			$$values (cast('$$ || thelink || $$' as uuid), 
				'$$ || newuseremail || $$')$$,
			'Change email must returns a link and store the new address.');
	end;
$test$ language plpgsql;

create or replace function test_users_function_changeemail_fails_with_wrong_password()
returns setof text as $test$
	declare
		session1		text;
		newuseremail	text;
	begin 
		select into session1 loggedinsession
			from get_logged_in_test_user();
		select into newuseremail newemail
			from get_new_test_user();
		return next throws_ok(
			$$select users.change_email('$$ || session1 || $$',
				'$$ || newuseremail || $$', 'wrong')$$,
			'P0001', 'Password was incorrect',
			'Must use correct password to change email.');
	end;
$test$ language plpgsql;

create or replace function test_users_function_validateemail_exists()
returns setof text as $test$
	begin 
		return next function_returns('users', 'validate_email',
			array['uuid'], 'void', 
			'There needs to be a function to validate new email addresses.');
		return next is_definer('users', 'validate_email', 
			array['uuid'], 
			'Change user email needs to security definer access.');
	end;
$test$ language plpgsql;

create or replace function test_users_function_validateemail_changes_email()
returns setof text as $test$
	declare
		user1			text;
		password1		text;
		session1		text;
		newuseremail	text;
		thelink			uuid;
		theemail		text;
	begin 
		select into user1, password1, session1 
			loggedinusername, loggedinpassword, loggedinsession
			from get_logged_in_test_user();
		select into newuseremail newemail
			from get_new_test_user();
		select into theemail, thelink emailaddr, validlink
			from users.change_email(session1, newuseremail, password1);
		perform users.validate_email(thelink);
		return next results_eq(
			$$select email from users.user 
				where name = lower('$$ || user1 || $$')$$,
			$$values ('$$ || newuseremail || $$')$$,
			'Email validate should update the users email address.');
		return next is_empty(
			$$select * from users.validate_email
				where link = '$$ || thelink || $$'$$,
			'The update email link should be deleted when validated.');
	end;
$test$ language plpgsql;

create or replace function test_users_function_validateemail_expires_old()
returns setof text as $test$
	declare
		user1			text;
		password1		text;
		session1		text;
		newemail1		text;
		thelink			uuid;
	begin
		select into user1, password1, session1
			loggedinusername, loggedinpassword, loggedinsession
			from get_logged_in_test_user();
		select into newemail1 newemail
			from get_new_test_user();
		select into thelink validlink
			from users.change_email(session1, newemail1, password1);
		update users.validate_email 
			set expire = now() - interval '1 day'
			where link = thelink;
		perform users.change_password(session1, 'password', password1);
		return next is_empty(
			$$select * from users.validate_email
				where link = '$$ || thelink || $$'$$,
			'Expired email updates should expire on user updates.');
	end;
$test$ language plpgsql;

create or replace function test_users_function_retrieveuserrequest_exists()
returns setof text as $test$
	begin 
		return next function_returns('users', 'retrieve_user_request',
			array['text'], 'record', 
			'There needs to be a function to request a forgotten user retrieval.');
		return next is_definer('users', 'retrieve_user_request', 
			array['text'], 
			'Retrieve user request needs to securite definer access.');
	end;
$test$ language plpgsql;

create or replace function test_users_function_retrieveuserrequest_returns_link()
returns setof text as $test$
	declare
		user1				text;
		email1				text;
		theemail			text;
		thelink				uuid;
	begin
		select into user1, email1 loggedoutusername, loggedoutemail
			from get_logged_out_test_user();
		select into theemail, thelink useremail, userlink
			from users.retrieve_user_request(email1);
		return next is(email1, theemail,
			'Retrieve user request should return the email sent.');
		return next results_eq(
			$$select id from users.user 
				where name = '$$ || user1 || $$'$$,
			$$select user_id from users.validate_request
				where link = '$$ || thelink || $$'$$,
			'There must be a link to the retrieve user request.');
	end;
$test$ language plpgsql;

create or replace function test_users_function_retrieveuserrequest_fails_bad_email()
returns setof text as $test$
	declare
		email1			text;
	begin
		select into email1 newemail from get_new_test_user();
		return next throws_ok(
			$$select users.retrieve_user_request('$$ || email1 || $$')$$,
			'P0001', 'Email does not exist.',
			'Recovery request needs to fail if email is bad.');
	end;
$test$ language plpgsql;

create or replace function test_users_function_retrieveuser_exists()
returns setof text as $test$
	begin 
		return next function_returns('users', 'retrieve_user',
			array['uuid'], 'record', 
			'There needs to be a function to retrieve a forgotten user.');
		return next is_definer('users', 'retrieve_user', 
			array['uuid'], 
			'Retrieve user needs to securite definer access.');
	end;
$test$ language plpgsql;

create or replace function test_users_function_retrieveuser_returns_data()
returns setof text as $test$
	declare
		user1				text;
		email1				text;
		thelink				uuid;
		retname				text;
		retpasswd			text;
	begin
		select into user1, email1 loggedoutusername, loggedoutemail
			from get_logged_out_test_user();
		select into thelink userlink
			from users.retrieve_user_request(email1);
		select into retname, retpasswd username, userpassword
			from users.retrieve_user(thelink);
		return next is(retname, user1,
			'Retrieve user should return the user name.');
		return next lives_ok(
			$$select users.login('web-session-1', '$$ || retname || $$',
				'$$ || retpasswd || $$')$$,
			'The user should be able to login with the username and password.');
	end;
$test$ language plpgsql;

create or replace function test_users_function_login_removes_retrival()
returns setof text as $test$
	declare
		user1				text;
		password1			text;
		email1				text;
		session1			text;
	begin
		select into user1, password1, email1
			loggedoutusername, loggedoutpassword, loggedoutemail
			from get_logged_out_test_user();
		select into session1 sess_id from create_test_session();
		perform users.retrieve_user_request(email1);
		perform users.login(session1, user1, password1);
		return next is_empty(
			$$select * 
				from users.user, 
					users.validate_request
				where users.user.id = users.validate_request.user_id
					and users.user.name = '$$ || user1 || $$'$$,
			'Successful login should remove the user''s validation request');
	end;
$test$ language plpgsql;

create or replace function test_users_function_expire_retrieval_requests()
returns setof text as $test$
	declare
		user1				text;
		email1				text;
		password2			text;
		sessid2				text;
		thelink				uuid;
	begin
		select into user1, email1 loggedoutusername, loggedoutemail
			from get_logged_out_test_user();
		select into password2, sessid2 loggedinpassword, loggedinsession
			from get_logged_in_test_user();
		select into thelink userlink
			from users.retrieve_user_request(email1);
		update users.validate_request
			set expire = now() - interval '1 day'
			where link = thelink;
		perform users.change_password(sessid2, 'password', password2);
		return next is_empty(
			$$select * from users.validate_request
				where link = '$$ || thelink || $$'$$,
			'Username and password requests should expire after a time.');
	end;
$test$ language plpgsql;

create or replace function test_users_function_getuser_exists()
returns setof text as $test$
	begin
		return next function_returns('users', 'get_user',
			array['text'], 'text', 
			'There needs to be a function to request a forgotten user retrieval.');
		return next is_definer('users', 'get_user', array['text'], 
			'Retrieve user request needs to securite definer access.');
	end;
$test$ language plpgsql;

create or replace function test_users_function_getuser_returns_anon_for_bad_sessions()
returns setof text as $test$
	begin
		return next results_eq(
			$$select users.get_user(new_session_id())$$,
			$$values ('anonymous')$$,
			'Bad session ids should return the anonymous user.');
	end;
$test$ language plpgsql;

create or replace function test_users_function_getuser_returns_user_name()
returns setof text as $test$
	declare
		user1				text;
		password1			text;
		session1			text;
	begin
		select into user1, password1 loggedoutusername, loggedoutpassword
			from get_logged_out_test_user();
		select into session1 sess_id from create_test_session();
		return next results_eq(
			$$select users.get_user('$$ || session1 || $$')$$,
			$$select users.user.name
				from users.user,
					web.session
				where users.user.id = web.session.user_id
					and web.session.sess_id = '$$ || session1 || $$'$$,
			'Get user should return anonymous before the user logs in.');
		perform users.login(session1, user1, password1);
		return next results_eq(
			$$select users.get_user('$$ || session1 || $$')$$,
			$$select users.user.name
				from users.user,
					web.session
				where users.user.id = web.session.user_id
					and web.session.sess_id = '$$ || session1 || $$'$$,
			'Get user should always show the logged in user.');
	end;
$test$ language plpgsql;

create or replace function correct_users()
returns setof text as $func$
	begin
		if failed_test('test_users_schema') then
			create schema users;
			return next 'Created users schema';
		end if;

		if failed_test('test_users_user_exists') then
			create table users.user();
			return next 'Created the user''s table.';
		end if;
		if failed_test('test_users_table_user_column_id_exists') then
			alter table users.user
				add column id uuid;
			return next 'Created users id column.';
		end if;
		if failed_test('test_users_table_user_column_id_is_uuid') then
			alter table users.user 
				alter column id type uuid;
			return next 'Set user''s id column as uuid.';
		end if;
		if failed_test('test_users_table_user_column_id_is_pk') then
			alter table users.user
				add primary key (id);
			return next 'Added the primary key to users.user.';
		end if;
		if failed_test('test_users_table_user_column_active_exists') then
			alter table users.user
				add column active boolean;
			return next 'Added the active status column.';
		end if;
		if failed_test('test_users_table_user_column_active_is_bool') then 
			alter table users.user
				alter column active type boolean;
			return next 'Changed users.user.active to boolean.';
		end if;
		if failed_test('test_users_table_user_column_active_is_not_null') then
			alter table users.user
				alter column active set not null;
			return next 'Set users.user.active to not be null.';
		end if;
		if failed_test('test_users_table_user_column_active_defaults_false') then
			alter table users.user
				alter column active set default false;
			return next 'Setting the default for users.user.active.';
		end if;
		if failed_test('test_users_table_user_column_name_exists') then 
			alter table users.user
				add column name text;
			return next 'Added users.user.name.';
		end if;
		if failed_test('test_users_table_user_column_name_is_text') then 
			alter table users.user
				alter column active type text;
			return next 'Changed users.user.name to text.';
		end if;
		if failed_test('test_users_table_user_column_name_is_not_null') then
			alter table users.user
				alter column name set not null;
			return next 'Made users.user.name not null.';
		end if;
		if failed_test('test_users_function_add_user_name_length') then 
			alter table users.user
				add constraint name_len check (length(name) > 4);
			return next 'Set users.user.name to a minimum of 5 characters.';
		end if;
		if failed_test('test_users_table_user_column_password_exists') then
			alter table users.user 
				add column password text;
			return next 'Create the password column for users.user.';
		end if;
		if failed_test('test_users_table_user_column_password_is_text') then
			alter table users.user
				alter column password type text;
			return next 'Changed users.user.password to text.';
		end if;
		if failed_test('test_users_table_user_column_password_is_not_null') then
			alter table users.user
				alter column password set not null;
			return next 'Set users.user.password to it is not null';
		end if;
		if failed_test('test_users_table_user_column_email_exists') then
			alter table users.user 
				add column email text;
			return next 'Added the users.user.email column';
		end if;
		if failed_test('test_users_table_user_column_email_is_text') then
			alter table users.user
				alter column email type text;
			return next 'Users.user.email is not type text.';
		end if;
		if failed_test('test_users_table_user_column_email_is_not_null') then
			alter table users.user
				alter column email set not null;
			return next 'Set users.user.email to not null.';
		end if;

		if failed_test('test_users_table_user_index_name_exists') then
			drop index if exists users.username;
			create unique index username 
				on users.user (lower(name));
			return next 'Created users.user.name index.';
		end if;

		if failed_test('test_users_table_user_index_email_exists') then
			drop index if exists users.useremail;
			create unique index useremail 
				on users.user (lower(email));
			return next 'Created users.user.email index.';
		end if;

		if failed_test('test_users_has_anonymous_user') then
			insert into users.user (id, active, name, password, email) 
				values
				(uuid_nil(), true, 'anonymous', '','');
			return next 'Added the anonymous user.';
		end if;

		if failed_test('test_users_table_validate_exists') then
			create table users.validate();
			return next 'Created the validate table.';
		end if;
		if failed_test('test_users_table_validate_column_link_exists') then
			alter table users.validate
				add column link uuid;
			return next 'Added the link column to validation table.';
		end if;
		if failed_test('test_users_table_validate_column_link_is_uuid') then
			alter table users.validate
				alter column link type uuid;
			return next 'Made validation link a uuid.';
		end if;
		if failed_test('test_users_table_validate_column_link_is_pk') then
			alter table users.validate
				add primary key (link);
			return next 'Added primary key to validate.';
		end if;
		if failed_test('test_users_table_validate_column_userid_exists') then
			alter table users.validate
				add column user_id uuid;
			return next 'Added user id to validate table.';
		end if;
		if failed_test('test_users_table_validate_column_userid_is_uuid') then
			alter table users.validate
				alter column user_id type uuid;
		end if;
		if failed_test('test_users_table_validate_column_userid_is_fk') then
			alter table users.validate
				add constraint validate_usrid 
				foreign key (user_id) 
				references users.user (id)
				match full
				on delete cascade
				on update cascade;
			return next 'Added the validate user link user id foriegn key.';
		end if;
		if failed_test('test_users_table_validate_column_expire_exists') then
			alter table users.validate
				add column expire timestamp with time zone;
			return next 'Added the expiration timestamp to validate';
		end if;
		if failed_test('test_users_table_validate_column_expire_is_timestamp') then
			alter table users.validate
				alter column expire type timestamp with time zone;
			return next 'Made validate''s expire a timestamp.';
		end if;
		if failed_test('test_users_table_validate_cloumn_expire_is_not_null') then
			alter table users.validate
				alter column expire set not null;
			return next 'Making validate expire not null';
		end if;
		if failed_test('test_users_table_validate_column_expire_has_default') then
			alter table users.validate
				alter column expire set default now() + interval '7 days';
			return next 'Set validate expire to be in the future.';
		end if;
		
		if failed_test('test_users_table_validate_column_expire_is_indexed') then
			create index valid_expire on users.validate (expire);
			return next 'Created the validation expiration index.';
		end if;
		
		if failed_test('test_users_table_validateemail_exists') then
			create table users.validate_email ()
				inherits (users.validate);
			return next 'Created the validate email table.';
		end if;
		if failed_test('test_users_table_validateemail_column_email_exists') then
			alter table users.validate_email
				add column email text;
			return next 'Added the email column to the validate email table.';
		end if;
		if failed_test('test_users_table_validateemail_cloumn_email_is_not_null') then
			alter table users.validate_email
				alter column email set not null;
			return next 'set validate email email column to not null.';
		end if;
		
		if failed_test('test_users_table_validaterequest_exists') then
			create table users.validate_request ()
				inherits (users.validate);
			return next 'Create the validate request table.';
		end if;
		
		if failed_test('test_web_table_session_column_userid_exists') then
			alter table web.session
				add column user_id uuid default uuid_nil();
			return next 'Added user ids to web sessions.';
		end if;
		if failed_test('test_web_table_session_column_userid_is_uuid') then
			alter table web.session
				alter column user_id type uuid;
			return next 'Set web session user id to uuid.';
		end if;
		if failed_test('test_web_table_session_column_userid_default') then
			alter table web.session
				alter column user_id set default uuid_nil();
			return next 'Set the default for the session user id.';
		end if;
		if failed_test('test_web_table_session_column_userid_is_fk') then
			alter table web.session
				add constraint sess_usrid 
				foreign key (user_id) 
				references users.user (id)
				match full
				on delete cascade
				on update cascade;
			return next 'Linked the session id to the users.';
		end if;
		if failed_test('test_web_table_session_column_userid_not_null') then
			alter table web.session
				alter column user_id set not null;
			return next 'Made web.session.user_id not null.';
		end if;
		
		drop trigger if exists delete_unvalidated on users.user;
		drop trigger if exists protect_anonymous on users.user;
		
		create or replace function users.check_password_length(
			password	text)
		returns void as $$
			begin
				if length(password) < 5 then
					raise 'new row for relation "user" violates check constraint "passwd_len"' 
						using errcode = 'check_violation';
				end if;
			end;
		$$ language plpgsql security definer
		set search_path = users, pg_temp;
		
		create or replace function users.get_new_link()
		returns uuid as $$
			declare
				newlink		uuid;
				linkholder	uuid;
			begin
				loop
					select public.uuid_generate_v4() into newlink;
					select link into linkholder 
						from users.validate
						where link = newlink;
					exit when not found;
				end loop;
				return newlink;
			end;
		$$ language plpgsql security definer
		set search_path = users, pg_temp;
		
		create or replace function users.add_user(
			username	text,
			passwd		text,
			useremail	text,
			out		emailaddr		text,
			out		validlink		uuid)
		as $$
			declare
				id_holder	uuid;
				new_uid		uuid;
			begin
				perform users.check_password_length(passwd);
				emailaddr := useremail;
				validlink := users.get_new_link();
				loop
					select public.uuid_generate_v4() into new_uid;
					select id into id_holder 
						from users.user
						where id = new_uid;
					exit when not found;
				end loop;
				insert into users.user (id, name, password, email) 
					values (new_uid, username, 
						public.crypt(passwd, 
							public.gen_salt('bf')), 
							useremail);
				insert into users.validate (link, user_id) values
					(validlink, new_uid);
			end;
		$$ language plpgsql security definer
		set search_path = users, pg_temp;
		return next 'Created function users.add_user.';
		
		create or replace function users.validate_user(
			linkcode				uuid,
			out		username		text)
		as $$
			begin
				select into username users.user.name 
					from users.user,
						users.validate
					where users.user.id = users.validate.user_id
						and users.validate.link = linkcode;
				update users.user set active = true
					where name = lower(username);
				delete from users.validate 
					where link = linkcode;
			end;
		$$ language plpgsql security definer
		set search_path = users, pg_temp;
		return next 'Created function users.validate_user.';

		create or replace function users.delete_unvalidated()
		returns trigger as $$
			begin
				delete from users.user 
					where id = (select user_id from only users.validate
						where expire < now());
				delete from users.validate_email
					where expire < now();
				delete from users.validate_request
					where expire < now();
				return null;
			end;
		$$ language plpgsql security definer
		set search_path = users, pg_temp;
		return next 'Created function users.delete_unvalidated.';
				
		create or replace function users.protect_anonymous()
		returns trigger as $$
			begin
				if OLD.name = 'anonymous' then 
					raise 'Anonymous cannot be changed.';
				end if;
				if TG_OP = 'UPDATE' then
					return NEW;
				end if;
				if TG_OP = 'DELETE' then
					return OLD;
				end if;
			end;
		$$ language plpgsql security definer
		set search_path = users, pg_temp;
		return next 'Created function users.protect_anonymous.';

		create or replace function users.login(
			sessionid		text,
			username		text,
			passwd			text)
		returns void as $$
			declare
				theuserid	uuid;
			begin
				select id into theuserid
					from users.user
					where name = lower(username)
						and active = true
						and password = public.crypt(passwd, password);
				if not found then
					raise 'Bad username or password.';
				end if;
				update web.session
					set user_id = theuserid
					where sess_id = sessionid;
				delete from users.validate_request
					where user_id = theuserid;
			end;
		$$ language plpgsql security definer
		set search_path = users, pg_temp;
		return next 'Created function users.login.';

		create or replace function users.logout(
			sessid		text)
		returns void as $$
			begin
				update web.session
					set user_id = public.uuid_nil()
					where sess_id = sessid;
			end;
		$$ language plpgsql security definer
		set search_path = users, pg_temp;
		return next 'Created function users.logout.';
		
		create or replace function users.change_name(
			sessionid	text,
			username	text,
			passwd		text)
		returns void as $$
			begin
				update users.user set name = username
					where id = (select user_id from web.session
						where sess_id = sessionid)
					and password = public.crypt(passwd, password);
				if not found then
					raise 'Password was incorrect';
				end if;
			end;
		$$ language plpgsql security definer
		set search_path = users, pg_temp;
		return next 'Created function users.change_name.';

		create or replace function users.change_password(
			sessionid		text,
			newpassword		text,
			oldpassword		text)
		returns void as $$
			begin
				perform users.check_password_length(newpassword);
				update users.user 
					set password = public.crypt(newpassword, public.gen_salt('bf'))
				where id = (select user_id from web.session 
					where sess_id = sessionid)
					and password = public.crypt(oldpassword, password);
				if not found then
					raise 'Password was incorrect';
				end if;
			end;
		$$ language plpgsql security definer
		set search_path = users, pg_temp;
		return next 'Created function users.change_password.';

		create or replace function users.change_email(
			sessionid	text,
			newemail	text,
			passwd		text,
			out		emailaddr		text,
			out		validlink		uuid)
		as $$
			declare
				userid		uuid;
			begin
				emailaddr := newemail;
				validlink := users.get_new_link();
				select into userid users.user.id
					from users.user, web.session
					where users.user.id = web.session.user_id 
						and users.user.password = 
							public.crypt(passwd, password)
						and web.session.sess_id = sessionid;
				if not found then
					raise 'Password was incorrect';
				end if;
				insert into users.validate_email (link, user_id, email) 
					values (validlink, userid, newemail);
			end;
		$$ language plpgsql security definer
		set search_path = users, pg_temp;
		return next 'Created function users.change_email.';
		
		create or replace function users.validate_email(
			linkid		uuid)
		returns void as $$
			declare
				newemail		text;
				userid			uuid;
			begin
				select into userid, newemail user_id, email 
					from users.validate_email
					where link = linkid; 
				update users.user
					set email = newemail
					where id = userid;
				delete from users.validate_email
					where link = linkid;
			end;
		$$ language plpgsql security definer
		set search_path = users, pg_temp;
		return next 'Created function users.change_email.';
		
		create or replace function users.retrieve_user_request(
			emailaddr		text,
			out		useremail		text,
			out		userlink		uuid)
		as $$
			declare
				userid		uuid;
			begin
				useremail := emailaddr;
				userlink := users.get_new_link();
				select into userid id from users.user
					where email = useremail;
				if found then
					insert into users.validate_request (user_id, link)
						values (userid, userlink);
				else
					raise 'Email does not exist.';
				end if;
			end;
		$$ language plpgsql security definer
		set search_path = users, pg_temp;
		return next 'Created function users.retrieve_user_request.';

		create or replace function users.retrieve_user(
			thelink		uuid,
			out		username		text,
			out		userpassword	text)
		as $$
			begin
				select users.user.name into username
					from users.user,
						users.validate_request
					where users.user.id = users.validate_request.user_id
						and users.validate_request.link = thelink;
				userpassword := '';
				for iLoop in 1 .. 10 loop
					userpassword = userpassword || chr(int4(random()*26)+97);
				end loop;
				update users.user 
					set password = public.crypt(userpassword, public.gen_salt('bf'))
					where name = lower(username);
			end;
		$$ language plpgsql security definer
		set search_path = users, pg_temp;
		return next 'Created function users.retrieve_user.';
		
		create or replace function users.get_user(
			sessionid		text)
		returns text as $$
			declare
				username	text;
			begin
				select users.user.name into username
					from users.user,
						web.session
					where users.user.id = web.session.user_id
						and web.session.sess_id = sessionid;
				if found then
					return username;
				else
					return 'anonymous';
				end if;
			end;
		$$ language plpgsql security definer
		set search_path = users, pg_temp;
		return next 'Created function users.get_user.';

		create trigger delete_unvalidated
			after update
			on users.user
			execute procedure users.delete_unvalidated();
		return next 'Created the remove unvalidated trigger.';

		create trigger protect_anonymous
			before update or delete
			on users.user
			for each row execute procedure users.protect_anonymous();
		return next 'Created the protect anonymous trigger.';

		revoke all on function 
			-- Support functions
			users.check_password_length(
				password		text),
			users.get_new_link(),
			-- Triggers
			users.delete_unvalidated(),
			users.protect_anonymous(),
			-- User Functions
			users.add_user(
				username		text,
				passwd			text,
				useremail		text),
			users.validate_user(
				linkcode		uuid),
			users.login(
				sessionid		text,
				username		text,
				passwd			text),
			users.logout(
				sessid			text),
			users.change_name(
				sessionid		text,
				newname			text,
				passwd			text),
			users.change_password(
				sessionid		text,
				newpassword		text,
				oldpassword		text),
			users.change_email(
				sessionid		text,
				username		text,
				passwd			text),
			users.validate_email(
				link			uuid),
			users.retrieve_user_request(
				emailaddr		text),
			users.retrieve_user(
				thelink			uuid),
			users.get_user(
				sessionid		text)
		from public;
		
		grant execute on function 
			users.add_user(
				username		text,
				passwd			text,
				useremail		text),
			users.validate_user(
				linkcode		uuid),
			users.login(
				sessionid		text,
				username		text,
				passwd			text),
			users.logout(
				sessid			text),
			users.change_name(
				sessionid		text,
				newname			text,
				passwd			text),
			users.change_password(
				sessionid		text,
				newpassword		text,
				oldpassword		text),
			users.change_email(
				sessionid		text,
				username		text,
				passwd			text),
			users.validate_email(
				link			uuid),
			users.retrieve_user_request(
				emailaddr		text),
			users.retrieve_user(
				thelink			uuid),
			users.get_user(
				sessionid		text)
		to nodepg;
		
		grant usage on schema users to nodepg;
		
		return next 'Permissions set.';		
	end;
$func$ language plpgsql;
*/