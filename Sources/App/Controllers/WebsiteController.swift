import Vapor
import Leaf
import Fluent

// Declare a new WebsiteController type that conforms to RouteCollection
struct WebsiteController: RouteCollection {
    // Implement boot(router:) as required by RouteCollection.
    func boot(router: Router) throws {
        //Register indexHandler(_:) to process GET requests to the router's
        //root path,i.e.,a request to /.
        router.get(use: indexHandler)
        router.get("acronyms", Acronym.parameter, use: acronymHandler)
        router.get("users", User.parameter, use: userHandler)
        router.get("users", use: allUsersHandler)
        router.get("categories", use: allCategoriesHandler)
        router.get("categories", Category.parameter, use: categoryHandler)
        router.get("acronyms", "create", use: createAcronymHandler)
        //router.post(Acronym.self, at: "acronyms", "create", use: createAcronymPostHandler)
        router.get("acronyms", Acronym.parameter, "edit", use: editAcronymHandler)
        router.post("acronyms", Acronym.parameter, "edit", use: editAcronymPostHandler)
        router.post("acronyms", Acronym.parameter, "delete", use: deleteAcronymHandler)
        router.post(CreateAcronymData.self, at: "acronyms", "create", use: createAcronymPostHandler)
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
                return acronym.user
                    .get(on: req)
                    .flatMap(to: View.self) { user in
                        let categories = try acronym.categories.query(on: req).all()
                        let context = AcronymContext(title: acronym.short,
                                                     acronym: acronym,
                                                     user: user,
                                                     categories: categories)
                        return try req.view().render("acronym", context)
                }
        }
    }

    func userHandler(_ req: Request) throws -> Future<View> {

        return try req.parameters.next(User.self)
            .flatMap(to: View.self) { user in
                return try user.acronyms
                    .query(on: req)
                    .all()
                    .flatMap(to: View.self) { acronyms in
                        let context = UserContext(
                        title: user.name,
                        user: user,
                        acronyms: acronyms)
                        return try req.view().render("user", context)
                }
        }
    }

    func allUsersHandler(_ req: Request) throws -> Future<View> {
        return User.query(on: req)
                       .all()
                       .flatMap(to: View.self) { users in
                            let context = AllUsersContext(title: "All users", users: users)
                            return try req.view().render("allUsers", context)
                       }
    }

    func allCategoriesHandler(_ req: Request) throws -> Future<View> {
        let categories = Category.query(on: req).all()
        let context = AllCategoriesContext(categories: categories)

        return try req.view().render("allCategories", context)
    }

    func categoryHandler(_ req: Request) throws -> Future<View> {
        return try req.parameters.next(Category.self)
            .flatMap(to: View.self) { category in
                let acronyms = try category.acronyms.query(on: req).all()
                let context = CategoryContext(
                        title: category.name,
                        category: category,
                        acronyms: acronyms)
                    return try req.view().render("category", context)
           }
    }

    func createAcronymHandler(_ req: Request) throws -> Future<View> {
        let context = CreateAcronymContext(
            users: User.query(on: req).all())

        return try req.view().render("createAcronym", context)
    }
    // change the content type of route handler to accept CreateAcronymData.
    func createAcronymPostHandler(_ req: Request, data: CreateAcronymData) throws -> Future<Response> {
        //create an acronym object to save as it's no longer passed into the  route
        let acronym = Acronym(
            short: data.short,
            long: data.long,
            userID: data.userID
        )
        //call flatMap(to:) instead of map(to:) as you now return a Future<Response> in the closure
        return acronym.save(on: req).flatMap(to: Response.self) { acronym in
            guard let id = acronym.id else {
                throw Abort(.internalServerError)
            }
            //define an array of Futures to store the save operations
            var categorySaves: [Future<Void>] = []
            //Loop through all the categories provided to the request and 
            //add the resluts of Category.addCategory(_ to:on:) to the array
            for category in data.categories ?? [] {
                try categorySaves.append(Category.addCategory(category, to: acronym, on: req))
            }
            //Flatten the array to complete all the Fluent operations
            //and transform the reslut to a Response.Rediect the page
            //to the new acronym's page.
            let redirect = req.redirect(to: "/acronyms/\(id)")
            return categorySaves.flatten(on: req)
                .transform(to: redirect)
        }
    }

    func editAcronymHandler(_ req: Request) throws -> Future<View> {
        return try req.parameters.next(Acronym.self)
            .flatMap(to: View.self) { acronym in
                let users = User.query(on: req).all()
                let categories = try acronym.categories.query(on: req).all()
                
                let context = EditAcronymContext(
                    acronym: acronym,
                    users: users,
                    categories: categories)

                return try req.view().render("createAcronym", context)
            }
    }

    func editAcronymPostHandler(_ req: Request) throws -> Future<Response> {
        //1 Change the content type the request decodes to CreateAcronymData.
        return try flatMap(
            to: Response.self,
            req.parameters.next(Acronym.self),
            req.content.decode(CreateAcronymData.self)
        ) { acronym, data in

            acronym.short = data.short
            acronym.long = data.long
            acronym.userID = data.userID
            //2 Use flatMap(to:) on save(on:) since the closure now return a future
            return acronym.save(on: req)
                .flatMap(to: Response.self) { savedAcronym in
                    guard let id = savedAcronym.id else {
                        throw Abort(.internalServerError)
                    }
                    //return req.redirect(to: "/acronyms/\(id)")
                    //3 get all categories from the database 
                    return try acronym.categories.query(on: req).all()
                        .flatMap(to: Response.self) { existingCategories in
                            //4 create an array of category names from the categories in the database
                            let existingStringArray = existingCategories.map { $0.name }
                            //5 create a set for the categories in the database and another 
                            //for the categories supplied with the request
                            let existingSet = Set<String>(existingStringArray)
                            let newSet = Set<String>(data.categories ?? [])
                            //6 Calculate the categories to add to the acronym and the
                            // categories to remove
                            let categoriesToAdd = newSet.subtracting(existingSet)
                            let categoriesToRemove = existingSet.subtracting(newSet)
                            //7 create an array of category operation resluts.
                            var categoryResults: [Future<Void>] = []
                            //8 Loop through all the categories to add and call Category.addCategory(_:to:on:)
                            // to set up the relationship. Add each reslut to the resluts array. 
                            for newCategory in categoriesToAdd {
                                categoryResults.append(
                                    try Category.addCategory(
                                        newCategory,
                                        to: acronym,
                                        on: req))
                            }
                            //9 Loop through all the categories to remove from the acronym
                            for categoryNameToRemove in categoriesToRemove {
                                //10 Get the category object from the name of the remove
                                let categoryToRemove = existingCategories.first {
                                    $0.name == categoryNameToRemove
                                }
                                //11 if the category object exists,use detach(_:on:)
                                //to remove the relationship and delete the pivot
                                if let category = categoryToRemove {
                                    categoryResults.append(
                                        acronym.categories.detach(category, on: req))
                                }
                            }
                        //12 Flatten all the future category resluts.Transform the
                        //reslut to redirect to the updated acronym's page.
                            return categoryResults
                                .flatten(on: req)
                                .transform(to: req.redirect(to: "/acronyms/\(id)"))
                        }
                }
        }
    }

    func deleteAcronymHandler(_ req: Request) throws -> Future<Response> {
        return try req.parameters.next(Acronym.self)
            .delete(on: req)
            .transform(to: req.redirect(to: "/"))
    }
 }

struct IndexContext: Encodable {
    let title: String
    let acronyms: [Acronym]?
}

struct AcronymContext: Encodable {
    let title: String
    let acronym: Acronym
    let user: User
    let categories: Future<[Category]>
}

struct UserContext: Encodable {
    let title: String
    let user: User
    let acronyms: [Acronym]
}

struct AllUsersContext: Encodable {
    let title: String
    let users: [User]
}

struct AllCategoriesContext: Encodable {
    let title = "All Categories"
    let categories: Future<[Category]>
}

struct CategoryContext: Encodable {
    let title: String
    let category: Category
    let acronyms: Future<[Acronym]>
}

struct CreateAcronymContext: Encodable {
    let title = "Create An Acronym"
    let users: Future<[User]>
}

struct EditAcronymContext: Encodable {
    let title = "Edit Acronym"
    let acronym: Acronym
    let users: Future<[User]>
    let editing = true
    let categories: Future<[Category]>
}

struct CreateAcronymData: Content {
    let userID: User.ID
    let short: String
    let long: String
    let categories: [String]?
}
