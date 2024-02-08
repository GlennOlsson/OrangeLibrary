import Vapor
import Fluent

let ID_PARAM_NAME: String = "id"

let SUBSCRIBER_PATH: PathComponent = "subscriber"
let SUBSCRIBER_ID_PARAM_PATH: PathComponent = ":\(ID_PARAM_NAME)"

let USER_PATH: PathComponent = "user"
let USER_ID_PARAM_PATH: PathComponent = ":\(ID_PARAM_NAME)"

func _get_by(email: String, on db: Database) async throws -> [Subscriber] {
	return try await Subscriber.query(on: db).filter(\.$email == email).all()
}

func _get_by(username: String, on db: Database) async throws -> [User] {
	return try await User.query(on: db).filter(\.$username == username).all()
}

func _exists(email: String, on db: Database) async throws -> Bool {
	return try await _get_by(email: email, on: db).count > 0
}

func _exists(username: String, on db: Database) async throws -> Bool {
	return try await _get_by(username: username, on: db).count > 0
}

func _remove(with id: Int, on db: Database) async throws -> Subscriber {
	guard let result = try await Subscriber.find(id, on: db) else {
		throw Abort(.notFound)
	}

	try await result.delete(on: db)

	return result
}

func assertCanPerform(action: Action, as user: User) throws {
	if !user.canPerform(action: action) {
		throw Abort(.unauthorized, reason: "You are not authorized to perform this action")
	}
}

func registerRoutes(auth authenticated: RoutesBuilder, nonAuth unauthenticated: RoutesBuilder) {

	// Create new. Only path without authentication
	unauthenticated.post(SUBSCRIBER_PATH) { req async throws in 
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

	// Get all
	authenticated.get(SUBSCRIBER_PATH) { req async throws in 
		let requestingUser = try req.auth.require(User.self)
		try assertCanPerform(action: .readSubscriber, as: requestingUser)

		let result = try await Subscriber.query(on: req.db).all()
		req.logger.info("Got all subscribers")
		return result
	}

	// Get specific subscriber
	authenticated.get(SUBSCRIBER_PATH, SUBSCRIBER_ID_PARAM_PATH) { req async throws in 
		let requestingUser = try req.auth.require(User.self)
		try assertCanPerform(action: .readSubscriber, as: requestingUser)

		let idString = req.parameters.get(ID_PARAM_NAME) ?? "-1"
		let id = Int(idString) ?? -1
		guard let result = try await Subscriber.find(id, on: req.db) else {
			throw Abort(.notFound)
		}

		req.logger.info("Got subscriber with id \(id)")
		
		return result
	}

	// Update subscriber
	authenticated.put(SUBSCRIBER_PATH, SUBSCRIBER_ID_PARAM_PATH) { req async throws in 
		let requestingUser = try req.auth.require(User.self)
		try assertCanPerform(action: .updateSubscriber, as: requestingUser)
		
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

	// Delete subscriber
	authenticated.delete(SUBSCRIBER_PATH, SUBSCRIBER_ID_PARAM_PATH) { req async throws in 
		let requestingUser = try req.auth.require(User.self)
		try assertCanPerform(action: .deleteSubscriber, as: requestingUser)
		
		let idString = req.parameters.get(ID_PARAM_NAME) ?? "-1"
		let id = Int(idString) ?? -1

		let result = try await _remove(with: id, on: req.db)

		req.logger.info("Deleted subscriber with id \(id) and email \(result.email)")

		return result
	}

	// Get all users
	authenticated.get(USER_PATH) { req async throws in 
		let requestingUser = try req.auth.require(User.self)
		try assertCanPerform(action: .readUser, as: requestingUser)
		
		return try await User.query(on: req.db).all().map { $0.response }
	}

	// Create user
	authenticated.post(USER_PATH) { req async throws in 
		let requestingUser = try req.auth.require(User.self)
		try assertCanPerform(action: .createUser, as: requestingUser)
		
		try User.Create.validate(content: req)
		let userRequest = try req.content.decode(User.Create.self)

		let authority = userRequest.authority
		if (
			authority != nil &&
			authority! > requestingUser.authority
		) {
			throw Abort(
				.unauthorized, 
				reason: "Cannot assign authority \(authority!) with your authority \(requestingUser.authority)"
			)
		}

		guard userRequest.password == userRequest.confirmPassword else {
			throw Abort(.badRequest, reason: "Passwords don't match")
		}

		let newUser = try User(username: userRequest.username, password: userRequest.password, authority: authority)

		try await newUser.create(on: req.db)

		return newUser.response
	}

	// Update user
	authenticated.put(USER_PATH, USER_ID_PARAM_PATH) { req async throws in
		let requestingUser = try req.auth.require(User.self)
		try assertCanPerform(action: .updateUser, as: requestingUser)

		let idString = req.parameters.get(ID_PARAM_NAME) ?? "-1"
		let id = Int(idString) ?? -1
		guard let currentUser = try await User.find(id, on: req.db) else {
			throw Abort(.notFound)
		}

		let userUpdate = try req.content.decode(User.Update.self)

		if (userUpdate.username != nil) {
			let usernameExists = try await _exists(username: userUpdate.username!, on: req.db)
			if usernameExists {
				throw Abort(.badRequest, reason: "User with username already exists")
			}
		}

		let oldAuthority = currentUser.authority
		let newAuthority = userUpdate.authority
		// Cannot change authority of someone with higher authority, nor make their authority higher than your own
		if oldAuthority > requestingUser.authority ||
			(
				newAuthority != nil &&
				newAuthority! > requestingUser.authority
			)
		{
			throw Abort(
				.unauthorized, 
				reason: "You don't have sufficient authority to do this"
			)
		}

		guard try currentUser.update(with: userUpdate) else {
			throw Abort(.badRequest, reason: "Nothing was updated")
		}

		try await currentUser.update(on: req.db)

		return currentUser.response
	}

	// Delete user
	authenticated.delete(USER_PATH, USER_ID_PARAM_PATH) { req async throws in
		let requestingUser = try req.auth.require(User.self)
		try assertCanPerform(action: .deleteUser, as: requestingUser)

		let idString = req.parameters.get(ID_PARAM_NAME) ?? "-1"
		let id = Int(idString) ?? -1
		guard let user = try await User.find(id, on: req.db) else {
			throw Abort(.notFound)
		}

		let userAuthority = user.authority
		if (userAuthority > requestingUser.authority) {
			throw Abort(
				.unauthorized, 
				reason: "Cannot remove user with higher privelage"
			)
		}

		try await user.delete(on: req.db)

		return user.response
	}
}


