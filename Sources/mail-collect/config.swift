import Foundation
import Logging


// class Config {
// 	var database: Database?
// 	let _logger = Logger(label: "config-logger")

// 	func initiateDatabase() async {
// 		do {
// 			self.database = try await Database()
// 		} catch {
// 			_logger.info("Could not initate database connection")
// 		}
// 	}

// 	func killDatabase() async {
// 		do {
// 			try await self.database?.close()
// 		} catch {
// 			_logger.info("Could not close database connection")
// 		}
// 	}

// 	init() async throws {
// 		await initiateDatabase()

// 		_logger.info("Created config object")

		

// 		 guard let result = try await database?.connection.query("SELECT * FROM subscribers", logger: _logger) else {
//                 print("No results")
//                 return
//             }

//             print("Made query, getting")

//             for try await row in result {
// 				let email = try? row.decode((String).self)
// 				// let v = row.
//                 print("ROW", row, email, row)
//             }

// 		print("got here")
// 		print("got here1")
// 		print("got here2")
// 		print("got here3")

// 		return
// 	}
// }
