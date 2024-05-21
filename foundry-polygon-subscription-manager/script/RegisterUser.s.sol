// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {Script} from "forge-std/Script.sol";
import {SubscriptionManager} from "../src/SubscriptionManager.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {StableCoin} from "../src/StableCoin.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract RegisterUser is Script {
    function run(SubscriptionManager subscriptionManager) external {
        HelperConfig helperConfig = new HelperConfig();
        (uint256 deployerKey, address ethPriceFeed) = helperConfig.activeNetworkConfig();

        vm.startBroadcast(deployerKey);
        subscriptionManager.registerUser(vm.envAddress("ANVIL_PUBLIC_KEY_ONE"));
        vm.stopBroadcast();
    }
}
