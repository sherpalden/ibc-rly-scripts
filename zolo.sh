xcall_wasm=inj1mxqp64mphz2t79hz7dr4xl9593v7mrpy3srehm
xcall_icon=cx15a339fa60bd86225050b22ea8cd4a9d7cd8bb83

icon_network_id=0x2.icon
wasm_network_id=injective-888

ibc_handler_wasm=
ibc_handler_icon=

ibc_conn_wasm=inj1rvqt3h2k70kkpc5cyfnkrxn9dzqpf3pf6l8t73
ibc_conn_icon=cx7acee950ca6ca031c6e491ba9e0117d97ff48f55

central_conn_wasm=inj1fhn37xp52cgjesvt8ne47acej7vpe3vvued3p9
central_conn_icon=cx8d02efb10359105f7e033149556eaea531a3740e

mock_dapp_wasm=inj1ve9pmrjfv2fct3mkv22s5svrzaanm4gsjyepeu
mock_dapp_icon=cx1612636339cfcd5459bc0ff3b26bc888630070da

wasm_key=admin
wasm_node=https://injective-testnet-rpc.publicnode.com:443
wasm_gas_prices=500000000inj

icon_key=$HOME/blockchain/wallets/icon/relayer-testnet.json
icon_pass=Password_123
icon_node=https://lisbon.net.solidwallet.io/api/v3/

function send_message_wasm() {
    rollback="[38,246,198,198,38,22,54]"
    rollback_msg="[82,111,108,108,98,97,99,107,68,97,116,97,84,101,115,116,105,110,103]"
    msg=$rollback

    icon_network_id=0x3.icon
    mock_dapp_icon=cxd8ba294771e3ec0c7f9911706c71cd5c5630a013
    xcall_wasm=inj1yqp9llvrgywh0a060kgz4409skwlqqnznaj55r

    # call_params="{\"send_call_message\":{\"to\":\"$icon_network_id/$dapp_icon\",\"data\":$msg,\"sources\":$sources,\"destinations\":$destinations}}"
    call_params="{\"send_call_message\":{\"to\":\"$icon_network_id/$mock_dapp_icon\",\"data\":$msg}}"

    tx="injectived tx wasm execute \
        $xcall_wasm \
        '$call_params' \
        --from $wasm_key --keyring-backend test --node $wasm_node --chain-id $wasm_network_id --gas-prices $wasm_gas_prices --gas auto --gas-adjustment 1.5 \
        --amount 50000000000000000inj \
        -y --output json"

    echo $tx
    eval $tx
}


function send_message_icon() {
    helloMsg=0x68656c6c6f
    rollbackMsg=0x726f6c6c6261636b

    msg=$helloMsg

    # sources="[\"$ibc_conn_icon\"]"
    # destinations="[\"$ibc_conn_wasm\"]"

    sources="[\"cx07300971594d7160a9ec62e4ec68d8fa10b9d9dc\"]"
    destinations="[\"4vfkXyxMxptmREF3RaFKUwnPRuqsXJJeUFzpCjPSSVMb\"]"

    # param="{\"params\":{\"_to\":\"$wasm_network_id/$mock_dapp_wasm\",\"_data\":\"$msg\",\"_sources\":$sources,\"_destinations\":$destinations}}"
    param="{\"params\":{\"_to\":\"solana/8tJx9uFHvK33etttKFi8XWHEKMo3q3K6UdSWLTTKnUvX\",\"_data\":\"$msg\",\"_sources\":$sources,\"_destinations\":$destinations}}"
	
    tx="goloop rpc sendtx call \
	    --to $xcall_icon \
	    --method sendCallMessage \
	    --raw '$param' \
        --uri $icon_node --nid 0x2 \
        --key_store $icon_key --key_password $icon_pass \
        --value 5000000000000000000 \
        --step_limit 100000000000"
    
    echo $tx
    eval $tx
}

send_message_wasm

# tx_result=$(injectived query tx 58E8594E08245D3963204C5AFD9A8163C0A97D04B49924F1F83777549D9780AF --node https://injective-testnet-rpc.publicnode.com:443 --output json)
# # echo $tx_result | jq -r .events
# code_id=$(echo $tx_result | jq -r '.events[] | select(.type == "cosmwasm.wasm.v1.EventCodeStored") | .attributes[] | select(.key == "code_id") | .value')
# echo "code id: $code_id"