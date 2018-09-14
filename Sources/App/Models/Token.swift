import Foundation
import Vapor
import FluentPostgreSQL
import Authentication
import Crypto

final class Token: Codable {
    var id: UUID?
    var token: String
    var userID: User.ID

    init(token: String, userID: User.ID) {
        self.token = token
        self.userID = userID
    }
}

extension Token: PostgreSQLUUIDModel {}

extension Token: Migration {
    static func prepare(on connection: PostgreSQLConnection) -> Future<Void> {
        return Database.create(self, on: connection) { builder in
            try addProperties(to: builder)
            builder.reference(from: \.userID, to: \User.id)
        }
    }
}

extension Token: Content {}

extension Token {
    // Define a static function to generate a token for a user.
    static func generate(for user: User) throws -> Token {
        // Generate 16 random bytes to act as the token.
        let random = try CryptoRandom().generateData(count: 16)
        // create a token using the base64-encoded representation
        // of the random bytes and the user's ID.
        return try Token(
                token: random.base64EncodedString(),
                userID: user.requireID())
    }
}

extension Token: Authentication.Token {
    //Define the user ID key on Token
    static let userIDKey: UserIDKey = \Token.userID
    //Tell Vapor what type the user is
    typealias UserType = User
}

// Conform Token to BearerAuthenticatable. This allows you
// to use Token with bearer authentication
extension Token: BearerAuthenticatable {
    // Tell Vapor the key path to the token key,
    // in this case,Token's token string
    static let tokenKey: TokenKey = \Token.token
}