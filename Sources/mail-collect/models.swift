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
