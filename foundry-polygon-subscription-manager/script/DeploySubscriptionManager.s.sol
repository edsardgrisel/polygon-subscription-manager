// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {Script} from "forge-std/Script.sol";
import {SubscriptionManager} from "../src/SubscriptionManager.sol";
import {HelperConfig} from "./HelperConfig.s.sol";

contract DeploySubscriptionManager is Script {
    function run() external returns (SubscriptionManager, HelperConfig) {
        HelperConfig helperConfig = new HelperConfig();
        (uint256 deployerKey, address priceFeed) = helperConfig.activeNetworkConfig();

        vm.startBroadcast(deployerKey);
        SubscriptionManager subscriptionManager = new SubscriptionManager(priceFeed);
        vm.stopBroadcast();
        return (subscriptionManager, helperConfig);
    }
}
