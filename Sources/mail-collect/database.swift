import Vapor
import Fluent
import FluentPostgresDriver

func createDatabaseConfig(
  username: String, 
  password: String, 
  database: String
) -> DatabaseConfigurationFactory {
  let postgresConfig: SQLPostgresConfiguration = .init(
    hostname: "postgresdb", 
    port: 5432, 
    username: username,
    password: password,
    database: database,
    tls: .disable // TODO: Activate
  )
  return DatabaseConfigurationFactory.postgres(configuration: postgresConfig)
}

func useDatabase(
  on app: Application, 
  with config: DatabaseConfigurationFactory
) {  
  app.databases.use(config, as: .psql)
}
