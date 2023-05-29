<?php

// Add block to Keychain Services
function addBlock($blockData) {
  $keychain = new Keychain();
  $keychain->addGenericPassword('block', json_encode($blockData));
}

// Mine new block
function mineBlock($lastBlock, $newData) {
  $nonce = 0;
  while (true) {
    $hash = sha256($lastBlock['hash'] . $newData . $nonce);
    if (substr($hash, 0, 4) === '0000') {
      return array(
        'nonce' => $nonce,
        'hash' => $hash
      );
    }
    $nonce++;
  }
}

// Exchange blocks
function exchangeBlocks($myBlock, $peerBlock) {
  if ($peerBlock['hash'] == $myBlock['hash']) {
    return true;
  } elseif ($peerBlock['nonce'] > $myBlock['nonce']) {
    return true;
  } else {
    return false;
  }
}

// Retrieve puzzles from Keychain Services
function getPuzzles() {
  $keychain = new Keychain();
  $puzzles = $keychain->getGenericPassword('puzzles');
  return json_decode($puzzles);
}
?>
