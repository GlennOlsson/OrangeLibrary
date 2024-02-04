import Foundation
import Logging
import Vapor

enum EnvironmentVariable: String {
	case DATABASE = "POSTGRES_DB"
	case DATABASE_USER = "POSTGRES_USER"
	case DATABASE_PASSWORD = "POSTGRES_PASSWORD"
}

func getEnvironment(_ key: EnvironmentVariable) -> String? {
	return Environment.get(key.rawValue)
}
