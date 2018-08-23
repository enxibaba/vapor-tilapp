import Vapor
import Fluent

/// Register your application's routes here.
public func routes(_ router: Router) throws {
    // Basic "Hello, world!" example
    router.get("hello") { _ in
        return "Hello, world!"
    }
    
    try router.register(collection: AcronymsController())
    
    // Example of configuring a controller
}
