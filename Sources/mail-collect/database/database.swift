import Vapor
import Fluent
import FluentPostgresDriver

func configureDatabase(app: Application) {
  let postgresConfig: SQLPostgresConfiguration = .init(
    hostname: "postgresdb", 
    port: 5432, 
    username: getEnvironment(.DATABASE_USER)!, 
    password: getEnvironment(.DATABASE_PASSWORD)!, 
    database: getEnvironment(.DATABASE)!,
    tls: .disable // TODO: Activate
  )
  
  app.databases.use(.postgres(configuration: postgresConfig), as: .psql)
}
