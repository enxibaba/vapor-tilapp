import Vapor
import FluentPostgreSQL

final class Category: Codable {
    var id: Int?
    var name: String

    init(name: String) {
        self.name = name
    }
}

extension Category: PostgreSQLModel {}
extension Category: Content {}
extension Category: Migration {}
extension Category: Parameter {}

extension Category {
    var acronyms: Siblings<Category, Acronym, AcronymCategoryPivot> {
        return siblings()
    }
    
    static func addCategory(_ name: String,
                            to acronym: Acronym,
                            on req: Request) throws -> Future<Void> {
        // Perform a query to search for a category with the provided name
        return Category.query(on: req)
            .filter(\.name == name)
            .first()
            .flatMap(to: Void.self) { foundCategory in
                if let existingCategory = foundCategory {
                    // if the category exists,set up the relationship and
                    // transform to result to void.
                    return acronym.categories
                        .attach(existingCategory, on: req)
                        .transform(to: ())
                } else {
                    // if the categroy doesn't exist,create a new Category
                    // object with the provided name.
                    let category = Category(name: name)
                    // save the new category and unwrap the returned Future
                    return category.save(on: req)
                        .flatMap(to: Void.self) { savedCategory in
                            return acronym.categories
                                .attach(savedCategory, on: req)
                                .transform(to: ())
                    }
                }
        }
    }
}
