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
		this.users = new userMod(connNode);
	},
	'constructor': {
		'should be a function': function () {
			assert.typeOf(userMod, 'function', 'Constructor should be a function.');
		},
		'//should accept the promise of a client': function () {},
		'//should accept a client directly': function () {},
		'//should accept a client string': function () {}
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
			var sessionid = '';
			when(rootQuery('select sess_id from create_test_session()'), 
				function (row) {
					sessionid = row['sess_id'];
					return users.getUser(sessionid);
				}
			).then(
				function (user) {
					assert.equals(user, 'anonymous', 
							'Undefined session returns anonymous user');
				}
			).then(
				function () {
					return rootQuery('delete from web.session where sess_id = $1',
							[sessionid]);
				}
			).then(
				function () {
					deferred.resolver.resolve();
				}
			);
			return deferred.promise;
		},
		'should return the logged in user name': function () {
			var deferred = when.defer();
			var rowHolder = [];
			var users = this.users;
			when(rootQuery('select * from get_logged_in_test_user()'),
				function (row) {
					rowHolder = row;
					return users.getUser(rowHolder['loggedinsession']);
				}
			).then(
				function (user) {
					assert.equals(user, rowHolder['loggedinusername'],
							'Should return active user name.');
				}
			).then(
				function () {
					return rootQuery('delete from users.user where name = $1',
						[rowHolder['loggedinusername']]);
				}
			).then(
				function () {
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
		}
	}
});