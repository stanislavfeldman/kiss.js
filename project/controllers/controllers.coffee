kiss = require "kiss.js"

class MyController
	@index = (req, res) ->
		#translator = new kiss.views.Translator()
		#console.log translator.translate req, "hello"
		#console.log translator.translate req, 'hello, {0}', "Стас"
		context = { template_name: "view.html", foo: 'hello', names: ["Stas", "Boris"], numbers: [], name: -> "Bob " + "Marley"  }
		for i in [0..10]
			context.numbers.push "bla bla " + i
		v = new kiss.views.TextViewer()
		v.render req, res, context

	@on_not_found = (req, res) ->
		res.writeHead 404, {'Content-Type': 'text/html'}
		res.end "custom 404"

exports.MyController = MyController
