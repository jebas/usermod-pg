-- This installs the tables and functions into the database.

create schema users;

create table users.user(
	active		boolean		default false,
	name		text		primary key		check (length(name) > 4),
	password	text,
	email		text
);

insert into users.user (active, name, password, email) values (true, 'anonymous', '', '');

create table users.session(
	sess_id		text		primary key,
	name		text,
	foreign key (sess_id) references web.session (sess_id) on delete cascade,
	foreign key (name) references users.user (name)
);

create table users.unconfirmed(
	link		uuid		primary key,
	name		text,
	foreign key (name) references users.user (name) on delete cascade
);

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
returns uuid
as $$
	declare
		thelink uuid;
	begin
		insert into users.user (name, password, email) 
			values (username, md5(password), email);
		loop
			begin
				select uuid_generate_v4() into thelink;
				insert into users.unconfirmed (link, name)
					values (thelink, username);
				return thelink;
			exception
				when unique_violation then
					-- loop and try again.
			end;
		end loop;
	end;
$$ language plpgsql security definer;