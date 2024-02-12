import Vapor

func configure(app: Application) {
	let corsConfiguration = CORSMiddleware.Configuration(
		allowedOrigin: .all,
		allowedMethods: [.GET, .POST, .PUT, .OPTIONS, .DELETE, .PATCH],
		allowedHeaders: [.accept, .authorization, .contentType, .origin, .xRequestedWith, .userAgent, .accessControlAllowOrigin]
	)
	let cors = CORSMiddleware(configuration: corsConfiguration)
	app.middleware.use(cors, at: .beginning)

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

//	defer { 
//		print("Shutting down...")
//		app.shutdown() 
//	}

	registerRoutes(auth: authenticatedApp, nonAuth: app)
}
