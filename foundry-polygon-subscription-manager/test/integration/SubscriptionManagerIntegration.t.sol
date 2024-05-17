// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.19;

import {ERC20, IERC20Errors} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Test, console} from "forge-std/Test.sol";
import {DeploySubscriptionManager} from "../../script/DeploySubscriptionManager.s.sol";
import {DeployStableCoin} from "../../script/DeployStableCoin.s.sol";
import {SubscriptionManager} from "../../src/SubscriptionManager.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {StableCoin} from "../../src/StableCoin.sol";

contract SubscriptionManagerTest is Test {
    SubscriptionManager subscriptionManager;
    StableCoin stableCoin;
    HelperConfig helperConfig;

    address admin = makeAddr("admin");
    address user1 = makeAddr("user1");
    address user2 = makeAddr("user2");

    uint256 USDT_DECIMALS = 6;
    uint256 priceInUsd = 100e18; //100 USD with 18 decimals
    uint256 priceInUsd6Decimals = priceInUsd / 10 ** 12; // 100 USD with 6 decimals

    uint256 paymentInterval = 30 days;
    uint256 duration = 90 days;
    uint256 startingEthPriceInUsd = 2000e18; // 2000 USD with 18 decimals

    function setUp() external {
        DeployStableCoin deployStableCoin = new DeployStableCoin();
        stableCoin = deployStableCoin.run();
        DeploySubscriptionManager deploySubscriptionManager = new DeploySubscriptionManager();
        (subscriptionManager, helperConfig) = deploySubscriptionManager.run(address(stableCoin));

        vm.startPrank(user1);
        stableCoin.mint();
        vm.stopPrank();

        vm.deal(user1, 10 ether);

        vm.startPrank(user2);
        stableCoin.mint();
        vm.stopPrank();

        vm.deal(user2, 10 ether);
    }

    function testSubscriptionManager() public {}
}
