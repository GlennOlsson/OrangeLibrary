import Fluent

func initDatabase(db: Database) async throws {
	try await db.transaction { db in
		try await db.schema(Subscriber.schema)
			.id()
			.field("email", .string)
			.field("created_at", .datetime)
			.field("updated_at", .datetime)
			.create()


		try await db.schema(User.schema)
			.id()
			.field("username", .string)
			.field("password_hash", .string)
			.field("authority", .int8)
			.field("created_at", .datetime)
			.field("updated_at", .datetime)
			.create()
	}
}


func clearDatabase(db: Database) async throws {
	try await db.transaction { db in
		try await db.schema(Subscriber.schema).delete()

		try await db.schema(User.schema).delete()
	}
}
