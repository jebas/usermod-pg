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

	describe('add user', function () {
		beforeEach(function () {
			this.res = {'render': jasmine.createSpy()};
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
			var req = {'body': {'flintstone': 'fred'}};
			var callCount = this.res.render.callCount;
			users.add(req, this.res);
			waitsFor(function () {
				return callCount != this.res.render.callCount;
			}, 'Waiting on add user.', 10000);
			runs(function () {
				expect(this.res.render).toHaveBeenCalledWith('users/newuser');
			});
		});
		
		it('should return to add user if username is less than 5 letters', function () {
			var req = {'body': {'username': 'four'}};
			var callCount = this.res.render.callCount;
			users.add(req, this.res);
			waitsFor(function () {
				return callCount != this.res.render.callCount;
			}, 'Waiting on add user.', 10000);
			runs(function () {
				expect(this.res.render).toHaveBeenCalledWith('users/newuser');
			});
		});

		it('should return to add user if password1 is not defined', function () {
			var req = {'body': {'username': 'flintstone'}};
			var callCount = this.res.render.callCount;
			users.add(req, this.res);
			waitsFor(function () {
				return callCount != this.res.render.callCount;
			}, 'Waiting on add user.', 10000);
			runs(function () {
				expect(this.res.render).toHaveBeenCalledWith('users/newuser');
			});
		});
		
		it('should return to add user if password2 is not defined', function () {
			var req = {'body': {'username': 'flintstone',
				'password1': 'secret'}};
			var callCount = this.res.render.callCount;
			users.add(req, this.res);
			waitsFor(function () {
				return callCount != this.res.render.callCount;
			}, 'Waiting on add user.', 10000);
			runs(function () {
				expect(this.res.render).toHaveBeenCalledWith('users/newuser');
			});
		});

		it('should return to add user if password fields are not equal', function () {
			var req = {'body': {'username': 'flintstone',
				'password1': 'secret',
				'password2': 'super secret'}};
			var callCount = this.res.render.callCount;
			users.add(req, this.res);
			waitsFor(function () {
				return callCount != this.res.render.callCount;
			}, 'Waiting on add user.', 10000);
			runs(function () {
				expect(this.res.render).toHaveBeenCalledWith('users/newuser');
			});
		});

		it('should return to add user if email field is not valid', function () {
			var req = {'body': {'username': 'flintstone',
				'password1': 'secret',
				'password2': 'secret'}};
			var callCount = this.res.render.callCount;
			users.add(req, this.res);
			waitsFor(function () {
				return callCount != this.res.render.callCount;
			}, 'Waiting on add user.', 10000);
			runs(function () {
				expect(this.res.render).toHaveBeenCalledWith('users/newuser');
			});
		});
		
		it('should add the user to the database', function () {
			var req = {'body': {'username': 'flintstone',
				'password1': 'secret',
				'password2': 'secret',
				'email': 'flintstone@bedrock.com'}};
			var callCount = this.res.render.callCount;
			users.add(req, this.res);
			waitsFor(function () {
				return callCount != this.res.render.callCount;
			}, 'Waiting on add user.', 10000);
			runs(function () {
				expect(this.res.render).toHaveBeenCalledWith('users/useradded');
			});
		});
	});
});