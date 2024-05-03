// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.18;

import "@openzeppelin/contracts/access/Ownable.sol";

contract SubscriptionManager is Ownable {
    // State variables
    mapping(address admin => mapping(address user => Subscription)) public s_subscriptions; // the agreement between the admin and the user
    mapping(uint256 date => address[] usersToPayOnDate) public s_subscriptionsDue; // for each day in the future, there is a list of users that are required to pay on that day

    // Events
    event SubscriptionActivated(
        address indexed admin,
        address indexed user,
        uint256 price,
        uint256 paymentInterval,
        uint256 startTime,
        uint256 endTime
    );

    event PaymentMade(address indexed admin, address indexed user, uint256 price, uint256 nextPaymentTime);

    // Errors
    error SubscriptionManager__SubscriptionAlreadyActive();
    error SubscriptionManager__SubscriptionPriceMismatch();

    // Structs

    struct Subscription {
        uint256 price;
        uint256 paymentInterval;
        uint256 startTime;
        uint256 endTime;
        uint256 nextPaymentTime;
        address admin;
        address user;
        bool isActive;
    }

    // Constructor
    constructor() Ownable(msg.sender) {
        // constructor code
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
        public
        onlyOwner
    {
        address admin = msg.sender;
        // create a new subscription
        Subscription memory newSubscription = Subscription({
            price: price,
            paymentInterval: paymentInterval,
            startTime: 0, // all times are set to max value to indicate that the subscription has not started yet
            endTime: 0,
            nextPaymentTime: 0,
            admin: admin,
            user: user,
            isActive: false
        });
        // add the inactive subscription to the mapping
        s_subscriptions[admin][user] = newSubscription;
    }

    /**
     * @dev Activate a subscription. This function is called by the user that is subscribing.
     * @param admin The admin of the subscription the user is subscribing to.
     */
    function activateSubscription(address admin) public payable {
        Subscription subscription = s_subscriptions[admin][msg.sender];

        if (subscription.isActive == true) {
            revert SubscriptionManager__SubscriptionAlreadyActive();
        }
        if (msg.value != subscription.price) {
            revert SubscriptionManager__SubscriptionPriceMismatch();
        }

        // Set times and activate the subscription
        Subscription memory newSubscription = Subscription({
            price: subscription.price,
            paymentInterval: subscription.paymentInterval,
            startTime: block.timestamp, // all times are set to max value to indicate that the subscription has not started yet
            endTime: block.timestamp + subscription.duration,
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
    }

    function makePayment() public payable {
        Subscription subscription = s_subscriptions[msg.sender][msg.sender];

        if (subscription.isActive == true) {
            revert SubscriptionManager__SubscriptionAlreadyActive();
        }
        if (msg.value != subscription.price) {
            revert SubscriptionManager__SubscriptionPriceMismatch();
        }

        // Set times and activate the subscription
        Subscription memory newSubscription = Subscription({
            price: subscription.price,
            paymentInterval: subscription.paymentInterval,
            startTime: subscription.startTime, // all times are set to max value to indicate that the subscription has not started yet
            endTime: subscription.endTime,
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
    }
}
