-- This installs the tables and functions into the database.

create schema users;

create table users.user(
	name		text		primary key
);

create table users.session(
	sess_id		text		primary key,
	name		text,
	foreign key (sess_id) references web.session (sess_id),
	foreign key (name) references users.user (name)
);