/*
var buster = require('buster')
  , when = require('when')
  , pg = require('pg')
  , userMod = require('../');

var connNode = 'tcp://nodepg:password@localhost/pgstore';
var connRoot = 'tcp://jeff:tester@localhost/pgstore';

function rootQuery (query, values) {
	var deferred = when.defer();
	pg.connect(connRoot, function (err, client) {
		if (err) {
			console.log(JSON.stringify(err));
			deferred.resolver.reject();
		} else {
			client.query(query, values, function (err, result) {
				if (err) {
					console.log(JSON.stringify(err));
					deferred.resolver.reject();
				} else {
					deferred.resolver.resolve(result.rows[0]);
				}
			});
		}
	});
	return deferred.promise;
}

buster.testCase('userMod', {
	'setUp': function () {
		var usedSessions = [];
		var testUsers = [];
		this.users = new userMod(connNode);

		this.getSession = function () {
			var deferred = when.defer();
			when(rootQuery('select sess_id from create_test_session()'),
				function (row) {
					usedSessions.push(row['sess_id']);
					deferred.resolver.resolve(row['sess_id']);
				}
			);
			return deferred.promise;
		};
		
		this.getInactiveUser = function () {
			var deferred = when.defer();
			when(rootQuery('select * from get_inactive_test_user()'),
				function (row) {
					testUsers.push(row['inactiveusername']);
					deferred.resolver.resolve({
						'username':  row['inactiveusername'],
						'password':  row['inactivepassword'],
						'email':     row['inactiveemail'],
						'link':      row['validationlink']
					});
				}
			);
			return deferred.promise;
		};
		
		this.getLoggedOutUser = function () {
			var deferred = when.defer();
			when(rootQuery('select * from get_logged_out_test_user()'),
				function (row) {
					testUsers.push(row['loggedoutusername']);
					deferred.resolver.resolve({
						'username':  row['loggedoutusername'],
						'password':  row['loggedoutpassword'],
						'email':     row['loggedoutemail']
					});
				}
			);
			return deferred.promise;
		};
		
		this.getLoggedInUser = function () {
			var deferred = when.defer();
			when(rootQuery('select * from get_logged_in_test_user()'),
				function (row) {
					testUsers.push(row['loggedinusername']);
					deferred.resolver.resolve({
						'username':  row['loggedinusername'],
						'password':  row['loggedinpassword'],
						'email':     row['loggedinemail'],
						'sessionID': row['loggedinsession']
					});
				}
			);
			return deferred.promise;
		};
		
		this.usedSessions = usedSessions;
		this.testUsers = testUsers;
	},
	'tearDown': function () {
		var deferreds = [];
		
		while (this.usedSessions.length) {
			deferreds.push(rootQuery(
					'delete from web.session where sess_id = $1', 
					[this.usedSessions.pop()]));
		}
		while (this.testUsers.length) {
			deferreds.push(rootQuery(
					'delete from users.user where name = $1',
					[this.testUsers.pop()]));
		}
		return when.all(deferreds);
	},
	'constructor': {
		'should be a function': function () {
			assert.typeOf(userMod, 'function', 'Constructor should be a function.');
		}
	},
	'testing test': function () {
		var deferred = when.defer();
		when(this.getSession(),
			function (sess_id) {
				assert(true);
				deferred.resolver.resolve();
			}
		);
		return deferred.promise;
	},
	'getUser': {
		'should be a function': function () {
			assert.typeOf(this.users.getUser, 'function', 
					'Needs a getUser function.');
		},
		'should return a promise': function () {
			assert.typeOf(this.users.getUser().then, 'function',
					'There should be a then function of a promise.');
		},
		'should return anonymous when session is not specified': function () {
			var deferred = when.defer();
			this.users.getUser().then(function (user) {
				assert.equals(user, 'anonymous', 
						'Undefined session returns anonymous user');
				deferred.resolver.resolve();
			});
			return deferred.promise;
		},
		'should return anonymous if logged out': function () {
			var users = this.users;
			var deferred = when.defer();
			when(this.getSession(),
				function (sessionID) {
					return users.getUser(sessionID);
				}
			).then(
				function (user) {
					assert.equals(user, 'anonymous', 
						'Undefined session returns anonymous user');
					deferred.resolver.resolve();
				}
			);
			return deferred.promise;
		},
		'should return the logged in user name': function () {
			var users = this.users;
			var deferred = when.defer();
			var userInfo = {};
			when(this.getLoggedInUser(),
				function (user) {
					userInfo = user;
					return users.getUser(userInfo.sessionID);
				}
			).then(
				function (username) {
					assert.equals(username, userInfo.username);
					deferred.resolver.resolve();
				}
			);
			return deferred.promise;
		},
		'//should reject promise if there is an error': function () {
			// Need to figure out how to make the function fail.
			var deferred = when.defer();
			when(this.users.getUser(null),
				function () {
					assert(false,'resolve should not run on failure.');
					deferred.resolver.resolve();
				},
				function () {
					assert(true, 'error was rejected');
					deferred.resolver.resolve();
				}
			);
			return deferred.promise;
		}
	},
	'login': {
		'should be a function': function () {
			assert.typeOf(this.users.login, 'function',
					'There should be a login function.');
		},
		'should assign the user to a session': function () {
			var users = this.users;
			var getLoggedOutUser = this.getLoggedOutUser;
			var deferred = when.defer();
			var sessionID = '';
			var userInfo = {};

			when(this.getSession(),
				function (sessID) {
					sessionID = sessID;
					return getLoggedOutUser();
				}
			).then(
				function (user) {
					userInfo = user;
					return users.login(sessionID, userInfo.username,
							userInfo.password);
				}
			).then(
				function () {
					return users.getUser(sessionID);
				}
			).then(
				function (name) {
					assert.equals(name, userInfo.username,
						'User should be logged in.');
					deferred.resolver.resolve();
				}
			);
			return deferred.promise;
		},
		'should reject a failed login': function () {
			var users = this.users;
			var getLoggedOutUser = this.getLoggedOutUser;
			var deferred = when.defer();
			var sessionID = '';
			var userInfo = {};

			when(this.getSession(),
				function (sessID) {
					sessionID = sessID;
					return getLoggedOutUser();
				}
			).then(
				function (user) {
					userInfo = user;
					return users.login(sessionID, userInfo.username,
							'wrong');
				}
			).then(
				function () {},
				function (err) {
					assert(true, 'It should reject the promise.');
					deferred.resolver.resolve();
				}
			);
			return deferred.promise;
		},
		'should reject user is inactive': function () {
			var users = this.users;
			var getInactiveUser = this.getInactiveUser;
			var deferred = when.defer();
			var sessionID = '';
			var userInfo = {};

			when(this.getSession(),
				function (sessID) {
					sessionID = sessID;
					return getInactiveUser();
				}
			).then(
				function (user) {
					userInfo = user;
					return users.login(sessionID, userInfo.username,
							userInfo.password);
				}
			).then(
				function () {},
				function (err) {
					assert(true, 'It should reject the promise.');
					deferred.resolver.resolve();
				}
			);
			return deferred.promise;
		}
	},
	'logout': {
		'should be a function': function () {
			assert.typeOf(this.users.logout, 'function',
			'There should be a logout function.');
		}
	}
});
*/