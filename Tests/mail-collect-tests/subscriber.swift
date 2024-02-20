@testable import mail_collect
import XCTest
import XCTVapor

import FluentSQLiteDriver
import Logging


final class SubscriberTests: XCTestCase {
	let logger = Logger(label: "subsriber-tester")
	
	var app: Application!

	var privilegeUser: User!
	var privilegeUserPassword: String = "averyhardpassword"
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

		self.privilegeUser = try! User(username: "privilege-user", password: self.privilegeUserPassword, authority: 999)
		try await self.privilegeUser.create(on: db)

		self.unprivilegeUser = try! User(username: "unprivilege-user", password: "averyhardpassword", authority: 1)
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

	func privilegeAuthHeader() -> HTTPHeaders {
		return _authHeader(username: self.privilegeUser.username, password: self.privilegeUserPassword)
	}

	func unprivilegeAuthHeader() -> HTTPHeaders {
		return _authHeader(username: self.unprivilegeUser.username, password: self.unprivilegeUserPassword)
	}

	func testGetSubscribersIsEmpty() async throws {
		try self.app.test(.GET, "subscriber", headers: privilegeAuthHeader()) {resp in 
			XCTAssertEqual(resp.status, .ok)
			
			let subscribers = try resp.content.decode([Subscriber].self)
			XCTAssertEqual(subscribers.count, 0)
		}
	}

	func testGetSubscribersReturnsSubscribers() async throws {
		let sub1 = Subscriber(email: "someemail@gmail.com", name: "Some Realname")
		let sub2 = Subscriber(email: "someotheremail@gmail.com", name: "Some Realname")

		let auth = privilegeAuthHeader()

		try self.app.test(.POST, "subscriber", beforeRequest: { try $0.content.encode(sub1) })
		try self.app.test(.POST, "subscriber", beforeRequest: { try $0.content.encode(sub2) })

		try self.app.test(.GET, "subscriber", headers: auth) { resp in
			XCTAssertEqual(resp.status, .ok)

			let subscribers = try resp.content.decode([Subscriber].self)
			XCTAssertEqual(subscribers.count, 2)
		
			XCTAssert(subscribers.contains(where: { $0.email == sub1.email }))
			XCTAssert(subscribers.contains(where: { $0.email == sub2.email }))
		}
	}

	func testGetCreated() throws {
		let sub = Subscriber(email: "someemail@gmail.com", name: "Some Realname")

		var createdSubscriber: Subscriber!
		try self.app.test(.POST, "subscriber", beforeRequest: { try $0.content.encode(sub) }) {resp in
			createdSubscriber = try resp.content.decode(Subscriber.self)
		}

		XCTAssertEqual(sub.email, createdSubscriber.email)
		XCTAssertEqual(sub.name, createdSubscriber.name)

		try self.app.test(
			.GET, 
			"subscriber/\(createdSubscriber.id!)", 
			headers: self.privilegeAuthHeader(), 
			beforeRequest: { try $0.content.encode(sub) }
		) {resp in 
			let gottenSubscriber = try resp.content.decode(Subscriber.self)

			XCTAssertEqual(createdSubscriber, gottenSubscriber)
		}
	}

	func testCreateWithExistingEmailFails() throws {
		let sub = Subscriber(email: "someemail@gmail.com", name: "Some Realname")

		try self.app.test(.POST, "subscriber", beforeRequest: { try $0.content.encode(sub) })

		try self.app.test(.POST, "subscriber", beforeRequest: { try $0.content.encode(sub) }) { resp in 
			XCTAssertEqual(resp.status, .badRequest)
		}
	}

	// Assert that we can update the email of a subscriber
	func testUpdateSubscriber() throws {
		let sub = Subscriber(email: "someemail@gmail.com", name: "Some Realname")

		var createdSubscriber: Subscriber!
		try self.app.test(.POST, "subscriber", beforeRequest: { try $0.content.encode(sub) }) {resp in
			createdSubscriber = try resp.content.decode(Subscriber.self)
		}

		let auth = privilegeAuthHeader()

		let updatedSubscriber = Subscriber(email: "someotheremail@gmail.com", name: "New Realname")

		// Make sure we're updating with new email
		XCTAssertNotEqual(createdSubscriber.email, updatedSubscriber.email)
		XCTAssertNotEqual(createdSubscriber.name, updatedSubscriber.name)

		try self.app.test(.PUT, "subscriber/\(createdSubscriber.id!)", headers: auth, beforeRequest: { req in
			try req.content.encode(updatedSubscriber)
		}) { resp in
			let newSubscriber = try resp.content.decode(Subscriber.self)

			XCTAssertEqual(newSubscriber.email, updatedSubscriber.email)
		}
	}

	func testUpdateWithExistingEmailFails() throws {
		let sub1 = Subscriber(email: "someemail@gmail.com", name: "Some Realname")
		let sub2 = Subscriber(email: "someotheremail@gmail.com", name: "Some Realname")

		var sub1ID: Int!

		// Create both separately
		try self.app.test(.POST, "subscriber", beforeRequest: { try $0.content.encode(sub1) }) { resp in 
			XCTAssertEqual(resp.status, .ok)

			let sub = try resp.content.decode(Subscriber.self)

			sub1ID = sub.id!
		}

		try self.app.test(.POST, "subscriber", beforeRequest: { try $0.content.encode(sub2) }) { resp in 
			XCTAssertEqual(resp.status, .ok)
		}

		// Update sub1 with sub2 email
		try self.app.test(.PUT, "subscriber/\(sub1ID!)", headers: privilegeAuthHeader(), beforeRequest: { try $0.content.encode(sub2) }) { resp in 
			XCTAssertEqual(resp.status, .badRequest)
		}
	}

	func testGetNonExistingSubscriberReturns404() throws {
		try self.app.test(.GET, "subscriber/999", headers: privilegeAuthHeader()) { resp in
			XCTAssertEqual(resp.status, .notFound)
		}
	}

	func testDeleteNonExistingSubscriberReturns404() throws {
		try self.app.test(.DELETE, "subscriber/999", headers: privilegeAuthHeader()) { resp in
			XCTAssertEqual(resp.status, .notFound)
		}
	}

	func testGetDeletedSubscriberReturns404() throws {
		let sub = Subscriber(email: "someemail@gmail.com", name: "Some Realname")

		var receivedSubscriber: Subscriber!
		try self.app.test(.POST, "subscriber", beforeRequest: { try $0.content.encode(sub) }) {resp in 
			receivedSubscriber = try resp.content.decode(Subscriber.self)
		}

		try self.app.test(.DELETE, "subscriber/\(receivedSubscriber.id!)", headers: privilegeAuthHeader()) { resp in
			XCTAssertEqual(resp.status, .ok)
		}

		try self.app.test(.GET, "subscriber/\(receivedSubscriber.id!)", headers: privilegeAuthHeader()) { resp in
			XCTAssertEqual(resp.status, .notFound)
		}
	}

	func performTestUnathorized(_ method: HTTPMethod, _ endpoint: String, headers: HTTPHeaders = [:]) throws {
		try self.app.test(method, endpoint, headers: headers) { resp in
			XCTAssertEqual(resp.status, .unauthorized)
		}
	}

	func performTestAllUnathorized(_ method: HTTPMethod, _ endpoint: String) throws {
		// No auth header
		try performTestUnathorized(method, endpoint)
		// Unprivileged user
		try performTestUnathorized(method, endpoint, headers: self.unprivilegeAuthHeader())
		// Non-existing account
		try performTestUnathorized(method, endpoint, headers: self._authHeader(username: "fakeuser", password: "fakepass"))
	}

	func testGetSubscribersIsUnauthorized() throws {
		try performTestAllUnathorized(.GET, "subscriber")
	}
	
	func testGetSubscriberIsUnauthorized() throws {
		try performTestAllUnathorized(.GET, "subscriber/1")
	}

	func testUpdateSubscriberIsUnauthorized() throws {
		try performTestAllUnathorized(.PUT, "subscriber/1")
	}

	func testDeleteSubscriberIsUnauthorized() throws {
		try performTestAllUnathorized(.DELETE, "subscriber/1")
	}

}
