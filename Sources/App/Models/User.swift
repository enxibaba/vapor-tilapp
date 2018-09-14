import Foundation
import Vapor
import FluentPostgreSQL
import Authentication

final class User: Codable {
    var id: UUID?
    var name: String
    var username: String
    var password: String

    init(name: String, username: String, password: String) {
        self.name = name
        self.username = username
        self.password = password
    }
    
    final class Public: Codable {
        var id: UUID?
        var name: String
        var username: String
        
        init(id: UUID?, name: String, username: String) {
            self.id = id
            self.name = name
            self.username = username
        }
    }

}



extension User: PostgreSQLUUIDModel {}
extension User: Content {}
extension User: Parameter {}
extension User.Public: Content {}
extension User: Migration {
    static func prepare(on connection: PostgreSQLConnection) -> Future<Void> {
        // create the user table
        return Database.create(self, on: connection) { builder in
            // Add all the columns to the user table using user's properties
            try addProperties(to: builder)
            // add a unique index to username on user
            builder.unique(on: \.username)
        }
    }
}
extension User {
    var acronyms: Children<User, Acronym> {
        return children(\.userID)
    }
}

extension User {
    //define a method on User that returns User.Public
    func convertToPublic() -> User.Public {
        //Create a public version of the current object
        return User.Public(id: id, name: name, username: username)
    }
}
// Define an extension for Future<User>
extension Future where T: User {
    // Define a new method that returens a Future<User.Public>
    func convertToPublic() -> Future<User.Public> {
        // Unwrap the user contained in self
        return self.map(to: User.Public.self) { user in
            // Convert the User object to User.Public
            return user.convertToPublic()
        }
    }
}

extension User: BasicAuthenticatable {
    // Tell Vapor which propery of User is the username.
    static let usernameKey: UsernameKey = \User.username
    // Tell Vapor which propery of User is the password
    static let passwordKey: PasswordKey = \User.password
}

extension User: TokenAuthenticatable {
    //
    typealias TokenType = Token
}

struct AdminUser: Migration {
    // Define which database type this migration is for
    typealias Database = PostgreSQLDatabase
    // Implement the required prepare(on:)
    static func prepare(on connection: PostgreSQLConnection) -> Future<Void> {
        // create a password hash and terminate with a fatal error
        // if this fails.
        let password = try? BCrypt.hash("password")
        guard  let hasedPassword = password else {
            fatalError("Failed to create admin user")
        }
        //
        let user = User(
                name: "Admin",
                username: "admin",
                password: hasedPassword)
        //
        return user.save(on: connection).transform(to: ())
    }
    // Implement the required revert(on:). done(on:) returns
    // a pre-completed
    static func revert(on connection: PostgreSQLConnection) -> Future<Void> {
        return .done(on: connection)
    }
}