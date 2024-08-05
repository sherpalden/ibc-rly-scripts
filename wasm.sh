#!/bin/bash

source const.sh
source utils.sh

function create_accounts() {
	file_content=$(cat $HOME/mnemonics.json)
	for row in $(echo "${file_content}" | jq -r '.[] | @base64'); do
		_jq() {
			echo "${row}" | base64 --decode | jq -r "${1}"
		}
		USER=$(_jq '.name')
		USER_MNEMONIC=$(_jq '.mnemonics')
		echo $USER_MNEMONIC | archwayd keys add $USER --recover --keyring-backend test
		echo $USER_MNEMONIC | picad keys add $USER --recover --keyring-backend test

		genesis_addr_arch=$(get_address_from_key ARCHWAY genesis-local-1)
		genesis_addr_cent=$(get_address_from_key CENTAURI genesis-local)

		rcv_addr_arch=$(get_address_from_key ARCHWAY $USER)
		rcv_addr_cent=$(get_address_from_key CENTAURI $USER)

		ARCHWAY_COMMON_ARGS=" --keyring-backend $WASM_KEYRING_BACKEND --node ${ARCHWAY_NODE_URI} --chain-id ${ARCHWAY_CHAIN_ID} --gas-prices ${ARCHWAY_GAS_PRICE}${ARCHWAY_DENOM} --gas auto --gas-adjustment 1.5 "
		CENTAURI_COMMON_ARGS=" --keyring-backend $WASM_KEYRING_BACKEND --node ${CENTAURI_NODE_URI} --chain-id ${CENTAURI_CHAIN_ID} --gas-prices ${CENTAURI_GAS_PRICE}${CENTAURI_DENOM} --gas auto --gas-adjustment 1.5 "

		archwayd tx bank send $genesis_addr_arch $rcv_addr_arch 1000000000stake $ARCHWAY_COMMON_ARGS --yes
		sleep 3

		picad tx bank send $genesis_addr_cent $rcv_addr_cent 1000000000stake $CENTAURI_COMMON_ARGS --yes
		sleep 3
	done
}

function check_balance() {
	file_content=$(cat $HOME/mnemonics.json)
	for row in $(echo "${file_content}" | jq -r '.[] | @base64'); do
		_jq() {
			echo "${row}" | base64 --decode | jq -r "${1}"
		}
		USER=$(_jq '.name')
		# addr_arch=$(get_address_from_key ARCHWAY $USER)
		addr_cent=$(get_address_from_key CENTAURI $USER)

		# balance_arch=$(archwayd query bank balances $addr_arch)

		balance_cent=$(picad query bank balances $addr_cent)

		# echo "balance arch: $balance_arch"
		echo "------"
		echo "balance cent: $balance_cent"
	done
}

function deploy_contractV1() {
	log_stack

	local chain=$1
	local wasm_file=$2
	local addr_loc=$3
	local init_args=$4

	binary=$(get ${chain}_BINARY)
	common_args=$(get ${chain}_COMMON_ARGS)
	node_uri=$(get ${chain}_NODE_URI)

	requireFile ${wasm_file} "${wasm_file} does not exist"
	log "deploying contract ${wasm_file##*/}"

	local store_res=$($binary tx wasm store $wasm_file $common_args --yes --output json --broadcast-mode sync)
	local store_tx_hash=$(echo $store_res | jq -r '.txhash')
	echo "Store Tx Hash: $store_tx_hash"
	local store_tx_result=$(wait_for_tx_result $chain $store_tx_hash)
	local code_id=$(echo $store_tx_result | jq -r '.logs[0].events[] | select(.type=="store_code") | .attributes[] | select(.key=="code_id") | .value')
	log "received code id ${code_id}"

	local admin=$($binary keys show $WASM_GENESIS_KEY --keyring-backend $WASM_KEYRING_BACKEND --output=json | jq -r .address)
	local init_res=$($binary tx wasm instantiate $code_id $init_args $common_args --label "github.com/izyak/icon-ibc" --admin $admin -y)

	while :; do
		local addr=$($binary query wasm lca "${code_id}" --node $node_uri --output json | jq -r '.contracts[-1]') 
		if [ "$addr" != "null" ]; then
	        break
	    fi
	    sleep 2
	done

	local contract=$($binary query wasm lca "${code_id}" --node $node_uri --output json | jq -r '.contracts[-1]')
	log "${wasm_file##*/} deployed at : ${contract}"
	echo $contract > $addr_loc
	sleep 5
}

function deploy_contract() {
	log_stack

	local chain=$1
	local wasm_file=$2
	local addr_loc=$3
	local init_args=$4

	binary=$(get ${chain}_BINARY)
	common_args=$(get ${chain}_COMMON_ARGS)
	node_uri=$(get ${chain}_NODE_URI)

	requireFile ${wasm_file} "${wasm_file} does not exist"
	log "deploying contract ${wasm_file##*/}"

	local store_res=$($binary tx wasm store $wasm_file $common_args --yes --output json --broadcast-mode sync)
	echo "store tx hash: $store_res"
	local store_tx_hash=$(echo $store_res | jq -r '.txhash')
	echo "Store Tx Hash: $store_tx_hash"
	local store_tx_result=$(wait_for_tx_result $chain $store_tx_hash)
	local code_id=$(echo $store_tx_result | jq -r '.events[] | select(.type == "cosmwasm.wasm.v1.EventCodeStored") | .attributes[] | select(.key == "code_id") | .value' | tr -d '"')
	log "received code id ${code_id}"

	local admin=$($binary keys show $WASM_GENESIS_KEY --keyring-backend $WASM_KEYRING_BACKEND --output=json | jq -r .address)
	local init_res=$($binary tx wasm instantiate $code_id $init_args $common_args --label "github.com/izyak/icon-ibc" --admin $admin -y)

	while :; do
		local addr=$($binary query wasm lca "${code_id}" --node $node_uri --output json | jq -r '.contracts[-1]') 
		if [ "$addr" != "null" ]; then
	        break
	    fi
	    sleep 2
	done

	local contract=$($binary query wasm lca "${code_id}" --node $node_uri --output json | jq -r '.contracts[-1]')
	log "${wasm_file##*/} deployed at : ${contract}"
	echo $contract > $addr_loc
	sleep 5
}

function check_txn_result() {
	log_stack
	local chain=$1
	local tx_hash=$2

	local tx_result=$(wait_for_tx_result $chain $tx_hash) || handle_error "failed to wait for tx result"

	local code=$(echo $tx_result | jq -r .code) || handle_error "failed to get code from tx result"

	if [ "$code" == "0" ]; then 
		log "txn successful"
	else
		handle_error "txn failure: $(echo $tx_result | jq -r .raw_log)"
	fi
}

function wait_for_tx_result() {
	local chain=$1
    local tx_hash=$2

	binary=$(get ${chain}_BINARY)
	node_uri=$(get ${chain}_NODE_URI)
	chain_id=$(get ${chain}_CHAIN_ID)

    while :; do
        local res=$($binary query tx $tx_hash --node $node_uri --chain-id $chain_id 2>&1)
		if [[ $res == *"tx ($tx_hash) not found"* ]]; then
            echo "Transaction is still being processed. Waiting..." >&2
            sleep 1 
        else
			local tx_result=$($binary query tx $tx_hash --node $node_uri --chain-id $chain_id --output json)
            echo "$tx_result"  # This will be captured by the caller
            break  # Exit the loop
        fi
    done
}

function execute_contract() {
	log_stack
	local chain=$1
	local contract_addr=$2
	local init_args=$3
	log "method and params ${init_args}"

	binary=$(get ${chain}_BINARY)
	node_uri=$(get ${chain}_NODE_URI)
	common_args=$(get ${chain}_COMMON_ARGS)

	local tx_hash=$(${binary} tx wasm execute ${contract_addr} ${init_args} $common_args -y --output json | jq -r .txhash) || handle_error "failed to execute contract"
	log "tx_hash : ${tx_hash}"
	check_txn_result $chain $tx_hash
}

function execute_contract_v1() {
	log_stack
	local chain=$1
	local contract_addr=$2
	local init_args=$3
	local from=$4
	log "method and params ${init_args}"

	binary=$(get ${chain}_BINARY)
	node_uri=$(get ${chain}_NODE_URI)
	common_args=$(get ${chain}_COMMON_ARGS_V1)

	local tx_hash=$(${binary} tx wasm execute ${contract_addr} ${init_args} --from $from $common_args -y --output json | jq -r .txhash) || handle_error "failed to execute contract"

	log "tx_hash : ${tx_hash}"
	check_txn_result $chain $tx_hash
}

function deploy_ibc_core() {
	chain=$1
	ibc_core_addr=$(getAddr $chain .ibcCore)
	deploy_contract $chain $CW_IBC_CORE $ibc_core_addr '{}'
}

function gen_ics08_wasm_proposal() {
	local wasm_file_path=$1
	local proposal_file=$2

	# Check if the file exists
	if [ ! -e "$wasm_file_path" ]; then
		echo "File not found: $wasm_file_path"
		exit 1
	fi

	local encoded_content=$(get_base64_encoded_file_content $wasm_file_path)

	# JSON content with encoded wasm_byte_code
	json_content='{
		"metadata": "ipfs://CID",
		"deposit": "100000001ppica",
		"title": "ICON Light Client",
		"summary": "summary",
		"messages": [
			{
				"@type": "/ibc.lightclients.wasm.v1.MsgPushNewWasmCode",
				"signer": "'"$GOV_ADDR_CENTAURI"'",
				"code": "'"$encoded_content"'"
			}
		]
	}'

	# Save the JSON content to a file
	echo "$json_content" > $proposal_file
}

function deploy_ics_08_icon_light_client() {
	log_stack

	chain=$1
	common_args=$(get ${chain}_COMMON_ARGS)
	binary=$(get ${chain}_BINARY)

	log "deploying ics-08 wasm icon light client contract ${CW_ICS08_ICON_LIGHT_CLIENT##*/}"

	gen_ics08_wasm_proposal $CW_ICS08_ICON_LIGHT_CLIENT $WASM_08_ICON_LIGHT_CLIENT_PROPOSAL_FILE

	local tx="$binary tx gov submit-proposal $WASM_08_ICON_LIGHT_CLIENT_PROPOSAL_FILE \
		$common_args --yes --output json"
	echo "executing: $tx"
	local res=$($tx)

	local tx_hash=$(echo $res | jq -r '.txhash')
	echo "tx Hash: $tx_hash"

	local tx_result=$(wait_for_tx_result $chain $tx_hash)

	local code=$(echo $tx_result | jq -r .code)

	if [ "$code" == "0" ]; then 
		log "txn successful"
		local proposal_id=$(echo $tx_result | jq -r '.events[] | select(.type == "submit_proposal") | .attributes[] | select(.key == "proposal_id") | .value')
		echo "proposal id: $proposal_id"
		echo $proposal_id > $WASM_08_ICON_LIGHT_CLIENT_PROPOSAL_ID
	else
		log "txn failure: $(echo $tx_result | jq -r .raw_log)"
	fi
}

function vote_ics_08_icon_light_client_proposal(){
	chain=$1
	common_args=$(get ${chain}_COMMON_ARGS)

	local proposal_id=$(cat $WASM_08_ICON_LIGHT_CLIENT_PROPOSAL_ID)
	local tx="picad tx gov vote $proposal_id yes $common_args --yes --output json"
	echo "executing: $tx"
	local res=$($tx)

	local tx_hash=$(echo $res | jq -r '.txhash')
	echo "tx Hash: $tx_hash"

	check_txn_result $chain $tx_hash
}

function deploy_icon_light_client() {
	chain=$1
	common_args=$(get ${chain}_COMMON_ARGS)

	local ibc_core_addr=$(cat $(getAddr $chain .ibcCore))

	local client_args="{\"ibc_host\":\"$ibc_core_addr\"}"
	deploy_contract $chain $CW_ICON_LIGHT_CLIENT $(getAddr $chain .iconLightClient) ${client_args}

	local icon_light_client_addr=$(cat $(getAddr $chain .iconLightClient))

	local register_client_args="{\"register_client\":{\"client_type\":\"iconclient\",\"client_address\":\"$icon_light_client_addr\"}}"
	execute_contract $chain $ibc_core_addr $register_client_args
}

function whitelist_relayer() {
	chain=$1
	common_args=$(get ${chain}_COMMON_ARGS)

	local relayer_address=$(get_address_from_key $chain $WASM_RELAYER_KEY)

	local tx="picad tx transmiddleware add-rly $relayer_address \
		$common_args --yes --output json"

	echo "executing: $tx"

	local res=$($tx)
	local tx_hash=$(echo $res | jq -r '.txhash')

	echo "Tx Hash: $tx_hash"

	check_txn_result $chain $tx_hash
}

function push_wasm() {
	local tx="picad tx ibc-wasm store-code $CW_ICS08_ICON_LIGHT_CLIENT $CENTAURI_COMMON_ARGS"
	echo $tx
	local output=$($tx)
	echo $output
}

function deploy_xcall() {
	chain=$1
	network_id=$(get ${chain}_NETWORK_ID)
	denom=$(get ${chain}_DENOM)

	xcall_addr_path=$(getAddr $chain .xcall)

	local xcall_args="{\"network_id\":\"$network_id\",\"denom\":\"$denom\"}"

	deploy_contract $chain $CW_XCALL $xcall_addr_path ${xcall_args}
}

function deploy_xcall_connection() {
	chain=$1
	network_id=$(get ${chain}_NETWORK_ID)
	denom=$(get ${chain}_DENOM)

	local ibc_core_addr=$(cat $(getAddr $chain .ibcCore))
	local xcall_addr=$(cat $(getAddr $chain .xcall))


	local connection_args="{\"ibc_host\":\"${ibc_core_addr}\",\"port_id\":\"${PORT_ID_XCALL_CONNECTION}\",\"xcall_address\":\"$xcall_addr\",\"denom\":\"$denom\"}"    
	deploy_contract $chain $CW_XCALL_CONNECTION $(getAddr $chain .xcallConnection) ${connection_args}

	local xcall_connection_addr=$(cat $(getAddr $chain .xcallConnection))

	local bind_port_args="{\"bind_port\":{\"port_id\":\"$PORT_ID_XCALL_CONNECTION\",\"address\":\"$xcall_connection_addr\"}}"
	execute_contract $chain ${ibc_core_addr} ${bind_port_args}
}

function deploy_xcall_dapp() {
	log_stack

	chain=$1

	local xcall_addr=$(cat $(getAddr $chain .xcall))

	local xcall_dapp_args="{\"address\":\"${xcall_addr}\"}"

	deploy_contract $chain $CW_XCALL_DAPP $(getAddr $chain .xcallDapp) $xcall_dapp_args

	local xcall_dapp_addr=$(cat $(getAddr $chain .xcallDapp))

	local xcall_connection_dst=$(cat $(getAddr ICON .xcallConnection))
    local xcall_connection_src=$(cat $(getAddr $chain .xcallConnection))

	local add_connection_args="{\"add_connection\":{\"src_endpoint\":\"$xcall_connection_src\",\"dest_endpoint\":\"$xcall_connection_dst\",\"network_id\":\"$ICON_NETWORK_ID\"}}"
	execute_contract $chain $xcall_dapp_addr $add_connection_args
}

function configure_connection() {
	log_stack
	local chain=$1
	local relay_path=$2

	wasm_chain_id=$(get ${chain}_CHAIN_ID)

	local src_chain_id=$(yq -e .paths.${relay_path}.src.chain-id $RELAY_CFG_FILE)
    local dst_chain_id=$(yq -e .paths.${relay_path}.dst.chain-id $RELAY_CFG_FILE)

    local client_id=""
    local conn_id=""

    if [[ $src_chain_id == $wasm_chain_id ]]; then
        client_id=$(yq -e .paths.${relay_path}.src.client-id $RELAY_CFG_FILE)
        conn_id=$(yq -e .paths.${relay_path}.src.connection-id $RELAY_CFG_FILE)
    elif [[ $dst_chain_id == $wasm_chain_id ]]; then
        client_id=$(yq -e .paths.${relay_path}.dst.client-id $RELAY_CFG_FILE)
        conn_id=$(yq -e .paths.${relay_path}.dst.connection-id $RELAY_CFG_FILE)
    fi

    local dst_port_id=$PORT_ID_XCALL_CONNECTION

    local configure_args="{\"configure_connection\":{\"connection_id\":\"$conn_id\",\"counterparty_port_id\":\"$dst_port_id\",\"counterparty_nid\":\"$ICON_NETWORK_ID\",\"client_id\":\"${client_id}\",\"timeout_height\":30000}}"
    local xcall_connection_addr=$(cat $(getAddr $chain .xcallConnection))

    execute_contract $chain $xcall_connection_addr $configure_args

    local xcall_addr=$(cat $(getAddr $chain .xcall))

    local default_conn_args="{\"set_default_connection\":{\"nid\":\"$ICON_NETWORK_ID\",\"address\":\"$xcall_connection_addr\"}}"
    execute_contract $chain $xcall_addr $default_conn_args
}

function send_message_icon() {
	log_stack

	chain=$1
	# from=$2

	# rollback message
	rollback="[38,246,198,198,38,22,54]"
	rollback_msg="[82,111,108,108,98,97,99,107,68,97,116,97,84,101,115,116,105,110,103]"

	msg=$rollback 


	# log "Sending from: $from"



	local xcall_dapp_wasm=$(cat $(getAddr $chain .xcallDapp))
	local xcall_dapp_icon=$(cat $(getAddr ICON .xcallDapp))

	local send_msg_args="{\"send_call_message\":{\"to\":\"$ICON_NETWORK_ID/$xcall_dapp_icon\",\"data\":$msg,\"rollback\":$rollback_msg}}"
	
	# execute_contract_v1 $chain ${xcall_dapp_wasm} ${send_msg_args} $from
	execute_contract $chain ${xcall_dapp_wasm} ${send_msg_args}
}

function send_message_icon_bulk() {
	for i in {1..20}; do
		send_message_icon ARCHWAY user$i
	done
}

function transfer_token_icon (){
	receiver_addr=$(get_address_from_keystore $ICON_MINTER_KEY_STORE)
	src_port=$PORT_ID_ICS20_APP
	src_channel=channel-0

	ibc_denom=ibc/$(get_hash 'transfer/channel-0/icx')

	from_user=$1

	local tx="picad tx ibc-transfer transfer $src_port $src_channel $receiver_addr 100000stake \
	--packet-timeout-height 1-500000 \
	--packet-timeout-timestamp 0 \
	--chain-id $CENTAURI_CHAIN_ID  \
	--from $from_user \
	--gas-prices 0.1stake \
	--gas-adjustment 1.5 \
	--gas auto --output json -y"

	echo "executing: $tx"

	local res=$($tx)

	local tx_hash=$(echo $res | jq -r '.txhash')

	log "tx_hash : ${tx_hash}"

	check_txn_result CENTAURI $tx_hash
}

function print_client_hash() {
	hash1=$(get_sha256sum_hex $CW_ICS08_ICON_LIGHT_CLIENT)

	echo "hash1: $hash1 and hash2: $hash2"
}

function setup_archway() {
	log_stack
	deploy_ibc_core ARCHWAY

	deploy_icon_light_client ARCHWAY

	deploy_xcall ARCHWAY

	deploy_xcall_connection ARCHWAY

	deploy_xcall_dapp ARCHWAY
}

function setup_injective() {
	log_stack
	deploy_ibc_core INJECTIVE

	deploy_icon_light_client INJECTIVE

	deploy_xcall INJECTIVE

	deploy_xcall_connection INJECTIVE
}

function setup_centauri() {
	log_stack

	deploy_ics_08_icon_light_client CENTAURI


	vote_ics_08_icon_light_client_proposal CENTAURI

	sleep 45

	whitelist_relayer CENTAURI
}


if [ $# -lt 1 ]; then
    echo "Error: Invalid number of arguments."
    usage
    exit 1
fi

ACTION=$1
CONTRACT=$2

case "$ACTION" in
	print_client_hash)
		print_client_hash
	;;
	send-to-icon-bulk)
		send_message_icon_bulk
	;;
	create-accounts)
		create_accounts
	;;
	check-balance)
		check_balance
	;;
	setup-archway)
		setup_archway
	;;
	setup_injective)
		setup_injective
	;;
	setup-centauri)
		setup_centauri
	;;
	deploy)
        case "$CONTRACT" in
            ibc-core)
                deploy_ibc_core $3
                ;;
			icon-light-client)
                deploy_icon_light_client $3
                ;;
			ics08-icon-light-client)
				deploy_ics_08_icon_light_client $3
			;;
            xcall)
                deploy_xcall $3
                ;;
			xcall-connection)
				deploy_xcall_connection $3
			;;
			xcall-dapp)
				deploy_xcall_dapp $3
			;;
            *)
                echo "Error: Unknown contract '$CONTRACT' for deploying."
                ;;
        esac
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
	send_message_icon)
		send_message_icon $2
	;;
	transfer_token_icon)
		transfer_token_icon $2
	;;
	push-wasm)
		push_wasm
	;;
	whitelist-relayer)
		whitelist_relayer CENTAURI
	;;
	vote_ics_08_icon_light_client_proposal)
		vote_ics_08_icon_light_client_proposal CENTAURI
	;;
    *)
        echo "Error: Unknown action '$ACTION'."
        ;;
esac