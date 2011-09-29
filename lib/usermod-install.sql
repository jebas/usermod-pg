-- This setup needs to run after webs setup.
create or replace function startup_20_users()
returns setof text as $test$
	declare
		nameholder	text;
		userid		uuid;
		grpid		uuid;
	begin
		delete from users.test_user;
		loop
			select md5(random()::text) into nameholder;
			select id into userid
				from users.user 
				where name = lower(nameholder)
					or email = lower(nameholder);
			if found then
				continue;
			end if;
			insert into users.test_user (name) 
				values (nameholder);
			if (select count(*) > 5 from users.test_user) then
				insert into users.user (id, name, password, email)
					values (public.uuid_generate_v1(), nameholder,
					public.crypt('password', public.gen_salt('bf')),
					nameholder);
			end if;
			if (select count(*) > 10 from users.test_user) then
				update users.user set active = true 
					where name = lower(nameholder);
			end if;
			exit when (select count(*) > 14 from users.test_user);
		end loop;
		delete from users.test_group;
		loop 
			select md5(random()::text) into nameholder;
			select id into grpid
				from users.group
				where name = lower(nameholder);
			if found then
				continue;
			end if;
			insert into users.test_group (name)
				values (nameholder);
			if (select count(*) > 5 from users.test_group) then 
				insert into users.group (id, name) values
					(public.uuid_generate_v1(), nameholder);
			end if;
			exit when (select count(*) > 9 from users.test_group);
		end loop;
	exception
		when invalid_schema_name or  undefined_function or
			undefined_table or undefined_column then
			--do nothing
	end;
$test$ language plpgsql;

create or replace function setup_20_users()
returns setof text as $test$
	begin
		update web.session 
			set user_id = 
				(select 
					users.group_user_link.user_id 
				from users.group,
					users.group_user_link
				where 
					users.group.id = users.group_user_link.group_id
					and users.group.name = 'admin'
				limit 1)
			where web.session.sess_id = 'web-session-1';
	exception
		when invalid_schema_name or undefined_function or
			undefined_table or undefined_column then
			--do nothing
	end; 
$test$ language plpgsql;

create or replace function test_users_schema()
returns setof text as $$
	begin 
		return next has_schema('users', 'There should be a users schema.');
	end;
$$ language plpgsql;

create or replace function test_users_table_testusers_exists()
returns setof text as $test$
	begin
		return next has_table('users', 'test_user', 
			'There should be a table to hold test users.');
	end;
$test$ language plpgsql;

create or replace function test_users_table_testusers_column_name_exists()
returns setof text as $test$
	begin
		return next has_column('users', 'test_user', 'name',
			'Needs a user name column in test users.');
	end;
$test$ language plpgsql;  

create or replace function test_users_table_testuser_column_name_is_text()
returns setof text as $test$
	begin
		return next col_type_is('users', 'test_user', 'name', 'text',
			'The test user name needs to be text.');
	end;
$test$ language plpgsql;  

create or replace function test_users_table_testuser_column_name_is_pk()
returns setof text as $test$
	begin 
		return next col_is_pk('users', 'test_user', 'name',
			'Name should be primary key for test users.');
	end;
$test$ language plpgsql;

create or replace function test_users_table_testgroup_exists()
returns setof text as $test$
	begin
		return next has_table('users', 'test_group', 
			'There should be a table to hold test groups.');
	end;
$test$ language plpgsql;

create or replace function test_users_table_testgroup_column_name_exists()
returns setof text as $test$
	begin
		return next has_column('users', 'test_group', 'name',
			'Needs a user name column in test users.');
	end;
$test$ language plpgsql;  

create or replace function test_users_table_testgroup_column_name_is_text()
returns setof text as $test$
	begin
		return next col_type_is('users', 'test_group', 'name', 'text',
			'The test group name needs to be text.');
	end;
$test$ language plpgsql;  

create or replace function test_users_table_testgroup_column_name_is_pk()
returns setof text as $test$
	begin 
		return next col_is_pk('users', 'test_group', 'name',
			'Name should be primary key for test group.');
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
			array['text', 'text', 'text', 'text'], 'uuid',
			'There needs to be an add user function.');
		return next is_definer('users', 'add_user', 
			array['text', 'text', 'text', 'text'],
			'Add user should have definer security.');
	end;
$test$ language plpgsql;

create or replace function test_users_function_add_user_inserts_data()
returns setof text as $test$
	declare
		newusercur		cursor for select users.test_user.name
							from users.test_user
							left outer join users.user on 
								(lower(users.test_user.name) = 
								users.user.name)
							where users.user.active is null;
		user1			text;
		holder			text;
	begin
		open newusercur;
		fetch from newusercur into user1;
		select add_user into holder from
			users.add_user('web-session-1', user1, 'password',
				user1);
		return next results_eq(
			$$select active, name, email from users.user 
				where name = '$$ || user1 || $$'$$,
			$$values (false, '$$ || user1 || $$', 
				'$$ || user1 || $$')$$,
			'add_user needs to add the user to users.user.');
		return next results_ne(
			$$select password from users.user
				where name = '$$ || user1 || $$'$$,
			$$values ('password')$$,
			'User''s password needs to be encrypted.');
		return next results_eq(
			$$select cast(users.validate.link as text)
				from users.validate, users.user
				where users.user.id = users.validate.user_id
					and users.user.name = '$$ || user1 || $$'$$,
			array[holder],
			'User add must output the validation link');
	end;
$test$ language plpgsql;

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

create or replace function test_users_function_add_user_password_length()
returns setof text as $test$
	declare
		newusercur		cursor for select users.test_user.name
							from users.test_user
							left outer join users.user on 
								(lower(users.test_user.name) = 
								users.user.name)
							where users.user.active is null;
		user1			text;
	begin
		open newusercur;
		fetch from newusercur into user1;
		return next throws_ok(
			$$select users.add_user('web-session-1', 
				'$$ || user1 || $$',
				'four', '$$ || user1 || $$')$$,
			'23514', 
			'new row for relation "user" violates check constraint "passwd_len"',
			'User password must be a minimum of 5 characters.');
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

create or replace function test_users_function_validate_exists()
returns setof text as $test$
	begin
		return next function_returns('users', 'validate_user',
			array['text', 'uuid'], 'void',
			'There needs to be a function that validates new users.');
		return next is_definer('users', 'validate_user', 
			array['text', 'uuid'], 
			'Validate user needs to have security definer access.');
	end;
$test$ language plpgsql;

create or replace function test_users_function_validate_activates_user()
returns setof text as $test$
	declare
		newusercur		cursor for select users.test_user.name
							from users.test_user
							left outer join users.user on 
								(lower(users.test_user.name) = 
								users.user.name)
							where users.user.active is null;
		user1		text;
		holder		uuid;
	begin
		open newusercur;
		fetch from newusercur into user1;
		select add_user into holder from
			users.add_user('web-session-1', user1, 'password',
				user1);
		perform users.validate_user('web-session-1', holder);
		return next results_eq(
			$$select active from users.user 
				where name = '$$ || user1 || $$'$$,
			array[true],
			'Validate user should make the user active.');
		return next is_empty(
			$$select * from users.validate, users.user
				where users.user.id = users.validate.user_id
				and users.user.name = '$$ || user1 || $$'$$,
			'Validate needs to delete the validation link.');
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
		newusercur		cursor for select users.test_user.name
							from users.test_user
							left outer join users.user on 
								(lower(users.test_user.name) = 
								users.user.name)
							where users.user.active is null;
		activeusercur		cursor for select users.test_user.name
							from users.test_user
							left outer join users.user on 
								(lower(users.test_user.name) = 
								users.user.name)
							where users.user.active = true;
		newuser			text;
		activeuser		text;
		newuserlink		uuid;
	begin 
		open newusercur;
		open activeusercur;
		fetch from newusercur into newuser;
		fetch from activeusercur into activeuser;
		select add_user into newuserlink from
			users.add_user('web-session-1', newuser, 'password',
				newuser);
		update users.validate set expire = now() - interval '1 day' 
			where link = newuserlink;
		update users.user set password =
			public.crypt('password', public.gen_salt('bf'))
			where name = lower(activeuser);
		return next is_empty(
			$$select * from users.user where 
				name = lower('$$ || newuser || $$')$$,
			'Unvalidated users should expire after a time.');
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
	declare 
		activeusercur		cursor for select users.test_user.name
							from users.test_user
							left outer join users.user on 
								(lower(users.test_user.name) = 
								users.user.name)
							where users.user.active = true;
		activeuser		text;
	begin 
		open activeusercur;
		fetch from activeusercur into activeuser;
		perform users.delete_user('web-session-1', activeuser);
		return next is_empty(
			$$select * from users.user 
				where name = '$$ || activeuser || $$'$$,
			'Delete user should remove the user.');
	end;
$test$ language plpgsql;

create or replace function test_users_function_deleteuser_not_case_sensitive()
returns setof text as $test$
	declare 
		activeusercur		cursor for select users.test_user.name
							from users.test_user
							left outer join users.user on 
								(lower(users.test_user.name) = 
								users.user.name)
							where users.user.active = true;
		activeuser		text;
	begin 
		open activeusercur;
		fetch from activeusercur into activeuser;
		perform users.delete_user('web-session-1', upper(activeuser));
		return next is_empty(
			$$select * from users.user 
				where name = '$$ || activeuser || $$'$$,
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
	declare 
		newgrpcur		cursor for select users.test_group.name
							from users.test_group
							left outer join users.group on 
								(lower(users.test_group.name) = 
								users.group.name)
							where users.group.id is null;
		newgroup		text;
	begin 
		open newgrpcur;
		fetch from newgrpcur into newgroup;
		perform users.add_group('web-session-1', newgroup);
		return next results_eq( 
			$$select name from users.group
				where name = '$$ || newgroup || $$'$$,
			$$values ('$$ || newgroup || $$')$$,
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
	declare
		grpcur		cursor for select users.test_group.name
							from users.test_group
							left outer join users.group on 
								(lower(users.test_group.name) = 
								users.group.name)
							where users.group.id is not null;
		agroup		text;
	begin 
		open grpcur;
		fetch from grpcur into agroup;
		perform users.delete_group('web-session-1', agroup);
		return next is_empty(
			$$select * from users.group
				where name = '$$ || agroup || $$'$$,
			'Delete user should remove the group.');
	end;
$test$ language plpgsql;

create or replace function test_users_function_deletegroup_not_case_sensitive()
returns setof text as $test$
	declare
		grpcur		cursor for select users.test_group.name
							from users.test_group
							left outer join users.group on 
								(lower(users.test_group.name) = 
								users.group.name)
							where users.group.id is not null;
		agroup		text;
	begin 
		open grpcur;
		fetch from grpcur into agroup;
		perform users.delete_group('web-session-1', upper(agroup));
		return next is_empty(
			$$select * from users.group
				where name = '$$ || agroup || $$'$$,
			'Delete user should remove the group.');
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

create or replace function test_users_function_protect_group_link_exists()
returns setof text as $test$
	begin 
		return next function_returns('users', 'protect_group_link',
			'trigger', 
			'There needs to be a function to protect group user links.');
		return next is_definer('users', 'protect_group_link', 
			'Delete group needs to securite definer access.');
	end;
$test$ language plpgsql;

create or replace function test_users_trigger_protect_group_link_exists()
returns setof text as $test$
	begin 
		return next trigger_is(
			'users', 'group_user_link', 'protect_group_link',
			'users', 'protect_group_link',
			'Needs a trigger to protect the group users link table.');
	end;
$test$ language plpgsql;

create or replace function test_users_function_protect_group_link_from_anonymous()
returns setof text as $test$
	begin
		return next throws_ok(
			$$insert into users.group_user_link (group_id, user_id) 
				select users.group.id, users.user.id 
				from users.user, users.group 
				where users.user.name = 'anonymous'
					and users.group.name = 'admin'$$,
			'P0001', 'Anonymous cannot be assigned to this group.',
			'Anonymous cannot be an administrator.');
		return next throws_ok(
			$$insert into users.group_user_link (group_id, user_id) 
				select users.group.id, users.user.id 
				from users.user, users.group 
				where users.user.name = 'anonymous'
					and users.group.name = 'authenticated'$$,
			'P0001', 'Anonymous cannot be assigned to this group.',
			'Anonymous is always the logged out user.');
	end;
$test$ language plpgsql;

create or replace function test_users_function_protect_group_link_update_anonymous()
returns setof text as $test$
	declare
		activeusercur		cursor for select users.test_user.name
							from users.test_user
							left outer join users.user on 
								(lower(users.test_user.name) = 
								users.user.name)
							where users.user.active = true;
		activeuser		text;
	begin 
		open activeusercur;
		fetch from activeusercur into activeuser;
		insert into users.group_user_link (group_id, user_id) 
			select users.group.id, users.user.id 
			from users.user, users.group
			where users.user.name = activeuser
			and users.group.name = 'admin';
		return next throws_ok(
			$$update users.group_user_link 
				set user_id = public.uuid_nil()
				where user_id = (select id from users.user
					where name = '$$ || activeuser || $$')
				and group_id = (select id from users.group
					where name = 'admin')$$,
			'P0001', 'Anonymous cannot be assigned to this group.',
			'Anonymous cannot be an administrator.');
		return next throws_ok(
			$$update users.group_user_link 
				set user_id = public.uuid_nil()
				where user_id = (select id from users.user
					where name = '$$ || activeuser || $$')
				and group_id = (select id from users.group
					where name = 'authenticated')$$,
			'P0001', 'Anonymous cannot be assigned to this group.',
			'Anonymous is always the logged out user.');
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
		activeusercur		cursor for select users.test_user.name
							from users.test_user
							left outer join users.user on 
								(lower(users.test_user.name) = 
								users.user.name)
							where users.user.active = true;
		activeuser		text;
	begin 
		open activeusercur;
		fetch from activeusercur into activeuser;
		perform users.login('web-session-2', activeuser,
			'password');
		return next results_eq(
			$$select user_id from web.session 
				where sess_id = 'web-session-2'$$,
			$$select id from users.user 
				where name = lower('$$ || activeuser || $$')$$,
			'Login should assign the user to the session.');
	end;
$test$ language plpgsql;

create or replace function test_users_function_login_username_case_insensitive()
returns setof text as $test$
	declare
		activeusercur		cursor for select users.test_user.name
							from users.test_user
							left outer join users.user on 
								(lower(users.test_user.name) = 
								users.user.name)
							where users.user.active = true;
		activeuser		text;
	begin 
		open activeusercur;
		fetch from activeusercur into activeuser;
		perform users.login('web-session-2', upper(activeuser),
			'password');
		return next results_eq(
			$$select user_id from web.session 
				where sess_id = 'web-session-2'$$,
			$$select id from users.user 
				where name = lower('$$ || activeuser || $$')$$,
			'Login should assign the user to the session.');
	end;
$test$ language plpgsql;
















create or replace function test_users_function_login_fails_for_incorrect_values()
returns setof text as $test$
	begin
		perform users.validate_user('web-session-1', users.add_user(
			'web-session-1', 'test-user1', 'password', 
			'test-user1@testers.com'));
		perform web.set_session_data('users-session-1', '{}',
			now() + interval '1 day');
		return next throws_ok(
			$$select users.login('users-session-1', 'test-user1',
				'wrong')$$, 
			'P0001', 'Incorrect user name or password.',
			'Login needs to throw an error on failure.');
	end;
$test$ language plpgsql;












create or replace function test_users_function_login_username_only_active()
returns setof text as $test$
	begin
		perform users.add_user(
			'web-session-1', 'test-user1', 'password', 
			'test-user1@testers.com');
		perform web.set_session_data('users-session-1', '{}',
			now() + interval '1 day');
		return next throws_ok(
			$$select users.login('users-session-1', 'test-user1',
				'password')$$, 
			'P0001', 'Incorrect user name or password.',
			'Login needs to throw an error for inactive users.');
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
	begin
		perform users.validate_user('web-session-1', users.add_user(
			'web-session-1', 'test-user1', 'password', 
			'test-user1@testers.com'));
		perform web.set_session_data('users-session-1', '{}',
			now() + interval '1 day');
		perform users.login('users-session-1', 'test-user1',
				'password');
		perform users.logout('users-session-1');
		return next results_eq(
			$$select web.session.user_id from web.session 
				where sess_id = 'users-session-1'$$,
			array[uuid_nil()],
			'Logout must return the session to anonymous');
	end;
$test$ language plpgsql;

create or replace function test_users_function_updatespecialgroups_exists()
returns setof text as $test$
	begin 
		return next function_returns('users', 'update_special_groups',
			'trigger', 
			'There needs to be a function to update special groups.');
		return next is_definer('users', 'update_special_groups', 
			'Update special groups needs to securite definer access.');
	end;
$test$ language plpgsql;

create or replace function test_users_user_updatespecialgroups_trigger()
returns setof text as $test$
	begin
		return next trigger_is('users', 'user', 'update_special_groups',
			'users', 'update_special_groups',
			'Needs a trigger to update special groups.');
	end;
$test$ language plpgsql;

create or replace function test_users_function_updatespecialgroups_adds_user_to_groups()
returns setof text as $test$
	begin
		perform users.validate_user('web-session-1', users.add_user(
			'web-session-1', 'test-user1', 'password', 
			'test-user1@testers.com'));
		return next bag_has(
			$$select users.user.name 
				from users.user, users.group, users.group_user_link
				where users.user.id = users.group_user_link.user_id
					and users.group.id = users.group_user_link.group_id
					and users.group.name = 'authenticated'$$,
			$$values ('test-user1')$$,
			'New users need to be added to the authenticated group.');
		return next bag_has(
			$$select users.user.name 
				from users.user, users.group, users.group_user_link
				where users.user.id = users.group_user_link.user_id
					and users.group.id = users.group_user_link.group_id
					and users.group.name = 'everyone'$$,
			$$values ('test-user1'), ('anonymous')$$,
			'New users need to be added to the everyone group.');
		return next bag_hasnt(
			$$select users.user.name 
				from users.user, users.group, users.group_user_link
				where users.user.id = users.group_user_link.user_id
					and users.group.id = users.group_user_link.group_id
					and users.group.name = 'authenticated'$$,
			$$values ('anonymous')$$,
			'Anonymous cannot be part of the authenticated group.');
	end;
$test$ language plpgsql;

create or replace function test_users_table_groupinvite_exists()
returns setof text as $test$
	begin
		return next has_table('users', 'group_invite',
			'Needs a group invite table.');
	end;
$test$ language plpgsql;

create or replace function test_users_table_groupinvite_column_link_exists()
returns setof text as $test$
	begin
		return next has_column('users', 'group_invite', 'link',
			'Group invite needs a link column.');
	end;
$test$ language plpgsql;

create or replace function test_users_table_groupinvite_column_link_is_uuid()
returns setof text as $test$
	begin
		return next col_type_is('users', 'group_invite', 'link', 'uuid',
			'Group invite''s link needs to be uuid');
	end;
$test$ language plpgsql;

create or replace function test_users_table_groupinvite_column_link_is_pk()
returns setof text as $test$
	begin
		return next col_is_pk( 'users', 'group_invite', 'link',
			'Link needs to be the primary key on group_invite.');
	end;
$test$ language plpgsql;

create or replace function test_users_table_groupinvite_column_groupid_exists()
returns setof text as $test$
	begin
		return next has_column('users', 'group_invite', 'group_id',
			'Group invite needs a group id column.');
	end;
$test$ language plpgsql;

create or replace function test_users_table_groupinvite_column_groupid_is_uuid()
returns setof text as $test$
	begin
		return next col_type_is('users', 'group_invite', 'group_id', 'uuid',
			'Group invite group id needs to be uuid');
	end;
$test$ language plpgsql;

create or replace function test_users_table_groupinvite_column_groupid_is_fk()
returns setof text as $test$
	begin
		return next fk_ok('users', 'group_invite', 'group_id',
			'users', 'group', 'id',
			'Group invite group id needs to be linked to group');
	end;
$test$ language plpgsql;

create or replace function test_users_table_groupinvite_column_userid_exists()
returns setof text as $test$
	begin
		return next has_column('users', 'group_invite', 'user_id',
			'Group invite needs a user id column.');
	end;
$test$ language plpgsql;

create or replace function test_users_table_groupinvite_column_userid_is_uuid()
returns setof text as $test$
	begin
		return next col_type_is('users', 'group_invite', 'user_id', 'uuid',
			'Group invite user id needs to be uuid');
	end;
$test$ language plpgsql;

create or replace function test_users_table_groupinvite_column_userid_is_fk()
returns setof text as $test$
	begin
		return next fk_ok('users', 'group_invite', 'user_id',
			'users', 'user', 'id',
			'Group invite user id needs to be linked to group');
	end;
$test$ language plpgsql;

create or replace function test_users_table_groupinvite_column_refused_exists()
returns setof text as $test$
	begin
		return next has_column('users', 'group_invite', 'refused',
			'Group invite needs a refused column.');
	end;
$test$ language plpgsql;

create or replace function test_users_table_groupinvite_column_refused_is_boolean()
returns setof text as $test$
	begin
		return next col_type_is('users', 'group_invite', 'refused', 'boolean',
			'Group invite user id needs to be boolean');
	end;
$test$ language plpgsql;

create or replace function test_users_table_groupinvite_colume_refused_has_default()
returns setof text as $test$
	begin
		return next col_default_is('users', 'group_invite', 'refused',
			'false'::boolean,
			'The group invite refused should default to false.');
	end;
$test$ language plpgsql;

create or replace function test_users_table_groupinvite_column_expire_exists()
returns setof text as $test$
	begin
		return next has_column('users', 'group_invite', 'expire',
			'Group invite needs a expiration column.');
	end;
$test$ language plpgsql;

create or replace function test_users_table_groupinvite_column_expire_is_timestamp()
returns setof text as $test$
	begin
		return next col_type_is('users', 'group_invite', 'expire', 
			'timestamp with time zone',
			'Group invite user id needs to be boolean');
	end;
$test$ language plpgsql;

create or replace function test_users_table_groupinvite_colume_expire_has_default()
returns setof text as $test$
	begin
		return next col_default_is('users', 'group_invite', 'expire',
			$$(now() + '1 mon'::interval)$$,
			'The group invite expire should default to one month.');
	end;
$test$ language plpgsql;

create or replace function test_users_function_addgroupuser_exists()
returns setof text as $test$
	begin 
		return next function_returns('users', 'group_user_add',
			array['text', 'text', 'text'], 'uuid', 
			'There needs to be a function to add users to a group.');
		return next is_definer('users', 'group_user_add', 
			array['text', 'text', 'text'], 
			'Logout needs to securite definer access.');
	end;
$test$ language plpgsql;

create or replace function test_users_function_addgroupuser_adds_data()
returns setof text as $test$
	begin 
		--perform users.add_group_user('web-session-1', 
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
		
		if failed_test('test_users_table_testusers_exists') then 
			create table users.test_user();
			return next 'Created the test users table.';
		end if;
		if failed_test('test_users_table_testusers_column_name_exists') then
			alter table users.test_user
				add column name text;
			return next 'Added the user name column to test users.';
		end if;
		if failed_test('test_users_table_testuser_column_name_is_text') then
			alter table users.test_user
				alter column name type text;
			return next 'Altered test user name to text.';
		end if;  
		if failed_test('test_users_table_testuser_column_name_is_pk') then
			alter table users.test_user
				add primary key (name);
			return next 'Added the primary key to test users.';
		end if;  
		
		if failed_test('test_users_table_testgroup_exists') then 
			create table users.test_group();
			return next 'Created the test group table.';
		end if;
		if failed_test('test_users_table_testgroup_column_name_exists') then
			alter table users.test_group
				add column name text;
			return next 'Added the user name column to test group.';
		end if;
		if failed_test('test_users_table_testgroup_column_name_is_text') then
			alter table users.test_group
				alter column name type text;
			return next 'Altered test group name to text.';
		end if;  
		if failed_test('test_users_table_testgroup_column_name_is_pk') then
			alter table users.test_group
				add primary key (name);
			return next 'Added the primary key to test group.';
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
			create unique index groupname on users.group (lower(name));
			return next 'Created the group name index.';
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
		
		if failed_test('test_users_table_groupinvite_exists') then
			create table users.group_invite();
			return next 'Created the group invite table.';
		end if;
		if failed_test('test_users_table_groupinvite_column_link_exists') then
			alter table users.group_invite
				add column link uuid;
			return next 'Added the group invite link column.';
		end if;
		if failed_test('test_users_table_groupinvite_column_link_is_uuid') then
			alter table users.group_invite
				alter column link type uuid;
			return next 'Changed group invite link column to uuid.';
		end if;
		if failed_test('test_users_table_groupinvite_column_link_is_pk') then
			alter table users.group_invite
				add primary key (link);
			return next 'Added the primary key to group_invite';
		end if;
		if failed_test('test_users_table_groupinvite_column_groupid_exists') then
			alter table users.group_invite
				add column group_id uuid;
			return next 'Added the group invite groupid column.';
		end if;
		if failed_test('test_users_table_groupinvite_column_groupid_is_uuid') then
			alter table users.group_invite
				alter column group_id type uuid;
			return next 'Changed group invite group id column to uuid.';
		end if;
		if failed_test('test_users_table_groupinvite_column_groupid_is_fk') then
			alter table users.group_invite
				add constraint invite_grpid 
				foreign key (group_id) 
				references users.group (id)
				match full
				on delete cascade
				on update cascade;
			return next 'Linked the group invite group id to the group id.';
		end if;
		if failed_test('test_users_table_groupinvite_column_userid_exists') then
			alter table users.group_invite
				add column user_id uuid;
			return next 'Added the group invite userid column.';
		end if;
		if failed_test('test_users_table_groupinvite_column_userid_is_uuid') then
			alter table users.group_invite
				alter column user_id type uuid;
			return next 'Changed group invite user id column to uuid.';
		end if;
		if failed_test('test_users_table_groupinvite_column_userid_is_fk') then
			alter table users.group_invite
				add constraint invite_usrid 
				foreign key (user_id) 
				references users.user (id)
				match full
				on delete cascade
				on update cascade;
			return next 'Linked the group invite user id to the user id.';
		end if;
		if failed_test('test_users_table_groupinvite_column_refused_exists') then
			alter table users.group_invite
				add column refused boolean;
			return next 'Added the group invite refused column.';
		end if;
		if failed_test('test_users_table_groupinvite_column_refused_is_boolean') then
			alter table users.group_invite
				alter column refused type boolean;
			return next 'Changed group invite refused column to boolean.';
		end if;
		if failed_test('test_users_table_groupinvite_colume_refused_has_default') then
			alter table users.group_invite
				alter column refused set default false;
			return next 'Set the default for users group invite refused.';
		end if;
		if failed_test('test_users_table_groupinvite_column_expire_exists') then
			alter table users.group_invite
				add column expire timestamp with time zone;
			return next 'Added the group invite expiration column.';
		end if;
		if failed_test('test_users_table_groupinvite_column_expire_is_timestamp') then
			alter table users.group_invite
				alter column expire type boolean;
			return next 'Changed group invite expire column to timestamp.';
		end if;
		if failed_test('test_users_table_groupinvite_colume_expire_has_default') then
			alter table users.group_invite
				alter column expire set default now() + interval '1 month';
			return next 'Set the default for group invite expiration.';
		end if;
		
		drop trigger if exists protect_anonymous on users.user;
		drop trigger if exists delete_unvalidated on users.user;
		drop trigger if exists update_special_groups on users.user;
		drop trigger if exists protect_special_groups on users.group;
		drop trigger if exists protect_group_link on users.group_user_link;
		
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
		
		create or replace function users.protect_group_link()
		returns trigger as $$
			declare
				gname		text;
			begin 
				if NEW.user_id = public.uuid_nil() then
					select name into gname
						from users.group
						where id = NEW.group_id
						and ( name = 'admin'
						or name = 'authenticated');
					if found then
						raise 'Anonymous cannot be assigned to this group.';
					end if;
				end if;
				return NEW;
			end;
		$$ language plpgsql security definer
		set search_path = users, pg_temp;
		return next 'Created function users.protect_group_link.';

		create or replace function users.update_special_groups()
		returns trigger as $$
			begin
				insert into users.group_user_link (user_id, group_id)
					select
						users.user.id as user_id,
						users.group.id as group_id
					from 
						users.user left join 
							(select 
								users.group_user_link.user_id as user_id,
								users.group.name as grpname
							from 
								users.group,
								users.group_user_link
							where 
								users.group.id = users.group_user_link.group_id
								and users.group.name = 'everyone') as grouping
							on users.user.id = grouping.user_id,
						users.group
					where 
						grouping.grpname is null
						and users.group.name = 'everyone';
				insert into users.group_user_link (user_id, group_id)
					select
						users.user.id as user_id,
						users.group.id as group_id
					from 
						users.user left join 
							(select 
								users.group_user_link.user_id as user_id,
								users.group.name as grpname
							from 
								users.group,
								users.group_user_link
							where 
								users.group.id = users.group_user_link.group_id
								and users.group.name = 'authenticated') as grouping
							on users.user.id = grouping.user_id,
						users.group
					where 
						grouping.grpname is null
						and users.user.name != 'anonymous'
						and users.group.name = 'authenticated';
				return null;
			end;
		$$ language plpgsql security definer
		set search_path = users, pg_temp;
		return next 'Created function users.update_special_groups.';

		create or replace function users.delete_unvalidated()
		returns trigger as $$
			begin
				delete from users.user 
					where id = (select user_id from users.validate
						where expire < now());
				return null;
			end;
		$$ language plpgsql security definer
		set search_path = users, pg_temp;
		return next 'Created function users.delete_unvalidated.';

		create or replace function users.add_user(
			sessid		text,
			username	text,
			passwd		text,
			useremail		text)
		returns uuid as $$
			declare
				link_holder	uuid;
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
				select public.uuid_generate_v5(
					public.uuid_ns_x500(),
					lower(username)) into link_holder;
				insert into users.validate (link, user_id) values
					(link_holder, new_uid);
				return link_holder;
			end;
		$$ language plpgsql security definer
		set search_path = users, pg_temp;
		return next 'Created function users.add_user.';
		
		create or replace function users.validate_user(
			sessid		text,
			linkcode		uuid)
		returns void as $$
			begin
				update users.user set active = true 
					where id = (select user_id 
						from users.validate 
						where link = linkcode);
				delete from users.validate
					where link = linkcode;
			end;
		$$ language plpgsql security definer
		set search_path = users, pg_temp;
		return next 'Created function users.validate_user.';
		
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
		
		create or replace function users.login(
			sessid		text,
			username	text,
			passwd		text)
		returns void as $$
			declare
				userid		uuid;
			begin
				select id into userid
					from users.user
					where name = lower(username)
						and active = true
						and password = public.crypt(passwd,
							password);
				if found then
					update web.session
						set user_id = userid
						where sess_id = sessid;
				else
					raise 'Incorrect user name or password.';
				end if;
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
		
		create or replace function users.group_user_add(
			sessid		text,
			groupname	text,
			username	text)
		returns uuid as $$
			begin
				return public.uuid_nil();
			end;
		$$ language plpgsql security definer
		set search_path = users, pg_temp;
		return next 'Created function users.group_user_add.';
		
		create trigger protect_anonymous
			before update or delete
			on users.user
			for each row execute procedure users.protect_anonymous();
		return next 'Created the protect anonymous trigger.';

		create trigger delete_unvalidated
			after update
			on users.user
			execute procedure users.delete_unvalidated();
		return next 'Created the remove unvalidated trigger.';

		create trigger update_special_groups
			after update
			on users.user
			execute procedure users.update_special_groups();
		return next 'Created the update special groups trigger.';

		create trigger protect_special_groups
			before update or delete
			on users.group
			for each row execute procedure users.protect_special_groups();
		return next 'Created the protect special groups trigger.';

		create trigger protect_group_link
			before insert or update
			on users.group_user_link
			for each row execute procedure users.protect_group_link();
		return next 'Created the protect special group link trigger.';

		revoke all on function 
			users.protect_anonymous(),
			users.delete_unvalidated(),
			users.protect_special_groups(),
			users.update_special_groups(),
			users.protect_group_link(),
			users.add_user(
				sessid		text,
				username	text,
				passwd		text,
				useremail		text),
			users.validate_user(
				sessid		text,
				linkcode		uuid),
			users.delete_user(
				sessid		text,
				username	text),
			users.add_group(
				sessid		text,
				groupname	text),
			users.delete_group(
				sessid		text,
				groupname	text),
			users.login(
				sessid		text,
				username	text,
				passwd		text),
			users.logout(
				sessid		text),
			users.group_user_add(
				sessid		text,
				groupname	text,
				username	text)
		from public;
		
		grant execute on function 
			users.add_user(
				sessid		text,
				username	text,
				passwd		text,
				useremail		text),
			users.validate_user(
				sessid		text,
				linkcode		uuid),
			users.delete_user(
				sessid		text,
				username	text),
			users.add_group(
				sessid		text,
				groupname	text),
			users.delete_group(
				sessid		text,
				groupname	text),
			users.login(
				sessid		text,
				username	text,
				passwd		text),
			users.logout(
				sessid		text),
			users.group_user_add(
				sessid		text,
				groupname	text,
				username	text)
		to nodepg;
		
		grant usage on schema users to nodepg;
		
		return next 'Permissions set.';
	end;
$func$ language plpgsql;






/*
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