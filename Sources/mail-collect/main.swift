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

registerRoutes(app)

try! app.run()
