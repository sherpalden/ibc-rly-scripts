#!/bin/bash

################################### REPO PATHS ###################################

export IBC_RELAY=$HOME/blockchain/projects/ibc-relay
export IBC_INTEGRATION=$HOME/blockchain/projects/IBC-Integration

export ICON_CHAIN_PATH=$HOME/blockchain/chains/gochain-btp
export CENTAURI_CHAIN_PATH=$HOME/blockchain/chains/composable-cosmos
export ARCHWAY_CHAIN_PATH=$HOME/blockchain/chains/archway

##############################     WALLETS     ###################################
export WASM_KEYRING_BACKEND=test
export WASM_GENESIS_KEY=admin
export WASM_RELAYER_KEY=$WASM_GENESIS_KEY

-----------------------------------------------------------------------------------

# export ICON_GENESIS_KEY=relayer-testnet
export ICON_GENESIS_KEY=genesis-local
export ICON_GENESIS_KEY_STORE=$HOME/blockchain/wallets/icon/${ICON_GENESIS_KEY}.json
export ICON_GENESIS_KEY_PASSWORD=gochain

export ICON_RELAYER_KEY=$ICON_GENESIS_KEY
export ICON_RELAYER_KEY_STORE=$HOME/blockchain/wallets/icon/${ICON_RELAYER_KEY}.json
export ICON_RELAYER_KEY_PASSWORD=$ICON_GENESIS_KEY_PASSWORD

export ICON_MINTER_KEY=minter-local
export ICON_MINTER_KEY_STORE=$HOME/blockchain/wallets/icon/${ICON_MINTER_KEY}.json
export ICON_MINTER_KEY_PASSWORD=password


##############################     OTHER     ###################################

export PORT_ID_XCALL_CONNECTION="xcall"
export PORT_ID_ICS20_APP=transfer

export RELAY_CFG_FILE=$HOME/.relayer/config/config.yaml

##############################    CENTAURI    ###################################
export CENTAURI_BINARY=picad
export CENTAURI_NETWORK_ID=centauri
export CENTAURI_PREFIX=pica
export CENTAURI_NODE_URI=http://localhost:26657
export CENTAURI_CHAIN_ID=localpica
export CENTAURI_DENOM=ppica
export CENTAURI_GAS_PRICE=5

export CENTAURI_COMMON_ARGS=" --from ${WASM_GENESIS_KEY} --keyring-backend $WASM_KEYRING_BACKEND --node ${CENTAURI_NODE_URI} --chain-id ${CENTAURI_CHAIN_ID} --gas-prices ${CENTAURI_GAS_PRICE}${CENTAURI_DENOM} --gas auto --gas-adjustment 1.5 "
export CENTAURI_COMMON_ARGS_V1=" --keyring-backend $WASM_KEYRING_BACKEND --node ${CENTAURI_NODE_URI} --chain-id ${CENTAURI_CHAIN_ID} --gas-prices ${CENTAURI_GAS_PRICE}${CENTAURI_DENOM} --gas auto --gas-adjustment 1.5 "

##############################    ARCHWAY    ###################################
export ARCHWAY_BINARY=archwayd
export ARCHWAY_NETWORK_ID=archway
export ARCHWAY_PREFIX=archway
export ARCHWAY_NODE_URI=http://localhost:26657
export ARCHWAY_CHAIN_ID=localnet-1
export ARCHWAY_DENOM=stake
export ARCHWAY_GAS_PRICE=0.025

export ARCHWAY_COMMON_ARGS=" --from ${WASM_GENESIS_KEY} --keyring-backend $WASM_KEYRING_BACKEND --node ${ARCHWAY_NODE_URI} --chain-id ${ARCHWAY_CHAIN_ID} --gas-prices ${ARCHWAY_GAS_PRICE}${ARCHWAY_DENOM} --gas auto --gas-adjustment 1.5 "
export ARCHWAY_COMMON_ARGS_V1=" --keyring-backend $WASM_KEYRING_BACKEND --node ${ARCHWAY_NODE_URI} --chain-id ${ARCHWAY_CHAIN_ID} --gas-prices ${ARCHWAY_GAS_PRICE}${ARCHWAY_DENOM} --gas auto --gas-adjustment 1.5 "

##############################    INJECTIVE    ###################################
export INJECTIVE_BINARY=injectived
export INJECTIVE_NETWORK_ID=injective
export INJECTIVE_PREFIX=inj
export INJECTIVE_NODE_URI=https://injective-testnet-rpc.publicnode.com:443
export INJECTIVE_CHAIN_ID=injective-888
export INJECTIVE_DENOM=inj
export INJECTIVE_GAS_PRICE=500000000

export INJECTIVE_COMMON_ARGS=" --from ${WASM_GENESIS_KEY} --keyring-backend $WASM_KEYRING_BACKEND --node ${INJECTIVE_NODE_URI} --chain-id ${INJECTIVE_CHAIN_ID} --gas-prices ${INJECTIVE_GAS_PRICE}${INJECTIVE_DENOM} --gas auto --gas-adjustment 1.5 "
		
##############################    ICON    ###################################
# export ICON_CHAIN_ID=lisbon
# export ICON_NID=0x2
# export ICON_SLEEP_TIME=2
# export ICON_NODE_URI=https://lisbon.net.solidwallet.io/api/v3/
# export ICON_DEBUG_NODE=https://lisbon.net.solidwallet.io/api/v3d
# export ICON_NETWORK_ID="0x2.icon"

# export ICON_STEP_LIMIT=100000000000
	
# export ICON_COMMON_ARGS=" --uri $ICON_NODE_URI --nid $ICON_NID --step_limit $ICON_STEP_LIMIT --key_store $ICON_GENESIS_KEY_STORE --key_password $ICON_GENESIS_KEY_PASSWORD "


# ##############################    ICON    ###################################
export ICON_CHAIN_ID=ibc-icon
export ICON_NID=3
export ICON_SLEEP_TIME=2
export ICON_NODE_URI=http://localhost:9082/api/v3/
export ICON_DEBUG_NODE=http://localhost:9082/api/v3d
export ICON_NETWORK_ID="0x3.icon"

export ICON_STEP_LIMIT=100000000000
	
export ICON_COMMON_ARGS=" --uri $ICON_NODE_URI --nid $ICON_NID --step_limit $ICON_STEP_LIMIT --key_store $ICON_GENESIS_KEY_STORE --key_password $ICON_GENESIS_KEY_PASSWORD "



export IRC_TOKEN_FILE=$PWD/artifacts/irc-bytecode
###############################    CONTRACTS     ################################
export CW_DIR=$PWD/artifacts

export JS_DIR=$HOME/blockchain/projects/IBC-Integration/contracts/javascore
---------------------------------------------------------------------------------
export CW_IBC_CORE=$CW_DIR/cw_ibc_core.wasm

export CW_ICON_LIGHT_CLIENT=$CW_DIR/cw_icon_light_client.wasm
export CW_ICS08_ICON_LIGHT_CLIENT=$CW_DIR/cw_08wasm_icon_light_client.wasm

export CW_XCALL=$CW_DIR/cw_xcall.wasm
export CW_XCALL_CONNECTION=$CW_DIR/cw_xcall_ibc_connection.wasm
export CW_XCALL_DAPP=$CW_DIR/cw_mock_dapp_multi.wasm

---------------------------------------------------------------------------------
export JS_IBC_CORE=$JS_DIR/ibc/build/libs/ibc-0.1.0-optimized.jar

export JS_TM_LIGHT_CLIENT=$JS_DIR/lightclients/tendermint/build/libs/tendermint-0.1.0-optimized.jar
export JS_ICS08_TM_LIGHT_CLIENT=$JS_DIR/lightclients/ics-08-tendermint/build/libs/ics-08-tendermint-0.1.0-optimized.jar

export JS_XCALL=$PWD/artifacts/xcall.jar
export JS_XCALL_DAPP=$PWD/artifacts/dapp_multi.jar

export JS_IBC_MOCK_DAPP=$PWD/artifacts/mockapp-0.1.0-optimized.jar

export JS_XCALL_CONNECTION=$JS_DIR/xcall-connection/build/libs/xcall-connection-0.1.0-optimized.jar

# export JS_ICS20_APP=$JS_DIR/ics20/build/libs/ics20-0.1.0-optimized.jar
export JS_ICS20_APP=$PWD/artifacts/ics20-0.1.0-optimized.jar

export JS_IRC2_TRADEABLE=$PWD/artifacts/irc2Tradeable-0.1.0-optimized.jar

export JS_ADDR_GOVERNANCE=cx0000000000000000000000000000000000000001

####################  CREATE DIRECTORY IF NOT EXISTS #######################
mkdir -p $PWD/env/ARCHWAY
mkdir -p $PWD/env/CENTAURI
mkdir -p $PWD/env/INJECTIVE
mkdir -p $PWD/env/ICON

###########################################  PROPOSALS ####################################
export GOV_ADDR_CENTAURI=pica10d07y265gmmuvt4z0w9aw880jnsr700jp7sqj5
export WASM_08_ICON_LIGHT_CLIENT_PROPOSAL_FILE=$PWD/proposals/wasm-08/iconLightClient/wasmpush-proposal.json
export WASM_08_ICON_LIGHT_CLIENT_PROPOSAL_ID=$PWD/proposals/wasm-08/iconLightClient/.proposal_id


###############################################################################
############################### BIG MAN BIG BOSS ##############################
###############################################################################
function get() {
    # Using variable indirection to get the value of the variable whose name is passed as an argument
    echo "${!1}"
}

function getAddr() {
	echo "$PWD/env/$1/$2"
}