// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {Script} from "forge-std/Script.sol";
import {SubscriptionManager} from "../src/SubscriptionManager.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {StableCoin} from "../src/StableCoin.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {DeployStableCoin} from "./DeployStableCoin.s.sol";

contract DeployTestSubscriptionManager is Script {
    function run() external returns (SubscriptionManager, StableCoin, HelperConfig) {
        // FOr local only
        DeployStableCoin deployStableCoin = new DeployStableCoin();
        StableCoin acceptedToken = deployStableCoin.run();

        HelperConfig helperConfig = new HelperConfig();
        (uint256 deployerKey, address ethPriceFeed) = helperConfig.activeNetworkConfig();

        vm.startBroadcast(deployerKey);
        SubscriptionManager subscriptionManager = new SubscriptionManager(ERC20(acceptedToken), ethPriceFeed);
        vm.stopBroadcast();

        return (subscriptionManager, acceptedToken, helperConfig);
    }
}
