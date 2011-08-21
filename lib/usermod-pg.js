/*
 * 
 */
var pg = require('pg')
   ,pgConnStr = ''
   ,notificationCB = function () {};

function pgConnect (callback) {
	pg.connect(pgConnStr, function (err, client) {
		if (err) {
			console.log(err.message);
		}
		if (client) {
			callback(client);
		}
	});
}

exports.setConnectionString = function (connectStr) {
	pgConnStr = connectStr;
	pgConnect(function () {});
};

exports.info = function (req, res, callback) {
	pgConnect(function (client) {
		client.query(
				'select username from users.info($1)',
				[req.session.key,],
				function (err, result) {
					if (err) {
						console.log(err.message);
					}
					if (result) {
						res.render('users/info', result.rows[0]);
						if (typeof callback == 'function') {
							callback(null, {});
						}
					}
				});
	});
};

exports.login = function (req, res, callback) {
	if (req.body && req.body.username && req.body.password){
		pgConnect(function (client) {
			client.query(
					'select users.login($1, $2, $3)', 
					[req.session.key, req.body.username, req.body.password], 
					function (err, result) {
						if (err) {
							if (err.code == 'P0001') {
								res.render('401', {'error': err.message}, 401);
								if (typeof callback == 'function') {
									callback({'message': err.message}, null);
								}
							} else {
								console.log(err.message);
							}
						}
						if (result) {
							res.render('users/login');
							if (typeof callback == 'function') {
								callback(null,
										{'sessionID': req.session.key,
										'update': 'personalInfo'});
							}
						}
					});
		});
	} else {
		res.render('400', {'error': 'Needs user name and password'}, 400);
		if (typeof callback == 'function') {
			callback({'message': 'Needs user name and password'}, null);
		}
	}
};

exports.logout = function (req, res, callback) {
	pgConnect(function (client) {
		client.query(
				'select users.logout($1)', 
				[req.session.key,],
				function (err, result) {
					if (err) {
						if (err.code == 'P0001') {
							res.render('401', {'error': err.message}, 401);
							if (typeof callback == 'function') {
								callback({'message': err.message}, null);
							}
						} else {
							console.log(err.message);
						}
					}
					if (result) {
						res.redirect('home');
						if (typeof callback == 'function') {
							callback(null,
									{'sessionID': req.session.key,
									'update': 'personalInfo'});
						}
					}
				});
	});
};

exports.add = function (req, res, callback) {
	res.render('400', {'error': 'Needs new user data'}, 400);
	if (typeof callback == 'function') {
		callback({'message': 'Needs new user data'}, null);
	}
};

exports.setPassword = function (req, res) {
	res.render('400', {'error': 'Needs old and new password'}, 400);
};







/*
exports.setConnect = function (connectStr) {
	if (arguments.length == 0) {
		throw TypeError;
	}
	pgConnect = connectStr;
};

exports.setMail = function (smtp) {
	if (arguments.length == 0) {
		throw TypeError;
	}
	if (typeof smtp.send_mail != 'function') {
		throw TypeError;
	}
	this.smtp = smtp;
};

exports.setVerificationEmailRender = function (mailRender) {
	if (arguments.length == 0) {
		throw TypeError;
	}
	if (typeof mailRender != 'function') {
		throw TypeError;
	}
	this.mailRender = mailRender;
};

function dbConnect (callback) {
	pg.connect(pgConnect, function (err, client) {
		if (err) {
			console.log(JSON.stringify(err));
		}
		if (client) {
			callback(client);
		}
	});
};

exports.add = function (req, res) {
	var rtnView = 'users/newuser';
	var additionalValues = null;
	var smtp = this.smtp;
	var mailRender = this.mailRender;
	if (req.body && req.body.username && req.body.password1 && req.body.password2 &&
			(req.body.password1 == req.body.password2) && req.body.email) {
		dbConnect(function (client) {
			client.query('select users.add($1, $2, $3)', 
					[req.body.username, req.body.password1, req.body.email], 
					function (err, result) {
				if (err) {
					if (!(err.code == '23514' || err.code == '23505')) {
						console.log(JSON.stringify(err));
					}
					res.render(rtnView);
				}
				if (result) {
					rtnView = 'users/useradded';
					additionalValues = {'name': req.body.username};
					var mailMsg = { 
							'sender': 'noreply@' + req.header.host.replace(new RegExp('^www\.'), ''),
							'to': req.body.email,
							'subject': 'Thank You for Registering at ' + req.header.host,
							'body': mailRender(result.rows[0].add)
					};
					smtp.send_mail(mailMsg);
					res.render(rtnView, additionalValues);
				}
			});
		});
	} else {
		res.render(rtnView);
	}
};

exports.validate = function (req, res) {
	var template = 'users/novalidation';
	dbConnect(function (client) {
		client.query('select users.validate($1)', 
				[req.params.link,], 
				function (err, result) {
			if (err) {
				if (err.code != '22P02') {
					console.log(JSON.stringify(err));
				}
			}
			if (result) {
				if (result.rows[0].validate) {
					template = 'users/validation';
				}
			}
			res.render(template);
		});
	});
};

exports.login = function (req, res) {
	var gotolink = 'back';
	if (req.body && req.body.username && req.body.password) {
		dbConnect(function (client) {
			client.query('select users.login($1, $2, $3)',
					[req.session.key, req.body.username, req.body.password],
					function (err, result) {
				if (err) {
					console.log(JSON.stringify(err));
				} 
				if (result) {
					if (result.rows[0].login) {
						if (req.params) {
							if (req.params.logingoto) {
								gotolink = req.params.logingoto;
							}
						}
					}
				}
				res.redirect(gotolink);
			});
		});
	} else {
		res.redirect(gotolink);
	}
};

exports.logout = function (req, res) {
	dbConnect(function (client) {
		client.query('select users.logout($1)',
				[req.session.key,],
				function (err, result) {
			res.redirect('home');
		});
	});
};

exports.getUser = function (sess_id, callback) {
	dbConnect(function (client) {
		client.query('select users.get_user($1)', 
				[sess_id,], 
				function (err, result) {
			if (err) {
				console.log(JSON.stringify(err));
			}
			if (result) {
				callback(null, result.rows[0].get_user);
			}
		});
	});
};

exports.addGroup = function (req, res) {
	res.redirect('back');
};

exports.ownedGroups = function (sess_id, callback) {
	dbConnect(function (client) {
		client.query('select users.get_groups($1)',
				[sess_id,], 
				function (err, result) {
			if (err) {
				console.log(JSON.stringify(err));
			}
			if (result) {
				var holder = [];
				for(var i = 0, l = result.rows.length; i < l; i++) {
					holder.push(result.rows[i].get_groups);
				}
				callback(holder);
			}
		});
	});
};
*/