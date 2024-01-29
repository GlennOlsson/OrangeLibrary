import Foundation
import Logging

enum EnvironmentVariable: String {
	case DATABASE = "POSTGRES_DB"
	case DATABASE_USER = "POSTGRES_USER"
	case DATABASE_PASSWORD = "POSTGRES_PASSWORD"
}

struct _Environment {
	private let variables: [String: String]
	private static let logger = Logger(label: "env-logger")

	private static func readFile(path: String) -> String? {
		guard let filePath  = Bundle.module.path(forResource: path, ofType: nil) else {
			logger.info("Bad path: \(path)")
			return nil
		}

		return try? String(contentsOfFile: filePath)
	}

	private static func parse(path: String) -> [String: String] {
		guard let fileContent = readFile(path: path) else {
			logger.info("No file content")
			return [:]
		}

		let keyValues = fileContent
		.trimmingCharacters(in: .whitespacesAndNewlines)
		.components(separatedBy: "\n")
		.map({s in 
			let components = s.components(separatedBy: "=")
			return (components[0], components[1])
		})

		var mapping: [String: String] = [:]
		for (k, v) in keyValues {
			mapping[k] = v
		}

		return mapping
	}

	init(path: String = "secrets.txt"){
		print("Init")

		self.variables = _Environment.parse(path: path)
	}

	func get(_ key: EnvironmentVariable) -> String? {
		return self.variables[key.rawValue]
	}

}

let Environment = _Environment()
