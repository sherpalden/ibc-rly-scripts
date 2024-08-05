#!/bin/bash

source const.sh
source utils.sh


RELAY_CFG_BACKUP_FILE=$HOME/.relayer/config/config_backup.yaml
KEY_DIR=$HOME/.relayer/keys

mkdir -p $KEY_DIR/$ICON_CHAIN_ID
cp $ICON_RELAYER_KEY_STORE $KEY_DIR/$ICON_CHAIN_ID/

injective_addr_ibc=$(cat $PWD/env/INJECTIVE/.ibcCore)
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
  injective:
    type: wasm
    value:
      key-directory: $KEY_DIR
      key: admin
      chain-id: $INJECTIVE_CHAIN_ID 
      rpc-addr: $INJECTIVE_NODE_URI
      account-prefix: $INJECTIVE_PREFIX
      keyring-backend: $WASM_KEYRING_BACKEND
      gas-adjustment: 1.5
      gas-prices: ${INJECTIVE_GAS_PRICE}${INJECTIVE_DENOM}
      min-gas-amount: 1_000_000
      debug: true
      timeout: 20s
      block-timeout: ""
      output-format: json
      sign-mode: direct
      extra-codecs: []
      coin-type: 0
      broadcast-mode: batch
      ibc-handler-address: $injective_addr_ibc
      start-height: 0
      block-interval: 500
  
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
      btp-network-id: $btp_network_id
      btp-network-type-id: 1
      start-btp-height: 0
      ibc-handler-address: $icon_addr_ibc
      start-height: 0
      block-interval: 2000
paths:
  icon-injective:
    src:
      chain-id: $ICON_CHAIN_ID
    dst:
      chain-id: $INJECTIVE_CHAIN_ID
    src-channel-filter:
      rule: ""
      channel-list: []
EOF

log "relay config updated!"