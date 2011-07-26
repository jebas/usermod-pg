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

exports.add = function (req, res) {
	var rtnView = 'users/newuser';
	var additionalValues = null;
	var smtp = this.smtp;
	var mailRender = this.mailRender;
	if (req.body && req.body.username && req.body.password1 && req.body.password2 &&
			(req.body.password1 == req.body.password2) && req.body.email) {
		pg.connect(this.connectStr, function (err, client) {
			client.query('select users.add($1, $2, $3)', 
					[req.body.username, req.body.password1, req.body.email], 
					function (err, result) {
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
				} else {
					res.render(rtnView);
				}
			});
		});
	} else {
		res.render(rtnView);
	}
};

exports.validate = function (req, res) {
	pg.connect(this.connectStr, function (err, client) {
		client.query('select users.validate($1)', 
				[req.params.link,], 
				function (err, result) {
			var template = 'users/novalidation';
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
	res.redirect('back');
};