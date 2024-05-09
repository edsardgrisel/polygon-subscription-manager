// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {MockV3Aggregator} from "../test/mock/MockV3Aggregator.sol";
import {Script} from "forge-std/Script.sol";

contract HelperConfig is Script {
    NetworkConfig public activeNetworkConfig;

    uint8 public constant DECIMALS = 8;
    int256 public constant INITIAL_PRICE = 2000e8;

    struct NetworkConfig {
        uint256 deployerKey;
        address priceFeed;
    }

    event HelperConfig__CreatedMockPriceFeed(address priceFeed);

    constructor() {
        if (block.chainid == 1442) {
            activeNetworkConfig = getCardonaEthConfig();
        } else {
            activeNetworkConfig = getOrCreateAnvilEthConfig();
        }
    }

    function getCardonaEthConfig() public view returns (NetworkConfig memory cardonaNetworkConfig) {
        cardonaNetworkConfig = NetworkConfig({
            deployerKey: vm.envUint("ZKEVM_TESTNET_PRIVATE_KEY"),
            priceFeed: 0xd94522a6feF7779f672f4C88eb672da9222f2eAc
        });
    }

    function getOrCreateAnvilEthConfig() public returns (NetworkConfig memory anvilNetworkConfig) {
        // Check to see if we set an active network config
        if (activeNetworkConfig.priceFeed != address(0)) {
            return activeNetworkConfig;
        }
        vm.startBroadcast();
        MockV3Aggregator mockPriceFeed = new MockV3Aggregator(DECIMALS, INITIAL_PRICE);
        vm.stopBroadcast();
        emit HelperConfig__CreatedMockPriceFeed(address(mockPriceFeed));

        anvilNetworkConfig =
            NetworkConfig({deployerKey: vm.envUint("ANVIL_PRIVATE_KEY_ZERO"), priceFeed: address(mockPriceFeed)});
    }
}
