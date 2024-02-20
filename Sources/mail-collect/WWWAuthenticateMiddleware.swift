import Vapor

let REALM_NAME = "subscriber"

/**
	Adds a WWW-Authentication header to requests with unauthorized response with the global realm
*/
class WWWAuthenticationMiddleware: AsyncMiddleware {
   	func respond(to request: Request, chainingTo next: AsyncResponder) async throws -> Response {
		do {
			return try await next.respond(to: request)
		} catch var error as Abort {
			if error.status == .unauthorized {
				error.headers.add(name: .wwwAuthenticate, value: "Basic realm=\(REALM_NAME), charset=\"UTF-8\"")
			}
			throw error
		}
    }
}
