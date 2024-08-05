#!/bin/bash

source const.sh
source utils.sh

RELAY_CFG_BACKUP_FILE=$HOME/.relayer/config/config_backup.yaml
KEY_DIR=$HOME/.relayer/keys

injective_addr_ibc=$(cat $PWD/env/INJECTIVE/.ibcCore)
icon_addr_ibc=$(cat $PWD/env/ICON/.ibcCore)

cp $RELAY_CFG_FILE $RELAY_CFG_BACKUP_FILE
rm $RELAY_CFG_FILE

cat <<EOF >> $RELAY_CFG_FILE
    global:
    api-listen-addr: :5183
    timeout: 10s
    memo: ""
    light-cache-size: 20
    chains:
    icon:
        type: icon
        value:
        key-directory: /home/ubuntu/.relayer/keys
        chain-id: lisbon
        rpc-addr: https://lisbon.net.solidwallet.io/api/v3/
        timeout: 30s
        keystore: relayWalleti
        password: gochain
        icon-network-id: 2
        btp-network-id: 2
        btp-network-type-id: 1
        start-height: 0
        ibc-handler-address: cx27d5d8af883b7f0a69377e4cb05648adff6f695b
        first-retry-block-after: 0
        block-interval: 2000
    injective:
        type: wasm
        value:
        key-directory: /Users/sherpalden/.relayer/keys/injective-888
        key: relayWallet
        chain-id: injective-888
        rpc-addr: https://injective-testnet-rpc.publicnode.com:443
        block-rpc-addr: https://testnet.sentry.tm.injective.network:443
        account-prefix: inj
        keyring-backend: test
        gas-adjustment: 1.5
        gas-prices: 500000000inj
        min-gas-amount: 1000000
        debug: true
        timeout: 20s
        block-timeout: ""
        output-format: json
        sign-mode: direct
        extra-codecs: []
        coin-type: 0
        broadcast-mode: batch
        ibc-handler-address: inj1k5nwz0ctk98k7zwn95jjy2klhfpgufklnt0sgq
        first-retry-block-after: 0
        start-height: 0
        block-interval: 800
    paths:
    icon-injective:
        src:
        chain-id: lisbon
        client-id: 07-tendermint-61
        connection-id: connection-69
        dst:
        chain-id: injective-888
        client-id: iconclient-32
        connection-id: connection-17
        src-channel-filter:
        rule: ""
        channel-list: []
EOF    
echo "relay config updated!"