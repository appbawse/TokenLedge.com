<?php
use Defuse\Crypto\Crypto;
use Defuse\Crypto\Key;

// Define the list of nodes ( Validators comoleted the Puzzle from the invited Stake-holders :
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

                // Generate the JWT token
                $blockData = array(
                    'index' => 1,
                    'timestamp' => 1527619688,
                    'data' => 'Block data',
                    'previousHash' => '0000',
                    'hash' => '0000b33af811f5db911b5ef5c72267dfaa5ca5324ceae4f0a0d9d4e71c0d276a',
                    'nonce' => 472
                );
                $blockJson = json_encode($blockData);
                $key = Key::createNewRandomKey();
                $encryptedBlockJson = Crypto::encrypt($blockJson, $key);
                $jwtToken = array(
                    'puzzles' => array(
                        array(
                            'question' => 'What is the capital of France?',
                            'answer' => 'Paris'
                        ),
                        array(
                            'question' => 'What is the largest country in the world by land area?',
                            'answer' => 'Russia'
                        ),
                        array(
                            'question' => 'What is the chemical symbol for gold?',
                            'answer' => 'Au'
                        )
                    ),
                    'encrypted_block' => base64_encode($encryptedBlockJson)
);
