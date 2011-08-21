/**
 * 
 */
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
			/* Create this test. */
		});

		it('should report client problems to the console log', function () {
			/* Create this test. */
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
			/* Create this test. */
		});

		it('should report client problems to the console log', function () {
			/* Create this test. */
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
			/* Create this test. */
		});

		it('should report client problems to the console log', function () {
			/* Create this test. */
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
		
		/*
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
		*/
	});
});











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