@testable import mail_collect
import Fluent

func clearDatabase(db: Database) async throws {
	try await db.transaction { db in
		try await db.schema(Subscriber.schema).delete()

		try await db.schema(User.schema).delete()
	}
}
