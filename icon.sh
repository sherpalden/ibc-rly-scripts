#!/bin/bash

source const.sh
source utils.sh

function icon_wait_tx() {
    local tx_hash="$1"
    if [[ -z "$tx_hash" ]]; then
        handle_error "tx_hash is empty"
    fi

    echo "Tx Hash: $tx_hash"

    local tx_receipt
    local tx="goloop rpc --uri $ICON_NODE_URI txresult $tx_hash"
    while :; do
        tx_receipt=$(eval "$tx" 2>/dev/null)
        if [[ $tx_receipt == *"Error:"* ]] || [[ $tx_receipt == "" ]]; then
            echo "Transaction is still being processed. Waiting..." >&2
            sleep 1 
        else
            break 
        fi
    done

    local status=$(jq -r <<<"$tx_receipt" .status)
    if [[ $status == "0x1" ]]; then
        log "txn success with status: $status"
    else
        handle_error "txn failed with status: $status"
    fi
}

function save_address() {
    log_stack
    local ret=1
    local tx_hash=$1
    local addr_loc=$2
    [[ -z $tx_hash ]] && return
    local txr=$(goloop rpc --uri "$ICON_NODE_URI" txresult "$tx_hash" 2>/dev/null)
    local score_address=$(jq <<<"$txr" -r .scoreAddress)
    echo $score_address > $addr_loc
    log "contract address : $score_address"
}

function deploy_contract() {
	log_stack
	local jarFile=$1
    local addrLoc=$2
	requireFile $jarFile "$jarFile does not exist"
	log "deploying contract ${jarFile##*/}"

	local params=()
    for i in "${@:3}"; do params+=("--param $i"); done

    local tx_hash=$(
        goloop rpc sendtx deploy $jarFile \
	    	--content_type application/java \
	    	--to cx0000000000000000000000000000000000000000 \
	    	$ICON_COMMON_ARGS \
	    	${params[@]} | jq -r .
    )
   	icon_wait_tx "$tx_hash"
    save_address "$tx_hash" $addrLoc
}

function icon_send_tx() {
    log_stack
    local address=$1
    require_contract_addr $address

    local method=$2

    log "calling ${method}"

    local params=()
    for i in "${@:3}"; do params+=("--param $i"); done

    local tx_hash=$(
        goloop rpc sendtx call \
            --to "$address" \
            --method "$method" \
            $ICON_COMMON_ARGS \
            ${params[@]} | jq -r .
    ) || handle_error "failed to send tx to icon"

    icon_wait_tx "$tx_hash"
}

function deploy_ibc_core(){
    log_stack
    deploy_contract $JS_IBC_CORE $(getAddr ICON .ibcCore)
}

function deploy_ics20_app() {
    log_stack

    local ibc_handler=$(cat $(getAddr ICON .ibcCore))
    require_contract_addr $ibc_handler

    local irc_bytecode=$(cat $IRC_TOKEN_FILE)

    deploy_contract $JS_ICS20_APP $(getAddr ICON .ics20App) _ibcHandler=${ibc_handler} _serializeIrc2=${irc_bytecode}
}

function update_ics20_app() {
    log_stack
    local ics20_app_addr=$(cat $(getAddr ICON .ics20App))

    local ibc_handler=$(cat $(getAddr ICON .ibcCore))
    require_contract_addr $ibc_handler

    local irc_bytecode=$(cat $IRC_TOKEN_FILE)

    local tx_hash=$(goloop rpc sendtx deploy $JS_ICS20_APP  \
        --content_type application/java \
        --to $ics20_app_addr \
        --param _ibcHandler=$ibc_handler \
        --param _serializeIrc2=$irc_bytecode \
        $ICON_COMMON_ARGS | jq -r .)

    icon_wait_tx "$tx_hash"
}

function register_cosmos_token(){
	local ics20AppAddress=$(cat $(getAddr ICON .ics20App))
    icon_send_tx $ics20AppAddress "registerCosmosToken" name="transfer/channel-0/ppica" symbol=ppica decimals=12 
}

function deploy_irc2_token(){
    local name=$1
    local symbol=$2
    local decimals=$3
    deploy_contract $JS_IRC2_TRADEABLE $(getAddr ICON .irc2_$name) _name=$name _symbol=$symbol _decimals=$decimals
}

function register_icon_token(){
    deploy_irc2_token icx icx 18 || handle_error "failed to deploy irc2 icx token"

	local ics20AppAddress=$(cat $(getAddr ICON .ics20App))
    local token_address=$(cat $(getAddr ICON .irc2_icx))
    icon_send_tx $ics20AppAddress "registerIconToken" tokenAddress=$token_address 
}

function open_btp_network() {
    local ibc_handler=$(cat $(getAddr ICON .ibcCore))
    require_contract_addr $ibc_handler

    icon_send_tx $JS_ADDR_GOVERNANCE "openBTPNetwork" networkTypeName=eth name=eth owner=${ibc_handler}
}

function deploy_tm_light_client() {
    local ibc_handler=$(cat $(getAddr ICON .ibcCore))
    require_contract_addr $ibc_handler

    deploy_contract $JS_TM_LIGHT_CLIENT $(getAddr ICON .tmLightClient) ibcHandler=${ibc_handler}
}

function register_tm_light_client() {
    local tm_client=$(cat $(getAddr ICON .tmLightClient))
    require_contract_addr $tm_client

    local ibc_handler=$(cat $(getAddr ICON .ibcCore))
    require_contract_addr $ibc_handler

    icon_send_tx $ibc_handler "registerClient" clientType="07-tendermint" client="${tm_client}"
}

function deploy_ics08_tm_light_client() {
    local ibc_handler=$(cat $(getAddr ICON .ibcCore))
    require_contract_addr $ibc_handler

    deploy_contract $JS_ICS08_TM_LIGHT_CLIENT $(getAddr ICON .ics08tmLightClient) ibcHandler=${ibc_handler}
}

function register_ics08_tm_light_client() {
    local tm_client=$(cat $(getAddr ICON .ics08tmLightClient))
    require_contract_addr $tm_client

    local ibc_handler=$(cat $(getAddr ICON .ibcCore))
    require_contract_addr $ibc_handler

    icon_send_tx $ibc_handler "registerClient" hashType=1 clientType="ics08-tendermint" client="${tm_client}"
}

function deploy_xcall() {
    deploy_contract $JS_XCALL $(getAddr ICON .xcall) networkId=${ICON_NETWORK_ID}
}

function deploy_xcall_connection() {
    local xcall=$(cat $(getAddr ICON .xcall))
    require_contract_addr $xcall

    local ibc_handler=$(cat $(getAddr ICON .ibcCore))
    require_contract_addr $ibc_handler

    deploy_contract $JS_XCALL_CONNECTION $(getAddr ICON .xcallConnection) _xCall=${xcall} _ibc=${ibc_handler} _port=${PORT_ID_XCALL_CONNECTION}
}

function bind_xcall_connection_port(){
    local xcall_connection=$(cat $(getAddr ICON .xcallConnection))
    require_contract_addr $xcall_connection

    local ibc_handler=$(cat $(getAddr ICON .ibcCore))
    require_contract_addr $ibc_handler

    icon_send_tx $ibc_handler "bindPort" moduleAddress=${xcall_connection} portId=${PORT_ID_XCALL_CONNECTION}
}

function bind_ics20_app_port(){
    local ics20_app=$(cat $(getAddr ICON .ics20App))
    require_contract_addr $ics20_app

    local ibc_handler=$(cat $(getAddr ICON .ibcCore))
    require_contract_addr $ibc_handler

    icon_send_tx $ibc_handler "bindPort" moduleAddress=${ics20_app} portId=${PORT_ID_ICS20_APP}
}

function send_message_wasm() {
    log_stack

    dest_chain=$1
    
    rollback="0x726f6c6c6261636b"

    msg=$rollback
    rollback_msg="0x526f6c6c6261636b4461746154657374696e67"

    wasm_network_id=$(get ${dest_chain}_NETWORK_ID)

    local xcall_dapp_icon=$(cat $(getAddr ICON .xcallDapp))
    local xcall_dapp_wasm=$(cat $(getAddr $dest_chain .xcallDapp))

    icon_send_tx $xcall_dapp_icon "sendMessage" _to=$wasm_network_id/$xcall_dapp_wasm _data=$msg _rollback=$rollback_msg
}

function configure_connection() {
    log_stack

    local dest_chain=$1

    local relay_path=$2

    local dest_nid=$(get ${dest_chain}_NETWORK_ID)

    local src_chain_id=$(yq -e .paths.${relay_path}.src.chain-id $RELAY_CFG_FILE)
    local dst_chain_id=$(yq -e .paths.${relay_path}.dst.chain-id $RELAY_CFG_FILE)

    local client_id=""
    local conn_id=""

    if [[ $src_chain_id == $ICON_CHAIN_ID ]]; then
        client_id=$(yq -e .paths.${relay_path}.src.client-id $RELAY_CFG_FILE)
        conn_id=$(yq -e .paths.${relay_path}.src.connection-id $RELAY_CFG_FILE)
    elif [[ $dst_chain_id == $ICON_CHAIN_ID ]]; then
        client_id=$(yq -e .paths.${relay_path}.dst.client-id $RELAY_CFG_FILE)
        conn_id=$(yq -e .paths.${relay_path}.dst.connection-id $RELAY_CFG_FILE)
    fi

    local dst_port_id=$PORT_ID_XCALL_CONNECTION
    local xcall_connection=$(cat $(getAddr ICON .xcallConnection))

    icon_send_tx $xcall_connection "configureConnection" \
        connectionId=${conn_id}  counterpartyPortId=${dst_port_id} \
        counterpartyNid=${dest_nid} clientId=${client_id} \
        timeoutHeight=1000000

    local xcall=$(cat $(getAddr ICON .xcall))
    icon_send_tx $xcall "setDefaultConnection" _nid=${dest_nid} _connection=${xcall_connection}
}

function deploy_xcall_dapp() {
    log_stack

    dest_chain=$1
    local dest_nid=$(get ${dest_chain}_NETWORK_ID)
    
    local xcall=$(cat $(getAddr ICON .xcall))
    require_contract_addr $xcall

    deploy_contract $JS_XCALL_DAPP $(getAddr ICON .xcallDapp) _callService=$xcall

    local xcall_connection_src=$(cat $(getAddr ICON .xcallConnection))
    local xcall_connection_dst=$(cat $(getAddr $dest_chain .xcallConnection))
    local xcall_dapp=$(cat $(getAddr ICON .xcallDapp))

    icon_send_tx $xcall_dapp "addConnection" nid=$dest_nid source=$xcall_connection_src destination=$xcall_connection_dst
}

function transfer_icx_to_wasm(){
	local ics20_app_addr=$(cat $(getAddr ICON .ics20App))

	local receiver_account_addr=pica1hj5fveer5cjtn4wd6wstzugjfdxzl0xpas3hgy

    local raw_params='{"params":{"receiver":"'"$receiver_account_addr"'","sourcePort":"transfer","sourceChannel":"channel-0","timeoutHeight":{"revisionHeight":"134234","revisionNumber":"1"},"timeoutTimestamp":"0"}}'

    local query="goloop rpc sendtx call --to $ics20_app_addr --method sendICX --raw '$raw_params' --value 100 --uri $ICON_NODE_URI  --nid $ICON_NID  --step_limit 100000000000 --key_store $ICON_GENESIS_KEY_STORE --key_password $ICON_GENESIS_KEY_PASSWORD"

	echo $query

	local tx_hash=$($query)
    icon_wait_tx $tx_hash
}

function get_token_address() {
    local denom=$1
    local ics20_app_addr=$(cat $(getAddr ICON .ics20App))

    local query="goloop rpc call \
        --to $ics20_app_addr \
        --method getTokenContractAddress \
        --param denom=$denom \
        --uri $ICON_NODE_URI"
    
    echo $($query)

}

function transfer_token_to_wasm(){
    local dest_chain=$1
    local toUser=$2
    
    local token=$3
    local channel=channel-0
    local denom=transfer/$channel/$token

	local ics20_app_addr=$(cat $(getAddr ICON .ics20App))

    local token_address=$(get_token_address $denom)

	local sender=$(get_address_from_keystore $ICON_GENESIS_KEY_STORE)
    local receiver=$(get_address_from_key $dest_chain $toUser)

    local amount=10
    local memo=""

    local data="{\"method\": \"sendFungibleTokens\", \"params\": {\"denomination\": \"$denom\", \"amount\": $amount, \"sender\": \"$sender\", \"receiver\": \"$receiver\", \"sourcePort\": \"transfer\", \"sourceChannel\": \"$channel\", \"timeoutHeight\": {\"latestHeight\": 2387937, \"revisionNumber\": 5}, \"timeoutTimestamp\": 0, \"memo\": \"$memo\"}}"
    local hex_data=$(str_to_hex "$data")

    local query="goloop rpc sendtx call \
        --to $token_address \
        --method transfer \
        --param _to=$ics20_app_addr \
        --param _value=$amount \
        --param _data=$hex_data \
        --uri $ICON_NODE_URI  --nid $ICON_NID  --step_limit 100000000000 --key_store $ICON_GENESIS_KEY_STORE --key_password $ICON_GENESIS_KEY_PASSWORD"

	echo $query

	local tx_hash=$($query)
    icon_wait_tx $tx_hash
}

function checkBalance(){
    local account_addr=$(get_address_from_keystore $ICON_MINTER_KEY_STORE)
    
	local denom=transfer/channel-1/stake

	local ics20_bank_addr=cx8ed956211dba69aae88ba083f361501aa2143e5c

	local call="goloop rpc call --to $ics20_bank_addr --method balanceOf --uri $ICON_NODE_URI --param _owner=$account_addr"

    echo "tx call: $call"
    balance=$($call)

	echo "balance is: " $(hex_to_decimal $balance)
}

function stress_start(){
    stress_icon_archway
    stress_icon_centauri
}

function setup_icon() {
    log_stack

    deploy_ibc_core

    open_btp_network

    deploy_tm_light_client

    register_tm_light_client

    # deploy_ics08_tm_light_client

    # register_ics08_tm_light_client

    deploy_xcall

    deploy_xcall_connection

    bind_xcall_connection_port
    
    # deploy_ics20_app

    # bind_ics20_app_port

    # register_cosmos_token

    # register_icon_token
}


if [ $# -lt 1 ]; then
    echo "Error: Invalid number of arguments."
    usage
    exit 1
fi

ACTION=$1
CONTRACT=$2

case "$ACTION" in
    test)
        str_to_bytes NEPAL
    ;;
    check-balance)
        checkBalance
    ;;
    setup-icon)
        setup_icon 
    ;;
    deploy)
        case "$CONTRACT" in
            ibc-core)
                deploy_ibc_core
                ;;
			tm-light-client)
                deploy_tm_light_client
                ;;
            xcall)
                deploy_xcall
                ;;
            xcall-dapp)
                deploy_xcall_dapp $3
            ;;
			xcall-connection)
				deploy_xcall_connection
			;;
            ics20-app)
                deploy_ics20_app
            ;;
            *)
                echo "Error: Unknown contract type '$CONTRACT' for deploying."
                ;;
        esac
    ;;
    open-btp-network)
        open_btp_network
    ;;
    register-tm-client)
        register_tm_light_client
    ;;
    bind-xcall-connection-port)
        bind_xcall_connection_port
    ;;
    bind-ics20-app-port)
        bind_ics20_app_port
    ;;
	configure-connection-icon-archway)
		configure_connection ARCHWAY icon-archway
	;;
    configure-connection-icon-injective)
		configure_connection INJECTIVE icon-injective
	;;
	configure-connection-icon-centauri)
		configure_connection CENTAURI icon-centauri
	;;
    send_message)
        send_message_wasm $2
    ;;
    register_cosmos_token)
        register_cosmos_token
    ;;
    register_icon_token)
        register_icon_token
    ;;
    get_token_address)
        get_token_address $2
    ;;
    transfer_icx)
        transfer_icx_to_wasm
    ;;
    transfer-token)
        transfer_token_to_wasm $2 $3 $4
    ;;
    update-ics20-app)
        update_ics20_app
    ;;
    *)
        echo "Error: Unknown action '$ACTION'."
        ;;
esac