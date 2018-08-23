import Vapor
import Fluent

struct AcronymsController: RouteCollection {
    func boot(router: Router) throws {
        let acronymsRoutes = router.grouped("api", "acronyms")
        
        acronymsRoutes.post(Acronym.self, use: createHandler)
        acronymsRoutes.get(use: getAllHandle)
        acronymsRoutes.put(Acronym.parameter, use: updateHandler)
        acronymsRoutes.get(Acronym.parameter, use: getHandle)
        acronymsRoutes.delete(Acronym.parameter, use: delectHandler)
        acronymsRoutes.get("search", use: searchHander)
        acronymsRoutes.get("first", use: getFirstHandler)
        acronymsRoutes.get("sorted", use: sortedHandler)
    }
    
    func getAllHandle(_ req: Request) throws -> Future<[Acronym]> {
        return Acronym.query(on: req).all()
    }
    
    func createHandler(_ req: Request, acronym: Acronym) throws -> Future<Acronym> {
//        return try req.content.decode(Acronym.self)
//            .flatMap(to: Acronym.self) { acronym in
//                acronym.save(on: req)
//        }
        return acronym.save(on: req)
    }
    
    func getHandle(_ req: Request) throws -> Future<Acronym> {
        return try req.parameters.next(Acronym.self)
    }
    
    func updateHandler(_ req: Request) throws -> Future<Acronym> {
        return try flatMap(to: Acronym.self,
                           req.parameters.next(Acronym.self),
                           req.content.decode(Acronym.self)) { acronym, updatedAcronym in
                            acronym.short = updatedAcronym.short
                            acronym.long = updatedAcronym.long
                            
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
        
        return try Acronym.query(on: req)
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
        return try Acronym.query(on: req)
            .sort(\.short, .ascending)
            .all()
    }
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
