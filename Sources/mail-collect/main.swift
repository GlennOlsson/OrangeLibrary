import Vapor
import Foundation

print("Starting")

var env = try Environment.detect()
try LoggingSystem.bootstrap(from: &env)

let app = Application(env)

// Otherwise cannot be reached from outside docker container
app.http.server.configuration.hostname = "0.0.0.0"


let databaseConfig = createDatabaseConfig(
	username: getEnvironment(.DATABASE_USER)!, 
	password: getEnvironment(.DATABASE_PASSWORD)!, 
	database: getEnvironment(.DATABASE)!
)
useDatabase(
	on: app,
	with: databaseConfig
)

let authenticatedApp = app.grouped(User.authenticator())

defer { 
	print("Shutting down...")
	app.shutdown() 
}

registerRoutes(auth: authenticatedApp, nonAuth: app)

try! app.run()
