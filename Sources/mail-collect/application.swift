import Vapor
import Leaf

func configure(app: Application) {
	let corsConfiguration = CORSMiddleware.Configuration(
		allowedOrigin: .all,
		allowedMethods: [.GET, .POST, .PUT, .OPTIONS, .DELETE, .PATCH],
		allowedHeaders: [.accept, .authorization, .contentType, .origin, .xRequestedWith, .userAgent, .accessControlAllowOrigin]
	)
	let cors = CORSMiddleware(configuration: corsConfiguration)
	app.middleware.use(cors, at: .beginning)
	app.middleware.use(WWWAuthenticationMiddleware())

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

	// For HTML templating
	app.views.use(.leaf)


	let authenticatedApp = app.grouped(User.authenticator())

	registerRoutes(auth: authenticatedApp, nonAuth: app)
}
