import Vapor
import Fluent

// MARK: - User

final class User: Model, Content {
    static let schema = "User"
    
    @ID(custom: "id")
    var id: Int?
    
    @Field(key: "username")
    var username: String
    
    @Field(key: "password_hash")
    var passwordHash: String
    
    @Field(key: "salt")
    var salt: String
    
    @Field(key: "public_key")
    var publicKey: String
    
    init() {}
    
    init(id: Int? = nil, username: String, passwordHash: String, salt: String, publicKey: String) {
        self.id = id
        self.username = username
        self.passwordHash = passwordHash
        self.salt = salt
        self.publicKey = publicKey
    }
}

// MARK: - Address

final class Address: Model, Content {
    static let schema = "Address"
    
    @ID(custom: "id")
    var id: Int?
    
    @Field(key: "user_id")
    var userId: Int
    
    @Field(key: "address")
    var address: String
    
    init() {}
    
    init(id: Int? = nil, userId: Int, address: String) {
        self.id = id
        self.userId = userId
        self.address = address
    }
}

// MARK: - Transaction

final class Transaction: Model, Content {
    static let schema = "Transaction"
    
    @ID(custom: "id")
    var id: Int?
    
    @Field(key: "from_address_id")
    var fromAddressID: Int
    
    @Field(key: "to_address_id")
    var toAddressID: Int
    
    @Field(key: "amount")
    var amount: Decimal
    
    @Field(key: "timestamp")
    var timestamp: Date
    
    @Field(key: "hash")
    var hash: String
    
    init() {}
    
    init(id: Int? = nil, fromAddressID: Int, toAddressID: Int, amount: Decimal, timestamp: Date, hash: String) {
        self.id = id
        self.fromAddressID = fromAddressID
        self.toAddressID = toAddressID
        self.amount = amount
        self.timestamp = timestamp
        self.hash = hash
    }
}

// MARK: - Block

final class Block: Model, Content {
    static let schema = "Block"
    
    @ID(custom: "id")
    var id: Int?
    
    @Field(key: "version")
    var version: Int
    
    @Field(key: "timestamp")
    var timestamp: Date
    
    @Field(key: "previous_hash")
    var previousHash: String
    
    @Field(key: "merkle_root")
    var merkleRoot: String
    
    @Field(key: "nonce")
    var nonce: Int
    
    @Field(key: "hash")
    var hash: String
    
    init() {}
    
    init(id: Int? = nil, version: Int, timestamp: Date, previousHash: String, merkleRoot: String, difficulty: Int, nonce: Int, hash: String) {
        self.id = id
        self.version = version
        self.timestamp = timestamp
        self.previousHash = previousHash
        self.merkleRoot = merkleRoot
        self.nonce = nonce
        self.hash = hash
    }
}

// MARK: - BlockTransaction
final class BlockTransaction: Model, Content {
    static let schema = "BlockTransaction"
    
    @ID(custom: "id")
    var id: Int?
    
    @Field(key: "block_id")
    var blockID: Int
    
    @Field(key: "transaction_id")
    var transactionID: Int
    
    init() {}
    
    init(id: Int? = nil, blockID: Int, transactionID: Int) {
        self.id = id
        self.blockID = blockID
        self.transactionID = transactionID
    }
}

// MARK: - Migration

struct CreateTables: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        database.schema("User")
            .id()
            .field("username", .string, .required)
            .field("password_hash", .string, .required)
            .field("salt", .string, .required)
            .field("public_key", .string, .required)
            .create()
        
        database.schema("Address")
            .id()
            .field("user_id", .int, .required)
            .field("address", .string, .required)
            .create()
        
        database.schema("Transaction")
            .id()
            .field("from_address_id", .int, .required)
            .field("to_address_id", .int, .required)
            .field("amount", .double, .required)
            .field("timestamp", .datetime, .required)
            .field("hash", .string, .required)
            .create()
        
        database.schema("Block")
            .id()
            .field("version", .int, .required)
            .field("timestamp", .datetime, .required)
            .field("previous_hash", .string, .required)
            .field("merkle_root", .string, .required)
            .field("difficulty", .int, .required)
            .field("nonce", .int, .required)
            .field("hash", .string, .required)
            .create()
        
        database.schema("BlockTransaction")
            .id()
            .field("block_id", .int, .required)
            .field("transaction_id", .int, .required)
            .create()
        
        return database.schema("User")
            .field("id", .int, .identifier(auto: true))
            .create()
    }
    
    func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema("User").delete()
        database.schema("Address").delete()
        database.schema("Transaction").delete()
        database.schema("Block").delete()
        database.schema("BlockTransaction").delete()
        return database.eventLoop.future()
    }
}

// MARK: - Routes

func routes(_ app: Application) throws {
    app.post("user") { req -> EventLoopFuture<User> in
        let user = try req.content.decode(User.self)
        return user.create(on: req.db).map { user }
    }
    
    app.get("user", ":id") { req -> EventLoopFuture<User> in
        guard let userID = req.parameters.get("id", as: Int.self) else {
            throw Abort(.badRequest)
        }
        return User.find(userID, on: req.db)
            .unwrap(or: Abort(.notFound))
    }
    
    app.post("address") { req -> EventLoopFuture<Address> in
        let address = try req.content.decode(Address.self)
        return address.create(on: req.db).map { address }
    }
    
    app.get("address", ":id") { req -> EventLoopFuture<Address> in
        guard let addressID = req.parameters.get("id", as: Int.self) else {
            throw Abort(.badRequest)
        }
        return Address.find(addressID, on: req.db)
            .unwrap(or: Abort(.notFound))
    }
    
    // Route to generate the Merkle tree hash
    app.get("merkleTreeHash") { req -> String in
        // Generate the Merkle tree hash
        let merkleTree = MerkleTree()
        let merkleTreeHash = merkleTree.generateHash()
        return merkleTreeHash
    }
    
    // Route to generate a Merkle tree proof item
    app.get("merkleTreeProofitem", ":index") { req -> String in
        // Get the index parameter from the request
        guard let index = req.parameters.get("index", as: Int.self) else {
            throw Abort(.badRequest)
        }
        
        // Generate the Merkle tree proof item for the given index
        let merkleTree = MerkleTree()
        let proofItem = merkleTree.generateProofItem(at: index)
        return proofItem
    }
    
    // Route to generate a Merkle tree proof
    app.get("merkleTreeProof", ":index") { req -> [String] in
        // Get the index parameter from the request
        guard let index = req.parameters.get("index", as: Int.self) else {
            throw Abort(.badRequest)
        }
        
        // Generate the Merkle tree proof for the given index
        let merkleTree = MerkleTree()
        let proof = merkleTree.generateProof(at: index)
        return proof
    }
    
    // Route to retrieve the balance based on the Merkle tree
    app.get("balance", ":index") { req -> Int in
        // Get the index parameter from the request
        guard let index = req.parameters.get("index", as: Int.self) else {
            throw Abort(.badRequest)
        }
        
        // Retrieve the balance based on the Merkle tree and the given index
        let merkleTree = MerkleTree()
        let balance = merkleTree.getBalance(at: index)
        return balance
    }
}
