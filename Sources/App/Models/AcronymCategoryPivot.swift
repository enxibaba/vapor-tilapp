import FluentPostgreSQL
import Foundation

final class AcronymCategoryPivot: PostgreSQLUUIDPivot, ModifiablePivot {

    var id: UUID?

    var acronymID: Acronym.ID
    var categoryID: Category.ID

    typealias Left = Acronym
    typealias Right = Category

    static let leftIDKey: LeftIDKey = \.acronymID
    static let rightIDKey: RightIDKey = \.categoryID

    init(_ acronym: Acronym, _ category: Category) throws {
        self.acronymID = try acronym.requireID()
        self.categoryID = try category.requireID()
    }

}

// conform AcronymCategoryPivot to Migration
extension AcronymCategoryPivot: Migration {
    // Implement prepare(on:) as define by Migration. This overrides the default implementation
    static func prepare(on connection: PostgreSQLConnection) -> Future<Void> {
        // Create the table for AcronymCategoryPivot in the database
        return Database.create(self, on: connection) { builder in
            // Use addProperties(to:) to add all the fields to the database
            try addProperties(to: builder)
            // Add a reference between the acronymID property on AcronymCategoryPivot and the
            // id property on Acronym. This sets up the foreign key constraint
            builder.reference(from: \.acronymID, to: \Acronym.id, onDelete: .cascade)
            // Add a reference between the categroyID property on AcronymCategoryPivot and the
            // id property on Category. This sets up the foreign key constraint
            builder.reference(from: \.categoryID, to: \Category.id, onDelete: .cascade)
        }
    }
}
