import Vapor
import Foundation

print("Starting")

var env = try Environment.detect()
try LoggingSystem.bootstrap(from: &env)

let app = Application(env)

// Otherwise cannot be reached from outside docker container
app.http.server.configuration.hostname = "0.0.0.0"

defer { 
	print("Shutting down...")
	app.shutdown() 
}

app.get("hello") { req async in
	print("GOT REQUEST")
	return "Hello, world."
}

try! app.run()
