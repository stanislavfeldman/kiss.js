core = require "./core"
dust = require 'dust'
path = require 'path'
mime = require 'mime'
fs = require "fs"
findit = require 'findit'
less = require 'less'
uglify = require "uglify-js"
coffeescript = require "coffee-script"

class TextViewer
	@instance: undefined
	
	constructor: (options)->
		if TextViewer.instance isnt undefined
			return TextViewer.instance
		@template_path = options.template_path
		unless path.existsSync @template_path
			return
		finder = findit.find path.normalize @template_path
		finder.on 'file', (file) =>
			filepath = path.normalize file
			data = fs.readFileSync filepath, 'utf-8'
			tname = filepath.substring (path.normalize @template_path).length
			compiled = dust.compile data, tname
			dust.loadSource compiled
		TextViewer.instance = this
	
	render: (req, res, context) ->
		dust.render context.template_name, context, (err, out) =>
			res.writeHead 200, {'Content-Type': 'text/html'}
			res.end out

class Compiler
	@instance: undefined
	
	constructor: ->
		if Compiler.instance isnt undefined
			return Compiler.instance
		Compiler.instance = this
		
	compile_css: (css, callback) ->
		less_parser = new(less.Parser)
		less_parser.parse css, (e, tree) ->
			callback tree.toCSS({ compress: true })
			
	compile_js: (js, callback) ->
		ast = uglify.parser.parse js
		ast = uglify.uglify.ast_mangle ast
		ast = uglify.uglify.ast_squeeze ast
		callback uglify.uglify.gen_code ast
		
	compile_coffee: (coffee, callback) ->
		cf = coffeescript.compile coffee
		@compile_js cf, (js) ->
			callback js

class FileView
	constructor: (file_path) ->
		@file = file_path
		@mimetype = mime.lookup this.file
		@filename = path.basename this.file
	
	render: (req, res, options) ->
		res.setHeader 'Content-disposition', 'attachment; filename=' + options.filename
		res.setHeader 'Content-type', @mimetype
		filestream = fs.createReadStream this.file
		filestream.on 'data', (chunk) =>
			res.write chunk
		filestream.on 'end', ->
			res.end()
			new core.Eventer().emit "after_action", req, res
			
class Translator
	@instance: undefined
	
	constructor: (options) ->
		if Translator.instance isnt undefined
			return Translator.instance
		unless path.existsSync options.locale_path
			return
		@translations = {}
		@files = fs.readdirSync path.normalize options.locale_path
		for file in @files
			data = fs.readFileSync options.locale_path+file, 'utf-8'
			#json file with name "<lang>.json"
			@translations[file.substring 0, file.length-5] = JSON.parse data
		Translator.instance = this
	
	#file format:
	#"<words> {0} <words>" : "<trans_words> {0} <trans_words>"
	translate: (req, str) ->
		msg = ""
		lang = @translations[@get_lang req];
		if(lang)
			msg = lang[str]
			if msg and arguments.length > 2
				args = Array.prototype.slice.call arguments, 2
				msg = @substitute msg, args
		return msg || ""
	
	substitute: (str, arr) ->
		for i in [0..arr.length]
			pattern = "\\{" + i + "\\}"
			re = new RegExp(pattern, "g")
			str = str.replace re, arr[i] 
		return str || ""
	
	get_lang: (request) ->
		if typeof request is 'object'
		    language_header = request.headers['accept-language']
		    languages = []
		    regions = []
		    if language_header
		        (language_header.split ',').forEach (l) ->
		            header = (l.split ';', 1)[0]
		            lr = header.split '-', 2
		            if lr[0]
		            	languages.push lr[0].toLowerCase()
		            if lr[1]
		                regions.push lr[1].toLowerCase()

		        if languages.length > 0
		            request.languages = languages
		            request.language = languages[0]

		        if regions.length > 0
		            request.regions = regions
		            request.region = regions[0]
		    return request.language

exports.TextViewer = TextViewer
exports.FileView = FileView
exports.Translator = Translator
exports.Compiler = Compiler
