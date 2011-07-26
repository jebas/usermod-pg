-- This installs the tables and functions into the database.

create schema users;

create table users.user(
	id			uuid		primary key,
	active		boolean		default false,
	name		text		check (length(name) > 4),
	password	text,
	email		text
);

create unique index username on users.user (lower(name)); 

insert into users.user (id, active, name, password, email) 
	values (uuid_nil(), true, 'anonymous', '', '');

create table users.session(
	sess_id		text		primary key,
	user_id		uuid,
	foreign key (sess_id) references web.session (sess_id) on delete cascade,
	foreign key (user_id) references users.user (id)
);

create table users.unconfirmed(
	link		uuid		primary key,
	user_id		uuid,
	expire		timestamp with time zone	default now() + interval '7 days',
	foreign key (user_id) references users.user (id) on delete cascade
);

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

create or replace function users.login(thesession text, theusername text, thepassword text)
returns boolean
as $$
	declare
		the_user_id		uuid;
	begin
		select id into the_user_id 
			from users.user
			where name = theusername and
				password = md5(thepassword);
		if found then
			update users.session
				set user_id = the_user_id
				where sess_id = thesession;
			return true;
		else
			return false;
		end if;
	end;
$$ language plpgsql security definer;