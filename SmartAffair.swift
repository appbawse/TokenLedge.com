import MultipeerConnectivity

class ViewController: UIViewController, MCSessionDelegate, MCNearbyServiceBrowserDelegate, MCNearbyServiceAdvertiserDelegate {

    var peerID: MCPeerID!
    var session: MCSession!
    var browser: MCNearbyServiceBrowser!
    var advertiser: MCNearbyServiceAdvertiser!

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

    // MARK: - MCSessionDelegate

    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        // Handle peer state changes
    }

    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        // Handle received data
    }

    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
        // Handle received stream
    }

    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {
        // Handle started receiving resource
    }

    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {
        // Handle finished receiving resource
    }
    
    guard let localURL = localURL else {
            print("Error receiving resource: \(resourceName) from peer: \(peerID.displayName), localURL is nil")
            return
        }
        
        // Process the received resource
        // ...
        
        print("Finished receiving resource: \(resourceName) from peer: \(peerID.displayName), saved to local URL: \(localURL.absoluteString)")
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
    mcAdvertiserAssistant = MCAdvertiserAssistant(serviceType: "my-service-type", discoveryInfo: nil, session: mcSession)
    mcAdvertiserAssistant.start()
}

@IBAction func joinSession(_ sender: UIButton) {
    // Show browser view controller to allow user to browse for other peers
    let mcBrowser = MCBrowserViewController(serviceType: "my-service-type", session: mcSession)
    mcBrowser.delegate = self
    present(mcBrowser, animated: true, completion: nil)
}

@IBAction func sendBlockMined(_ sender: UIButton) {
// Send a message to all connected peers
let message = ["message": "block_mined"]
let data = try? JSONSerialization.data(withJSONObject: message, options: [])
try? mcSession.send(data!, toPeers: mcSession.connectedPeers, with: .reliable)
}



}
