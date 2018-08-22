import Vapor
import FluentPostgreSQL

final class Acronym: Codable {
    var id: Int?
    var short: String
    var long: String
    
    init(short: String, long: String) {
        self.short = short
        self.long = long
    }
}

extension Acronym: PostgreSQLModel {
//    typealias Database = PostgreSQLDatabase
//    typealias ID = Int
//    public static var idKey: IDKey = \Acronym.id
}

extension Acronym: Migration {}

extension Acronym: Content {}


