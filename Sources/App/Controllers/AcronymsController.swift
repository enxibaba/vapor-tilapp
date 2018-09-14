import Vapor
import Fluent
import Authentication

struct AcronymsController: RouteCollection {
    func boot(router: Router) throws {

        let acronymsRoutes = router.grouped("api", "acronyms")

        acronymsRoutes.get(use: getAllHandle)
        acronymsRoutes.get(Acronym.parameter, use: getHandle)
        acronymsRoutes.get("search", use: searchHander)
        acronymsRoutes.get("first", use: getFirstHandler)
        acronymsRoutes.get("sorted", use: sortedHandler)
        acronymsRoutes.get(Acronym.parameter, "user", use: getUserHandler)
        acronymsRoutes.get(Acronym.parameter, "categories", use: getCategoriesHandler)


        let tokenAuthMiddleware = User.tokenAuthMiddleware()
        let guardAuthMiddleware = User.guardAuthMiddleware()

        let tokenAuthGroup = acronymsRoutes.grouped(
                tokenAuthMiddleware,
                guardAuthMiddleware)

        tokenAuthGroup.post(AcronymCreateData.self, use: createHandler)
        tokenAuthGroup.put(Acronym.parameter, use: updateHandler)
        tokenAuthGroup.delete(Acronym.parameter, use: delectHandler)
        tokenAuthGroup.post(
                Acronym.parameter,
                "categories",
                Category.parameter,
                use: addCategoriesHandler)
        tokenAuthGroup.delete(
                Acronym.parameter,
                "categories",
                Category.parameter,
                use: removeCategoriesHandler)

    }

    func getAllHandle(_ req: Request) throws -> Future<[Acronym]> {
        return Acronym.query(on: req).all()
    }
    // Define a route handler that accepts AcronymCreateData as
    // the request body.
    func createHandler(_ req: Request, data: AcronymCreateData) throws -> Future<Acronym> {
        // Get the authenticated user from the request.
        let user = try req.requireAuthenticated(User.self)
        // create a new acronym using the data from the request
        // and the authenticated user.
        let acronym = try Acronym(
                short: data.short,
                long: data.long,
                userID: user.requireID())

        return acronym.save(on: req)
    }

    func getHandle(_ req: Request) throws -> Future<Acronym> {
        return try req.parameters.next(Acronym.self)
    }

    func updateHandler(_ req: Request) throws -> Future<Acronym> {
        // Decode the request's data to AcronymCreateData since
        // request no longer contains the user's ID in the post data.
        return try flatMap(to: Acronym.self,
                           req.parameters.next(Acronym.self),
                           req.content.decode(AcronymCreateData.self)) { acronym, updatedData in
                            acronym.short = updatedData.short
                            acronym.long = updatedData.long
                            //Get the authenticated user from the request and use
                            //that to update the acronym
                            let user = try req.requireAuthenticated(User.self)
                            acronym.userID = user.requireID()
                            return acronym.save(on: req)
        }
    }

    func delectHandler(_ req: Request) throws -> Future<HTTPStatus> {
        return try req.parameters.next(Acronym.self)
            .delete(on: req)
            .transform(to: HTTPStatus.noContent)
    }

    func searchHander(_ req: Request) throws -> Future<[Acronym]> {
        guard let searchTerm = req.query[String.self, at: "term"] else {
            throw Abort(.badRequest)
        }

        return Acronym.query(on: req)
            .filter(\.short == searchTerm)
            .filter(\.long == searchTerm)
            .all()
    }

    func getFirstHandler(_ req: Request) throws-> Future<Acronym> {
        return Acronym.query(on: req)
            .first()
            .map(to: Acronym.self) { acronym in
                guard let acronym = acronym else {
                    throw Abort(.notFound)
                }
                return acronym
        }
    }

    func sortedHandler(_ req: Request) throws -> Future<[Acronym]> {
        return Acronym.query(on: req)
            .sort(\.short, .ascending)
            .all()
    }
    
    func getUserHandler(_ req: Request) throws -> Future<User.Public> {
        return try req.parameters.next(Acronym.self)
            .flatMap(to: User.Public.self) { acronym in
                 acronym.user.get(on: req).convertToPublic()
        }
    }

    func addCategoriesHandler(_ req: Request) throws -> Future<HTTPStatus> {
        return try flatMap(to: HTTPStatus.self,
                           req.parameters.next(Acronym.self),
                           req.parameters.next(Category.self)) { acronym, category in
                            
                            let pivot = try AcronymCategoryPivot(acronym,
                                                                category)
                            return pivot.save(on: req)
                                        .transform(to: .created)
        }
    }
    
    func getCategoriesHandler(_ req: Request) throws -> Future<[Category]> {
        return try req.parameters.next(Acronym.self)
            .flatMap(to: [Category].self) { acronym in
                try acronym.categories.query(on: req).all()
        }
    }

    func removeCategoriesHandler(_ req: Request) throws -> Future<HTTPStatus> {
        //
        return try flatMap(
                to: HTTPStatus.self,
                req.parameters.next(Acronym.self),
                req.parameters.next(Category.self)
        ) { acronym, category in
            //
            return acronym.categories
                .detach(category, on: req)
                .transform(to: .noContent)
        }
    }
}

struct AcronymCreateData: Content {
    let short: String
    let long: String
}

//router.get("api", "acronyms", "first") { req -> Future<Acronym> in
//    return try Acronym.query(on: req).first().map(to: Acronym.self) { acronym in
//        guard let acronym = acronym else {
//            throw Abort(.notFound)
//        }
//        return acronym
//    }
//}
//
//router.get("api", "acronyms", "sorted") { req -> Future<[Acronym]> in
//    return try Acronym.query(on: req)
//        .sort(\.short, .ascending)
//        .all()
//}
