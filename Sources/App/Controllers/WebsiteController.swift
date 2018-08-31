import Vapor
import Leaf

// Declare a new WebsiteController type that conforms to RouteCollection
struct WebsiteController: RouteCollection {
    // Implement boot(router:) as required by RouteCollection.
    func boot(router: Router) throws {
        //Register indexHandler(_:) to process GET requests to the router's
        //root path,i.e.,a request to /.
        router.get(use: indexHandler)
        router.get("acronyms", Acronym.parameter,use: acronymHandler)
    }
    
    func indexHandler(_ req: Request) throws -> Future<View> {
        
        //Use Fluent query to get all the acronyms from the database.
        return Acronym.query(on: req)
                      .all()
                      .flatMap(to: View.self) { acronyms in
                        //add the acronyms to IndexContext if there are any,
                        //otherwise set the variable to nil. This is easier for
                        //Leaf to manage than an empty array.
                        let acronymsData = acronyms.isEmpty ? nil : acronyms
                        let context = IndexContext(title: "Homepage",
                                                   acronyms: acronymsData)
                        return try req.view().render("index", context)
        }
    }
    
    func acronymHandler(_ req: Request) throws -> Future<View> {
        return try req.parameters.next(Acronym.self)
            .flatMap(to: View.self) { acronym in
                return try acronym.user
                    .get(on: req)
                    .flatMap(to: View.self) { user in
                        let context = AcronymContext(title: acronym.short,
                                                     acronym: acronym,
                                                     user: user)
                        return try req.view().render("acronym", context)
                }
        }
    }
}

struct IndexContext: Encodable {
    let title: String
    let acronyms: [Acronym]?
}

struct AcronymContext: Encodable{
    let title: String
    let acronym: Acronym
    let user: User
}
