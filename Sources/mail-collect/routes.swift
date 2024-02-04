import Vapor
 
func createApp() -> Application {
	let app = try! Application(.detect())

	app.get("hello") { req in
		print("GOT REQUEST")
		return "Hello, world."
	}

	return app
}


