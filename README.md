# SmartAffair.ai
  <h1>API Documentation</h1>

  <h2>POST /addblock</h2>
  <p>Adds a new block to the blockchain with the given data, previous hash, and nonce.</p>
  <h3>Request Body</h3>
  <pre>
  {
    "data": "string",
    "previousHash": "string",
    "nonce": "number"
  }
  </pre>
  <h3>Response Body</h3>
  <pre>
  {
    "data": "string",
    "previousHash": "string",
    "hash": "string",
    "nonce": "number"
  }
  </pre>

  <h2>POST /mineblock</h2>
  <p>Mines a new block with the given data and previous hash.</p>
  <h3>Request Body</h3>
  <pre>
  {
    "data": "string",
    "previousHash": "string"
  }
  </pre>
  <h3>Response Body</h3>
  <pre>
  {
    "data": "string",
    "previousHash": "string",
    "hash": "string",
    "nonce": "number"
  }
  </pre>

  <h2>POST /nodes</h2>
  <p>Exchanges nodes with other party using Socket.io</p>
  <h3>Request Body</h3>
  <pre>
  {
    "encryptedNode": "string",
    "jwtToken": "string",
    "merkleProof": "string"
  }
  </pre>
  <h3>Response Body</h3>
  <pre>
  {
    "payload": "object",
    "decrypted": "string"
  }
  </pre>

  <h2>GET /puzzle</h2>
  <p>Generates a puzzle.</p>
  <h3>Response Body</h3>
  <pre>
  {
    "puzzle": "string"
  }
  </pre>

  <h2>POST /csv</h2>
  <p>Returns CSV data from the given file path.</p>
  <h3>Request Body</h3>
  <pre>
  {
    "filePath": "string"
  }
  </pre>
  <h3>Response Body</h3>
  <pre>
  [    {      "header1": "value1",      "header2": "value2",      ...    },    {      "header1": "value3",      "header2": "value4",      ...    },    ...  ]
  </pre>

  <h2>POST /privatekey</h2>
  <p>Generates a shared secret for encrypting and decrypting messages between parties.</p>
  <h3>Request Body</h3>
  <pre>
  {
    "publicKey": "string",
    "prime": "string"
  }
  </pre>
  <h3>Response Body</h3>
  <pre>
  {
    "sharedSecret": "string"
  }
  </pre>

  <h2>GET /amount</h2>
  <p>Returns the amount for the given party ID and password from the database.</p>
  <h3>Request Body</h3>
  <pre>
  {
    "partyId": "string”
    “password”: “string”
}
  </pre>
  <h3>Response Body</h3>
  <pre>
  {
    "amount": "number"
  }
  </pre>
