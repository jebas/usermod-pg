/*
 * 
 */
var pg = require('pg');

exports.setConnect = function (connectStr) {
	if (arguments.length == 0) {
		throw TypeError;
	}
	this.connectStr = connectStr;
};

exports.add = function (req, res) {
	var rtnView = 'users/newuser';
	var additionalValues = null;
	if (req.body && req.body.username && req.body.password1 && req.body.password2 &&
			(req.body.password1 == req.body.password2) && req.body.email) {
		pg.connect(this.connectStr, function (err, client) {
			client.query('select users.add($1, $2, $3)', 
					[req.body.username, req.body.password1, req.body.email], 
					function (err, result) {
				if (result) {
					rtnView = 'users/useradded';
					additionalValues = {'name': req.body.username};
				}
				res.render(rtnView, additionalValues);
			});
		});
	} else {
		res.render(rtnView);
	}
};