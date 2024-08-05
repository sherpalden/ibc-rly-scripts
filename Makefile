
.PHONY: clean
clean:
	rm -Rf env

config:
	./cfg.sh

stop_all_nodes:
	./nodes.sh stop-node-centauri
	./nodes.sh stop-node-archway
	./nodes.sh stop-node-icon

restart_icon_centauri:
	./nodes.sh stop-node-centauri
	./nodes.sh stop-node-icon

	./nodes.sh start-node-centauri
	./nodes.sh start-node-icon
	
restart_all_nodes:
	./nodes.sh stop-node-centauri
	./nodes.sh stop-node-archway
	./nodes.sh stop-node-icon

	./nodes.sh start-node-centauri
	./nodes.sh start-node-archway
	./nodes.sh start-node-icon


start_node_icon:
	./nodes.sh start-node-icon
stop_node_icon:
	./nodes.sh stop-node-icon

start_node_archway:
	./nodes.sh start-node-archway
stop-node-archway:
	./nodes.sh stop-node-archway

start-node-centauri:
	./nodes.sh start-node-centauri
	sleep 5
stop-node-centauri:
	./nodes.sh stop-node-centauri

setup-all:
	./icon.sh setup-icon
	sleep 5
	./wasm.sh setup-archway

	sleep 5

	./icon.sh deploy xcall-dapp ARCHWAY

	sleep 5
	
	./wasm.sh deploy xcall-dapp ARCHWAY

	./cfg.sh

setup-icon-inj:
	./icon.sh setup-icon
	sleep 5
	./wasm.sh setup-injective

	sleep 5

	./icon.sh deploy xcall-dapp INJECTIVE

	sleep 5
	
	./wasm.sh deploy xcall-dapp INJECTIVE

	./cfg.testnet.sh


handshake-icon-archway:
	rly tx clients icon-archway --client-tp "10000000m" --override
	sleep 6
	rly tx conn icon-archway
	sleep 6

	./icon.sh configure-connection-icon-archway
	sleep 6
	./wasm.sh configure-connection-icon-archway
	sleep 6

	rly tx chan icon-archway --src-port=xcall --dst-port=xcall

handshake-icon-injective:
	rly tx clients icon-injective --client-tp "10000000m" --override
	sleep 6
	rly tx conn icon-injective --timeout 5m
	sleep 6

	./icon.sh configure-connection-icon-injective
	sleep 6
	./wasm.sh configure-connection-icon-injective
	sleep 6

	rly tx chan icon-injective --src-port=xcall --dst-port=xcall


handshake-icon-centauri:
	./nodes.sh create-client-icon-centauri
	sleep 5
	rly tx conn icon-centauri
	sleep 5
	rly tx chan icon-centauri --src-port=transfer --dst-port=transfer

transfer-token-icon-centauri:
	./icon.sh transfer-token CENTAURI

transfer-token-centauri-icon:
	./wasm.sh transfer_token_icon

send-msg-icon-to-centauri:
	./icon.sh send-message CENTAURI

send-msg-icon-to-archway:
	./icon.sh send-message ARCHWAY

send-msg-archway-to-icon:
	./wasm.sh send-message-icon ARCHWAY