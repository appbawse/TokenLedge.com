import Foundation
import SwiftRedis
import CryptoKitRSA
import UIKit
import MultipeerConnectivity
import CryptoKit
import SwiftJWT
import MerkleTools
import MySQL

class ViewController: UIViewController, MCSessionDelegate, MCNearbyServiceBrowserDelegate, MCNearbyServiceAdvertiserDelegate {
    // Declare and initialize the mysqlConnection variable
    var mysqlConnection = MySQL.Connection()

    // Connect to the MySQL server
    let connected = mysqlConnection.connect(host: "localhost", user: "your_username", password: "your_password", database: "your_database_name")

    // Other properties
    var peerID: MCPeerID!
    var session: MCSession!
    var browser: MCNearbyServiceBrowser!
    var advertiser: MCNearbyServiceAdvertiser!
    let privateKey = P256.KeyAgreement.PrivateKey()
    let publicKey = privateKey.publicKey
    let jwtSecret = "your_jwt_secret"
    let merkleTools = MerkleTools()

    override func viewDidLoad() {
        super.viewDidLoad()

        // Initialize peerID and session
        peerID = MCPeerID(displayName: UIDevice.current.name)
        session = MCSession(peer: peerID, securityIdentity: nil, encryptionPreference: .required)
        session.delegate = self

        // Initialize browser and advertiser
        browser = MCNearbyServiceBrowser(peer: peerID, serviceType: "my-service")
        browser.delegate = self
        advertiser = MCNearbyServiceAdvertiser(peer: peerID, discoveryInfo: nil, serviceType: "my-service")
        advertiser.delegate = self

        // Start browsing and advertising for peers
        browser.startBrowsingForPeers()
        advertiser.startAdvertisingPeer()

        connectToRedis()
    }

    func connectToRedis() {
        let redis = Redis()

        redis.connect(host: "localhost", port: 6379) { (redisError: NSError?) in
            guard redisError == nil else {
                print("Error connecting to Redis: \(redisError!)")
                return
            }

            redis.get("merkle_tree_data") { (redisResponse: RedisResponse?, redisError: NSError?) in
                guard redisError == nil, let redisMerkleTree = redisResponse?.asString() else {
                    print("Error retrieving Merkle tree data from Redis: \(redisError!)")
                    return
                }

                // Retrieve the latest Merkle tree data from MySQL
                let latestMerkleTreeQuery = "SELECT tree_data FROM merkle_tree ORDER BY timestamp DESC LIMIT 1"
                mysqlConnection.query(latestMerkleTreeQuery) { (mysqlResult: MySQLResult?) in
                    guard let mysqlResult = mysqlResult else {
                        print("Error retrieving Merkle tree data from MySQL: \(mysqlConnection.errorCode()) \(mysqlConnection.errorMessage())")
                        return
                    }

                    if let mysqlMerkleTree = mysqlResult.next()?[0]?.asString() {
                        // Compare the Merkle tree data from Redis and MySQL
                        let redisTimestampQuery = "GET merkle_tree_timestamp"
                        let mysqlTimestampQuery = "SELECT timestamp FROM merkle_tree ORDER BY timestamp DESC LIMIT 1"
                        let multi = redis.multi()
                        multi.sendCommand("GET", params: ["merkle_tree_timestamp"])
                        multi.sendCommand("SELECT", params: ["timestamp FROM merkle_tree ORDER BY timestamp DESC LIMIT 1"])

                        multi.exec { (redisResponses: [RedisResponse]?, redisError: NSError?) in
                            guard redisError == nil, let redisResponses = redisResponses else {
                                print("Error retrieving timestamps from Redis: \(redisError!)")
                                return
                            }

                            let redisTimestamp = redisResponses[0].asString()
                            let mysqlTimestamp = redisResponses[1].asString()

                            if let redisTimestamp = redisTimestamp, let mysqlTimestamp = mysqlTimestamp {
                                if let redisTimestampInt = Int(redisTimestamp), let mysqlTimestampInt = Int(mysqlTimestamp) {
                                    if redisTimestampInt >= mysqlTimestampInt {                                         processMerkleTree(redisMerkleTree)
                                    } else {
                                        processMerkleTree(mysqlMerkleTree)
                                    }
                                }
                            } else if let redisTimestamp = redisTimestamp {
                                processMerkleTree(redisMerkleTree)
                            } else if let mysqlTimestamp = mysqlTimestamp {
                                processMerkleTree(mysqlMerkleTree)
                            } else {
                                print("No Merkle tree data found")
                            }
                        }
                    } else {
                        print("No Merkle tree data found in MySQL")
                    }
                }
            }
        }
    }

    func processMerkleTree(_ merkleTree: String) {
        // Perform necessary processing or calculations on the latest Merkle tree data
        print("Latest Merkle tree data: \(merkleTree)")
    }

    // MARK: - MCNearbyServiceBrowserDelegate

    func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String: String]?) {
        // Invite the peer to join the session
        browser.invitePeer(peerID, to: session, withContext: nil, timeout: 30)
    }

    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        // Handle lost peer
    }

    // MARK: - MCNearbyServiceAdvertiserDelegate

    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        // Accept the invitation and join the session
        invitationHandler(true, session)
    }

    // MARK: - MCSessionDelegate methods

    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        // Handle session state changes
        switch state {
        case .connected:
            print("Connected to peer: \(peerID.displayName)")
        case .connecting:
            print("Connecting to peer: \(peerID.displayName)")
        case .notConnected:
            print("Disconnected from peer: \(peerID.displayName)")
        @unknown default:
            break
        }
    }

    func session(_ session: MCSession, didReceiveCertificate certificate: [Any]?, fromPeer peerID: MCPeerID, certificateHandler: @escaping (Bool) -> Void) {
        // Handle received certificate
        certificateHandler(true)
    }

    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        // Handle received data
        handleReceivedData(data)
    }

    func session(_ session: MCSession, didReceiveStream stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
        // Handle receiving a stream from other peers
    }

    // MARK: - MCBrowserViewControllerDelegate methods

      func browserViewControllerDidFinish(_ browserViewController: MCBrowserViewController) {
        // Handle user finishing browsing for other peers
        dismiss(animated: true, completion: nil)
    }

    func browserViewControllerWasCancelled(_ browserViewController: MCBrowserViewController) {
        // Handle user cancelling browsing for other peers
        dismiss(animated: true, completion: nil)
    }

    // MARK: - IBActions

    @IBAction func startHosting(_ sender: UIButton) {
        // Start advertising to other peers
        advertiser.startAdvertisingPeer()
    }

    @IBAction func joinSession(_ sender: UIButton) {
        // Show browser view controller to allow the user to browse for other peers
        let mcBrowser = MCBrowserViewController(serviceType: "my-service", session: session)
        mcBrowser.delegate = self
        present(mcBrowser, animated: true, completion: nil)
    }

    @IBAction func sendBlockMined(_ sender: UIButton) {
        // Generate the encrypted JWT
        guard let encryptedJWT = generateEncryptedJWT() else {
            print("Error generating encrypted JWT")
            return
        }

        // Send the encrypted JWT to all connected peers
        let message = ["encryptedJWT": encryptedJWT]
        guard let data = try? JSONSerialization.data(withJSONObject: message, options: []) else {
            print("Error serializing message")
            return
        }

        do {
            try session.send(data, toPeers: session.connectedPeers, with: .reliable)
        } catch {
            print("Error sending data: \(error)")
        }
    }

    // MARK: - Encryption and Decryption

    func encrypt(data: Data) -> Data? {
        do {
            let ciphertext = try CryptoKitRSA.encrypt(data, with: publicKey)
            return ciphertext
        } catch {
            print("Encryption error: \(error)")
            return nil
        }
    }

    func decrypt(data: Data) -> Data? {
        do {
            let plaintext = try CryptoKitRSA.decrypt(data, with: privateKey)
            return plaintext
        } catch {
            print("Decryption error: \(error)")
            return nil
        }
    }

    // Generate the Merkle root hash
func generateMerkleRootHash(_ treeHashes: [String]) -> String {
    let merkleTools = MerkleTools()
    
    // Add the tree hashes as leaf nodes
    for hash in treeHashes {
        merkleTools.addLeaf(hash.data(using: .utf8)!)
    }
    
    // Generate the Merkle root
    let root = merkleTools.makeTree()
    
    return root.hash
}

// Generate the Merkle tree proof item for the given index
func generateProofItem(_ merkleTree: MerkleTree, at index: Int) -> String {
    let proofItem = merkleTree.generateProofItem(at: index)
    return proofItem.hash
}

// Generate the Merkle tree proof for the given index
func generateProof(_ merkleTree: MerkleTree, at index: Int) -> [String] {
    let proof = merkleTree.generateProof(at: index)
    return proof.map { $0.hash }
}


    // MARK: - JWT Generation

    func generateEncryptedJWT() -> String? {
        let payload: [String: Any] = [
         "user_id": 123, // Replace with the actual user ID
         "transaction": [
             "from_address_id": 456, // Replace with the actual from address ID
             "to_address_id": 789, // Replace with the actual to address ID
             "balance": 10.0, // Replace with the actual transaction amount
             "timestamp": "2023-06-11T12:34:56Z", // Replace with the actual transaction timestamp
             "nonce": 12345,
             "hash": "transaction_hash" // Replace with the actual transaction hash
         ],
         "merkle_tree": [
             "root_hash": "merkle_root_hash", // Replace with the actual merkle root hash
             "tree_hash_1": "tree_hash_1", // Replace with the actual tree hash 1
             "tree_hash_2": "tree_hash_2", // Replace with the actual tree hash 2
             // Include more tree hashes as needed
        ]

        // Convert the payload to JSON data
        guard let payloadData = try? JSONSerialization.data(withJSONObject: payload, options: []) else {
            return nil
        }

        // Generate the JWT using the payload and secret
        let jwt = JWT(payload: payloadData)
        guard let jwtData = try? jwt.sign(using: .rs256(privateKey: privateKey)) else {
            return nil
        }

        // Create MerkleTools instance
        let merkleTools = MerkleTools()

        // Add the JWT data as a leaf node
        merkleTools.addLeaf(jwtData)

        // Add the tree hashes from the "merkle_tree" section
        if let merkleTree = payload["merkle_tree"] as? [String: String] {
            for (_, value) in merkleTree {
                merkleTools.addLeaf(value.data(using: .utf8)!)
            }
        }

        // Generate the Merkle root
        let root = merkleTools.makeTree()

        // Encrypt the Merkle root data using RSA
        guard let encryptedData = encrypt(data: root.data) else {
            return nil
        }

        // Encode the encrypted Merkle root data as a base64 string
        let encryptedRootString = encryptedData.base64EncodedString()

        return encryptedRootString
        }
}
