create or replace function test_users_schema()
returns setof text as $$
	begin 
		return next has_schema('users', 'There should be a users schema.');
	end;
$$ language plpgsql;

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

create or replace function test_users_for_uuid_ossp_installation()
returns setof text as $test$
	begin 
		return next isnt(
			findfuncs('public', '^uuid_'),
			'{}',
			'uuid-ossp needs to be installed into public.');
	end;
$test$ language plpgsql;

create or replace function test_users_has_anonymous_user()
returns setof text as $test$
	begin 
		return next results_eq(
			$$select * from users.user where name = 'anonymous'$$,
			$$values (uuid_nil(), true, 'anonymous', '', '')$$,
			'There should be an anonymous user with an all zeros id.');
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

create or replace function test_users_for_pgcrypto_installation()
returns setof text as $test$
	begin 
		return next isnt(
			findfuncs('public', '^crypt'),
			'{}',
			'pgcrypto needs to be installed into public.');
	end;
$test$ language plpgsql;

create or replace function test_users_function_add_user_exists()
returns setof text as $test$
	begin
		return next function_returns('users', 'add_user', 
			array['text', 'text', 'text', 'text'], 'text',
			'There needs to be an add user function.');
		return next is_definer('users', 'add_user', 
			array['text', 'text', 'text', 'text'],
			'Add user should have definer security.');
	end;
$test$ language plpgsql;

create or replace function test_users_function_add_user_inserts_data()
returns setof text as $test$
	declare
		holder		text;
	begin
		select add_user into holder from
			users.add_user('session-1', 'test-user', 'password',
				'tester@test.com');
		return next results_eq(
			$$select active, name, email from users.user 
				where name = 'test-user'$$,
			$$values (false, 'test-user', 'tester@test.com')$$,
			'add_user needs to add the user to users.user.');
		return next results_ne(
			$$select password from users.user
				where name = 'test-user'$$,
			$$values ('password')$$,
			'User''s password needs to be encrypted.');
	end;
$test$ language plpgsql;

create or replace function test_users_function_add_user_name_length()
returns setof text as $test$
	begin
		return next throws_ok(
			$$select users.add_user('session-1', 'four',
				'password', 'tester@test.com')$$,
			'23514', 
			'new row for relation "user" violates check constraint "name_len"',
			'User name must be a minimum of 5 characters.');
	end;
$test$ language plpgsql;

create or replace function test_users_function_add_user_password_length()
returns setof text as $test$
	begin
		return next throws_ok(
			$$select users.add_user('session-1', 'test-user',
				'four', 'tester@test.com')$$,
			'23514', 
			'new row for relation "user" violates check constraint "passwd_len"',
			'User password must be a minimum of 5 characters.');
	end;
$test$ language plpgsql;

create or replace function test_users_function_deleteuser_exists()
returns setof text as $test$
	begin 
		return next function_returns('users', 'delete_user',
			array['text', 'text'], 'void', 
			'There needs to be a function to delete users');
		return next is_definer('users', 'delete_user', 
			array['text', 'text'], 
			'Delete user needs to securite definer access.');
	end;
$test$ language plpgsql;

create or replace function test_users_function_deleteuser_removes_data()
returns setof text as $test$
	begin 
		perform users.add_user('session-1', 'test-user',
			'password', 'tester@test.com');
		perform users.delete_user('session-1', 'test-user');
		return next is_empty(
			$$select * from users.user 
				where name = 'test-user'$$,
			'Delete user should remove the user.');
	end;
$test$ language plpgsql;

create or replace function test_users_function_deleteuser_not_case_sensitive()
returns setof text as $test$
	begin 
		perform users.add_user('session-1', 'test-user',
			'password', 'tester@test.com');
		perform users.delete_user('session-1', 'TEST-USER');
		return next is_empty(
			$$select * from users.user 
				where name = 'test-user'$$,
			'Delete user should remove the user.');
	end;
$test$ language plpgsql;

create or replace function test_users_table_group_exists()
returns setof text as $test$
	begin 
		return next has_table('users', 'group',
			'Needs a table for group names.');
	end;
$test$ language plpgsql;

create or replace function test_users_table_group_column_id_exists()
returns setof text as $test$
	begin 
		return next has_column('users', 'group', 'id',
			'The groups table needs an id column.');
	end;
$test$ language plpgsql;

create or replace function test_users_table_group_column_is_uuid()
returns setof text as $test$
	begin
		return next col_type_is('users', 'group', 'id', 'uuid',
			'Group id is uuid.');
	end;
$test$ language plpgsql;

create or replace function test_users_table_group_column_id_is_pk()
returns setof text as $test$
	begin
		return next col_is_pk('users', 'group', 'id', 
			'Group id needs to be the primary key.');
	end;
$test$ language plpgsql;

create or replace function test_users_table_group_column_name_exists()
returns setof text as $test$
	begin 
		return next has_column('users', 'group', 'name', 
			'Group needs a name column.');
	end;
$test$ language plpgsql;

create or replace function test_users_table_group_column_name_is_text()
returns setof text as $test$
	begin 
		return next col_type_is('users', 'group', 'name', 'text',
			'Group name needs to be text.');
	end;
$test$ language plpgsql;

create or replace function test_users_table_group_column_name_is_not_null()
returns setof text as $test$
	begin
		return next col_not_null('users', 'group', 'name',
			'Group name cannot be null.');
	end;
$test$ language plpgsql;

create or replace function test_users_table_group_index_name_exists()
returns setof text as $$
	begin 
		return next has_index('users', 'group', 'groupname', 
			'lower(name)', 
			'Users.group.name must have a lowercase index.');
		return next index_is_unique('users', 'group', 'groupname',
			'Users.user.email must be unique.');
	end;
$$ language plpgsql;

create or replace function test_users_table_group_has_initial_groups()
returns setof text as $test$
	begin 
		return next bag_has(
			'select name from users.group',
			$$values ('admin'), ('everyone'), ('authenticated')$$,
			'The system needs the initial groups.');
	end;
$test$ language plpgsql;

create or replace function test_users_function_protectspecialgroups_exists()
returns setof text as $$
	begin
		return next function_returns('users', 'protect_special_groups', 
			'trigger',
			'There needs to be a protect special groups function.');
		return next is_definer('users', 'protect_special_groups', 
			'Add group should have definer security.');
	end;
$$ language plpgsql;

create or replace function test_users_user_specialgroups_trigger()
returns setof text as $test$
	begin
		return next trigger_is('users', 'group', 'protect_special_groups',
			'users', 'protect_special_groups',
			'Needs a trigger to protect the special groups.');
	end;
$test$ language plpgsql;

create or replace function test_users_table_groups_specialgroups_cannot_change()
returns setof text as $test$
	begin
		return next throws_ok(
			$$update users.group set id = uuid_nil()
				where name = 'admin'$$,
			'P0001', 'This group cannot be changed',
			'Cannot change the admin group.');
		return next throws_ok(
			$$update users.group set id = uuid_nil()
				where name = 'everyone'$$,
			'P0001', 'This group cannot be changed',
			'Cannot change the admin group.');
		return next throws_ok(
			$$update users.group set id = uuid_nil()
				where name = 'authenticated'$$,
			'P0001', 'This group cannot be changed',
			'Cannot change the admin group.');
	end;
$test$ language plpgsql;

create or replace function test_users_table_groups_specialgroups_cannot_be_deleted()
returns setof text as $text$
	begin
		return next throws_ok(
			$$delete from users.group 
				where name = 'admin'$$,
			'P0001', 'This group cannot be changed',
			'Cannot change the admin group.');
		return next throws_ok(
			$$delete from users.group 
				where name = 'everyone'$$,
			'P0001', 'This group cannot be changed',
			'Cannot change the admin group.');
		return next throws_ok(
			$$delete from users.group 
				where name = 'authenticated'$$,
			'P0001', 'This group cannot be changed',
			'Cannot change the admin group.');
	end;
$text$ language plpgsql;

create or replace function test_users_function_addgroup_exists()
returns setof text as $$
	begin
		return next function_returns('users', 'add_group', 
			array['text', 'text'], 'void',
			'There needs to be an add group function.');
		return next is_definer('users', 'add_group', 
			array['text', 'text'],
			'Add group should have definer security.');
	end;
$$ language plpgsql;

create or replace function test_users_function_addgroup_inserts_data()
returns setof text as $test$
	begin
		perform users.add_group('session-1', 'group1');
		return next results_eq( 
			$$select name from users.group
				where name = 'group1'$$,
			$$values ('group1')$$,
			'Users add group needs to add data.');
	end;
$test$ language plpgsql;

create or replace function test_users_function_deletegroup_exists()
returns setof text as $test$
	begin 
		return next function_returns('users', 'delete_group',
			array['text', 'text'], 'void', 
			'There needs to be a function to delete group.');
		return next is_definer('users', 'delete_group', 
			array['text', 'text'], 
			'Delete group needs to securite definer access.');
	end;
$test$ language plpgsql;

create or replace function test_users_function_deletegroup_removes_data()
returns setof text as $test$
	begin 
		perform users.add_group('session-1', 'group1');
		perform users.delete_group('session-1', 'group1');
		return next is_empty(
			$$select * from users.group
				where name = 'group1'$$,
			'Delete user should remove the group.');
	end;
$test$ language plpgsql;

create or replace function test_users_function_deletegroup_not_case_sensitive()
returns setof text as $test$
	begin 
		perform users.add_group('session-1', 'group1');
		perform users.delete_group('session-1', 'GROUP1');
		return next is_empty(
			$$select * from users.group
				where name = 'group1'$$,
			'Delete user should not be case sensitive.');
	end;
$test$ language plpgsql;

create or replace function test_users_table_groupuserlink_exists()
returns setof text as $test$
	begin 
		return next has_table('users', 'group_user_link',
			'There needs to be a table that links users to groups.');
	end;
$test$ language plpgsql;

create or replace function test_users_table_groupuserlink_column_groupid_exists()
returns setof text as $test$
	begin 
		return next has_column('users', 'group_user_link', 'group_id',
			'There should be a column for group ids in group user link.');
	end;
$test$ language plpgsql;

create or replace function test_users_table_groupuserlink_column_groupid_is_uuid()
returns setof text as $test$
	begin
		return next col_type_is('users', 'group_user_link', 'group_id',
			'uuid', 'Group user link group id needs to be UUID.');
	end;
$test$ language plpgsql;

create or replace function test_users_table_groupuserlink_column_groupid_has_fk()
returns setof text as $test$
	begin 
		return next fk_ok('users', 'group_user_link', 'group_id',
			'users', 'group', 'id',
			'Group users link needs group id to be a foreign key to group.');
	end;
$test$ language plpgsql;

create or replace function test_users_table_groupuserlink_column_userid_exists()
returns setof text as $test$
	begin 
		return next has_column('users', 'group_user_link', 'user_id',
			'There should be a column for user ids in group user link.');
	end;
$test$ language plpgsql;

create or replace function test_users_table_groupuserlink_column_userid_is_uuid()
returns setof text as $test$
	begin
		return next col_type_is('users', 'group_user_link', 'user_id',
			'uuid', 'Group user link user id needs to be UUID.');
	end;
$test$ language plpgsql;

create or replace function test_users_table_groupuserlink_column_userid_has_fk()
returns setof text as $test$
	begin 
		return next fk_ok('users', 'group_user_link', 'user_id',
			'users', 'user', 'id',
			'Group users link needs user id to be a foreign key to user.');
	end;
$test$ language plpgsql;

create or replace function test_users_table_groupuserlink_has_primary_key()
returns setof text as $test$
	begin 
		return next col_is_pk('users', 'group_user_link',
			array['group_id', 'user_id'],
			'There should be only one group entry per user.');
	end;
$test$ language plpgsql;

create or replace function test_users_table_groupuserlink_make_sure_theres_an_admin()
returns setof text as $test$
	begin
		return next results_ne(
			$$select cast(count(*) as int) 
				from users.group_user_link, users.group
				where users.group.id = users.group_user_link.group_id
				and users.group.name = 'admin'$$,
			$$values (0)$$,
			'There needs to be at least on admin user.');
	end;
$test$ language plpgsql;

create or replace function correct_users()
returns setof text as $func$
	declare 
		group_list		text[]:=array['admin', 'everyone', 'authenticated'];
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
		
		if failed_test('test_users_table_group_exists') then
			create table users.group();
			return next 'Created the group table.';
		end if;
		if failed_test('test_users_table_group_column_id_exists') then
			alter table users.group
				add column id uuid;
			return next 'Added the group id column.';
		end if;
		if failed_test('test_users_table_group_column_id_is_pk') then
			alter table users.group
				add primary key (id);
			return next 'Made the id the primary key to group.';
		end if;
		if failed_test('test_users_table_group_column_name_exists') then
			alter table users.group
				add column name text;
			return next 'Added the name column to the group table.';
		end if;
		if failed_test('test_users_table_group_column_name_is_text') then
			alter table users.group
				alter column name type text;
			return next 'Set group name to text.';
		end if;
		if failed_test('test_users_table_group_column_name_is_not_null') then
			alter table users.group
				alter column name set not null;
			return next 'Group name is set to not null.';
		end if;
		
		if failed_test('test_users_table_group_index_name_exists') then
			drop index if exists users.groupname;
			create unique index groupname 
				on users.group (lower(name));
			return next 'Created users.group.name index.';
		end if;
		
		if failed_test('test_users_table_group_has_initial_groups') then
			for i in 1..array_length(group_list, 1) loop
				begin 
					insert into users.group (id, name) values
						(uuid_generate_v5(uuid_ns_x500(),
							group_list[i]), group_list[i]);
				exception when unique_violation then
					-- skip this entry.
				end;
			end loop;
			return next 'Added the initial groups.';
		end if;
		
		if failed_test('test_users_table_groupuserlink_exists') then 
			create table users.group_user_link();
			return next 'Created the group user link table.';
		end if;
		if failed_test('test_users_table_groupuserlink_column_groupid_exists') then
			alter table users.group_user_link
				add column group_id uuid;
			return next 'Added the group id column to group users link.';
		end if;
		if failed_test('test_users_table_groupuserlink_column_groupid_is_uuid') then
			alter table users.group_user_link
				alter column group_id type uuid;
			return next 'Made group user link group id uuid.';
		end if;
		if failed_test('test_users_table_groupuserlink_column_groupid_has_fk') then
			alter table users.group_user_link
				add constraint gul_grpid 
				foreign key (group_id) 
				references users.group (id)
				match full
				on delete cascade
				on update cascade;
			return next 'Added the group user link group id foriegn key.';
		end if;
		if failed_test('test_users_table_groupuserlink_column_userid_exists') then
			alter table users.group_user_link
				add column user_id uuid;
			return next 'Added the user id column to group users link.';
		end if;
		if failed_test('test_users_table_groupuserlink_column_userid_is_uuid') then
			alter table users.group_user_link
				alter column user_id type uuid;
			return next 'Made group user link user id uuid.';
		end if;
		if failed_test('test_users_table_groupuserlink_column_userid_has_fk') then
			alter table users.group_user_link
				add constraint gul_usrid 
				foreign key (user_id) 
				references users.user (id)
				match full
				on delete cascade
				on update cascade;
			return next 'Added the group user link user id foriegn key.';
		end if;
		if failed_test('test_users_table_groupuserlink_has_primary_key') then
			alter table users.group_user_link
				add primary key (group_id, user_id);
			return next 'Added primary key for group users link.';
		end if;
		
		if failed_test('test_users_table_groupuserlink_make_sure_theres_an_admin') then
			insert into users.user (id, active, name, password, email) values
				(uuid_generate_v5(uuid_ns_x500(), 'admin'), true,
				'admin', public.crypt('admin', 
					public.gen_salt('bf')), 'to be assigned');
			insert into users.group_user_link (group_id, user_id) values
				((select id from users.group 
					where name = lower('admin')), 
				(select id from users.user
					where name = lower('admin')));
			return next 'Created an admin user.';
		end if;
		
		drop trigger if exists protect_anonymous on users.user;
		drop trigger if exists protect_special_groups on users.group;
		
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
		
		create or replace function users.protect_special_groups()
		returns trigger as $$
			declare
				group_list		text[]:=
					array['admin', 'everyone', 'authenticated'];
			begin
				if array[OLD.name] <@ group_list then
					raise 'This group cannot be changed';
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
		return next 'Created function users.protect_special_groups.';
		
		create or replace function users.add_user(
			sessid		text,
			username	text,
			passwd		text,
			useremail		text)
		returns text as $$
			declare
				new_uid		uuid;
				name_holder	text;
			begin
				if length(passwd) < 5 then
					raise 'new row for relation "user" violates check constraint "passwd_len"' 
						using errcode = 'check_violation';
				end if;
				loop
					select public.uuid_generate_v4() into new_uid;
					select name into name_holder 
						from users.user
						where id = new_uid;
					exit when not found;
				end loop;
				insert into users.user (id, name, password, email) 
					values (new_uid, username, 
						public.crypt(passwd, 
							public.gen_salt('bf')), 
						useremail);
				return 'fred';
			end;
		$$ language plpgsql security definer
		set search_path = users, pg_temp;
		return next 'Created function users.add_user.';
		
		create or replace function users.delete_user(
			sessid		text,
			username	text)
		returns void as $$
			begin
				delete from users.user 
					where name = lower(username);
			end;
		$$ language plpgsql security definer
		set search_path = users, pg_temp;
		return next 'Created function users.delete_user.';
		
		create or replace function users.add_group(
			sessid		text,
			groupname	text)
		returns void as $$
			begin
				declare 
					new_gid		uuid;
					holder_gid	uuid;
				begin
					loop 
						select public.uuid_generate_v4() into new_gid;
						select id into holder_gid from users.group
							where id = new_gid;
						exit when not found;
					end loop;
					insert into users.group (id, name) values
						(new_gid, groupname);
				end;
			end;
		$$ language plpgsql security definer
		set search_path = users, pg_temp;
		return next 'Created function users.add_group.';
		
		create or replace function users.delete_group(
			sessid		text,
			groupname	text)
		returns void as $$
			begin
				delete from users.group
					where name = lower(groupname);
			end;
		$$ language plpgsql security definer
		set search_path = users, pg_temp;
		return next 'Created function users.delete_group.';
		
		create trigger protect_anonymous
			before update or delete
			on users.user
			for each row execute procedure users.protect_anonymous();
		return next 'Created the protect anonymous trigger.';

		create trigger protect_special_groups
			before update or delete
			on users.group
			for each row execute procedure users.protect_special_groups();
		return next 'Created the protect special groups trigger.';

		revoke all on function 
			users.protect_anonymous(),
			users.protect_special_groups(),
			users.add_user(
				sessid		text,
				username	text,
				passwd		text,
				useremail		text),
			users.delete_user(
				sessid		text,
				username	text),
			users.add_group(
				sessid		text,
				groupname	text),
			users.delete_group(
				sessid		text,
				groupname	text)
		from public;
		
		grant execute on function 
			users.add_user(
				sessid		text,
				username	text,
				passwd		text,
				useremail		text),
			users.delete_user(
				sessid		text,
				username	text),
			users.add_group(
				sessid		text,
				groupname	text),
			users.delete_group(
				sessid		text,
				groupname	text)
		to nodepg;
		
		grant usage on schema users to nodepg;
		
		return next 'Permissions set.';
	end;
$func$ language plpgsql;






/*
-- Create Session Table with triggers
create table users.session(
	sess_id		text		primary key,
	user_id		uuid,
	foreign key (sess_id) references web.session (sess_id) on delete cascade,
	foreign key (user_id) references users.user (id) on delete cascade
);

insert into users.group_user_link (group_id, user_id) 
	select 
		users.group.id, 
		users.user.id 
	from 
		users.group, 
		users.user
	where
		users.user.name = 'anonymous'
		and users.group.name = 'everyone';

create or replace function users.init_session() 
returns trigger 
as $$
	begin
		insert into users.session (sess_id, user_id) values (NEW.sess_id, uuid_nil());
		return null;
	end;
$$ language plpgsql security definer;

create trigger init_session 
	after insert
	on web.session
	for each row execute procedure users.init_session();
	
create table users.function (
	id			uuid		primary key,
	name		text		not null
);

create unique index function_name on users.function (lower(name)); 

create or replace function users.add_function(function_name text)
returns void
as $$
	begin
		insert into users.function (id, name) values
			(uuid_generate_v5(uuid_ns_x500(), function_name), function_name);
	end;
$$ language plpgsql security definer;

select users.add_function('users.login');
select users.add_function('users.logout');
select users.add_function('users.info');

create table users.function_user_link(
	function_id			uuid,
	user_obj			uuid,
	user_id				uuid,
	foreign key (function_id) references users.function (id) on delete cascade,
	foreign key (user_obj) references users.user (id) on delete cascade,
	foreign key (user_id) references users.user (id) on delete cascade,
	primary key (function_id, user_obj, user_id)
);

insert into users.function_user_link (function_id, user_obj, user_id)
	select 
		users.function.id,
		users.user.id, 
		uuid_nil() 
	from 
		users.function,
		users.user
	where 
		users.function.name = 'users.login'
		and users.user.name = 'admin';

create table users.function_group_link(
	function_id			uuid,
	user_obj			uuid,
	group_id			uuid,
	foreign key (function_id) references users.function (id) on delete cascade,
	foreign key (user_obj) references users.user (id) on delete cascade,
	foreign key (group_id) references users.group (id) on delete cascade,
	primary key (function_id, user_obj, group_id)
);

insert into users.function_group_link (function_id, user_obj, group_id)
	select 
		users.function.id,
		users.user.id,
		users.group.id
	from
		users.function,
		users.user,
		users.group
	where
		users.function.name = 'users.logout'
		and users.user.name = 'anonymous'
		and users.group.name = 'authenticated';

insert into users.function_group_link (function_id, user_obj, group_id)
	select 
		users.function.id,
		users.user.id,
		users.group.id
	from
		users.function,
		users.user,
		users.group
	where
		users.function.name = 'users.info'
		and 
			(users.user.name = 'anonymous'
			or users.user.name = 'admin')
		and users.group.name = 'everyone';

create table users.unconfirmed(
	link			uuid		primary key,
	user_id		uuid,
	expire		timestamp with time zone	default now() + interval '7 days',
	foreign key (user_id) references users.user (id) on delete cascade
);

create or replace function users.approval(
	session_id		text,
	function_name	text,
	user_name		text)
returns void
as $$
	declare
		thesession		text;
	begin
		select
			users.session.sess_id into thesession
		from
			users.session,
			users.user,
			users.function,
			users.group_user_link,
			users.function_user_link,
			users.function_group_link
		where
			(users.user.name = lower(user_name)
				and users.user.active = true
				and users.user.id = users.function_user_link.user_obj
				and users.function.name = lower(function_name)
				and users.function.id = users.function_user_link.function_id
				and users.session.sess_id = session_id
				and users.session.user_id = users.function_user_link.user_id)
			or (users.user.name = user_name
				and users.user.id = users.function_group_link.user_obj
				and users.function.name = lower(function_name)
				and users.function.id = users.function_group_link.function_id
				and users.function_group_link.group_id = users.group_user_link.group_id
				and users.group_user_link.user_id = users.session.user_id
				and users.session.sess_id = session_id);
		if not found then
			raise 'Not Authorized';
		end if;
	end;
$$ language plpgsql security definer;

create type userinfo as (username text);

create or replace function users.login(
	session_id		text,
	username		text,
	passwd			text)
returns void
as $$
	declare
		newuserid	uuid;
	begin
		perform users.approval(session_id, 'users.login', username);
		select
			id into newuserid
			from
				users.user
			where
				name = lower(username)
				and password = crypt(passwd, password);
		if found then
			update 
				users.session
				set
					user_id = newuserid
				where
					sess_id = session_id;
		else
			raise 'Invalid username or password';
		end if;
	end;
$$ language plpgsql security definer;

create or replace function users.logout(session_id text)
returns void
as $$
	begin
		perform users.approval(session_id, 'users.logout', 'anonymous');
		update users.session set user_id = uuid_nil()
			where sess_id = session_id;
	end;
$$ language plpgsql security definer;

create or replace function users.set_password(
	session_id			text,
	username			text,
	passwordold			text,
	passwordnew			text)
returns void
as $$
	begin
		return;
	end;
$$ language plpgsql security definer;

create table users.user_group_link(
	group_id	uuid,
	owner		boolean		default true,
	user_id		uuid,
	foreign key (group_id) references users.group (id),
	foreign key (user_id) references users.user (id),
	primary key (group_id, user_id)
);

insert into users.user_group_link (group_id, owner, user_id) values
	((select id from users.group where name = 'admin'),
	true,
	(select id from users.user where name = 'admin'));

	
create or replace function users.expire_unconfirmed()
returns trigger
as $$
	begin
		delete from users.user 
			where id = (select user_id from users.unconfirmed where expire < now());
		return null;
	end;
$$ language plpgsql security definer;

create trigger expire_unconfirmed
	after insert
	on web.session
	execute procedure users.expire_unconfirmed();
	

create or replace function users.validate(thelink uuid)
returns boolean
as $$
	begin
		update users.user 
			set active = true 
			where id = (select user_id from users.unconfirmed
				where link = thelink);
		if found then
			delete from users.unconfirmed where link = thelink;
			return true;
		else
			return false;
		end if;
	end;
$$ language plpgsql security definer;

create or replace function users.get_groups(session_id text)
returns setof text
as $$
	begin
		return query
			select 
				users.group.name
			from
				users.session,
				users.group,
				users.user_group_link
			where
				users.session.user_id = users.user_group_link.user_id and
				users.user_group_link.group_id = users.group.id and
				users.session.sess_id = session_id;
	end;
$$ language plpgsql security definer;
*/