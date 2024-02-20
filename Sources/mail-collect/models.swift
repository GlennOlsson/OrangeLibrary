import Fluent
import Vapor

final class Subscriber: Model, Content, Encodable {
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

extension Subscriber: Equatable {
    static func == (lhs: Subscriber, rhs: Subscriber) -> Bool {
        return lhs.id == rhs.id && lhs.email == rhs.email
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
        Self.allCases.max(by: {$0.rawValue < $1.rawValue})?.rawValue ?? -1
    }
}

final class User: Model, Encodable {
    static let schema = "users"

    @ID(custom: "id", generatedBy: .database)
    var id: Int?

    @Field(key: "username")
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

    /**
        Default authority is 1
    */
    init(username: String, password: String, authority: Int16? = nil) throws {
        self.username = username
        self.authority = authority ?? 1
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

extension User {
    final class Create: Content {
        var username: String
        var password: String
        var confirmPassword: String
        var authority: Int16? = nil

        init(username: String, password: String, confirmPassword: String, authority: Int16? = nil) {
            self.username = username
            self.password = password
            self.confirmPassword = confirmPassword
            self.authority = authority
        }
    }
}

extension User.Create: Validatable {
    static func validations(_ validations: inout Vapor.Validations) {
        validations.add("username", as: String.self, is: !.empty)
        validations.add("password", as: String.self, is: .count(8...30))
        validations.add("confirmPassword", as: String.self, is: !.empty)
    }
}

extension User {
    final class Update: Content {
        var username: String? = nil
        var password: String? = nil
        var authority: Int16? = nil
    }
}

extension User {
    /**
        Update the current instance with the provided fields. Returns wether or not
        any field was updated
    */
    func update(with update: User.Update) throws -> Bool{
        var change = false
        if(update.username != nil) {
            self.username = update.username!
            change = true
        }
        if(update.password != nil) {
            self.passwordHash = try Bcrypt.hash(update.password!)
            change = true
        }
        if(update.authority != nil) {
            self.authority = update.authority!
            change = true
        }
        return change
    }
}

extension User {
    struct Response: Content {
        let id: Int
        let username: String
        let authority: Int16
        let createdAt: Date?
        let updatedAt: Date?
    }
}

extension User {
    var response: User.Response {
        return User.Response(
            id: self.id ?? -1, 
            username: self.username, 
            authority: self.authority, 
            createdAt: self.createdAt, 
            updatedAt: self.updatedAt
        )
    }
}


struct ViewParameters: Encodable {
	let subscribers: [Subscriber]
    let user: User
};
