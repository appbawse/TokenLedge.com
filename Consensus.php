<?php

// Define the list of nodes ( Validators completed the Puzzle from the invited Stake-holders :
$nodes = array(
    'node1' => array(
        'address' => '192.168.1.1',
        'port' => 8000,
        'public_key' => 'node1_public_key',
        'private_key' => 'node1_private_key'
    ),
    'node2' => array(
        'address' => '192.168.1.2',
        'port' => 8000,
        'public_key' => 'node2_public_key',
        'private_key' => 'node2_private_key'
    )
);

// Initialize the Merkle tree with the list of nodes
$merkleTree = new MerkleTools();
foreach ($nodes as $node) {
    $merkleTree->addLeaf($node['public_key']);
}
$merkleTree->makeTree();

// Loop through the nodes and establish connections with each other
foreach ($nodes as $nodeName => $node) {
    // Connect to all other nodes
    foreach ($nodes as $otherNodeName => $otherNode) {
        if ($nodeName !== $otherNodeName) {
            // Connect to the other node
            $client = new Ratchet\Client\WebSocket("ws://" . $otherNode['address'] . ":" . $otherNode['port']);
            $client->connect();

            // Send the public key and identity proof to the other node
            $data = array(
                'public_key' => $node['public_key'],
                'identity_proof' => $merkleTree->getProof($node['public_key'])
            );
            $data_json = json_encode($data);
            $client->send($data_json);

            // Receive the response from the other node
            $response_json = $client->receive();
            $response = json_decode($response_json, true);

            // Verify the other node's identity using the Merkle tree
            $verified = $merkleTree->validateProof($response['public_key'], $response['identity_proof']);

            if ($verified) {
                // Derive the shared key with the other node
                openssl_pkey_derive($shared_key, $node['private_key'], $response['public_key']);

                // Send the shared key to the other node
                $data = array(
                    'shared_key' => base64_encode($shared_key)
                );
                $data_json = json_encode($data);
                $client->send($data_json);
            }

            $client->close();
        }
    }
}

?>
