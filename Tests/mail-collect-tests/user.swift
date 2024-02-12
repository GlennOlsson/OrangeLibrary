@testable import mail_collect
import XCTest
import XCTVapor

import FluentSQLiteDriver
import Logging


final class UserTests: XCTestCase {
	let logger = Logger(label: "user-tester")
	
	var app: Application!

	var rootUser: User!
	var rootUserPassword: String = "averyhardpassword"
	var unprivilegeUser: User!
	var unprivilegeUserPassword: String = "anotherveryhardpassword"

	override func setUp() async throws {
		try await super.setUp()

		self.app = Application(.testing)

		// In memory db
		app.databases.use(.sqlite(.memory), as: .sqlite)

		let authApp = self.app.grouped(User.authenticator())

		registerRoutes(auth: authApp, nonAuth: app)

		let db = app.db(.sqlite)

		try await initDatabase(db: db)

		self.rootUser = try! User(username: "root", password: self.rootUserPassword, authority: Action.maxAuthority())
		try await self.rootUser.create(on: db)

		self.unprivilegeUser = try! User(username: "unprivilege-user", password: self.unprivilegeUserPassword, authority: 1)
		try await self.unprivilegeUser.create(on: db)
	}

	override func tearDown() async throws {
		try await super.tearDown()

		try await clearDatabase(db: self.app.db)

		self.app.shutdown()
	}

	func _authHeader(username: String, password: String) -> HTTPHeaders {
		var headers = HTTPHeaders()

		let authStr = "\(username):\(password)"
		headers.add(name: "Authorization", value: "Basic \(authStr.base64String())")

		return headers
	}

	func rootAuth() -> HTTPHeaders {
		return _authHeader(
			username: self.rootUser.username, 
			password: self.rootUserPassword
		)
	}

	func unprivilegeAuth() -> HTTPHeaders {
		return _authHeader(
			username: self.unprivilegeUser.username, 
			password: self.unprivilegeUserPassword
		)
	}

	func performTestUnathorized(
		_ method: HTTPMethod, 
		_ endpoint: String, 
		headers: HTTPHeaders = [:], 
		beforeRequest: (inout XCTHTTPRequest) throws -> () = { _ in }
	) throws {
		try self.app.test(
			method, 
			endpoint, 
			headers: headers, 
			beforeRequest: beforeRequest
		) { resp in
			XCTAssertEqual(resp.status, .unauthorized)
		}
	}

	func performTestAllUnathorized(
		_ method: HTTPMethod, 
		_ endpoint: String,
		beforeRequest: (inout XCTHTTPRequest) throws -> () = { _ in }
	) throws {
		// No auth header
		try performTestUnathorized(
			method,
			endpoint, 
			beforeRequest: beforeRequest
		)
		// Unprivileged user
		try performTestUnathorized(
			method, 
			endpoint, 
			headers: self.unprivilegeAuth(), 
			beforeRequest: beforeRequest
		)
		// Non-existing account
		try performTestUnathorized(
			method, 
			endpoint, 
			headers: self._authHeader(
				username: "fakeuser", 
				password: "fakepass"
			), 
			beforeRequest: beforeRequest
		)

		// Wrong password
		try performTestUnathorized(
			method, 
			endpoint, 
			headers: self._authHeader(
				username: self.rootUser.username, 
				password: "wrongpassword"
			), 
			beforeRequest: beforeRequest
		)
	}

	func testRootCanCreateUser() async throws {
		let user = User.Create(
			username: "somenewuser", 
			password: "fantasticpassword", 
			confirmPassword: "fantasticpassword"
		)

		try self.app.test(
			.POST, 
			"user", 
			headers: rootAuth(), 
			beforeRequest: { try $0.content.encode(user) }
		) { res in 
			print(res.body.string)
			XCTAssertEqual(res.status, .ok)
		}
	}

	func testUnathenticatedCannotCreateUser() throws {
		let user = User.Create(
			username: "somenewuser", 
			password: "fantasticpassword", 
			confirmPassword: "fantasticpassword"
		)

		try performTestAllUnathorized(
			.POST, 
			"user"
		) { try $0.content.encode(user) }
	}

	func testCannotCreateWithSameName() throws {
		let user = User.Create(
			username: self.rootUser.username, 
			password: "fantasticpassword", 
			confirmPassword: "fantasticpassword"
		)

		try self.app.test(
			.POST, "user", 
			headers: rootAuth(), 
			beforeRequest: { try $0.content.encode(user) }
		) { XCTAssertEqual($0.status, .badRequest) }
	}

	func testCannotCreateWithDifferentPasswords() throws {
		let user = User.Create(
			username: "okusername", 
			password: "fantasticpassword", 
			confirmPassword: "anotherpassword"
		)

		try self.app.test(
			.POST, 
			"user", 
			headers: rootAuth(), 
			beforeRequest: { try $0.content.encode(user) }
		) { XCTAssertEqual($0.status, .badRequest) }
	}

	func testGetCreatedUsers() throws {
		let user = User.Create(
			username: "somenewuser", 
			password: "fantasticpassword", 
			confirmPassword: "fantasticpassword"
		)

		try self.app.test(
			.POST, 
			"user", 
			headers: rootAuth(), 
			beforeRequest: { try $0.content.encode(user) }
		)

		try self.app.test(
			.GET, 
			"user", 
			headers: rootAuth()
		) { res in 
			XCTAssertEqual(res.status, .ok)

			let foundUsers = try res.content.decode([User.Response].self)

			XCTAssertEqual(foundUsers.count, 3)

			XCTAssert(foundUsers.contains(where: { $0.username == self.rootUser.username }))
			XCTAssert(foundUsers.contains(where: { $0.username == self.unprivilegeUser.username }))
			XCTAssert(foundUsers.contains(where: { $0.username == user.username }))
		}
	}

	func testGetNonExistingUserReturns404() throws {
		try self.app.test(
			.GET, 
			"user/999", 
			headers: rootAuth()
		) { XCTAssertEqual($0.status, .notFound) }
	}

	func testUpdateNonExistingUserReturns404() throws {
		let user = User.Create(
			username: "newuser", 
			password: "fantasticpassword", 
			confirmPassword: "fantasticpassword"
		)

		try self.app.test(
			.PUT, 
			"user/999", 
			headers: rootAuth(), 
			beforeRequest: { req in 
				try req.content.encode(user)
			}
		) { XCTAssertEqual($0.status, .notFound) }
	}

	func testDeleteNonExistingUserReturns404() throws {
		try self.app.test(
			.DELETE, 
			"user/999", 
			headers: rootAuth()
		) { XCTAssertEqual($0.status, .notFound) }
	}
}
