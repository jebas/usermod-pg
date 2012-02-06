/**
 * User Module JavaScript Test file.
 * 
 * Create a connection.js file in the spec directory.
 * In that file place the connection functions for 
 * the database super user and nodepg.  This file is 
 * ignored by git so it not part of the repository.
 *   
 * It should look similar to the following: 
 * 
 * var pg = require('pg');
 *
 * var connect = module.exports = function () {};
 * 
 * connect.prototype.root = function (callback) {
 * 	pg.connect('tcp://postgres:secret@localhost/pgstore',
 * 		function (err, client) {
 * 			if (err) {
 * 				console.log(JSON.stringify(err));
 * 			}
 * 			if (client) {
 * 				callback(client);
 * 			}
 * 		}
 * 	);
 * };
 * 
 * connect.prototype.nodepg= function (callback) {
 * 	pg.connect('tcp://nodepg:password@localhost/pgstore',
 * 		function (err, client) {
 * 			if (err) {
 * 				console.log(JSON.stringify(err));
 * 			}
 * 			if (client) {
 * 				callback(client);
 * 			}
 * 		}
 * 	);
 * };
 */

var UserMod = require('../');
var connection = require('./connection');

var connect = new connection();

describe('usermod', function () {
	beforeEach(function () {
		var sessionid;
		var newUser;
		var inactiveUser;
		var loggedOutUser;
		var loggedInUser;
		this.users = new UserMod(connect.nodepg);
		connect.root(function (client) {
			client.query('select sess_id from create_test_session()',
					function (err, result) {
				if (err) {
					console.log(JSON.stringify(err));
				}
				sessionid = result.rows[0].sess_id;
			});
			client.query('select * from get_new_test_user()', 
					function (err, result) {
				newUser = {
					'name': result.rows[0].newusername,
					'password': result.rows[0].newpassword,
					'email': result.rows[0].newemail
				};
			});
			client.query('select * from get_inactive_test_user()', 
					function (err, result) {
				inactiveUser = {
					'name': result.rows[0].inactiveusername,
					'password': result.rows[0].inactivepassword,
					'email': result.rows[0].inactiveemail,
					'link': result.rows[0].validationlink
				};
			});
			client.query('select * from get_logged_out_test_user()', 
					function (err, result) {
				if (err) {
					console.log(JSON.stringify(err));
				}
				loggedOutUser = {
					'name': result.rows[0].loggedoutusername,
					'password': result.rows[0].loggedoutpassword,
					'email': result.rows[0].loggedoutemail
				};
			});
			client.query('select * from get_logged_in_test_user()', 
					function (err, result) {
				if (err) {
					console.log(JSON.stringify(err));
				}
				loggedInUser = {
					'name': result.rows[0].loggedinusername,
					'password': result.rows[0].loggedinpassword,
					'email': result.rows[0].loggedinemail,
					'sessionid': result.rows[0].loggedinsession
				};
			});
		});
		waitsFor(function () {
			return newUser && sessionid && inactiveUser && 
				loggedOutUser && loggedInUser;
			}, 'session setup', 10000);
		runs(function () {
			this.sessionid = sessionid;
			this.newUser = newUser;
			this.inactiveUser = inactiveUser;
			this.loggedOutUser = loggedOutUser;
			this.loggedInUser = loggedInUser;
		});
	});
	
	afterEach(function () {
		var sessionid = this.sessionid;
		var newUser = this.newUser;
		var inactiveUser = this.inactiveUser;
		var loggedOutUser = this.loggedOutUser;
		var loggedInUser = this.loggedInUser;
		connect.root(function (client) {
			client.query('delete from web.session ' +
					'where sess_id = $1', [sessionid]);
			client.query('delete from users.user ' +
					'where name = $1', [newUser.name]);
			client.query('delete from users.user ' +
					'where name = $1', [inactiveUser.name]);
			client.query('delete from users.user ' +
					'where name = $1', [loggedOutUser.name]);
			client.query('delete from users.user ' +
					'where name = $1', [loggedInUser.name]);
		});
	});
	
	describe('constructor', function () {
		it('should have a constructor function', function () {
			expect(typeof UserMod).toEqual('function');
		});
		
		it('should throw an exception without a client function', function () {
			expect(function () {
				var users = new UserMod();
			}).toThrow(TypeError);
		});
		
		it('should throw an exception when client input is not a function', function () {
			expect(function () {
				var users = new UserMod('text');
			}).toThrow(TypeError);
		});
	});
	
	describe('get user', function () {
		it('should have a get user function', function () {
			expect(typeof this.users.getUser).toEqual('function');
		});
		
		it('should return anonymous when not logged in', function () {
			var sessionid = this.sessionid;
			var username;
			this.users.getUser(sessionid, function (err, result) {
				username = result;
			});
			waitsFor(function () {return username;}, 
					'getUser to return', 10000);
			runs(function () {
				expect(username).toEqual('anonymous');
			});
		});
		
		it('should return the user name for used sessions', function () {
			var username;
			this.users.getUser(this.loggedInUser.sessionid, function (err, result) {
				username = result;
			});
			waitsFor(function () {return username;}, 
					'getUser', 10000);
			runs(function () {
				expect(username).toEqual(this.loggedInUser.name);
			});
		});
	});
	
	describe('login', function () {
		it('should have a login function', function () {
			expect(typeof this.users.login).toEqual('function');
		});
		
		it('should allow the user to log in', function () {
			var loggedIn;
			var theError;
			this.users.login(this.sessionid, this.loggedOutUser.name,
					this.loggedOutUser.password, function (err, result) {
				loggedIn = result;
				theError = err;
			});
			waitsFor(function () {return loggedIn;}, 
					'login', 10000);
			runs(function () {
				expect(theError).toBeNull();
				expect(loggedIn).toBeTruthy();
				var username;
				this.users.getUser(this.sessionid, function (err, result) {
					username = result;
				});
				waitsFor(function () {return username;}, 
						'getUser', 10000);
				runs(function () {
					expect(username).toEqual(this.loggedOutUser.name);
				});
			});
		});
		
		it('should error on failed login', function () {
			var loggedIn;
			var theError;
			this.users.login(this.sessionid, this.loggedOutUser.name,
					'wrong', function (err, result) {
				loggedIn = result;
				theError = err;
			});
			waitsFor(function () {return theError;}, 
					'login', 10000);
			runs(function () {
				expect(loggedIn).toBeNull();
				expect(theError).toEqual('Invalid User Name or Password.');
				var username;
				this.users.getUser(this.sessionid, function (err, result) {
					username = result;
				});
				waitsFor(function () {return username;}, 
						'getUser', 10000);
				runs(function () {
					expect(username).toEqual('anonymous');
				});
			});
		});
		
		it('should not allow inactive users to log in', function () {
			var loggedIn;
			var theError;
			this.users.login(this.sessionid, this.inactiveUser.name,
					this.inactiveUser.password, function (err, result) {
				loggedIn = result;
				theError = err;
			});
			waitsFor(function () {return theError;}, 
					'login', 10000);
			runs(function () {
				expect(loggedIn).toBeNull();
				expect(theError).toEqual('Invalid User Name or Password.');
				var username;
				this.users.getUser(this.sessionid, function (err, result) {
					username = result;
				});
				waitsFor(function () {return username;}, 
						'getUser', 10000);
				runs(function () {
					expect(username).toEqual('anonymous');
				});
			});
		});
	});
	
	describe('logout', function () {
		it('should have a logout function', function () {
			expect(typeof this.users.logout).toEqual('function');
		});
		
		it('should set the session back to anonymous', function () {
			var loggedout;
			var theError;
			this.users.logout(this.loggedInUser.sessionid, function (err, result) {
				theError = err;
				loggedout = result;
			});
			waitsFor(function () {return loggedout;}, 'logout', 10000);
			runs(function () {
				expect(theError).toBeNull();
				expect(loggedout).toBeTruthy();
				var username;
				this.users.getUser(this.loggedInUser.sessionid, function (err, result) {
					username = result;
				});
				waitsFor(function () {return username;}, 'getUser', 10000);
				runs(function () {
					expect(username).toEqual('anonymous');
				});
			});
		});
	});
	
	describe('adding a user', function () {
		it('should have an add user function', function () {
			expect(typeof this.users.addUser).toEqual('function');
		});

		it('should have a validate new user function', function () {
			expect(typeof this.users.validateUser).toEqual('function');
		});
		
		it('should create a new user', function () {
			var username;
			var useremail;
			var validlink;
			this.users.addUser(this.newUser.name, this.newUser.password,
					this.newUser.email, function (err, result) {
				useremail = result.email;
				validlink = result.link;
			});
			waitsFor(function () {return useremail && validlink;}, 'addUser',
					10000);
			runs(function () {
				expect(useremail).toEqual(this.newUser.email);
				this.users.validateUser(validlink, function (err, result) {
					username = result;
				});
				waitsFor(function () {return username;}, 
						'validateUser', 10000);
				runs(function () {
					expect(username).toEqual(this.newUser.name);
					var loggedin;
					this.users.login(this.sessionid, this.newUser.name, 
							this.newUser.password, function (err, result) {
						loggedin = result;
					});
					waitsFor(function () {return loggedin;}, 'login',
							10000);
					runs(function () {
						expect(loggedin).toBeTruthy();
					});
				});
			});
		});
		
		it('should return an error when it fails to add user', function () {
			var theResult;
			var error;  
			this.users.addUser(this.newUser.name, 'four',
					this.newUser.email, function (err, result) {
				theResult = result;
				error = err;
			});
			waitsFor(function () {return error;}, 'addUser', 10000);
			runs(function () {
				expect(theResult).toBeNull();
				expect(typeof error).toEqual('object');
			});
		});
		
		it('should return an error for validating non-uuid links', function () {
			var theError;
			this.users.validateUser('fred', function (err, result) {
				theError = err;
			});
			waitsFor(function () {return theError;}, 'validateUser', 10000);
			runs(function () {
				expect(typeof theError).toEqual('object');
			});
		});
	});
	
	describe('change user name', function () {
		it('should have a change user name function', function () {
			expect(typeof this.users.changeName).toEqual('function');
		});
		
		it('should change the name of the user', function () {
			var nameChanged;
			this.users.changeName(this.loggedInUser.sessionid, this.newUser.name,
					this.loggedInUser.password, function (err, result) {
				nameChanged = result;
			});
			waitsFor(function () {return nameChanged;}, 'changeName', 10000);
			runs(function () {
				var username;
				this.users.getUser(this.loggedInUser.sessionid, function (err, result) {
					username = result;
				});
				waitsFor(function () {return username;}, 'getUser', 10000);
				runs(function () {
					expect(username).toEqual(this.newUser.name);
				});
			});
		});
		
		it('should return an error for failures', function () {
			var nameChanged;
			var theError;
			this.users.changeName(this.loggedInUser.sessionid, this.newUser.name,
					'wrong', function (err, result) {
				theError = err;
				nameChanged = result;
			});
			waitsFor(function () {return theError;}, 'changeName', 10000);
			runs(function () {
				expect(typeof theError).toEqual('object');
			});
		});
	});
	
	describe('change password', function () {
		it('should have a change user password function', function () {
			expect(typeof this.users.changePassword).toEqual('function');
		});
		
		it('should allow the user to set a new password', function () {
			var passwordChanged;
			this.users.changePassword(this.loggedInUser.sessionid, 'password',
					this.loggedInUser.password, function (err, result) {
				passwordChanged = true;
			});
			waitsFor(function () {return passwordChanged;}, 'changePassword', 10000);
			runs(function () {
				var loggedOut;
				this.users.logout(this.loggedInUser.sessionid, function () {
					loggedOut = true;
				});
				waitsFor(function () {return loggedOut;}, 'logout', 10000);
				runs(function() {
					var loggedIn;
					var theError;
					this.users.login(this.sessionid, this.loggedInUser.name, 'password',
							function (err, result) {
						loggedIn = true;
						theError = err;
					});
					waitsFor(function () {return loggedIn;}, 'login', 10000);
					runs(function () {
						expect(theError).toBeNull();
					});
				});
			});
		});
		
		it('should return an err for failed password change', function () {
			var theError;
			var passwordChanged;
			this.users.changePassword(this.loggedInUser.sessionid, 'password',
					'password', function (err, result) {
				theError = err;
				passwordChanged = true;
			});
			waitsFor(function () {return passwordChanged;}, 'passwordChange', 10000);
			runs(function () {
				expect(theError).toBeTruthy();
			});
		});
	});
	
	describe('retrieve user', function () {
		it('should have a retrieve user name and password request function', function () {
			expect(typeof this.users.retrieveUserRequest).toEqual('function');
		});

		it('should have a retrieve user name and password function ', function () {
			expect(typeof this.users.retrieveUser).toEqual('function');
		});
		
		it('should give the user a new password', function () {
			var email;
			var link;
			this.users.retrieveUserRequest(this.loggedOutUser.email, 
					function (err, result) {
				email = result.email;
				link = result.link;
			});
			waitsFor(function() {return email && link;}, 'retrieveUserRequest', 10000);
			runs(function () {
				expect(email).toEqual(this.loggedOutUser.email);
				var username;
				var password;
				this.users.retrieveUser(link, function (err, result) {
					username = result.username;
					password = result.password;
				});
				waitsFor(function () {return username && password;}, 'retrieveUser', 10000);
				runs(function () {
					expect(username).toEqual(this.loggedOutUser.name);
					var loggedIn;
					this.users.login(this.sessionid, this.loggedOutUser.name, password,
							function (err, result) {
						loggedIn = result;
					});
					waitsFor(function () {return loggedIn;}, 'login', 10000);
					runs(function () {
						expect(loggedIn).toBeTruthy();
					});
				});
			});
		});
		
		it('should send an error if the email is invalid upon request', function () {
			var theError;
			this.users.retrieveUserRequest(this.newUser.email, function (err, result) {
				theError = err;
			});
			waitsFor(function () {return theError;}, 'retrieveUserRequest', 10000);
			runs(function () {
				expect(theError).toBeTruthy();
			});
		});
		
		it('should send an error if the link is not a uuid', function () {
			var theError;
			this.users.retrieveUser('fred', function (err, result) {
				theError = err;
			});
			waitsFor(function () {return theError;}, 'retrieveUser', 10000);
			runs(function () {
				expect(theError).toBeTruthy();
			});
		});
	});

	describe('change user email', function () {
		it('should have a change user email function', function () {
			expect(typeof this.users.changeEmail).toEqual('function');
		});

		it('should have a validate new user email', function () {
			expect(typeof this.users.validateEmail).toEqual('function');
		});
		
		it('should allow the user to change email addresses', function () {
			var email;
			var link;
			this.users.changeEmail(this.loggedInUser.sessionid, this.newUser.email,
					this.loggedInUser.password, function (err, result) {
				email = result.email;
				link = result.link;
			});
			waitsFor(function () {return email && link;}, 'changeEmail', 10000);
			runs(function () {
				expect(email).toEqual(this.newUser.email);
				var validated;
				this.users.validateEmail(link, function (err, result) {
					validated = true;
				});
				waitsFor(function () {return validated;}, 'validateEmail', 10000);
				runs(function () {
					var username = this.loggedInUser.name;
					var email;
					connect.root(function (client) {
						client.query('select email from users.user ' +
								'where users.user.name = $1', [username],
								function (err, result) {
							email = result.rows[0].email;
						});
					});
					waitsFor(function () {return email;}, 'email query', 10000);
					runs(function () {
						expect(email).toEqual(this.newUser.email);
					});
				});
			});
		});
		
		it('should produce an error if change email fails', function () {
			var theError;
			this.users.changeEmail(this.loggedInUser.sessionid, this.newUser.email,
					'wrong', function (err, result) {
				theError = err;
			});
			waitsFor(function () {return theError;}, 'change email', 10000);
			runs(function () {
				expect(theError).toBeTruthy();
			});
		});
		
		it('should produce an error if email validation link is not a uuid', function () {
			var theError;
			this.users.validateEmail('fred', function (err, result) {
				theError = err;
			});
			waitsFor(function () {return theError;}, 'validateEmail', 10000);
			runs(function () {
				expect(theError).toBeTruthy();
			});
		});
	});
});







/*
var users = require('../');
var connectStr = "tcp://thetester:password@localhost/pgstore";
var pg = require('pg');
var PGStore = require('connect-pg');
var storeOptions = {pgConnect: connectStr};
var pgStore = new PGStore(storeOptions);

describe('user', function () {
	beforeEach(function () {
		this.req = {
				'session': {
					'key': 'session1'
				},
				'body': {
					'username': 'admin',
					'password': 'admin'
				}
		};
		this.res = {
				'render': jasmine.createSpy(),
				'redirect': jasmine.createSpy()
		};
		var callback = jasmine.createSpy();
		var callCount = callback.callCount;
		pgStore.set('session1', {}, callback);
		waitsFor(function () {
			return callCount != callback.callCount;
		}, 'session set callback', 10000);
		runs(function () {});
	});
	
	afterEach(function () {
		var callback = jasmine.createSpy();
		var callCount = callback.callCount;
		pgStore.clear(callback);
		waitsFor(function () {
			return callCount != callback.callCount;
		}, 'session set callback', 10000);
		runs(function () {});
	});
	
	describe('setup', function () {
		it('should have a function to set the pg connection string', function () {
			expect(typeof users.setConnectionString).toEqual('function');
		});
		
		it('should send a message to the console log if connection fails', function () {
			spyOn(console, 'log');
			var callCount = console.log.callCount;
			users.setConnectionString('badConnectionString');
			waitsFor(function () {
				return callCount != console.log.callCount;
			}, 'console log entry', 10000);
			runs(function () {
				expect(console.log).toHaveBeenCalled();
			});
		});
	});
	
	describe('info', function () {
		it('should have a user function', function () {
			expect(typeof users.info).toEqual('function');
		});
		
		it('should report database connection problems to the console log', function () {
		});

		it('should report client problems to the console log', function () {
		});
		
		it('should return anonymous when no one is logged in', function () {
			users.setConnectionString(connectStr);
			var callCount = this.res.render.callCount;
			users.info(this.req, this.res);
			waitsFor(function () {
				return callCount != this.res.render.callCount;
			}, 'response from userid', 10000);
			runs(function () {
				expect(this.res.render).toHaveBeenCalledWith('users/info', 
						{'username': 'anonymous'});
			});
		});
		
		it('should return the user if someone is logged in', function () {
			var callCount = this.res.render.callCount;
			users.login(this.req, this.res);
			waitsFor(function () {
				return callCount != this.res.render.callCount;
			}, 'response from userid', 10000);
			runs(function () {
				this.res = {'render': jasmine.createSpy()};
				callCount = this.res.render.callCount;
				users.info(this.req, this.res);
				waitsFor(function () {
					return callCount != this.res.render.callCount;
				}, 'response from userid', 10000);
				runs(function () {
					expect(this.res.render).toHaveBeenCalledWith('users/info', 
							{'username': 'admin'});
				});
			});
		});
		
		it('should accept a callback function', function () {
			var callback = jasmine.createSpy();
			var callCount = callback.callCount;
			users.info(this.req, this.res, callback);
			waitsFor(function () {
				return callCount != callback.callCount;
			}, 'info callback', 10000);
			runs(function () {
				expect(callback).toHaveBeenCalledWith(null, {});
			});
		});
	});
	
	describe('login', function () {
		it('should be a function', function () {
			expect(typeof users.login).toEqual('function');
		});
		
		it('should report database connection problems to the console log', function () {
		});

		it('should report client problems to the console log', function () {
		});
		
		it('should fail if nothing is sent', function () {
			delete this.req.body;
			var callCount = this.res.render.callCount;
			users.login(this.req, this.res);
			waitsFor(function () {
				return callCount != this.res.render.callCount;
			}, 'response from userid', 10000);
			runs(function () {
				expect(this.res.render).toHaveBeenCalledWith('400', 
						{'error': 'Needs user name and password'}, 400);
			});
		});
		
		it('should send the error in the callback with a malformed login', function () {
			delete this.req.body;
			var callback = jasmine.createSpy();
			var callCount = callback.callCount;
			users.login(this.req, this.res, callback);
			waitsFor(function () {
				return callCount != callback.callCount;
			}, 'response from userid', 10000);
			runs(function () {
				expect(callback).toHaveBeenCalledWith(
						{'message': 'Needs user name and password'}, null);
			});
		});
		
		it('should fail if a bad username or password is sent', function () {
			this.req.body.password = 'wrong';
			var callCount = this.res.render.callCount;
			users.login(this.req, this.res);
			waitsFor(function () {
				return callCount != this.res.render.callCount;
			}, 'response from userid', 10000);
			runs(function () {
				expect(this.res.render).toHaveBeenCalledWith('401', 
						{'error': 'Invalid username or password'}, 401);
			});
		});
		
		it('should have callback return the invalid password error', function () {
			this.req.body.password = 'wrong';
			var callback = jasmine.createSpy();
			var callCount = callback.callCount;
			users.login(this.req, this.res, callback);
			waitsFor(function () {
				return callCount != callback.callCount;
			}, 'response from userid', 10000);
			runs(function () {
				expect(callback).toHaveBeenCalledWith(
						{'message': 'Invalid username or password'}, null);
			});
		});
		
		it('should pass if user name and password are correct', function () {
			var callCount = this.res.render.callCount;
			users.login(this.req, this.res);
			waitsFor(function () {
				return callCount != this.res.render.callCount;
			}, 'response from userid', 10000);
			runs(function () {
				expect(this.res.render).toHaveBeenCalledWith('users/login');
			});
		});
		
		it('should call callback is login is successful', function () {
			var callback = jasmine.createSpy();
			var callCount = callback.callCount;
			users.login(this.req, this.res, callback);
			waitsFor(function () {
				return callCount != callback.callCount;
			}, 'notification callback', 10000);
			runs(function () {
				expect(callback).toHaveBeenCalledWith(null,
						{'sessionID': 'session1',
						'update': 'personalInfo'});
			});
		});
		
		it('should return access denied if already logged in', function () {
			var callCount = this.res.render.callCount;
			users.login(this.req, this.res);
			waitsFor(function () {
				return callCount != this.res.render.callCount;
			}, 'response from userid', 10000);
			runs(function () {
				this.res.render = jasmine.createSpy();
				callCount = this.res.render.callCount;
				users.login(this.req, this.res);
				waitsFor(function () {
					return callCount != this.res.render.callCount;
				}, 'second response', 10000);
				runs(function () {
					expect(this.res.render).toHaveBeenCalledWith('401', 
							{'error': 'Not Authorized'}, 401);
				});
			});
		});
	});
	
	describe('logout', function () {
		it('should be a function', function () {
			expect(typeof users.logout).toEqual('function');
		});
		
		it('should report database connection problems to the console log', function () {
		});

		it('should report client problems to the console log', function () {
		});
		
		it('should return a redirection to the home page', function () {
			req = this.req;
			res = this.res;
			var callCount = res.render.callCount;
			users.login(req, res);
			waitsFor(function () {
				return callCount != res.render.callCount;
			}, 'response from userid', 10000);
			runs(function () {
				callCount = res.redirect.callCount;
				users.logout(req, res);
				waitsFor(function () {
					return callCount != res.redirect.callCount;
				}, 'logout redirect', 10000);
				runs(function () {
					expect(res.redirect).toHaveBeenCalledWith('home');
				});
			});
		});
		
		it('should set the user back to anonymous', function () {
			req = this.req;
			res = this.res;
			var callCount = res.render.callCount;
			users.login(req, res);
			waitsFor(function () {
				return callCount != res.render.callCount;
			}, 'response from userid', 10000);
			runs(function () {
				callCount = res.redirect.callCount;
				users.logout(req, res);
				waitsFor(function () {
					return callCount != res.redirect.callCount;
				}, 'logout redirect', 10000);
				runs(function () {
					res.render = jasmine.createSpy();
					callCount = res.render.callCount;
					users.info(req, res);
					waitsFor(function () {
						return callCount != res.render.callCount;
					}, 'response from userid', 10000);
					runs(function () {
						expect(res.render.mostRecentCall.args[1].username).toEqual('anonymous');
					});
				});
			});
		});
		
		it('should call notification on logout', function () {
			req = this.req;
			res = this.res;
			var callCount = res.render.callCount;
			users.login(req, res);
			waitsFor(function () {
				return callCount != res.render.callCount;
			}, 'response from userid', 10000);
			runs(function () {
				var callback = jasmine.createSpy();
				callCount = callback.callCount;
				users.logout(req, res, callback);
				waitsFor(function () {
					return callCount != callback.callCount;
				}, 'logout redirect', 10000);
				runs(function () {
					expect(callback).toHaveBeenCalledWith(null,
							{'sessionID': 'session1',
							'update': 'personalInfo'});
				});
			});
		});

		it('should return access denied if already logged out', function () {
			var callCount = this.res.render.callCount;
			users.logout(this.req, this.res);
			waitsFor(function () {
				return callCount != this.res.render.callCount;
			}, 'logout response', 10000);
			runs(function () {
				expect(this.res.render).toHaveBeenCalledWith('401', 
						{'error': 'Not Authorized'}, 401);
			});
		});
		
		it('should send an error to the callback if already logged out', function () {
			var callback = jasmine.createSpy();
			var callCount = callback.callCount;
			users.logout(this.req, this.res, callback);
			waitsFor(function () {
				return callCount != callback.callCount;
			}, 'logout response', 10000);
			runs(function () {
				expect(callback).toHaveBeenCalledWith({'message': 'Not Authorized'}, null);
			});
		});
	});
	
	describe('add user', function () {
		it('should have a function to add users', function () {
			expect(typeof users.add).toEqual('function');
		});
		
		it('should send an http error if there is not data', function () {
			delete this.req.body;
			var callCount = this.res.render.callCount;
			users.add(this.req, this.res);
			waitsFor(function () {
				return callCount != this.res.render.callCount;
			}, 'response from userid', 10000);
			runs(function () {
				expect(this.res.render).toHaveBeenCalledWith('400', 
						{'error': 'Needs new user data'}, 400);
			});
		});
		
		it('should reflect the no data error in the callback', function () {
			delete this.req.body;
			var callback = jasmine.createSpy();
			var callCount = callback.callCount;
			users.add(this.req, this.res, callback);
			waitsFor(function () {
				return callCount != callback.callCount;
			}, 'response from userid', 10000);
			runs(function () {
				expect(callback).toHaveBeenCalledWith(
						{'message': 'Needs new user data'}, null);
			});
		});
		
		it('should fail if the user already exsists', function () {
			var callCount = this.res.render.callCount;
			users.add(this.req, this.res);
			waitsFor(function () {
				return callCount != this.res.render.callCount;
			}, 'response from userid', 10000);
			runs(function () {
				expect(this.res.render).toHaveBeenCalledWith('400', 
						{'error': 'User already exists'}, 400);
			});
		});
	});
	
	describe('set password', function () {
		it('should have a users.setPassword function', function () {
			expect(typeof users.setPassword).toEqual('function');
		});
		
		it('should return error if there is no old and new password', function () {
			var callCount = this.res.render.callCount;
			users.login(this.req, this.res);
			waitsFor(function () {
				return callCount != this.res.render.callCount;
			}, 'response from userid', 10000);
			runs(function () {
				var res = {'render': jasmine.createSpy()};
				callCount = res.render.callCount;
				users.setPassword(this.req, res);
				waitsFor(function () {
					return callCount != res.render.callCount;
				}, 'setPassword response', 10000);
				runs(function () {
					expect(res.render).toHaveBeenCalledWith('400', 
							{'error': 'Needs old and new password'}, 400);
				});
			});
		});
		
		it('should return an error if the old password does not match user name', function () {
			var callCount = this.res.render.callCount;
			users.login(this.req, this.res);
			waitsFor(function () {
				return callCount != this.res.render.callCount;
			}, 'response from userid', 10000);
			runs(function () {
				var res = {'render': jasmine.createSpy()};
				this.req.params = {'username': 'admin'};
				this.req.body.passwordOld = 'wrong';
				this.req.body.passwordNew = 'superAdmin';
				callCount = res.render.callCount;
				users.setPassword(this.req, res);
				waitsFor(function () {
					return callCount != res.render.callCount;
				}, 'setPassword response', 10000);
				runs(function () {
					expect(res.render).toHaveBeenCalledWith('401', 
							{'error': 'Old password was incorrect'}, 401);
				});
			});
		});
	});
});
*/










/*
users.setConnect(connectStr);

describe('usermod-pg', function () {
	describe('PostgreSQL connection', function () {
		it('should have a function to set connection string', function () {
			expect(typeof users.setConnect).toEqual('function');
		});
		
		it('should throw type error if there is no connection string', function () {
			expect(function () {
				users.setConnect();
			}).toThrow(TypeError);
		});
	});
	
	describe('Mail connection', function () {
		it('should have a function for settings the mail server', function () {
			expect(typeof users.setMail).toEqual('function');
		});
		
		it('should throw error if called with nothing', function () {
			expect(function () {
				users.setMail();
			}).toThrow(TypeError);
		});
		
		it('should throw error if EmailMessage does not exist', function () {
			expect(function () {
				users.setMail({});
			}).toThrow(TypeError);
		});
		
		it('should throw error if send_mail is not a function', function () {
			expect(function () {
				var mail = {'send_mail': 'Hi!'};
				users.setMail(mail);
			}).toThrow(TypeError);
		});
	});
	
	describe('Mail Render', function () {
		it('should have a function for rendering the verification email', function () {
			expect(typeof users.setVerificationEmailRender).toEqual('function');
		});
		
		it('should throw TypeError with no arguments', function () {
			expect(function () {
				users.setVerificationEmailRender();
			}).toThrow(TypeError);
		});
		
		it('should throw TypeError if argument is not a function', function () {
			expect(function () {
				users.setVerificationEmailRender('fred');
			}).toThrow(TypeError);
		});
	});

	describe('add user', function () {
		beforeEach(function () {
			this.res = {'render': jasmine.createSpy()};
			this.req = {
				'body': {
					'username': 'flintstone',
					'password1': 'secret',
					'password2': 'secret',
					'email': 'flintstone@bedrock.com'
				},
				'header': {
					'host': 'testing.com'
				}
			};
			this.smtp = {
				'send_mail': jasmine.createSpy()	
			};
			users.setMail(this.smtp);
			users.setVerificationEmailRender(function (text) {
				return text;
			});
		});
		
		afterEach(function () {
			pg.connect(connectStr, function(err, client) {
				client.query("delete from users.user where name = 'flintstone'");
				client.query("delete from users.user where name = 'FLINTSTONE'");
			});
		});
		
		it('should have an add user function', function () {
			expect(typeof users.add).toEqual('function');
		});

		it('should return to add user if username is not defined', function () {
			delete this.req.body.username;
			var callCount = this.res.render.callCount;
			users.add(this.req, this.res);
			waitsFor(function () {
				return callCount != this.res.render.callCount;
			}, 'Waiting on add user.', 10000);
			runs(function () {
				expect(this.res.render).toHaveBeenCalledWith('users/newuser');
			});
		});
		
		it('should return to add user if username is less than 5 letters', function () {
			this.req.body.username = 'four';
			var callCount = this.res.render.callCount;
			users.add(this.req, this.res);
			waitsFor(function () {
				return callCount != this.res.render.callCount;
			}, 'Waiting on add user.', 10000);
			runs(function () {
				expect(this.res.render).toHaveBeenCalledWith('users/newuser');
			});
		});

		it('should return to add user if password1 is not defined', function () {
			delete this.req.body.password1;
			var callCount = this.res.render.callCount;
			users.add(this.req, this.res);
			waitsFor(function () {
				return callCount != this.res.render.callCount;
			}, 'Waiting on add user.', 10000);
			runs(function () {
				expect(this.res.render).toHaveBeenCalledWith('users/newuser');
			});
		});
		
		it('should return to add user if password2 is not defined', function () {
			delete this.req.body.password2;
			var callCount = this.res.render.callCount;
			users.add(this.req, this.res);
			waitsFor(function () {
				return callCount != this.res.render.callCount;
			}, 'Waiting on add user.', 10000);
			runs(function () {
				expect(this.res.render).toHaveBeenCalledWith('users/newuser');
			});
		});

		it('should return to add user if password fields are not equal', function () {
			this.req.body.password2 = 'super secret';
			var callCount = this.res.render.callCount;
			users.add(this.req, this.res);
			waitsFor(function () {
				return callCount != this.res.render.callCount;
			}, 'Waiting on add user.', 10000);
			runs(function () {
				expect(this.res.render).toHaveBeenCalledWith('users/newuser');
			});
		});

		it('should return to add user if email not defined', function () {
			delete this.req.body.email;
			var callCount = this.res.render.callCount;
			users.add(this.req, this.res);
			waitsFor(function () {
				return callCount != this.res.render.callCount;
			}, 'Waiting on add user.', 10000);
			runs(function () {
				expect(this.res.render).toHaveBeenCalledWith('users/newuser');
			});
		});
		
		it('should return add user if user is already used', function () {
			var callCount = this.res.render.callCount;
			users.add(this.req, this.res);
			waitsFor(function () {
				return callCount != this.res.render.callCount;
			}, 'Waiting on add user.', 10000);
			runs(function () {
				var res2 = {'render': jasmine.createSpy()};
				callCount = res2.render.callCount;
				users.add(this.req, res2);
				waitsFor(function () {
					return callCount != res2.render.callCount;
				}, 'Waiting on second add user.', 10000);
				runs(function () {
					expect(res2.render).toHaveBeenCalledWith('users/newuser');
				});
			});
		});

		it('should return add user if user is already used with different cases', function () {
			var callCount = this.res.render.callCount;
			users.add(this.req, this.res);
			waitsFor(function () {
				return callCount != this.res.render.callCount;
			}, 'Waiting on add user.', 10000);
			runs(function () {
				var res2 = {'render': jasmine.createSpy()};
				callCount = res2.render.callCount;
				this.req.body.username = 'FLINTSTONE';
				users.add(this.req, res2);
				waitsFor(function () {
					return callCount != res2.render.callCount;
				}, 'Waiting on add user.', 10000);
				runs(function () {
					expect(res2.render).toHaveBeenCalledWith('users/newuser');
				});
			});
		});
		
		it('should send verification email', function () {
			var callCount = this.res.render.callCount;
			users.add(this.req, this.res);
			waitsFor(function () {
				return callCount != this.res.render.callCount;
			}, 'Waiting on add user.', 10000);
			runs(function () {
				expect(this.res.render).toHaveBeenCalledWith('users/useradded',
						{'name': 'flintstone'});
				expect(this.smtp.send_mail).toHaveBeenCalled();
				var holder = this.smtp.send_mail.mostRecentCall.args[0];
				expect(holder.sender).toEqual('noreply@testing.com');
				expect(holder.to).toEqual('flintstone@bedrock.com');
				expect(holder.subject).toEqual('Thank You for Registering at testing.com');
			});
		});
		
		it('should trim www off of sender', function () {
			this.req.header.host = 'www.testing.com';
			var callCount = this.res.render.callCount;
			users.add(this.req, this.res);
			waitsFor(function () {
				return callCount != this.res.render.callCount;
			}, 'Waiting on add user.', 10000);
			runs(function () {
				var holder = this.smtp.send_mail.mostRecentCall.args[0];
				expect(holder.sender).toEqual('noreply@testing.com');
			});
		});
		
		it('should send an email body with a UUID as a link', function () {
			var uuidTest = new RegExp('^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$');
			var callCount = this.res.render.callCount;
			users.add(this.req, this.res);
			waitsFor(function () {
				return callCount != this.res.render.callCount;
			}, 'Waiting on add user.', 10000);
			runs(function () {
				var holder = this.smtp.send_mail.mostRecentCall.args[0];
				expect(uuidTest.test(holder.body)).toBeTruthy();
			});
		});
		
		it('should have a user validation function', function () {
			expect(typeof users.validate).toEqual('function');
		});
		
		it('should call invalid page when validation fails', function () {
			this.req.params = {'link': 'ReallyBadLink'};
			var callCount = this.res.render.callCount;
			users.validate(this.req, this.res);
			waitsFor(function () {
				return callCount != this.res.render.callCount;
			}, 'Waiting on validate', 10000);
			runs(function () {
				expect(this.res.render).toHaveBeenCalledWith('users/novalidation');
			});
		});
		
		it('should call validated page when validation succeeds', function () {
			var callCount = this.res.render.callCount;
			users.add(this.req, this.res);
			waitsFor(function () {
				return callCount != this.res.render.callCount;
			}, 'Waiting on add user.', 10000);
			runs(function () {
				var res2 = {'render': jasmine.createSpy()};
				var req2 = {'params': {'link': this.smtp.send_mail.mostRecentCall.args[0].body}};
				callCount = res2.render.callCount;
				users.validate(req2, res2);
				waitsFor(function () {
					return callCount != res2.render.callCount;
				}, 'Waiting on validate', 10000);
				runs(function () {
					expect(res2.render).toHaveBeenCalledWith('users/validation');
				});
			});
		});	
	});
	
	describe('logging procedures', function () {
		beforeEach(function () {
			pgStore.set('session1', {});
			var res = {'render': jasmine.createSpy()};
			var req = {
				'body': {
					'username': 'flintstone',
					'password1': 'secret',
					'password2': 'secret',
					'email': 'flintstone@bedrock.com'
				},
				'header': {
					'host': 'testing.com'
				}
			};
			this.smtp = {
				'send_mail': jasmine.createSpy()	
			};
			users.setMail(this.smtp);
			users.setVerificationEmailRender(function (text) {
				return text;
			});
			var callCount = res.render.callCount;
			users.add(req, res);
			waitsFor(function () {
				return callCount != res.render.callCount;
			}, 'Waiting on add user.', 10000);
			runs(function () {
				var res2 = {'render': jasmine.createSpy()};
				var req2 = {'params': {'link': this.smtp.send_mail.mostRecentCall.args[0].body}};
				callCount = res2.render.callCount;
				users.validate(req2, res2);
				waitsFor(function () {
					return callCount != res2.render.callCount;
				}, 'Waiting on validate', 10000);
				runs(function () {});
			});
			this.req = {
				'body': {
					'username': 'flintstone',
					'password': 'secret'
				},
				'params': {
					'logingoto': '/someplaceelse'
				},
				'session': {
					'key': 'session1'
				}
			};
			this.res = {'redirect': jasmine.createSpy()};
		});
		
		afterEach(function () {
			pgStore.clear();
			var callback = jasmine.createSpy();
			var callCount = callback.callCount;
			pg.connect(connectStr, function(err, client) {
				client.query("delete from users.user where name = 'flintstone' or name = 'rubble'", callback);
			});
			waitsFor(function () {
				return callCount != callback.callCount;
			});
		});
				
		describe('login', function () {
			it('should have a login function', function () {
				expect(typeof users.login).toEqual('function');
			});
			
			it('should return the original page if it fails to log on', function () {
				this.req.body = {};
				var callCount = this.res.redirect.callCount;
				users.login(this.req, this.res);
				waitsFor(function () {
					return callCount != this.res.redirect.callCount;
				}, 'Waiting for response', 10000);
				runs(function () {
					expect(this.res.redirect).toHaveBeenCalled();
					expect(this.res.redirect).toHaveBeenCalledWith('back');
				});
			});
			
			it('should return a given page if login successful', function () {
				var callCount = this.res.redirect.callCount;
				users.login(this.req, this.res);
				waitsFor(function () {
					return callCount != this.res.redirect.callCount;
				}, 'Waiting for response', 10000);
				runs(function () {
					expect(this.res.redirect).toHaveBeenCalledWith('/someplaceelse');
				});
			});
			
			it('should return to original page if no extra page is given', function () {
				this.req.params = {};
				var callCount = this.res.redirect.callCount;
				users.login(this.req, this.res);
				waitsFor(function () {
					return callCount != this.res.redirect.callCount;
				}, 'Waiting for response', 10000);
				runs(function () {
					expect(this.res.redirect).toHaveBeenCalledWith('back');
				});
			});
			
			it('should fail if user user is inactive', function () {
				var res = {'render': jasmine.createSpy()};
				var req = {
						'body': {
							'username': 'rubble',
							'password1': 'secret',
							'password2': 'secret',
							'email': 'rubble@bedrock.com'
						},
						'header': {
							'host': 'testing.com'
						}
					};
				var callCount = res.render.callCount;
				users.add(req, res);
				waitsFor(function () {
					return callCount != res.render.callCount;
				}, 'Waiting on add user.', 10000);
				runs(function () {
					res = {'redirect': jasmine.createSpy()};
					req = {
							'body': {
								'username': 'rubble',
								'password': 'secret'
								
							},
							'params': {
								'logingoto': '/someplaceelse'
							},
							'session': {
							
							
								'key': 'session1'
							}
						};
					callCount = res.redirect.callCount;
					users.login(req, res);
					waitsFor(function () {
						return callCount != res.redirect.callCount;
					}, 'Waiting for response', 10000);
					runs(function () {
						var callback = jasmine.createSpy();
						callCount = callback.callCount;
						users.getUser(this.req.session.key, callback);
						waitsFor(function () {
							return callCount != callback.callCount;
						}, 'Waiting for a callback', 10000);
						runs(function () {
							expect(callback).toHaveBeenCalledWith(null, 'anonymous');
						});
					});
				});
			});
		});
		
		describe('Get User Name', function () {
			it('should have a fetch user name function', function () {
				expect(typeof users.getUser).toEqual('function');
			});
			
			it('should return anonymous when the user is not logged in', function () {
				var callback = jasmine.createSpy();
				var callCount = callback.callCount;
				users.getUser(this.req.session.key, callback);
				waitsFor(function () {
					return callCount != callback.callCount;
				}, 'Waiting for a callback', 10000);
				runs(function () {
					expect(callback).toHaveBeenCalledWith(null, 'anonymous');
				});
			});
			
			it("should return the user's name when logged in", function () {
				var callCount = this.res.redirect.callCount;
				users.login(this.req, this.res);
				waitsFor(function () {
					return callCount != this.res.redirect.callCount;
				}, 'Waiting for response', 10000);
				runs(function () {
					var callback = jasmine.createSpy();
					callCount = callback.callCount;
					users.getUser(this.req.session.key, callback);
					waitsFor(function () {
						return callCount != callback.callCount;
					}, 'Waiting for a callback', 10000);
					runs(function () {
						expect(callback).toHaveBeenCalledWith(null, 'flintstone');
					});
				});
			});
			
			it('should return anonymous for bad session ids', function () {
				var callback = jasmine.createSpy();
				var callCount = callback.callCount;
				users.getUser('Frankenstein', callback);
				waitsFor(function () {
					return callCount != callback.callCount;
				}, 'Waiting for a callback', 10000);
				runs(function () {
					expect(callback).toHaveBeenCalledWith(null, 'anonymous');
				});
			});
		});
		
		describe('logout', function () {
			it('should have a log out function', function () {
				expect(typeof users.logout).toEqual('function');
			});
			
			it('should send the user to the home page', function () {
				var callCount = this.res.redirect.callCount;
				users.login(this.req, this.res);
				waitsFor(function () {
					return callCount != this.res.redirect.callCount;
				}, 'Waiting for response', 10000);
				runs(function () {
					var res = {'redirect': jasmine.createSpy()};
					callCount = res.redirect.callCount;
					users.logout(this.req, res);
					waitsFor(function () {
						return callCount != res.redirect.callCount;
					}, 'Waiting for logout redirect', 10000);
					runs(function () {
						expect(res.redirect).toHaveBeenCalledWith('home');
					});
				});
			});
			
			it('should set the user back to anonymous', function () {
				var callCount = this.res.redirect.callCount;
				users.login(this.req, this.res);
				waitsFor(function () {
					return callCount != this.res.redirect.callCount;
				}, 'Waiting for response', 10000);
				runs(function () {
					var res = {'redirect': jasmine.createSpy()};
					callCount = res.redirect.callCount;
					users.logout(this.req, res);
					waitsFor(function () {
						return callCount != res.redirect.callCount;
					}, 'Waiting for logout redirect', 10000);
					runs(function () {
						var callback = jasmine.createSpy();
						callCount = callback.callCount;
						users.getUser(this.req.session.key, callback);
						waitsFor(function () {
							return callCount != callback.callCount;
						}, 'Waiting for a callback', 10000);
						runs(function () {
							expect(callback).toHaveBeenCalledWith(null, 'anonymous');
						});
					});
				});
			});
		});
	});
	
	describe('Group functions', function () {
		beforeEach(function () {
			pgStore.set('session1', {});
			var req = {
					'body': {
						'username': 'admin',
						'password': 'admin'
					},
					'session': {
						'key': 'session1'
					}
				};
			var res = {'redirect': jasmine.createSpy()};
			var callCount = res.redirect.callCount;
			users.login(req, res);
			waitsFor(function () {
				return callCount != res.redirect.callCount;
			}, 'waiting for admin login', 10000);
			runs(function () {});
		});
		
		afterEach(function () {
			pgStore.clear();
		});
		
		describe('adding a group', function () {
			it('should have a create group function', function () {
				expect(typeof users.addGroup).toEqual('function');
			});
			
			it('should return with the back to the calling page', function () {
				req = {
					'body': {
						'newgroup': 'flintstones'
					},
					'session': {
						'key': 'session1'
					}
				};
				res = {'redirect': jasmine.createSpy()};
				var callCount = res.redirect.callCount;
				users.addGroup(req, res);
				waitsFor(function () {
					return callCount != res.redirect.callCount;
				}, 'waiting for addgroup', 10000);
				runs(function () {
					expect(res.redirect).toHaveBeenCalledWith('back');
				});
			});
		});
		
		describe('group listing', function () {
			it('should have a listing for groups owned by the user', function () {
				expect(typeof users.ownedGroups).toEqual('function');
			});
			
			it('should list all the groups owned by the user', function () {
				var callback = jasmine.createSpy();
				var callCount = callback.callCount;
				users.ownedGroups('session1', callback);
				waitsFor(function () {
					return callCount != callback.callCount;
				}, 'callback from ownedGroups', 10000);
				runs(function () {
					expect(callback).toHaveBeenCalled();
					expect(callback).toHaveBeenCalledWith(['admin',]);
				});
			});
		});
	});
});
*/