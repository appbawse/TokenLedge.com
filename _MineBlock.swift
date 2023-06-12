import CryptoKit

struct Block: Codable {
    let index: Int
    let timestamp: Int
    let data: String
    let previousHash: String
    let hash: String
    let nonce: Int
}

func MineBlock(blockData: [String: Any]) -> Block {
    let index = blockData["index"] as! Int
    let timestamp = blockData["timestamp"] as! Int
    let data = blockData["data"] as! String
    let previousHash = blockData["previousHash"] as! String
    var nonce = 0
    var hash = ""

    while true {
        let hashInput = "\(index)\(timestamp)\(data)\(previousHash)\(nonce)"
        let hashOutput = SHA256.hash(data: hashInput.data(using: .utf8)!)
        hash = hashOutput.compactMap { String(format: "%02x", $0) }.joined()

        if hash.hasPrefix("0000") {
            break
        }

        nonce += 1
    }

    return Block(index: index, timestamp: timestamp, data: data, previousHash: previousHash, hash: hash, nonce: nonce)
}

func addBlock() {
    let blockData = [
        "index": 1,
        "timestamp": 1527619688,
        "data": "Block data",
        "previousHash": "0000",
        "hash": "0000b33af811f5db911b5ef5c72267dfaa5ca5324ceae4f0a0d9d4e71c0d276a",
        "nonce": 472
    ]

    let block = MineBlock(blockData: blockData)
    let blockJsonData = try! JSONEncoder().encode(block)
    let blockJsonString = String(data: blockJsonData, encoding: .utf8)!
    let encryptedBlockData = encryptData(data: blockJsonString.data(using: .utf8)!)
    let encryptedBlockBase64 = encryptedBlockData.base64EncodedString()

    let jwtToken = [
        "puzzles": [
            [
                "question": "What is the capital of France?",
                "answer": "Paris"
            ],
            [
                "question": "What is the largest country in the world by land area?",
                "answer": "Russia"
            ],
            [
                "question": "What is the chemical symbol for gold?",
                "answer": "Au"
            ]
        ],
        "encrypted_block": encryptedBlockBase64
    ]

    // Use the jwtToken as needed
    print(jwtToken)
}

func encryptData(data: Data) -> Data {
    let symmetricKey = SymmetricKey(size: .bits256)
    let sealedBox = try! AES.GCM.seal(data, using: symmetricKey)
    return sealedBox.combined!
}

addBlock()
