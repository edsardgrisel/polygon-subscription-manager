// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.19;

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
    address user = makeAddr("user");

    uint256 USDT_DECIMALS = 6;
    uint256 price = 100 * 10 ** USDT_DECIMALS;
    uint256 paymentInterval = 30 days;
    uint256 duration = 90 days;

    function setUp() external {
        DeploySubscriptionManager deploySubscriptionManager = new DeploySubscriptionManager();
        (subscriptionManager, helperConfig) = deploySubscriptionManager.run();
        DeployStableCoin deployStableCoin = new DeployStableCoin();
        stableCoin = deployStableCoin.run();
        vm.startPrank(user);
        stableCoin.mint();
        vm.stopPrank();
    }

    modifier userRegistered() {
        vm.startPrank(subscriptionManager.owner());
        subscriptionManager.registerUser(user);
        vm.stopPrank();
        _;
    }

    // Setup

    function testSetup() public {
        assertEq(stableCoin.balanceOf(user), 100000 * 10 ** 6);
    }

    // createInactiveSubscription
    function testCreateInactiveSubscription() public userRegistered {
        vm.startPrank(admin);

        vm.expectEmit(true, true, false, true);
        emit SubscriptionManager.InactiveSubscriptionCreated(admin, user, price, paymentInterval, duration);
        subscriptionManager.createInactiveSubscription(price, paymentInterval, duration, user);

        vm.stopPrank();

        SubscriptionManager.Subscription memory subscription = subscriptionManager.getSubscription(admin, user);
        assertEq(subscription.price, price);
        assertEq(subscription.paymentInterval, paymentInterval);
        assertEq(subscription.duration, duration);
        assertEq(subscription.isActive, false);
    }

    function testCreateInactiveSubscriptionNotRegisteredUser() public {
        vm.startPrank(admin);
        vm.expectRevert(
            abi.encodeWithSelector(SubscriptionManager.SubscriptionManager__UserNotRegistered.selector, user)
        );

        subscriptionManager.createInactiveSubscription(price, paymentInterval, duration, user);
        vm.stopPrank();
    }

    // registerUser

    function testRegisterUser() public {
        vm.startPrank(subscriptionManager.owner());
        vm.expectEmit(true, false, false, false);
        emit SubscriptionManager.UserRegistered(user);
        subscriptionManager.registerUser(user);
        vm.stopPrank();

        assert(subscriptionManager.getIsRegisteredUser(user));
    }

    function testRegisterAlreadyRegisteredUser() public userRegistered {
        vm.startPrank(subscriptionManager.owner());
        vm.expectRevert(
            abi.encodeWithSelector(SubscriptionManager.SubscriptionManager__UserAlreadyRegistered.selector, user)
        );
        subscriptionManager.registerUser(user);
        vm.stopPrank();
    }

    // unregisterUser

    function testUnregisterUser() public userRegistered {
        vm.startPrank(subscriptionManager.owner());
        vm.expectEmit(true, false, false, false);
        emit SubscriptionManager.UserUnregistered(user);
        subscriptionManager.unregisterUser(user);
        vm.stopPrank();

        assert(!subscriptionManager.getIsRegisteredUser(user));
    }

    function testUnregisterUnregisteredUser() public {
        vm.startPrank(subscriptionManager.owner());
        vm.expectRevert(
            abi.encodeWithSelector(SubscriptionManager.SubscriptionManager__UserNotRegistered.selector, user)
        );
        subscriptionManager.unregisterUser(user);
        vm.stopPrank();
    }

    // activateSubscription

    modifier inactiveSubscriptionCreated() {
        vm.startPrank(admin);
        subscriptionManager.createInactiveSubscription(price, paymentInterval, duration, user);
        vm.stopPrank();
        _;
    }

    function testActivateSubscription() public userRegistered inactiveSubscriptionCreated {
        vm.startPrank(user);
        vm.expectEmit(true, true, false, true);
        emit SubscriptionManager.SubscriptionActivated(
            admin, user, price, paymentInterval, block.timestamp, block.timestamp + duration
        );
        subscriptionManager.activateSubscription(admin);
        vm.stopPrank();

        SubscriptionManager.Subscription memory subscription = subscriptionManager.getSubscription(admin, user);
        assert(subscription.isActive);
        assertEq(subscription.price, address(subscriptionManager).balance);
    }

    function testActivateSubscriptionAlreadyActive() public userRegistered inactiveSubscriptionCreated {
        vm.startPrank(user);

        subscriptionManager.activateSubscription(admin);
        vm.expectRevert(
            abi.encodeWithSelector(SubscriptionManager.SubscriptionManager__SubscriptionAlreadyActive.selector)
        );
        subscriptionManager.activateSubscription(admin);
        vm.stopPrank();
    }

    function testActivateSubscriptionPriceMismatch() public userRegistered inactiveSubscriptionCreated {
        vm.startPrank(user);

        vm.expectRevert(
            abi.encodeWithSelector(SubscriptionManager.SubscriptionManager__SubscriptionPriceMismatch.selector)
        );
        subscriptionManager.activateSubscription(admin);
        vm.stopPrank();
    }

    function testChainlinkFunction() public { /* TODO */ }

    // makePayment

    modifier subcriptionActive() {
        vm.startPrank(admin);
        subscriptionManager.createInactiveSubscription(price, paymentInterval, duration, user);
        vm.stopPrank();
        vm.startPrank(user);
        subscriptionManager.activateSubscription(admin);
        vm.stopPrank();
        _;
    }

    function testMakePayment() public userRegistered subcriptionActive {
        uint256 nextPaymentTime = subscriptionManager.getSubscription(admin, user).nextPaymentTime;
        uint256 startTime = subscriptionManager.getSubscription(admin, user).startTime;

        vm.startPrank(user);
        vm.expectEmit(true, true, false, true);
        emit SubscriptionManager.PaymentMade(admin, user, price, nextPaymentTime + paymentInterval);
        subscriptionManager.makePayment(admin);
        uint256 newNextPaymentTime = subscriptionManager.getSubscription(admin, user).nextPaymentTime;

        vm.stopPrank();
        assertEq(startTime + 2 * paymentInterval, newNextPaymentTime);
    }

    function testMakePaymentSubscriptionNotActive() public userRegistered {
        vm.startPrank(user);
        vm.expectRevert(abi.encodeWithSelector(SubscriptionManager.SubscriptionManager__SubscriptionNotActive.selector));
        subscriptionManager.makePayment(admin);
        vm.stopPrank();
    }

    function testMakePaymentPriceMismatch() public userRegistered subcriptionActive {
        vm.startPrank(user);
        vm.expectRevert(
            abi.encodeWithSelector(SubscriptionManager.SubscriptionManager__SubscriptionPriceMismatch.selector)
        );
        subscriptionManager.makePayment(admin);
        vm.stopPrank();
    }

    // calcualteFee

    function testCalculateFee() public {
        uint256 fee = subscriptionManager.calculateFee(price);
        assertEq(fee, price / 100);
    }
}
