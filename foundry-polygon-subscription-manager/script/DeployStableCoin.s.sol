// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.19;

import {Script} from "forge-std/Script.sol";
import {StableCoin} from "../src/StableCoin.sol";
import {HelperConfig} from "./HelperConfig.s.sol";

contract DeployStableCoin is Script {
    function run() external returns (StableCoin stableCoin) {
        HelperConfig helperConfig = new HelperConfig();
        (uint256 deployerKey, address priceFeed) = helperConfig.activeNetworkConfig();

        vm.startBroadcast(deployerKey);
        stableCoin = new StableCoin();
        vm.stopBroadcast();
    }
}
