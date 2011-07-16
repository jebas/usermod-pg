-- This installs the tables and functions into the database.

create schema users;

create table users.user(
	name		text		primary key		check (length(name) > 4),
	password	text,
	email		text
);

create table users.session(
	sess_id		text		primary key,
	name		text,
	foreign key (sess_id) references web.session (sess_id) on delete cascade,
	foreign key (name) references users.user (name)
);

insert into users.user (name, password, email) values ('anonymous', '', '');

create or replace function users.init_session() 
returns trigger 
as $$
	begin
		insert into users.session (sess_id, name) values (NEW.sess_id, 'anonymous');
		return null;
	end;
$$ language plpgsql security definer;

create trigger init_session 
	after insert
	on web.session
	for each row execute procedure users.init_session();
	
create or replace function users.add(username text, password text, email text)
returns void
as $$
	begin
		insert into users.user (name, password, email) 
			values (username, md5(password), email);
		return;
	end;
$$ language plpgsql security definer;