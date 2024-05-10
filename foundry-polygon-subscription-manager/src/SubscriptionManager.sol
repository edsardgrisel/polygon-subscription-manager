// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract SubscriptionManager is Ownable {
    // State variables
    mapping(address admin => mapping(address user => Subscription)) private s_subscriptions; // the agreement between the admin and the user
    mapping(uint256 date => address[] usersToPayOnDate) private s_subscriptionsDue; // for each day in the future, there is a list of users that are required to pay on that day
    mapping(address => bool) private s_registeredUsers;
    ERC20 public immutable stableCoin;
    uint256 public immutable DECIMALS = 6;

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
    event InactiveSubscriptionCreated(
        address indexed admin, address indexed user, uint256 price, uint256 paymentInterval, uint256 duration
    );
    event UserRegistered(address indexed user);
    event UserUnregistered(address indexed user);

    // Errors
    error SubscriptionManager__SubscriptionAlreadyActive();
    error SubscriptionManager__SubscriptionNotActive();
    error SubscriptionManager__SubscriptionPriceMismatch();
    error SubscriptionManager__UserNotRegistered(address user);
    error SubscriptionManager__UserAlreadyRegistered(address user);

    // Structs

    struct Subscription {
        uint256 price;
        uint256 paymentInterval;
        uint256 startTime;
        uint256 duration;
        uint256 nextPaymentTime;
        address admin;
        address user;
        bool isActive;
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
    constructor(address _stableCoin) Ownable(msg.sender) {
        stableCoin = ERC20(_stableCoin);
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
            startTime: 0, // all times are set to max value to indicate that the subscription has not started yet
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
     * @dev Activate a subscription. This function is called by the user that is subscribing.
     * @param admin The admin of the subscription the user is subscribing to.
     */
    function activateSubscription(address admin) public payable {
        Subscription memory subscription = s_subscriptions[admin][msg.sender];

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

        // chainlink function to call backend to send email to user with confirmation and next payment date
    }

    function makePayment(address admin) public payable {
        Subscription memory subscription = s_subscriptions[admin][msg.sender];

        if (subscription.isActive != true) {
            revert SubscriptionManager__SubscriptionNotActive();
        }
        if (msg.value != subscription.price) {
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
    }

    receive() external payable {} // to receive payments

    // Getters

    function getSubscriptionDue(address admin, uint256 date) public view returns (address[] memory) {
        return s_subscriptionsDue[date];
    }

    function getstableCoin() public view returns (address) {
        return address(stableCoin);
    }

    function getSubscription(address admin, address user) public view returns (Subscription memory) {
        return s_subscriptions[admin][user];
    }

    function getIsRegisteredUser(address user) public view returns (bool) {
        return s_registeredUsers[user];
    }
}
