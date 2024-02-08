@testable import mail_collect
import XCTest
import XCTVapor

import FluentSQLiteDriver
import Logging


final class RoutesTests: XCTestCase {
	let logger = Logger(label: "routes-tester")
	
	var app: Application!

	var privilegeUser: User!
	var unprivilegeUser: User!

	override func setUp() async throws {
		try await super.setUp()

		self.app = Application(.testing)

		// In memory db
		app.databases.use(.sqlite(.memory), as: .sqlite)

		let authApp = self.app.grouped(User.authenticator())

		registerRoutes(auth: authApp, nonAuth: app)

		let db = app.db(.sqlite)

		try await initDatabase(db: db)

		self.privilegeUser = try! User(username: "privilege-user", password: "averyhardpassword", authority: 999)
		try await self.privilegeUser.create(on: db)

		self.unprivilegeUser = try! User(username: "unprivilege-user", password: "averyhardpassword", authority: 1)
		try await self.unprivilegeUser.create(on: db)

	}

	override func tearDown() async throws {
		try await super.tearDown()

		self.app.shutdown()
	}

	func testGetSubscribers() async throws {

		let request: Request = .init(application: app, on: app.eventLoopGroup.next())
		request.auth.login(self.privilegeUser)

		print("Users", try await User.query(on: self.app.db).all())


		var headers: HTTPHeaders = .init()

		let authStr = "\(self.privilegeUser.username):averyhardpassword"
		print("AuthStr", authStr)
		headers.add(name: "Authorization", value: "Basic \(authStr.base64String())")

		try self.app.test(.GET, "subscriber", headers: headers) {resp in 
			XCTAssertEqual(resp.status, .ok)
			print(try resp.body.string)
		}
	}

}
