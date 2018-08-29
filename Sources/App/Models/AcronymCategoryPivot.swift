import FluentPostgreSQL
import Foundation

final class AcronymCategoryPivot: PostgreSQLUUIDPivot {
    
    var id: UUID?
    
    var acronymID: Acronym.ID
    var categoryID: Category.ID
    
    typealias Left = Acronym
    typealias Right = Category
    
    static let leftIDKey: LeftIDKey = \.acronymID
    static let rightIDKey: RightIDKey = \.categoryID
    
    init(_ acronymID: Acronym.ID, _ categoryID: Category.ID) {
        self.acronymID = acronymID
        self.categoryID = categoryID
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
            try builder.reference(from: \.acronymID, to: \Acronym.id)
            // Add a reference between the categroyID property on AcronymCategoryPivot and the
            // id property on Category. This sets up the foreign key constraint
            try builder.reference(from: \.categoryID,
                to: \Category.id)
        }
    }
}
