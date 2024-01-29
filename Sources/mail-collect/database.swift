import PostgresNIO

import Logging

let config = PostgresConnection.Configuration(
  host: "postgresdb",
  port: 5432,
  username: Environment.get(.DATABASE_USER)!,
  password: Environment.get(.DATABASE_PASSWORD)!,
  database: Environment.get(.DATABASE)!,
  tls: .disable
)

class Database {

  let logger = Logger(label: "postgres-logger")
  let connection: PostgresConnection

  init() async throws {
    logger.info("Connecting to database")
    self.connection = try await PostgresConnection.connect(
      configuration: config,
      id: 2,
      logger: logger
    )
    logger.info("Connection established")
  }  

  func close() async throws {
    try await self.connection.close()
  }
}
