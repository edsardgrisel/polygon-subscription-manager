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
    address user = makeAddr("user");

    uint256 USDT_DECIMALS = 6;
    uint256 price = 100 * 10 ** USDT_DECIMALS;
    uint256 paymentInterval = 30 days;
    uint256 duration = 90 days;
    uint256 startingEthPrice = 2000;

    function setUp() external {
        DeployStableCoin deployStableCoin = new DeployStableCoin();
        stableCoin = deployStableCoin.run();
        DeploySubscriptionManager deploySubscriptionManager = new DeploySubscriptionManager();
        (subscriptionManager, helperConfig) = deploySubscriptionManager.run(address(stableCoin));

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
    function testCreateInactiveSubscriptionWorks() public userRegistered {
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

    function testRegisterUserWorks() public {
        vm.startPrank(subscriptionManager.owner());
        vm.expectEmit(true, false, false, false);
        emit SubscriptionManager.UserRegistered(user);
        subscriptionManager.registerUser(user);
        vm.stopPrank();

        assertTrue(subscriptionManager.getIsRegisteredUser(user));
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

    function testUnregisterUserWorks() public userRegistered {
        vm.startPrank(subscriptionManager.owner());
        vm.expectEmit(true, false, false, false);
        emit SubscriptionManager.UserUnregistered(user);
        subscriptionManager.unregisterUser(user);
        vm.stopPrank();

        assertTrue(!subscriptionManager.getIsRegisteredUser(user));
    }

    function testUnregisterUnregisteredUser() public {
        vm.startPrank(subscriptionManager.owner());
        vm.expectRevert(
            abi.encodeWithSelector(SubscriptionManager.SubscriptionManager__UserNotRegistered.selector, user)
        );
        subscriptionManager.unregisterUser(user);
        vm.stopPrank();
    }

    // activateSubscriptionWithStableCoin

    modifier inactiveSubscriptionCreated() {
        vm.startPrank(admin);
        subscriptionManager.createInactiveSubscription(price, paymentInterval, duration, user);
        vm.stopPrank();
        _;
    }

    function testActivateSubscriptionWithStableCoinWorks() public userRegistered inactiveSubscriptionCreated {
        console.log("user sc balance: ", stableCoin.balanceOf(user));

        vm.startPrank(user);
        stableCoin.approve(address(subscriptionManager), price);

        vm.expectEmit(true, true, false, true);

        emit SubscriptionManager.SubscriptionActivated(
            admin, user, price, paymentInterval, block.timestamp, block.timestamp + duration
        );
        subscriptionManager.activateSubscriptionWithStableCoin(admin);
        vm.stopPrank();

        SubscriptionManager.Subscription memory subscription = subscriptionManager.getSubscription(admin, user);
        assertTrue(subscription.isActive);
        assertEq(subscription.price, stableCoin.balanceOf(address(subscriptionManager)));
    }

    function testActivateSubscriptionWithStableCoinAlreadyActive() public userRegistered inactiveSubscriptionCreated {
        vm.startPrank(user);
        stableCoin.approve(address(subscriptionManager), price);

        subscriptionManager.activateSubscriptionWithStableCoin(admin);
        stableCoin.approve(address(subscriptionManager), price);

        vm.expectRevert(
            abi.encodeWithSelector(SubscriptionManager.SubscriptionManager__SubscriptionAlreadyActive.selector)
        );
        subscriptionManager.activateSubscriptionWithStableCoin(admin);
        vm.stopPrank();
    }

    function testActivateSubscriptionWithStableCoinInsufficientAllowance()
        public
        userRegistered
        inactiveSubscriptionCreated
    {
        vm.startPrank(user);
        stableCoin.approve(address(subscriptionManager), price - 1);

        // ...

        vm.expectRevert(
            abi.encodeWithSelector(
                IERC20Errors.ERC20InsufficientAllowance.selector, subscriptionManager, price - 1, price
            )
        );
        subscriptionManager.activateSubscriptionWithStableCoin(admin);
        vm.stopPrank();
    }

    function testChainlinkFunction() public { /* TODO */ }

    // makePaymentWithStableCoin

    modifier subcriptionActive() {
        vm.startPrank(admin);
        subscriptionManager.createInactiveSubscription(price, paymentInterval, duration, user);
        vm.stopPrank();
        vm.startPrank(user);
        stableCoin.approve(address(subscriptionManager), price);
        subscriptionManager.activateSubscriptionWithStableCoin(admin);
        vm.stopPrank();
        _;
    }

    function testMakePaymentWithStableCoinWorks() public userRegistered subcriptionActive {
        uint256 nextPaymentTime = subscriptionManager.getSubscription(admin, user).nextPaymentTime;
        uint256 startTime = subscriptionManager.getSubscription(admin, user).startTime;

        vm.startPrank(user);
        stableCoin.approve(address(subscriptionManager), price);

        vm.expectEmit(true, true, false, true);
        emit SubscriptionManager.PaymentMade(admin, user, price, nextPaymentTime + paymentInterval);

        subscriptionManager.makePaymentWithStableCoin(admin);
        uint256 newNextPaymentTime = subscriptionManager.getSubscription(admin, user).nextPaymentTime;

        vm.stopPrank();
        assertEq(startTime + 2 * paymentInterval, newNextPaymentTime);
    }

    function testMakePaymentSubscriptionWithStableCoinNotActive() public userRegistered {
        vm.startPrank(user);
        stableCoin.approve(address(subscriptionManager), price);
        vm.expectRevert(abi.encodeWithSelector(SubscriptionManager.SubscriptionManager__SubscriptionNotActive.selector));
        subscriptionManager.makePaymentWithStableCoin(admin);
        vm.stopPrank();
    }

    function testMakePaymentWithStableCoinInsufficientAllowance() public userRegistered subcriptionActive {
        vm.startPrank(user);
        stableCoin.approve(address(subscriptionManager), price - 1);
        vm.expectRevert(
            abi.encodeWithSelector(
                IERC20Errors.ERC20InsufficientAllowance.selector, subscriptionManager, price - 1, price
            )
        );
        subscriptionManager.makePaymentWithStableCoin(admin);
        vm.stopPrank();
    }

    // calcualteFee

    function testCalculateFee() public {
        uint256 fee = subscriptionManager.calculateUsdFee(price);
        assertEq(fee, price / 100);
    }

    // Internal functions testing
    function testGetEthAmountFromUsd() public {
        (, address ethPriceFeed) = helperConfig.activeNetworkConfig();
        SubscriptionManagerHarness subscriptionManagerHarness = new SubscriptionManagerHarness(stableCoin, ethPriceFeed);
        uint256 usdAmount = 10e18; // $10
        uint256 ethAmount = subscriptionManagerHarness.getEthAmountFromUsd_HARNESS(usdAmount);
        assertEq(ethAmount, 10e18 / startingEthPrice);
    }

    function testHandleStableCoinPayment() public {}
}

contract SubscriptionManagerHarness is SubscriptionManager {
    constructor(StableCoin _acceptedToken, address _ethPriceFeed) SubscriptionManager(_acceptedToken, _ethPriceFeed) {}

    function getEthAmountFromUsd_HARNESS(uint256 _usdAmount) external view returns (uint256) {
        return super._getEthAmountFromUsd(_usdAmount);
    }
}
