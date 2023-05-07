<?php

use Ratchet\ConnectionInterface;
use Ratchet\RFC6455\Messaging\MessageInterface;
use SaaSBlueprint\WebSocket\Extensions\IExtensionPanel;ø

class TokenExchangeExtension implements IExtensionPanel
{
    private $private_key;
    private $public_key;
    private $shared_key;

    public function __construct()
    {
        // Generate SSL key pair for this party
        $this->private_key = openssl_pkey_new();
        openssl_pkey_export($this->private_key, $private_key_str);
        $this->public_key = openssl_pkey_get_details($this->private_key)['key'];
    }

    public function getName(): string
    {
        return 'Token Exchange';
    }

    public function getDescription(): string
    {
        return 'Perform token exchange with another party over private SSL keys.';
    }

    public function handleRequest(ConnectionInterface $conn, MessageInterface $msg): bool
    {
        $data = json_decode($msg->getPayload(), true);

        if (isset($data['public_key'])) {
            // This is the first message in the token exchange, so send our public key to the other party
            $data = array(
                'public_key' => $this->public_key,
                'identity_proof' => '', // Proof of identity using MerkleTools
            );
            $data_json = json_encode($data);
            $conn->send($data_json);

            return true;
        } else if (isset($data['shared_key'])) {
            // This is the last message in the token exchange, so store the shared key
            $shared_key_str = $data['shared_key'];
            $this->shared_key = base64_decode($shared_key_str);

            return true;
        }

        return false;
    }

    public function handleConnectionClosed(ConnectionInterface $conn): void
    {
        // Clean up any resources associated with the connection
        // ...
    }

    public function handleConnectionOpened(ConnectionInterface $conn): void
    {
        // Do nothing
    }

    public function handleConnectionError(ConnectionInterface $conn, \Exception $e): void
    {
        // Do nothing
    }

    public function getPanel(): string
    {
        $panel = <<<HTML
        <div class="panel-body">
            <p>Perform token exchange with another party over private SSL keys.</p>
            <div class="form-group">
                <label for="public_key">Other party's public key:</label>
                <input type="text" class="form-control" id="public_key">
            </div>
            <button type="button" class="btn btn-primary" id="exchange_tokens">Exchange Tokens</button>
        </div>
        <script>
        $('#exchange_tokens').click(function() {
            var public_key = $('#public_key').val();

            // Send request to other party
            var data = {
                public_key: public_key,
            };
            var data_json = JSON.stringify(data);
            conn.send(data_json);
        });
        </script>
        HTML;

        return $panel;
    }
}
