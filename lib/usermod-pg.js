/*
 * 
 */

var UserMod = module.exports = function (clientFN) {
	if (typeof clientFN == 'function') {
		this.pgConnect = clientFN;
	} else {
		throw TypeError;
	}
};

UserMod.prototype.getUser = function (sessionID, callback) {
	this.pgConnect(function (client) {
		client.query('select users.get_user($1)', [sessionID],
				function (err, result) {
			if (err) {
				callback(err, null);
			}
			if (result) {
				callback(null, result.rows[0].get_user);
			}
		});
	});
};

UserMod.prototype.login = function (sessionid, username, password, callback) {
	this.pgConnect(function (client) {
		client.query('select users.login($1, $2, $3)', [sessionid, username, password], 
				function (err, result) {
			if (err) {
				callback('Invalid User Name or Password.', null);
			} else {
				callback(null, true);
			}
		});
	});
};

UserMod.prototype.logout = function (sessionid, callback) {
	this.pgConnect(function (client) {
		client.query('select users.logout($1)', [sessionid],
				function (err, result) {
			callback(null, true);
		});
	});
};

UserMod.prototype.addUser = function (name, password, email, callback) {
	this.pgConnect(function (client) {
		client.query('select * from users.add_user($1, $2, $3)', 
				[name, password, email], function (err, result) {
			if (err) {
				callback(err, null);
			} else {
				var holder = {
						'email':result.rows[0].emailaddr,
						'link':result.rows[0].validlink
				};
				callback(null, holder);
			}
		});
	});
};

UserMod.prototype.validateUser = function (link, callback) {
	this.pgConnect(function (client) {
		client.query('select * from users.validate_user($1)', [link],
				function (err, result) {
			if(err) {
				callback(err, null);
			} else {
				callback(null, result.rows[0].username);
			}
		});
	});
};

UserMod.prototype.changeName = function (sessionid, name, password, callback) {
	this.pgConnect(function (client) {
		client.query('select * from users.change_name($1, $2, $3)',
				[sessionid, name, password], function (err, result) {
			if(err) {
				callback(err, null);
			} else {
				callback(null, true);
			}
		});
	});
};

UserMod.prototype.changePassword = function (sessionid, newPassword, oldPassword, callback) {
	this.pgConnect(function (client) {
		client.query('select * from users.change_password($1, $2, $3)', 
				[sessionid, newPassword, oldPassword], function (err, result) {
			if (err) {
				callback(err, null);
			} else {
				callback(null, true);
			}
		});
	});
};

UserMod.prototype.changeEmail = function (sessionid, email, password, callback) {
	this.pgConnect(function (client) {
		client.query('select * from users.change_email($1, $2, $3)', 
				[sessionid, email, password], function (err, result) {
			if (err) {
				callback(err, null);
			} else {
				callback(null, {
					'email': result.rows[0].emailaddr,
					'link': result.rows[0].validlink
				});
			}
		});
	});
};

UserMod.prototype.validateEmail = function (link, callback) {
	this.pgConnect(function (client) {
		client.query('select * from users.validate_email($1)', [link],
				function (err, result) {
			if (err) {
				callback(err, null);
			} else {
				callback(null, true);
			}
		});
	});
};

UserMod.prototype.retrieveUserRequest = function (email, callback) {
	this.pgConnect(function (client) {
		client.query('select * from users.retrieve_user_request($1)',
				[email], function (err, result) {
			if (err) {
				callback(err, null);
			} else {
				callback(null, {
					'email':result.rows[0].useremail,
					'link':result.rows[0].userlink});
			}
		});
	});
};

UserMod.prototype.retrieveUser = function (link, callback) {
	this.pgConnect(function (client) {
		client.query('select * from users.retrieve_user($1)', 
				[link], function (err, result) {
			if (err) {
				callback(err, null);
			} else {
				callback(null, {
					'username':result.rows[0].username,
					'password':result.rows[0].userpassword});
			}
		});
	});
};
