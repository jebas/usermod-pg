-- This installs the tables and functions into the database.

-- Create Schema
create schema users;

-- Create User table and initial data.
create table users.user(
	id			uuid		primary key,
	name		text		not null,
	password	text		not null
);

create unique index username on users.user (lower(name)); 

insert into users.user (id, name, password) values
	(uuid_nil(), 'anonymous', ''),
	(uuid_generate_v4(), 'admin', crypt('admin', gen_salt('bf')));

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
	foreign key (function_id) references users.function (id),
	foreign key (user_obj) references users.user (id),
	foreign key (user_id) references users.user (id),
	primary key (function_id, user_obj, user_id)
);

insert into users.function_user_link (function_id, user_obj, user_id)
	select id, uuid_nil(), uuid_nil() from users.function where name = 'users.login';

create table users.function_group_link(
	function_id			uuid,
	user_obj			uuid,
	group_id			uuid,
	foreign key (function_id) references users.function (id),
	foreign key (user_obj) references users.user (id),
	foreign key (group_id) references users.group (id),
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
		theuserid		uuid;
	begin
		select
			users.session.user_id into theuserid
		from
			users.session,
			users.user,
			users.function,
			users.group_user_link,
			users.function_user_link,
			users.function_group_link
		where
			(users.user.name = user_name
				and users.user.id = users.function_user_link.user_obj
				and users.function.name = function_name
				and users.function.id = users.function_user_link.function_id
				and users.session.sess_id = session_id
				and users.session.user_id = users.function_user_link.user_id)
			or (users.user.name = user_name
				and users.user.id = users.function_group_link.user_obj
				and users.function.name = function_name
				and users.function.id = users.function_group_link.function_id
				and users.function_group_link.group_id = users.group_user_link.group_id
				and users.group_user_link.user_id = users.session.user_id
				and users.session.sess_id = session_id);
		if not found then
			raise 'Not Authorized';
		end if;
	end;
$$ language plpgsql security definer;

create or replace function users.info(
	in session_id text, 
	out username text,
	out nameduser text)
returns setof record
as $$
	begin
		perform users.approval(session_id, 'users.info', 'admin');
		return query 
			select 
				users.user.name,
				users.user.name
				from 
					users.user,
					users.session
				where
					users.user.id = users.session.user_id
					and users.session.sess_id = session_id;
		return;
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
		perform users.approval(session_id, 'users.login', 'anonymous');
		select
			id into newuserid
			from
				users.user
			where
				name = username
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

/*
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

-- Create User Table with inital data.
create table users.user(
	id			uuid		primary key,
	active		boolean		default false,
	name		text		check (length(name) > 4),
	password	text,
	email		text
);


-- Create the function list table.  
create table users.function(
	id			uuid		primary key,
	code		text		not null,
	args		int			not null
);	
	
create unique index code on users.function (lower(code)); 

	
	

	
	
	





	
	
	
	
create table users.unconfirmed(
	link		uuid		primary key,
	user_id		uuid,
	expire		timestamp with time zone	default now() + interval '7 days',
	foreign key (user_id) references users.user (id) on delete cascade
);



	
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
	
create or replace function users.add(username text, password text, email text)
returns uuid
as $$
	declare
		usersid	uuid;
		thelink uuid;
	begin
		select uuid_generate_v4() into usersid;
		insert into users.user (id, name, password, email) 
			values (usersid, username, md5(password), email);
		select uuid_generate_v4() into thelink;
		insert into users.unconfirmed (link, user_id)
			values (thelink, usersid);
		return thelink;
	end;
$$ language plpgsql security definer;

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