// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {Script} from "forge-std/Script.sol";
import {SubscriptionManager} from "../src/SubscriptionManager.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {StableCoin} from "../src/StableCoin.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {DeployStableCoin} from "./DeployStableCoin.s.sol";
import {console} from "forge-std/Test.sol";

contract MakeActiveSubscription is Script {
    function run() external {
        SubscriptionManager subscriptionManager =
            SubscriptionManager(payable(0xCf7Ed3AccA5a467e9e704C703E8D87F634fB0Fc9));
        vm.startBroadcast(vm.envUint("ANVIL_PRIVATE_KEY_ONE"));
        console.log("one", subscriptionManager.getIsRegisteredUser(vm.envAddress("ANVIL_PUBLIC_KEY_ONE")));
        console.log("two", subscriptionManager.getIsRegisteredUser(vm.envAddress("ANVIL_PUBLIC_KEY_TWO")));

        subscriptionManager.createInactiveSubscription(10e18, 180, 9999999, vm.envAddress("ANVIL_PUBLIC_KEY_TWO"));
        console.log("Subscription created");
        vm.stopBroadcast();
    }
}
