models = require "./models"
core = require "./core"
mysql = require "mysql"

class MysqlAdapter extends models.Adapter
	constructor: () ->
		@app = new core.Application()
		@db = mysql.createClient(@app.options.models)
	
	save: (model) ->
		@db.query 'INSERT INTO t1 values (2, "stas")'
	
	find: (conditions) ->
		@db.query 'SELECT * FROM t1',
			(err, results, fields) =>
				console.log results
				console.log fields
				@db.end()
				
	remove: (model) ->
		console.log "remove"

exports.MysqlAdapter = MysqlAdapter
