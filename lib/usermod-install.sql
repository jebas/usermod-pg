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
		
		drop trigger if exists protect_anonymous on users.user;
		
		create or replace function users.protect_anonymous()
		returns trigger as $$
			begin
				if NEW.name = 'anonymous' then 
					raise 'Anonymous cannot be changed.';
				end if;
				return NEW;
			end;
		$$ language plpgsql security definer
		set search_path = users, pg_temp;
		return next 'Created function users.protect_anonymous.';
		
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
		
		create trigger protect_anonymous
			before update
			on users.user
			for each row execute procedure users.protect_anonymous();
		return next 'Created the protect anonymous trigger.';
		
		revoke all on function 
			users.protect_anonymous(),
			users.add_user(
				sessid		text,
				username	text,
				passwd		text,
				useremail		text)
		from public;
		
		grant execute on function 
			users.add_user(
				sessid		text,
				username	text,
				passwd		text,
				useremail		text)
		to nodepg;
		
		grant usage on schema users to nodepg;
		
		return next 'Permissions set.';
	end;
$func$ language plpgsql;






/*
-- Create User table and initial data.
insert into users.user (id, active, name, password, email) values
	(uuid_nil(), true, 'anonymous', '', ''),
	(uuid_generate_v4(), true, 'admin', crypt('admin', gen_salt('bf')), '');

-- Create Session Table with triggers
create table users.session(
	sess_id		text		primary key,
	user_id		uuid,
	foreign key (sess_id) references web.session (sess_id) on delete cascade,
	foreign key (user_id) references users.user (id) on delete cascade
);

-- Create Group table with initial data
create table users.group (
	id			uuid		primary key,
	name		text		not null
);

create unique index groupnames on users.group (lower(name)); 

insert into users.group (id, name) values
	(uuid_generate_v4(), 'admin'),
	(uuid_generate_v4(), 'everyone'),
	(uuid_generate_v4(), 'authenticated');
	
-- Create the Group user linking table.
create table users.group_user_link(
	group_id		uuid,
	user_id			uuid,
	foreign key (group_id) references users.group (id),
	foreign key (user_id) references users.user (id),
	primary key(group_id, user_id)
);

insert into users.group_user_link (group_id, user_id) 
	select 
		users.group.id, 
		users.user.id 
	from 
		users.group, 
		users.user
	where
		users.user.name = 'admin';
	
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

create or replace function users.info(
	in session_id text, 
	in get_info_name text)
returns userinfo
as $$
	declare
		theusername			text;
		userdata			record;
	begin
		perform users.approval(session_id, 'users.info', get_info_name);
		select 
			users.user.name as username into userdata
			from 
				users.user
			where
				users.user.name = get_info_name;
		return userdata;
	end;
$$ language plpgsql security definer;

create or replace function users.info(
	in session_id text)
returns userinfo
as $$
	declare
		sessusername	text;
		userdata		record;
	begin
		select 
			users.user.name into sessusername 
		from
			users.user,
			users.session
		where
			users.user.id = users.session.user_id
			and users.session.sess_id = session_id;
		select * into userdata from users.info(session_id, sessusername);
		return userdata;
	end;
$$ language plpgsql security definer;

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

create or replace function users.add(
	session_id text,
	username text, 
	passwd text, 
	user_email text)
returns uuid
as $$
	declare
		new_uid			uuid;
		new_link			uuid;
		holder_uid		uuid;
	begin
		if length(passwd) > 4 then
			loop
				select uuid_generate_v4() into new_uid;
				select id into holder_uid from users.user where id = new_uid;
				exit when not found;
			end loop;
			insert into users.user (id, name, password, email) values
				(new_uid, username, crypt(passwd, gen_salt('bf')), user_email);
		else
			raise 'new row for relation "password" violates check constraint "user_password_check"' 
				using errcode = 'check_violation';
		end if;
		loop
			begin
				select uuid_generate_v4() into new_link;
				insert into users.unconfirmed (link, user_id) values
					(new_link, new_uid);
				exit;
			exception when unique_violation then
				-- do nothing
			end;
		end loop;
		insert into users.function_user_link (function_id, user_obj, user_id) values
			((select id from users.function where name = 'users.login'),
				new_uid, uuid_nil()),
			((select id from users.function where name = 'users.logout'),
				new_uid, new_uid);
		insert into users.function_group_link (function_id, user_obj, group_id) values
			((select id from users.function where name = 'users.info'),
				new_uid, 
				(select id from users.group where name = 'everyone'));
		return new_link;
	end;
$$ language plpgsql security definer;

create or replace function users.del(
	session_id text,
	username text)
returns void
as $$
	begin
		return;
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

create or replace function users.startup_users_tests()
returns setof text
as $$
	begin
		perform web.set_session_data('session1', '{}', now() + interval '1 day');
	end;
$$ language plpgsql;

create or replace function users.teardown_users_tests()
returns setof text
as $$
	begin
		perform web.destroy_session('session1');
	end;
$$ language plpgsql;

create or replace function users.test_for_user_schema()
returns setof text
as $$
	begin
		return next has_schema('userss', 'There should be a schema for users.');
	end;
$$ language plpgsql;



create or replace function users.test_for_user_table()
returns setof text
as $$
	begin
		return next has_table('users', 'user', 'There should be a users table.');
		
		return next has_column('users', 'user', 'id', 'Needs to have a unique user id.');
		return next col_type_is('users', 'user', 'id', 'uuid', 'User id needs to ba a UUID.');
		return next col_is_pk('users', 'user', 'id', 'The user id is the primary key');
		
		return next has_column('users', 'user', 'active', 'Need a column of user status.');
		return next col_type_is('users', 'user', 'active', 'boolean', 'Active user is boolean.');
		return next col_not_null('users', 'user', 'active', 'User active column cannot be null.');
		return next col_default_is('users', 'user', 'active', 'false', 'Active column should default to false');
		
		return next has_column('users', 'user', 'name', 'Need a column of user names.');
		return next col_type_is('users', 'user', 'name', 'text', 'User name needs to be text');
		return next col_not_null('users', 'user', 'name', 'User name column cannot be null.');
		
		return next has_column('users', 'user', 'password', 'Needs a password column');
		return next col_type_is('users', 'user', 'password', 'text', 'Password needs to have a text input.');
		return next col_not_null('users', 'user', 'password', 'User passwork cannot be null.');
		
		return next has_column('users', 'user', 'email', 'Needs an email column.');
		return next col_type_is('users', 'user', 'email', 'text', 'Email needs to have a text input.');
		return next col_not_null('users', 'user', 'email', 'User email column cannot be null.');
	end;
$$ language plpgsql;

create or replace function users.test_for_anonymous_user()
returns setof text
as $$
	begin
		prepare anonymous_user as select * from users.user where name = 'anonymous';
		prepare anonymous_results as values (uuid_nil(), true, 'anonymous', '', '', null, null);
		return next results_eq(
			'"anonymous_user"',
			'"anonymous_results"',
			'There should be an anonymous user with an all zeros id.'
		);
	end;
$$ language plpgsql;

create or replace function users.test_admin_user_exists()
returns setof text
as $$
	begin 
		prepare admins_exist as 
			select 
				count(*) > 0 as exists
			from 
				users.user,
				users.group,
				users.group_user_link
			where 
				users.user.id = users.group_user_link.user_id
				and users.group.id = users.group_user_link.group_id
				and users.group.name = 'admin';
		return next results_eq(
			'"admins_exist"',
			'values (true)',
			'The system should have at least one admin.');
	end;
$$ language plpgsql;

create or replace function users.test_unique_lowercase_user_name()
returns setof text
as $$
	begin 
		prepare add_anonymous as insert into users.user (id, name, password, email)
			values (uuid_generate_v4(), 'ANONYMOUS', 'password', '');
		return next throws_like(
			'"add_anonymous"',
			'%violates unique constraint%',
			'User names should be unique, and case insensitive');
	end;
$$ language plpgsql;

create or replace function users.test_session_table()
returns setof text
as $$
	begin
		return next has_table('users', 'session', 'There should be a session linking users to sessions.');
		
		return next has_column('users', 'session', 'sess_id', 'sessions needs to have a session id.');
		return next col_is_pk('users', 'session', 'sess_id', 'Session ids need to be the primary key.');
		return next fk_ok('users', 'session', 'sess_id', 'web', 'session', 'sess_id', 'Users session table is linked to web session.');
		
		return next has_column('users', 'session', 'user_id', 'Session needs a user column.');
		return next fk_ok('users', 'session', 'user_id', 'users', 'user', 'id', 'Users session needs to be linked to the user ids.');
	end;
$$ language plpgsql;

create or replace function users.test_session_create()
returns setof text
as $$
	begin 
		prepare anonymous_session_select as select sess_id, user_id from users.session where sess_id = 'session1';
		prepare anonymous_session_values as values ('session1', uuid_nil());
		return next results_eq(
			'"anonymous_session_select"',
			'"anonymous_session_values"',
			'New sessions should be assigned to the anonymous user.');
	end;
$$ language plpgsql;

create or replace function users.test_session_delete()
returns setof text
as $$
	begin
		prepare session_counter as select cast(count(*) as int) from users.session where sess_id = 'session1';
		perform web.destroy_session('session1');
		return next results_eq(
			'"session_counter"',
			'values (0)',
			'User sessions should delete when web session is destroyed.');
	end;
$$ language plpgsql;
*/