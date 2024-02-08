import Vapor
import Fluent

let ID_PARAM_NAME: String = "id"

let SUBSCRIBER_PATH: PathComponent = "subscriber"
let SUBSCRIBER_ID_PARAM_PATH: PathComponent = ":\(ID_PARAM_NAME)"

let USER_PATH: PathComponent = "user"
let USER_ID_PARAM_PATH: PathComponent = "user"

func _get_by(email: String, on db: Database) async throws -> [Subscriber] {
	return try await Subscriber.query(on: db).filter(\.$email == email).all()
}

func _exists(email: String, on db: Database) async throws -> Bool {
	return try await _get_by(email: email, on: db).count > 0
}

func _remove(with id: Int, on db: Database) async throws -> Subscriber {
	guard let result = try await Subscriber.find(id, on: db) else {
		throw Abort(.notFound)
	}

	try await result.delete(on: db)

	return result
}

func registerRoutes(_ app: Application) {

	// Get all
	// TODO: Add authentication
	app.get(SUBSCRIBER_PATH) { req async throws in 
		let result = try await Subscriber.query(on: req.db).all()
		req.logger.info("Got all subscribers")
		return result
	}

	// Create new. Only path without authentication
	app.post(SUBSCRIBER_PATH) { req async throws in 
		try Subscriber.validate(content: req)

		let requestModel = try req.content.decode(Subscriber.self)

		let emailExists = try? await _exists(email: requestModel.email, on: req.db)
		guard emailExists != nil && !emailExists! else {
			throw Abort(.badRequest, reason: "email is already registered")
		} 

		try await requestModel.create(on: req.db)

		req.logger.info("New subscriber with email: \(requestModel.email) (id: \(requestModel.id ?? -1))")

		return requestModel
	}

	// Get specific entry
	// TODO: Add authentication
	app.get(SUBSCRIBER_PATH, SUBSCRIBER_ID_PARAM_PATH) { req async throws in 
		let idString = req.parameters.get(ID_PARAM_NAME) ?? "-1"
		let id = Int(idString) ?? -1
		guard let result = try await Subscriber.find(id, on: req.db) else {
			throw Abort(.notFound)
		}

		req.logger.info("Got subscriber with id \(id)")
		
		return result
	}

	// Update entry
	// TODO: Add authentication
	app.put(SUBSCRIBER_PATH, SUBSCRIBER_ID_PARAM_PATH) { req async throws in 
		try Subscriber.validate(content: req)

		let requestModel = try req.content.decode(Subscriber.self)

		let idString = req.parameters.get(ID_PARAM_NAME) ?? "-1"
		let id = Int(idString) ?? -1
		guard let result = try await Subscriber.find(id, on: req.db) else {
			throw Abort(.notFound)
		}

		let emailExists = try? await _exists(email: requestModel.email, on: req.db)
		guard emailExists != nil && !emailExists! else {
			throw Abort(.badRequest, reason: "email is already registered")
		} 

		// Update more fields if necessary
		result.email = requestModel.email

		try await result.update(on: req.db)

		req.logger.info("Updated subscriber \(id) to email \(requestModel.email)")
		
		return result
	}

	// Delete entry
	// TODO: Add authentication
	app.delete(SUBSCRIBER_PATH, SUBSCRIBER_ID_PARAM_PATH) { req async throws in 
		let idString = req.parameters.get(ID_PARAM_NAME) ?? "-1"
		let id = Int(idString) ?? -1

		let result = try await _remove(with: id, on: req.db)

		req.logger.info("Deleted subscriber with id \(id) and email \(result.email)")

		return result
	}

	app.post(USER_PATH) { req async throws in 
		try User.Create.validate(content: req)
		let userRequest = try req.content.decode(User.Create.self)

		guard userRequest.password == userRequest.confirmPassword else {
			throw Abort(.badRequest, reason: "Passwords don't match")
		}

		let authority = userRequest.authority
		// TODO: Check priveledge and if higher than requester, if not nil

		let newUser = try User(username: userRequest.username, password: userRequest.password, authority: authority)

		try await newUser.create(on: req.db)

		return newUser.response
	}
}


