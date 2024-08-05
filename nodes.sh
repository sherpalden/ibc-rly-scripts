#!/bin/bash

source const.sh
source utils.sh

function startNodeIcon() {
	cd $ICON_CHAIN_PATH
	make ibc-ready
}

function stopNodeIcon() {
	cd $ICON_CHAIN_PATH
	make stop
}


function startNodeArchway() {
	cd $ARCHWAY_CHAIN_PATH
	TAG=$(git describe --tags --abbrev=0) docker compose up -d
}

function stopNodeArchway() {
	cd $ARCHWAY_CHAIN_PATH
  TAG=$(git describe --tags --abbrev=0) docker compose down
}

function startNodeCentauri() {
  cd $CENTAURI_CHAIN_PATH
  docker compose up -d
}

function stopNodeCentauri() {
  cd $CENTAURI_CHAIN_PATH
  docker compose down
}

function loadFundIcon() {
  echo "Loading fund on ICON wallet..."
  local fund_receiver=$(get_address_from_keystore $ICON_MINTER_KEY_STORE)
  local tx="goloop rpc sendtx transfer --to $fund_receiver --key_store $ICON_GENESIS_KEY_STORE --key_password $ICON_GENESIS_KEY_PASSWORD --uri $ICON_NODE_URI --nid $ICON_NID --step_limit 1000000000 --value 1321226104143235154"
  echo "$tx"
  eval "$tx"
}


function getBalanceIcon() {
  echo "Querying balance of ICON wallet..."
  local address=$(get_address_from_keystore $ICON_MINTER_KEY_STORE)
  local query="goloop rpc balance --uri $ICON_NODE_URI $address"
  echo $($query)
  hex_to_decimal $($query)
}


function create_client_icon_centauri() {
  local code_hash=$(get_sha256sum_hex $CW_ICS08_ICON_LIGHT_CLIENT)
  rly tx clients icon-centauri --client-tp "1814399s" --src-wasm-code-id $code_hash --override -d
}



function usage() {
	echo "IBC Relay Scripts Running..."
	echo 
	echo "Usage: "
	echo "         ./nodes.sh icon-node-start                : Start BTP enabled icon local node"
	echo "         ./nodes.sh archway-node-start             : Start archway local node"
	echo "         ./nodes.sh centauri-node-start             : Start neutron local node"
}

CMD=$1

case "$CMD" in
  load-fund-icon)
    loadFundIcon
  ;;
  get-balance-icon)
    getBalanceIcon
  ;;
  start-node-icon)
    startNodeIcon
  ;;
  stop-node-icon)
    stopNodeIcon
  ;;

  start-node-archway)
    startNodeArchway
  ;;
  stop-node-archway)
    stopNodeArchway
  ;;

  start-node-centauri)
    startNodeCentauri
  ;;
  stop-node-centauri)
    stopNodeCentauri
  ;;

  create-client-icon-centauri)
    create_client_icon_centauri
  ;;
  * )
    echo "error: unknown command: $CMD"
    usage
esac