import Vapor
import Fluent

/// Register your application's routes here.
public func routes(_ router: Router) throws {
    // Basic "Hello, world!" example
    router.get("hello") { _ in
        return "Hello, world!"
    }

    try router.register(collection: AcronymsController())
    try router.register(collection: UsersController())
    try router.register(collection: CategoriesController())
    // Example of configuring a controller
}
