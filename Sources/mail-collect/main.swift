import Vapor
import Foundation

print("Starting")

var env = try Environment.detect()
try LoggingSystem.bootstrap(from: &env)

let app = Application(env)

// Otherwise cannot be reached from outside docker container
app.http.server.configuration.hostname = "0.0.0.0"

configureDatabase(app: app)

defer { 
	print("Shutting down...")
	app.shutdown() 
}

app.get("hello") { req async throws in
	print("GOT REQUEST")

	let database = req.db

	let result = try await Subscriber.query(on: database).all()

	return result
}

app.post("new") { req async throws in
	print("GOT CREATE REQUEST")

	// let bodyString = try req.content.decode(String.self)

	// print(bodyString)

	let subscriber = try req.content.decode(Subscriber.self)

	let database = req.db

	try await subscriber.create(on: database)

	return subscriber
}

try! app.run()
