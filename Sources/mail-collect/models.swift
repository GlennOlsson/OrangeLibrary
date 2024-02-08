import Fluent
import Vapor

final class Subscriber: Model, Content {
    static let schema = "subscribers"

	 // Custom id as we are auto-incrementing the ID in the db
    @ID(custom: "id", generatedBy: .database)
    var id: Int?

    @Field(key: "email")
    var email: String

	@Timestamp(key: "created_at", on: .create)
    var createdAt: Date?

	@Timestamp(key: "updated_at", on: .update)
    var updatedAt: Date?

	// Required to be empty
    init() { }

	// Convienience init
    init(id: Int? = nil, email: String) {
        self.id = id
        self.email = email
    }
}

extension Subscriber: Validatable {
    static func validations(_ validations: inout Vapor.Validations) {
        validations.add("email", as: String.self, is: .email)
    }
}

extension Subscriber {
    final class Update: Content {
        var email: String
    }
}

extension Subscriber.Update: Validatable {
    static func validations(_ validations: inout Vapor.Validations) {
        validations.add("email", as: String.self, is: .email)
    }
}

// Action, and the associated authority required to perform the action
// A negative authority requires no user account
enum Action: Int16, CaseIterable {
    case readUser = 70 
    case updateUser = 71 // User other than themselves, must also have same or higher authority than the other user
    case createUser = 72
    case deleteUser = 73

    case createSubscriber = -1
    case readSubscriber = 50
    case updateSubscriber = 51
    case deleteSubscriber = 52

    static func maxAuthority() -> Int16 {
        Self.allCases.max(by: {$0.rawValue > $1.rawValue})?.rawValue ?? -1
    }
}

final class User: Model {
    static let schema = "users"

    @ID(custom: "id", generatedBy: .database)
    var id: Int?

    @Field(key: "user")
    var username: String

    /**
        The authority of a user defines what action the user is allowed to to. The authority
        for a user is always positive, all callers have authority 0 by default
    */
    @Field(key: "authority")
    var authority: Int16

    @Field(key: "password_hash")
    var passwordHash: String

	@Timestamp(key: "created_at", on: .create)
    var createdAt: Date?

	@Timestamp(key: "updated_at", on: .update)
    var updatedAt: Date?

    init() { }

    init(username: String, password: String, authority: Int16 = 1) throws {
        self.username = username
        self.authority = authority
        self.passwordHash = try Bcrypt.hash(password)
    }
}

extension User: ModelAuthenticatable {
    static let usernameKey = \User.$username
    static let passwordHashKey = \User.$passwordHash

    func verify(password: String) throws -> Bool {
        try Bcrypt.verify(password, created: self.passwordHash)
    }    
}

extension User {
    func canPerform(action: Action) -> Bool{
        return self.authority >= action.rawValue
    }
}
