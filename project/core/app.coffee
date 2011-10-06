kiss = require "kiss.js"
controllers = require "../controllers/controllers"
models = require "../models/models"

options =
	events:
		"/$": controllers.MyController.index,
		"/2$": controllers.MyController.fileview,
		"not_found": controllers.MyController.on_not_found
	models:
		objects: [new models.MyModel(56, "some str")]
		user: "root"
		password: "!1ebet2@"
		database: "kiss_project"
app = new kiss.core.Application(options)
app.start()
