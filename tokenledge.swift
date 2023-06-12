import MultipeerConnectivity
import CryptoKit
import JWT
import MerkleTools
import CryptoKitRSA

class ViewController: UIViewController, MCSessionDelegate, MCNearbyServiceBrowserDelegate, MCNearbyServiceAdvertiserDelegate {

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

    // MARK: - JWT Generation

    func generateEncryptedJWT() -> String? {
        let payload = ["username": "JohnDoe"] // Replace with your desired payload

        // Convert the payload to JSON data
        guard let payloadData = try? JSONSerialization.data(withJSONObject: payload, options: []) else {
            return nil
        }

        // Generate the JWT using the payload and secret
        let jwt = JWT(payload: payloadData)
        guard let jwtData = try? jwt.sign(using: .rs256(privateKey: privateKey)) else {
            return nil
        }

        // Add the JWT data to MerkleTools
        merkleTools.addLeaf(jwtData)

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
