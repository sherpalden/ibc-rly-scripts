#!/bin/bash

source const.sh
source utils.sh


RELAY_CFG_BACKUP_FILE=$HOME/.relayer/config/config_backup.yaml
KEY_DIR=$HOME/.relayer/keys

mkdir -p $KEY_DIR/$ICON_CHAIN_ID
cp $ICON_RELAYER_KEY_STORE $KEY_DIR/$ICON_CHAIN_ID/

archway_addr_ibc=$(cat $PWD/env/ARCHWAY/.ibcCore)
icon_addr_ibc=$(cat $PWD/env/ICON/.ibcCore)

btp_network_id=$(goloop rpc btpnetworktype 0x1 --uri $ICON_NODE_URI | jq -r '.openNetworkIDs[-1]')

cp $RELAY_CFG_FILE $RELAY_CFG_BACKUP_FILE
rm $RELAY_CFG_FILE

cat <<EOF >> $RELAY_CFG_FILE
global:
  api-listen-addr: :5183
  timeout: 10s
  memo: ""
  light-cache-size: 20
chains:
  archway:
    type: cosmos
    value:
      key-directory: $KEY_DIR 
      key: genesis-local
      chain-id: localnet-1
      rpc-addr: http://localhost:26657
      account-prefix: archway
      keyring-backend: test
      gas-adjustment: 1.5
      gas-prices: 0.025stake
      min-gas-amount: 1_000_000
      debug: true
      timeout: 20s
      block-timeout: ""
      output-format: json
      sign-mode: direct
      extra-codecs: []
      coin-type: 0
      broadcast-mode: batch
      start-height: 0
      block-interval: 3000
  centauri:
    type: cosmos
    value:
      key-directory: $KEY_DIR 
      key: genesis-local
      chain-id: centauri-testnet-1
      rpc-addr: http://localhost:50001
      account-prefix: centauri
      keyring-backend: test
      gas-adjustment: 1.5
      gas-prices: 0.025stake
      min-gas-amount: 1_000_000
      debug: true
      timeout: 20s
      block-timeout: ""
      output-format: json
      sign-mode: direct
      extra-codecs: []
      coin-type: 0
      broadcast-mode: batch
      start-height: 0
      block-interval: 3000
  icon:
    type: icon
    value:
      key-directory: $KEY_DIR 
      chain-id: $ICON_CHAIN_ID
      rpc-addr: $ICON_NODE_URI
      timeout: 30s
      keystore: $ICON_RELAYER_KEY 
      password: $ICON_RELAYER_KEY_PASSWORD
      icon-network-id: $ICON_NID
      btp-network-id: $(hex_to_decimal $btp_network_id)
      btp-network-type-id: 1
      start-btp-height: 0
      ibc-handler-address: $icon_addr_ibc
      start-height: 0
      block-interval: 2000
paths:
  centauri-archway:
    src:
      chain-id: $CENTAURI_CHAIN_ID
    dst:
      chain-id: $ARCHWAY_CHAIN_ID
    src-channel-filter:
      rule: ""
      channel-list: []
  icon-centauri:
    src:
      chain-id: $CENTAURI_CHAIN_ID
    dst:
      chain-id: $ICON_CHAIN_ID
    src-channel-filter:
      rule: ""
      channel-list: []
EOF

log "relay config updated!"