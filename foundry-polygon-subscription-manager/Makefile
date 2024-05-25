
NETWORK_ARGS := --rpc-url http://localhost:8545 --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 --broadcast

ifeq ($(findstring --network fuji,$(ARGS)),--network fuji)
	NETWORK_ARGS := --chain-id 43113 --rpc-url $(FUJI_RPC_URL) --private-key $(FUJI_PRIVATE_KEY) --broadcast  
endif

deploy: 
	@forge script script/DeploySubscriptionManager.s.sol:DeploySubscriptionManager $(NETWORK_ARGS) 

deployFuji:
	@forge script script/DeploySubscriptionManager.s.sol:DeploySubscriptionManager --chain-id 43113 --rpc-url $FUJI_RPC_URL --private-key $FUJI_PRIVATE_KEY --broadcast



updateFrontEndAbi: node script/updateFrontEndAbi.js

