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
    SubscriptionManagerHarness subscriptionManagerHarness;

    address admin = makeAddr("admin");
    address user = makeAddr("user");

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

        vm.startPrank(user);
        stableCoin.mint();
        vm.stopPrank();

        vm.deal(user, 10 ether);
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
        emit SubscriptionManager.InactiveSubscriptionCreated(admin, user, priceInUsd, paymentInterval, duration);
        subscriptionManager.createInactiveSubscription(priceInUsd, paymentInterval, duration, user);

        vm.stopPrank();

        SubscriptionManager.Subscription memory subscription = subscriptionManager.getSubscription(admin, user);
        assertEq(subscription.price, priceInUsd);
        assertEq(subscription.paymentInterval, paymentInterval);
        assertEq(subscription.duration, duration);
        assertEq(subscription.isActive, false);
    }

    function testCreateInactiveSubscriptionNotRegisteredUser() public {
        vm.startPrank(admin);
        vm.expectRevert(
            abi.encodeWithSelector(SubscriptionManager.SubscriptionManager__UserNotRegistered.selector, user)
        );

        subscriptionManager.createInactiveSubscription(priceInUsd, paymentInterval, duration, user);
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
        subscriptionManager.createInactiveSubscription(priceInUsd, paymentInterval, duration, user);
        vm.stopPrank();
        _;
    }

    function testActivateSubscriptionWithStableCoinWorks() public userRegistered inactiveSubscriptionCreated {
        vm.startPrank(user);

        stableCoin.approve(address(subscriptionManager), priceInUsd6Decimals);

        vm.expectEmit(true, true, false, true);

        emit SubscriptionManager.SubscriptionActivated(
            admin, user, priceInUsd, paymentInterval, block.timestamp, block.timestamp + duration
        );
        subscriptionManager.activateSubscriptionWithStableCoin(admin);
        vm.stopPrank();

        SubscriptionManager.Subscription memory subscription = subscriptionManager.getSubscription(admin, user);
        assertTrue(subscription.isActive);
        assertEq(
            subscriptionManager.getAdminsUsdEarningsAfterFees(admin),
            priceInUsd - subscriptionManager.calculateUsdFee(priceInUsd)
        );
        assertEq(subscriptionManager.getTotalUsdFeesEarnings(), subscriptionManager.calculateUsdFee(priceInUsd));
        assertEq(stableCoin.balanceOf(address(subscriptionManager)), priceInUsd6Decimals);
    }

    function testActivateSubscriptionWithStableCoinAlreadyActive() public userRegistered inactiveSubscriptionCreated {
        vm.startPrank(user);
        stableCoin.approve(address(subscriptionManager), priceInUsd);

        subscriptionManager.activateSubscriptionWithStableCoin(admin);
        stableCoin.approve(address(subscriptionManager), priceInUsd);

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
        stableCoin.approve(address(subscriptionManager), priceInUsd6Decimals - 1);

        // ...

        vm.expectRevert(
            abi.encodeWithSelector(
                IERC20Errors.ERC20InsufficientAllowance.selector,
                subscriptionManager,
                priceInUsd6Decimals - 1,
                priceInUsd6Decimals
            )
        );
        subscriptionManager.activateSubscriptionWithStableCoin(admin);
        vm.stopPrank();
    }

    function testChainlinkFunction() public { /* TODO */ }

    // activateSubscriptionWithEth

    function testActivateSubscriptionWithEthWorks() public userRegistered inactiveSubscriptionCreated harnessCreated {
        vm.startPrank(user);
        vm.expectEmit(true, true, false, true);
        emit SubscriptionManager.SubscriptionActivated(
            admin, user, priceInUsd, paymentInterval, block.timestamp, block.timestamp + duration
        );
        uint256 priceInEth = subscriptionManagerHarness.getEthAmountFromUsd_HARNESS(priceInUsd);
        subscriptionManager.activateSubscriptionWithEth{value: priceInEth}(admin);
        vm.stopPrank();

        SubscriptionManager.Subscription memory subscription = subscriptionManager.getSubscription(admin, user);
        assertTrue(subscription.isActive);
        assertEq(address(subscriptionManager).balance, priceInEth);
        assertEq(
            subscriptionManager.getAdminsEthEarningsAfterFees(admin),
            priceInEth - subscriptionManager.calculateEthFee(priceInEth)
        );
        assertEq(subscriptionManager.getTotalEthFeesEarnings(), subscriptionManager.calculateEthFee(priceInEth));
    }

    function testActivateSubscriptionWithEthNoInactiveSubscription() public userRegistered harnessCreated {
        vm.startPrank(user);
        uint256 priceInEth = subscriptionManagerHarness.getEthAmountFromUsd_HARNESS(priceInUsd);
        vm.expectRevert(
            abi.encodeWithSelector(SubscriptionManager.SubscriptionManager__NoInactiveSubscriptionFound.selector, user)
        );
        subscriptionManager.activateSubscriptionWithEth{value: priceInEth}(admin);
        vm.stopPrank();
    }

    function testActivateSubscriptionWithEthAlreadyActive()
        public
        userRegistered
        inactiveSubscriptionCreated
        harnessCreated
    {
        vm.startPrank(user);
        uint256 priceInEth = subscriptionManagerHarness.getEthAmountFromUsd_HARNESS(priceInUsd);
        subscriptionManager.activateSubscriptionWithEth{value: priceInEth}(admin);
        vm.expectRevert(
            abi.encodeWithSelector(SubscriptionManager.SubscriptionManager__SubscriptionAlreadyActive.selector)
        );
        subscriptionManager.activateSubscriptionWithEth{value: priceInEth}(admin);
        vm.stopPrank();
    }

    function testActivateSubscriptionWithEthInsufficientEth()
        public
        userRegistered
        inactiveSubscriptionCreated
        harnessCreated
    {
        vm.startPrank(user);
        uint256 priceInEth = subscriptionManagerHarness.getEthAmountFromUsd_HARNESS(priceInUsd);
        vm.expectRevert(
            abi.encodeWithSelector(SubscriptionManager.SubscriptionManager__SubscriptionPriceMismatch.selector)
        );
        subscriptionManager.activateSubscriptionWithEth{value: priceInEth - 1}(admin);
        vm.stopPrank();
    }

    // makePaymentWithStableCoin

    modifier subscriptionActive() {
        vm.startPrank(admin);
        subscriptionManager.createInactiveSubscription(priceInUsd, paymentInterval, duration, user);
        vm.stopPrank();
        vm.startPrank(user);
        stableCoin.approve(address(subscriptionManager), priceInUsd);
        subscriptionManager.activateSubscriptionWithStableCoin(admin);
        vm.stopPrank();
        _;
    }

    function testMakePaymentWithStableCoinWorks() public userRegistered subscriptionActive {
        uint256 nextPaymentTime = subscriptionManager.getSubscription(admin, user).nextPaymentTime;
        uint256 startTime = subscriptionManager.getSubscription(admin, user).startTime;

        vm.startPrank(user);
        stableCoin.approve(address(subscriptionManager), priceInUsd);

        vm.expectEmit(true, true, false, true);
        emit SubscriptionManager.PaymentMade(admin, user, priceInUsd, nextPaymentTime + paymentInterval);

        subscriptionManager.makePaymentWithStableCoin(admin);
        uint256 newNextPaymentTime = subscriptionManager.getSubscription(admin, user).nextPaymentTime;

        vm.stopPrank();
        assertEq(startTime + 2 * paymentInterval, newNextPaymentTime);
    }

    function testMakePaymentSubscriptionWithStableCoinNotActive() public userRegistered {
        vm.startPrank(user);
        stableCoin.approve(address(subscriptionManager), priceInUsd);
        vm.expectRevert(abi.encodeWithSelector(SubscriptionManager.SubscriptionManager__SubscriptionNotActive.selector));
        subscriptionManager.makePaymentWithStableCoin(admin);
        vm.stopPrank();
    }

    function testMakePaymentWithStableCoinInsufficientAllowance() public userRegistered subscriptionActive {
        vm.startPrank(user);
        stableCoin.approve(address(subscriptionManager), priceInUsd6Decimals - 1);
        vm.expectRevert(
            abi.encodeWithSelector(
                IERC20Errors.ERC20InsufficientAllowance.selector,
                subscriptionManager,
                priceInUsd6Decimals - 1,
                priceInUsd6Decimals
            )
        );
        subscriptionManager.makePaymentWithStableCoin(admin);
        vm.stopPrank();
    }

    // makePaymentWithEth

    function testMakePaymentWithEthWorks() public userRegistered subscriptionActive harnessCreated {
        uint256 nextPaymentTime = subscriptionManager.getSubscription(admin, user).nextPaymentTime;
        uint256 startTime = subscriptionManager.getSubscription(admin, user).startTime;

        vm.startPrank(user);
        uint256 priceInEth = subscriptionManagerHarness.getEthAmountFromUsd_HARNESS(priceInUsd);

        vm.expectEmit(true, true, false, true);
        emit SubscriptionManager.PaymentMade(admin, user, priceInUsd, nextPaymentTime + paymentInterval);

        subscriptionManager.makePaymentWithEth{value: priceInEth}(admin);
        vm.stopPrank();

        assertEq(startTime + 2 * paymentInterval, subscriptionManager.getSubscription(admin, user).nextPaymentTime);
        assertEq(address(subscriptionManager).balance, priceInEth);
    }

    function testMakePaymentWithEthUserNotRegistered() public harnessCreated {
        vm.startPrank(user);
        uint256 priceInEth = subscriptionManagerHarness.getEthAmountFromUsd_HARNESS(priceInUsd);
        vm.expectRevert(
            abi.encodeWithSelector(SubscriptionManager.SubscriptionManager__UserNotRegistered.selector, user)
        );
        subscriptionManager.makePaymentWithEth{value: priceInEth}(admin);
        vm.stopPrank();
    }

    function testMakePaymentWithEthSubscriptionNotActive() public userRegistered harnessCreated {
        vm.startPrank(user);
        uint256 priceInEth = subscriptionManagerHarness.getEthAmountFromUsd_HARNESS(priceInUsd);
        vm.expectRevert(abi.encodeWithSelector(SubscriptionManager.SubscriptionManager__SubscriptionNotActive.selector));
        subscriptionManager.makePaymentWithEth{value: priceInEth}(admin);
        vm.stopPrank();
    }

    function testMakePaymentWithEthSubscriptionPriceMismatch()
        public
        userRegistered
        subscriptionActive
        harnessCreated
    {
        vm.startPrank(user);
        uint256 priceInEth = subscriptionManagerHarness.getEthAmountFromUsd_HARNESS(priceInUsd);
        vm.expectRevert(
            abi.encodeWithSelector(SubscriptionManager.SubscriptionManager__SubscriptionPriceMismatch.selector)
        );
        subscriptionManager.makePaymentWithEth{value: priceInEth - 1}(admin);
        vm.stopPrank();
    }

    // withdrawAdminEthEarnings
    function testWithdrawAdminEthEarningsWorks() public userRegistered subscriptionActive harnessCreated {
        uint256 priceInEth = subscriptionManagerHarness.getEthAmountFromUsd_HARNESS(priceInUsd);
        vm.startPrank(user);
        subscriptionManager.makePaymentWithEth{value: priceInEth}(admin);
        vm.stopPrank();

        uint256 adminEarnings = priceInEth - subscriptionManager.calculateEthFee(priceInEth);

        console.log(address(subscriptionManager).balance);
        vm.startPrank(admin);
        vm.expectEmit(true, false, false, true);
        emit SubscriptionManager.AdminEthWithdrawalSuccessful(admin, adminEarnings);
        subscriptionManager.withdrawAdminEthEarnings(adminEarnings);
        vm.stopPrank();
        assertEq(subscriptionManager.getAdminsEthEarningsAfterFees(admin), 0);
        assertEq(address(subscriptionManager).balance, subscriptionManager.calculateEthFee(priceInEth));
        assertEq(address(admin).balance, adminEarnings);
    }

    function testWithdrawAdminEthEarningsFailed() public userRegistered subscriptionActive harnessCreated {
        uint256 priceInEth = subscriptionManagerHarness.getEthAmountFromUsd_HARNESS(priceInUsd);
        vm.startPrank(user);
        subscriptionManager.makePaymentWithEth{value: priceInEth}(admin);
        vm.stopPrank();

        vm.startPrank(address(subscriptionManager));
        payable(address(0)).transfer(address(subscriptionManager).balance);
        vm.stopPrank();

        vm.startPrank(admin);
        vm.expectRevert(abi.encodeWithSelector(SubscriptionManager.SubscriptionManager__WithdrawFailed.selector));
        subscriptionManager.withdrawAdminEthEarnings(priceInEth);
        vm.stopPrank();
    }

    // withdrawAdminUsdEarnings

    function testWithdrawAdminUsdEarningsWorks() public userRegistered subscriptionActive {
        uint256 adminEarningsInUsd = priceInUsd - subscriptionManager.calculateUsdFee(priceInUsd);

        vm.startPrank(admin);
        vm.expectEmit(true, false, false, true);
        emit SubscriptionManager.AdminUsdWithdrawalSuccessful(admin, adminEarningsInUsd);
        subscriptionManager.withdrawAdminUsdEarnings(adminEarningsInUsd);
        vm.stopPrank();

        uint256 adminEarningsInUsd6Decimals = adminEarningsInUsd / 10 ** 12;

        assertEq(subscriptionManager.getAdminsUsdEarningsAfterFees(admin), 0);
        assertEq(subscriptionManager.getTotalUsdFeesEarnings(), subscriptionManager.calculateUsdFee(priceInUsd));
        assertEq(stableCoin.balanceOf(admin), adminEarningsInUsd6Decimals);
    }

    function testWithdrawAdminUsdEarningsFailed() public userRegistered subscriptionActive {
        vm.startPrank(address(subscriptionManager));
        stableCoin.transfer(address(this), stableCoin.balanceOf(address(subscriptionManager)));
        vm.stopPrank();

        uint256 adminEarningsInUsd = priceInUsd - subscriptionManager.calculateUsdFee(priceInUsd);

        vm.startPrank(admin);
        vm.expectRevert();
        subscriptionManager.withdrawAdminUsdEarnings(adminEarningsInUsd);
        vm.stopPrank();
    }

    // withdrawOwnerEthEarnings

    function testWithdrawOwnerEthEarningsWorks() public userRegistered subscriptionActive harnessCreated {
        uint256 priceInEth = subscriptionManagerHarness.getEthAmountFromUsd_HARNESS(priceInUsd);
        vm.startPrank(user);
        subscriptionManager.makePaymentWithEth{value: priceInEth}(admin);
        vm.stopPrank();

        uint256 ownerEarnings = subscriptionManager.calculateEthFee(priceInEth);

        vm.startPrank(subscriptionManager.owner());
        vm.expectEmit(true, false, false, true);
        emit SubscriptionManager.OwnerEthFeesWithdrawalSuccessful(subscriptionManager.owner(), ownerEarnings);
        subscriptionManager.withdrawOwnerEthFeesEarnings(ownerEarnings);
        vm.stopPrank();
        assertEq(subscriptionManager.getTotalEthFeesEarnings(), 0);
        assertEq(address(subscriptionManager).balance, priceInEth - ownerEarnings);
        assertEq(address(subscriptionManager.owner()).balance, ownerEarnings);
    }

    function testWithdrawOwnerEthEarningsFails() public userRegistered subscriptionActive harnessCreated {
        uint256 priceInEth = subscriptionManagerHarness.getEthAmountFromUsd_HARNESS(priceInUsd);
        vm.startPrank(user);
        subscriptionManager.makePaymentWithEth{value: priceInEth}(admin);
        vm.stopPrank();

        vm.startPrank(address(subscriptionManager));
        payable(address(0)).transfer(address(subscriptionManager).balance);
        vm.stopPrank();

        vm.startPrank(subscriptionManager.owner());
        vm.expectRevert();
        subscriptionManager.withdrawOwnerEthFeesEarnings(priceInEth);
        vm.stopPrank();
    }

    // withdrawOwnerUsdEarnings

    function testWithdrawOwnerUsdEarningsWorks() public userRegistered subscriptionActive {
        uint256 ownerEarningsInUsd = subscriptionManager.calculateUsdFee(priceInUsd);

        vm.startPrank(subscriptionManager.owner());
        vm.expectEmit(true, false, false, true);
        emit SubscriptionManager.OwnerUsdFeesWithdrawalSuccessful(subscriptionManager.owner(), ownerEarningsInUsd);
        subscriptionManager.withdrawOwnerUsdFeesEarnings(ownerEarningsInUsd);
        vm.stopPrank();

        uint256 ownerEarningsInUsd6Decimals = ownerEarningsInUsd / 10 ** 12;

        assertEq(subscriptionManager.getTotalUsdFeesEarnings(), 0);
        assertEq(stableCoin.balanceOf(subscriptionManager.owner()), ownerEarningsInUsd6Decimals);
    }

    function testWithdrawOwnerUsdEarningsFails() public userRegistered subscriptionActive {
        vm.startPrank(address(subscriptionManager));
        stableCoin.transfer(address(this), stableCoin.balanceOf(address(subscriptionManager)));
        vm.stopPrank();

        uint256 ownerEarningsInUsd = subscriptionManager.calculateUsdFee(priceInUsd);

        vm.startPrank(subscriptionManager.owner());
        vm.expectRevert();
        subscriptionManager.withdrawOwnerUsdFeesEarnings(ownerEarningsInUsd);
        vm.stopPrank();
    }

    // calcualteFee

    function testCalculateUsdFee() public {
        uint256 fee = subscriptionManager.calculateUsdFee(priceInUsd);
        assertEq(fee, priceInUsd / subscriptionManager.getPercentFee() - subscriptionManager.getFlatUsdFee());
    }

    function testCalculateEthFee() public harnessCreated {
        uint256 priceInEth = subscriptionManagerHarness.getEthAmountFromUsd_HARNESS(priceInUsd);
        uint256 fee = subscriptionManager.calculateEthFee(priceInEth);
        assertEq(
            fee,
            priceInEth / subscriptionManager.getPercentFee()
                - subscriptionManagerHarness.getEthAmountFromUsd_HARNESS(subscriptionManager.getFlatUsdFee())
        );
    }

    modifier harnessCreated() {
        (, address ethPriceInUsdFeed) = helperConfig.activeNetworkConfig();
        subscriptionManagerHarness = new SubscriptionManagerHarness(stableCoin, ethPriceInUsdFeed);
        _;
    }

    // Internal functions testing
    function testGetEthAmountFromUsd() public harnessCreated {
        uint256 usdAmount = 10e18; // $10
        uint256 ethAmount = subscriptionManagerHarness.getEthAmountFromUsd_HARNESS(usdAmount);
        assertEq(ethAmount, usdAmount / (startingEthPriceInUsd / 1e18));
    }
    //5000000000000000
    //50000000000000000

    function testHandleStableCoinPayment() public harnessCreated {
        uint256 usdAmount = 10e18; // $10
        vm.startPrank(user);
        stableCoin.approve(address(subscriptionManagerHarness), usdAmount);
        vm.stopPrank();
        subscriptionManagerHarness.handleStableCoinPayment_HARNESS(user, usdAmount);
        assertEq(stableCoin.balanceOf(address(subscriptionManagerHarness)), 10e6);
        assertEq(stableCoin.balanceOf(user), 100000e6 - 10e6);
    }
}

contract SubscriptionManagerHarness is SubscriptionManager {
    constructor(StableCoin _acceptedToken, address _ethPriceInUsdFeed)
        SubscriptionManager(_acceptedToken, _ethPriceInUsdFeed)
    {}

    function getEthAmountFromUsd_HARNESS(uint256 _usdAmount) external view returns (uint256) {
        return super._getEthAmountFromUsd(_usdAmount);
    }

    function handleStableCoinPayment_HARNESS(address from, uint256 _usdAmount) external {
        return super._handleStableCoinPayment(from, _usdAmount);
    }
}
