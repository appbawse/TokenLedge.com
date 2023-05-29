<?php
// Define the Diffie-Hellman parameters
$prime = "0xffffffffffffffffc90fdaa22168c234c4c6628b80dc1cd129024" .
         "e088a67cc74020bbea63b139b22514a08798e3404ddef9519b3cd" .
         "3a431b302b0a6df25f14374fe1356d6d51c245e485b576625e7ec6" .
         "f44c42e9a63a3620fafbb1f1c5b2778df523a9c47d08ffb10d4b8" .
         "c2b96e3a28a24bc1e3738ecc732fcca9d7211c0c2073b2a4b1b9g" .
         "76d3e2a0ad74f2d2af";
$generator = "2";

function generateKeys() {
    global $prime, $generator;
    // Generate the private key
    $privateKey = gmp_init(random_bytes(16), 16);
    // Compute the public key
    $publicKey = gmp_powm(gmp_init($generator, 16), $privateKey, gmp_init($prime, 16));
    return array('privateKey' => $privateKey, 'publicKey' => $publicKey);
}

function computeSharedSecret($privateKey, $otherPublicKey) {
    global $prime;
    // Compute the shared secret
    $sharedSecret = gmp_powm(gmp_init($otherPublicKey, 16), $privateKey, gmp_init($prime, 16));
    // Convert the shared secret to a binary string
    $sharedSecret = gmp_export($sharedSecret);
    // Hash the shared secret with SHA256
    $sharedSecret = hash('sha256', $sharedSecret, true);
    return $sharedSecret;
}

// Example usage:

// Alice generates her keys
$aliceKeys = generateKeys();

// Bob generates his keys
$bobKeys = generateKeys();

// Alice sends her public key to Bob
$bobPublicKey = gmp_strval($aliceKeys['publicKey'], 16);

// Bob computes the shared secret
$bobSharedSecret = computeSharedSecret($bobKeys['privateKey'], $bobPublicKey);

// Bob sends his public key to Alice
$alicePublicKey = gmp_strval($bobKeys['publicKey'], 16);

// Alice computes the shared secret
$aliceSharedSecret = computeSharedSecret($aliceKeys['privateKey'], $alicePublicKey);

// The shared secrets should be equal
var_dump($aliceSharedSecret === $bobSharedSecret);

?>
