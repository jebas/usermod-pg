# User Module for Node.js Connect using PostgreSQL

This module creates, controls, and tracks users in a Connect
session.  It also links users to a specific session id without
releasing the information outside of the database.  

## Feature List

<table>
	<tr>
		<th>Features</th>
		<th>Database</th>
		<th>Node</th>
		<th>Client</th>
	</tr>
	<tr>
		<td>Add User</td>
		<td>done</td>
	</tr>
	<tr>
		<td>Validate User</td>
	</tr>
	<tr>
		<td>Delete User</td>
	</tr>
	<tr>
		<td>Login</td>
	</tr>
	<tr>
		<td>Logout</td>
	</tr>
	<tr>
		<td>Change User Name</td>
	</tr>
	<tr>
		<td>Change User Password</td>
	</tr>
	<tr> 
		<td>Change User Email</td>
	</tr>
	<tr>
		<td>User name and password retrieval</td>
	</tr>
</table>

This module does not include features like avatars, descriptions, 
biographies, ect.  Those features should be added in a profile module.  

## Requirements
###Production
* Connect-PG
* Express
* PostgreSQL
* PostgreSQL Contrib (specifically uuid_ossp and pgcrypto)
* pgTAP

###Development
* Jasmine-node
