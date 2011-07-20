/**
 * 
 */
var connectStr = "tcp://thetester:password@localhost/pgstore";
var users = require('../');
users.setConnect(connectStr);
var pg = require('pg');

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
	});
});