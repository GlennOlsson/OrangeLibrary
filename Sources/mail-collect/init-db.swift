import Fluent

func initDatabase(db: Database) async throws {
	try await db.transaction { db in
		try await db.schema(Subscriber.schema)
			.field("id", .int, .identifier(auto: true))
			.field("email", .string)
			.field("real_name", .string)
			.field("created_at", .datetime)
			.field("updated_at", .datetime)
			.ignoreExisting()
			.create()


		try await db.schema(User.schema)
			.field("id", .int, .identifier(auto: true))
			.field("username", .string)
			.field("password_hash", .string)
			.field("authority", .int8)
			.field("created_at", .datetime)
			.field("updated_at", .datetime)
			.ignoreExisting()
			.create()
	}
}
