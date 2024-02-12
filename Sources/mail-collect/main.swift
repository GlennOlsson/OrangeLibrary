import Vapor
import Foundation

var env = try Environment.detect()
try LoggingSystem.bootstrap(from: &env)

let app = Application(env)

configure(app)

try! app.run()
