// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.19;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import {Test, console} from "forge-std/Test.sol";

contract SubscriptionManager is Ownable {
    // State variables
    mapping(address admin => mapping(address user => Subscription)) private s_subscriptions; // the agreement between the admin and the user
    mapping(address => bool) private s_registeredUsers;
    mapping(address admin => uint256 usdEarnings) private s_adminsUsdEarningsAfterFees;
    mapping(address admin => uint256 ethEarnings) private s_adminsEthEarningsAfterFees;
    uint256 private s_totalUsdFeesEarnings;
    uint256 private s_totalEthFeesEarnings;

    ERC20 public acceptedToken;
    AggregatorV3Interface public immutable wethPriceFeed;
    uint256 public immutable USDT_DECIMALS = 6;
    uint256 public immutable DECIMALS = 18;
    uint256 public immutable PRICE_FEED_DECIMALS = 8;
    uint256 public immutable FEE = 100; // Basis points 1.00%
    uint256 public immutable FLAT_USD_FEE = 0; // zero for now. may be added later

    mapping(uint256 day => AdminUserRelation[] adminUserRelations) private s_adminUserRelationsDueOnDay; // for each day in the future, there is a list of users that are required to pay on that day
    mapping(uint256 day => bool) private s_processedDays; // day is set to true if the day has been processed

    // Events
    // Note: All prices and amounts are with 18 decimals
    // if not specified, its usd and not eth
    event SubscriptionActivated(
        address indexed admin,
        address indexed user,
        uint256 price,
        uint256 paymentInterval,
        uint256 startTime,
        uint256 endTime
    );
    event PaymentMade(address indexed admin, address indexed user, uint256 price, uint256 nextPaymentTime);
    event InactiveSubscriptionCreated(
        address indexed admin, address indexed user, uint256 price, uint256 paymentInterval, uint256 duration
    );
    event UserRegistered(address indexed user);
    event UserUnregistered(address indexed user);
    event SubscriptionCancelled(address indexed admin, address indexed user);
    event AdminEthWithdrawalSuccessful(address indexed admin, uint256 amount);
    event AdminUsdWithdrawalSuccessful(address indexed admin, uint256 amount);
    event OwnerEthFeesWithdrawalSuccessful(address indexed owner, uint256 amount);
    event OwnerUsdFeesWithdrawalSuccessful(address indexed owner, uint256 amount);
    event DayProcessed(uint256 day);

    // Errors
    error SubscriptionManager__SubscriptionAlreadyActive();
    error SubscriptionManager__SubscriptionNotActive();
    error SubscriptionManager__SubscriptionPriceMismatch();
    error SubscriptionManager__UserNotRegistered(address user);
    error SubscriptionManager__UserAlreadyRegistered(address user);
    error SubscriptionManager__TokenNotAccepted(address tokenAddress);
    error SubscriptionManager__NoInactiveSubscriptionFound(address user);
    error SubscriptionManager__WithdrawFailed();

    // Structs

    struct Subscription {
        uint256 price; // in usd with 18 decimals
        uint256 paymentInterval;
        uint256 startTime;
        uint256 duration;
        uint256 nextPaymentTime;
        address admin;
        address user;
        bool isActive;
    }

    struct AdminUserRelation {
        address admin;
        address user;
    }

    // Modifiers
    modifier isRegisteredUser(address user) {
        if (s_registeredUsers[user] == false) {
            revert SubscriptionManager__UserNotRegistered(user);
        }
        _;
    }

    modifier isNotRegisteredUser(address user) {
        if (s_registeredUsers[user] == true) {
            revert SubscriptionManager__UserAlreadyRegistered(user);
        }
        _;
    }

    // Constructor
    constructor(ERC20 _acceptedToken, address _wethPriceFeed) Ownable(msg.sender) {
        acceptedToken = _acceptedToken;
        wethPriceFeed = AggregatorV3Interface(_wethPriceFeed);
    }

    // Chainlink automation

    function upKeep() external {
        uint256 day = _getNumberOfDaysSince1970(block.timestamp);
        if (getProcessedDay(day) == true) {
            return;
        }
        AdminUserRelation[] memory subscriptionsDueToday = getAdminUserRelationsDueOnDay(day);
        for (uint256 i = 0; i < subscriptionsDueToday.length; i++) {
            AdminUserRelation memory adminUserRelation = subscriptionsDueToday[i];
            Subscription memory subscription = s_subscriptions[adminUserRelation.admin][adminUserRelation.user];
            // console.log("day", day);
            // console.log("getNumberOfDaysSince1970", _getNumberOfDaysSince1970(subscription.nextPaymentTime));
            if (day == _getNumberOfDaysSince1970(subscription.nextPaymentTime)) {
                // if payment hasnt been made
                s_subscriptions[subscription.admin][subscription.user] = Subscription({
                    price: 0,
                    paymentInterval: 0,
                    startTime: 0,
                    duration: 0,
                    nextPaymentTime: 0,
                    admin: subscription.admin,
                    user: subscription.user,
                    isActive: false
                });
                emit SubscriptionCancelled(subscription.admin, subscription.user);
            } else {
                _handleSetNextPaymentDay(subscription.admin, subscription.user, subscription.nextPaymentTime);
            }
        }
        s_processedDays[day] = true;
        emit DayProcessed(day);
    }

    /**
     * @dev Create a new subscription. This subscription is inactive until the user makes the first payment by calling the makePayment() function.
     * Is called by the admin of the subscription.
     * @param price The price of the subscription
     * @param paymentInterval The interval at which the user has to pay
     * @param duration The duration of the subscription
     * @param user The user that is subscribing
     *
     */
    function createInactiveSubscription(uint256 price, uint256 paymentInterval, uint256 duration, address user)
        external
        isRegisteredUser(user)
    {
        address admin = msg.sender;
        // create a new subscription
        Subscription memory newSubscription = Subscription({
            price: price,
            paymentInterval: paymentInterval,
            startTime: 0, // all times are set to zero to indicate that the subscription has not started yet
            duration: duration,
            nextPaymentTime: 0,
            admin: admin,
            user: user,
            isActive: false
        });
        // add the inactive subscription to the mapping
        s_subscriptions[admin][user] = newSubscription;

        emit InactiveSubscriptionCreated(admin, user, price, paymentInterval, duration);

        // chainlink function to call backend to send email to user
    }

    /**
     * @dev Register a user. This function is called by the owner of the contract after name and email are in database.
     * @param user The user to register
     */
    function registerUser(address user) external onlyOwner isNotRegisteredUser(user) {
        s_registeredUsers[user] = true;
        emit UserRegistered(user);
    }

    /**
     * @dev Unregister a user. This function is called by the owner of the contract.
     * @param user The user to unregister
     */
    function unregisterUser(address user) external onlyOwner isRegisteredUser(user) {
        s_registeredUsers[user] = false;
        emit UserUnregistered(user);
    }

    /**
     * @dev Activate a subscription. This function is called with value by the user that is subscribing.
     * The user will pay for the first subscription period.
     * @param admin The admin of the subscription the user is subscribing to.
     */
    function activateSubscriptionWithEth(address admin) public payable isRegisteredUser(msg.sender) {
        Subscription memory subscription = s_subscriptions[admin][msg.sender];

        if (subscription.admin == address(0)) {
            revert SubscriptionManager__NoInactiveSubscriptionFound(msg.sender);
        }

        if (subscription.isActive == true) {
            revert SubscriptionManager__SubscriptionAlreadyActive();
        }

        uint256 ethAmount = _getEthAmountFromUsd(subscription.price);

        if (msg.value != ethAmount) {
            revert SubscriptionManager__SubscriptionPriceMismatch();
        }

        // Set times and activate the subscription
        Subscription memory newSubscription = Subscription({
            price: subscription.price,
            paymentInterval: subscription.paymentInterval,
            startTime: block.timestamp,
            duration: block.timestamp + subscription.duration,
            nextPaymentTime: block.timestamp + subscription.paymentInterval,
            admin: subscription.admin,
            user: subscription.user,
            isActive: true
        });
        s_subscriptions[subscription.admin][subscription.user] = newSubscription;

        // emit event
        emit SubscriptionActivated(
            subscription.admin,
            subscription.user,
            subscription.price,
            subscription.paymentInterval,
            block.timestamp,
            block.timestamp + subscription.duration
        );
        _handleSetNextPaymentDay(admin, msg.sender, newSubscription.nextPaymentTime);
        _updateAdminEthEarnings(admin, ethAmount);

        // chainlink function to call backend to send email to user with confirmation and next payment date
    }

    /**
     * @dev Activate a subscription. This function is called by the user that is subscribing.
     * The user will pay for the first subscription period. Approval for the payment must be given before calling this function.
     * Non ether Token must be accepted by the contract.
     * @param admin The admin of the subscription the user is subscribing to.
     */
    function activateSubscriptionWithStableCoin(address admin) public isRegisteredUser(msg.sender) {
        Subscription memory subscription = s_subscriptions[admin][msg.sender];

        if (subscription.admin == address(0)) {
            revert SubscriptionManager__NoInactiveSubscriptionFound(msg.sender);
        }

        if (subscription.isActive == true) {
            revert SubscriptionManager__SubscriptionAlreadyActive();
        }

        // Set times and activate the subscription
        Subscription memory newSubscription = Subscription({
            price: subscription.price,
            paymentInterval: subscription.paymentInterval,
            startTime: block.timestamp,
            duration: block.timestamp + subscription.duration,
            nextPaymentTime: block.timestamp + subscription.paymentInterval,
            admin: subscription.admin,
            user: subscription.user,
            isActive: true
        });
        s_subscriptions[subscription.admin][subscription.user] = newSubscription;

        // emit event
        emit SubscriptionActivated(
            subscription.admin,
            subscription.user,
            subscription.price,
            subscription.paymentInterval,
            block.timestamp,
            block.timestamp + subscription.duration
        );
        _handleSetNextPaymentDay(admin, msg.sender, newSubscription.nextPaymentTime);
        _updateAdminUsdEarnings(admin, subscription.price);
        _handleStableCoinPayment(msg.sender, subscription.price);

        // chainlink function to call backend to send email to user with confirmation and next payment date
    }

    /**
     * @dev Make a payment for a subscription. This function is called by the user that is subscribed.
     * The user will pay for the next subscription period. Approval for the payment must be given before calling this function.
     * @param admin The admin of the subscription the user is subscribing to.
     */
    function makePaymentWithEth(address admin) public payable isRegisteredUser(msg.sender) {
        Subscription memory subscription = s_subscriptions[admin][msg.sender];

        if (subscription.isActive != true) {
            revert SubscriptionManager__SubscriptionNotActive();
        }

        uint256 ethAmount = _getEthAmountFromUsd(subscription.price);

        if (msg.value != ethAmount) {
            revert SubscriptionManager__SubscriptionPriceMismatch();
        }

        // Set times and activate the subscription
        Subscription memory newSubscription = Subscription({
            price: subscription.price,
            paymentInterval: subscription.paymentInterval,
            startTime: subscription.startTime, // all times are set to max value to indicate that the subscription has not started yet
            duration: subscription.duration,
            nextPaymentTime: subscription.nextPaymentTime + subscription.paymentInterval,
            admin: subscription.admin,
            user: subscription.user,
            isActive: true
        });
        s_subscriptions[subscription.admin][subscription.user] = newSubscription;

        // emit event
        emit PaymentMade(
            newSubscription.admin, newSubscription.user, newSubscription.price, newSubscription.nextPaymentTime
        );
        _handleSetNextPaymentDay(admin, msg.sender, newSubscription.nextPaymentTime);
        _updateAdminEthEarnings(admin, ethAmount);
    }

    /**
     * @dev Make a payment for a subscription. This function is called by the user that is subscribing.
     * The user will pay for the next subscription period. Approval for the payment must be given before calling this function.
     * @param admin The admin of the subscription the user is subscribing to.
     */
    function makePaymentWithStableCoin(address admin) public isRegisteredUser(msg.sender) {
        Subscription memory subscription = s_subscriptions[admin][msg.sender];

        if (subscription.isActive != true) {
            revert SubscriptionManager__SubscriptionNotActive();
        }

        // Set times
        Subscription memory newSubscription = Subscription({
            price: subscription.price,
            paymentInterval: subscription.paymentInterval,
            startTime: subscription.startTime, // all times are set to max value to indicate that the subscription has not started yet
            duration: subscription.duration,
            nextPaymentTime: subscription.nextPaymentTime + subscription.paymentInterval,
            admin: subscription.admin,
            user: subscription.user,
            isActive: true
        });
        s_subscriptions[subscription.admin][subscription.user] = newSubscription;

        // emit event
        emit PaymentMade(
            newSubscription.admin, newSubscription.user, newSubscription.price, newSubscription.nextPaymentTime
        );
        _handleSetNextPaymentDay(admin, msg.sender, newSubscription.nextPaymentTime);
        _updateAdminUsdEarnings(admin, subscription.price);
        _handleStableCoinPayment(msg.sender, subscription.price);
    }

    /**
     * @dev Withdraw the earnings of the admin in ETH. This function is called by an admin of a subscription(s).
     * @param amount The amount of ETH to withdraw. If this is more than the fee earnings, all earnings will be withdrawn.
     */
    function withdrawAdminEthEarnings(uint256 amount) public {
        uint256 earnings = s_adminsEthEarningsAfterFees[msg.sender];
        if (amount > earnings) {
            amount = earnings;
        }
        s_adminsEthEarningsAfterFees[msg.sender] = earnings - amount;

        emit AdminEthWithdrawalSuccessful(msg.sender, amount);

        bool success = payable(msg.sender).send(amount);
        // In theory should never fail, but just in case
        if (!success) {
            revert SubscriptionManager__WithdrawFailed();
        }
    }

    /**
     * @dev Withdraw the earnings of the admin in USD. This function is called by the owner of the contract.
     * @param amount The amount of USD to withdraw with 18 deciamals. If this is more than the fee earnings, all earnings will be withdrawn.
     */
    function withdrawAdminUsdEarnings(uint256 amount) public {
        uint256 earnings = s_adminsUsdEarningsAfterFees[msg.sender];
        if (amount > earnings) {
            amount = earnings;
        }
        s_adminsUsdEarningsAfterFees[msg.sender] = earnings - amount;
        uint256 earnings6Decimals = amount / (10 ** (DECIMALS - USDT_DECIMALS));
        acceptedToken.transfer(msg.sender, earnings6Decimals);

        emit AdminUsdWithdrawalSuccessful(msg.sender, amount);
    }

    /**
     * @dev Withdraw the earnings of the admin in ETH. This function is called by the owner of the contract.
     * @param ethAmount The amount of ETH to withdraw. If this is more than the fee earnings, all earnings will be withdrawn.
     */
    function withdrawOwnerEthFeesEarnings(uint256 ethAmount) public onlyOwner {
        uint256 earnings = s_totalEthFeesEarnings;
        if (ethAmount > earnings) {
            ethAmount = earnings;
        }
        s_totalEthFeesEarnings -= ethAmount;
        s_adminsEthEarningsAfterFees[msg.sender] = earnings - ethAmount;
        emit OwnerEthFeesWithdrawalSuccessful(msg.sender, ethAmount);

        bool success = payable(msg.sender).send(ethAmount);
        // In theory should never fail, but just in case
        if (!success) {
            revert SubscriptionManager__WithdrawFailed();
        }
    }

    /**
     * @dev Withdraw the earnings of the admin in USD. This function is called by the owner of the contract.
     * @param usdAmount The amount to withdraw. If this is more than the fee earnings, all earnings will be withdrawn.
     */
    function withdrawOwnerUsdFeesEarnings(uint256 usdAmount) public onlyOwner {
        uint256 earnings = s_totalUsdFeesEarnings;
        if (usdAmount > earnings) {
            usdAmount = earnings;
        }
        s_totalUsdFeesEarnings -= usdAmount;
        s_adminsUsdEarningsAfterFees[msg.sender] = earnings - usdAmount;
        emit OwnerUsdFeesWithdrawalSuccessful(msg.sender, usdAmount);
        uint256 usdAmount6Decimals = usdAmount / (10 ** (DECIMALS - USDT_DECIMALS));
        acceptedToken.transfer(msg.sender, usdAmount6Decimals);
    }

    /**
     * @dev Cancel a subscription. This function is called by the user that is subscribed.
     * The user will no longer be required to pay for the subscription and it will be inactive.
     * If you call this function, your subscription will be cancelled regardless of the time left on the subscription.
     * Note: This may be redundant as the subscription will be cancelled if the user does not make a payment on time.
     * @param admin The admin of the subscription the user is subscribing to.
     */
    function cancelSubscription(address admin) public isRegisteredUser(msg.sender) {
        Subscription memory subscription = s_subscriptions[admin][msg.sender];
        if (subscription.isActive != true) {
            revert SubscriptionManager__SubscriptionNotActive();
        }
        s_subscriptions[admin][msg.sender].isActive = false;
        emit SubscriptionCancelled(admin, msg.sender);
    }

    receive() external payable {} // to receive payments

    // amount: 10000000 (10 USDT)

    /**
     * @dev Calculate the fee in USD for a given amount.
     * @param amount The amount to calculate the fee for in usd with 18 decimals
     * @return The fee in USD.
     */
    function calculateUsdFee(uint256 amount) public pure returns (uint256) {
        // 1000 000000/ 100 = 100_000
        uint256 percentFee = (amount * FEE) / 10000;
        return percentFee + FLAT_USD_FEE;
    }

    /**
     * @dev Calculate the fee in ETH for a given amount.
     * @param amount The amount to calculate the fee for in eth with 18 decimals
     * @return The fee in ETH.
     */
    function calculateEthFee(uint256 amount) public view returns (uint256) {
        // 1000 000000/ 100 = 100_000
        uint256 percentFee = (amount * FEE) / 10000;
        uint256 ethFee = _getEthAmountFromUsd(FLAT_USD_FEE);
        return percentFee + ethFee;
    }

    // internal functions

    /**
     * @dev Update the earnings of the admin in USD after they receive payment in USD.
     * @param admin The admin to update the earnings for
     * @param amount The amount in USD with 18 decimals
     */
    function _updateAdminUsdEarnings(address admin, uint256 amount) internal {
        uint256 fee = calculateUsdFee(amount);
        s_totalUsdFeesEarnings += fee;
        uint256 earningsAfterFees = amount - calculateUsdFee(amount);
        s_adminsUsdEarningsAfterFees[admin] += earningsAfterFees;
    }

    /**
     * @dev Update the earnings of the admin in ETH after they receive payment in ETH.
     * @param admin The admin to update the earnings for
     * @param amount The amount in ETH with 18 decimals
     */
    function _updateAdminEthEarnings(address admin, uint256 amount) internal {
        uint256 fee = calculateEthFee(amount);
        s_totalEthFeesEarnings += fee;
        uint256 earningsAfterFees = amount - calculateEthFee(amount);
        s_adminsEthEarningsAfterFees[admin] += earningsAfterFees;
    }

    /**
     * @dev Handle the payment in stable coin.
     * @param from The user that is paying
     * @param amount The amount in USD with 18 decimals
     */
    function _handleStableCoinPayment(address from, uint256 amount /* in usd with 18 decimals */ ) internal {
        uint256 usdtAmount = amount / (10 ** (DECIMALS - USDT_DECIMALS));
        acceptedToken.transferFrom(from, address(this), usdtAmount);
    }

    /**
     * @dev Get the amount of ETH for a given amount in USD.
     * @param amount The amount in USD with 18 decimals
     * @return The amount in ETH with 18 decimals.
     */
    function _getEthAmountFromUsd(uint256 amount) internal view returns (uint256) {
        (, int256 price,,,) = wethPriceFeed.latestRoundData(); // e.g $1000 would return 1000.00000000
        uint256 price18Decimals = uint256(price) * (10 ** (DECIMALS - PRICE_FEED_DECIMALS));
        return (amount * 1e18) / uint256(price18Decimals);
    }

    function _handleSetNextPaymentDay(address admin, address user, uint256 nextPaymentTime) internal {
        uint256 nextPaymentDay = _getNumberOfDaysSince1970(nextPaymentTime);
        AdminUserRelation memory adminUserRelation = AdminUserRelation({admin: admin, user: user});
        s_adminUserRelationsDueOnDay[nextPaymentDay].push(adminUserRelation);
    }

    /**
     * duplicate?
     * @dev Get the number of days since 1970-01-01.
     * @param timestamp The timestamp to get the number of days since 1970-01-01.
     * @return The number of days since 1970-01-01.
     */
    function _getNumberOfDaysSince1970(uint256 timestamp) internal pure returns (uint256) {
        return timestamp / 1 days;
    }

    // Getters

    function getAdminUserRelationsDueOnDay(uint256 date) public view returns (AdminUserRelation[] memory) {
        return s_adminUserRelationsDueOnDay[date];
    }

    function getstableCoinAddress() public view returns (address) {
        return address(acceptedToken);
    }

    function getSubscription(address admin, address user) public view returns (Subscription memory) {
        return s_subscriptions[admin][user];
    }

    function getIsRegisteredUser(address user) public view returns (bool) {
        return s_registeredUsers[user];
    }

    function getAdminsEthEarningsAfterFees(address admin) public view returns (uint256) {
        return s_adminsEthEarningsAfterFees[admin];
    }

    function getAdminsUsdEarningsAfterFees(address admin) public view returns (uint256) {
        return s_adminsUsdEarningsAfterFees[admin];
    }

    function getFlatUsdFee() public view returns (uint256) {
        return FLAT_USD_FEE;
    }

    function getPercentFee() public view returns (uint256) {
        return FEE;
    }

    function getTotalUsdFeesEarnings() public view returns (uint256) {
        return s_totalUsdFeesEarnings;
    }

    function getTotalEthFeesEarnings() public view returns (uint256) {
        return s_totalEthFeesEarnings;
    }

    function getProcessedDay(uint256 day) public view returns (bool) {
        return s_processedDays[day];
    }

    function getSubscriptionsDueOnDay(uint256 day) public view returns (AdminUserRelation[] memory) {
        return s_adminUserRelationsDueOnDay[day];
    }
}
