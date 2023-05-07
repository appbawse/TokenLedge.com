const express = require('express');
const bodyParser = require('body-parser');
const redis = require('redis');
const CryptoJS = require('crypto-js');
const dh = require('diffie-hellman');
const fs = require('fs');
const WebSocket = require('ratchet');
const GuzzleHttp = require('guzzlehttp/guzzlehttp/src/Client');
const jwt = require('jsonwebtoken');

const app = express();
const client = redis.createClient();

app.use(bodyParser.json());
app.use(bodyParser.urlencoded({ extended: true }));

const secretKey = 'my-secret-key';

// Redis example
app.get('/redis/:key', (req, res) => {
  const key = req.params.key;
  client.get(key, (err, data) => {
    if (err) throw err;
    res.send(data);
  });
});

app.post('/redis/:key', (req, res) => {
  const key = req.params.key;
  const value = req.body.value;
  client.set(key, value, (err) => {
    if (err) throw err;
    res.send('OK');
  });
});

// CryptoJS example
const message = 'Hello, world!';
const encrypted = CryptoJS.AES.encrypt(message, secretKey).toString();
console.log(`Encrypted message: ${encrypted}`);
const decrypted = CryptoJS.AES.decrypt(encrypted, secretKey).toString(CryptoJS.enc.Utf8);
console.log(`Decrypted message: ${decrypted}`);

// DiffieHellman example
const alice = dh.generateKeys();
const bob = dh.generateKeys();
const aliceSecret = alice.computeSecret(bob.getPublicKey());
const bobSecret = bob.computeSecret(alice.getPublicKey());
console.log(`Shared secrets match: ${aliceSecret.toString('hex') === bobSecret.toString('hex')}`);

// fs example
fs.readFile('/path/to/file', (err, data) => {
  if (err) throw err;
  console.log(data);
});

// Ratchet websocket example
const ws = new WebSocket('wss://example.com');
ws.on('open', () => {
  console.log('WebSocket connection opened');
});
ws.on('message', (message) => {
  console.log(`Received message: ${message}`);
});

// Guzzle HTTP example
const http = new GuzzleHttp\Client();
http.get('https://api.example.com/data').then((response) => {
  console.log(response.body);
}).catch((error) => {
  console.error(error);
});

// JWT example
app.post('/login', (req, res) => {
  const username = req.body.username;
  const password = req.body.password;

  // Authenticate user
  // ...

  // Generate JWT token
  const token = jwt.sign({ username }, secretKey, { expiresIn: '1h' });
  res.json({ token });
});

app.get('/protected', (req, res) => {
  const token = req.headers.authorization.split(' ')[1];
  jwt.verify(token, secretKey, (err, decoded) => {
    if (err) {
      return res.status(401).json({ message: 'Invalid token' });
    }

    // Authorized access
    res.json({ message: `Hello, ${decoded.username}!` });
  });
});

app.listen(3000, () => {
  console.log('Server listening on port 3000');
});
