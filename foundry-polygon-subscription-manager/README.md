# Avax subscription manager

### Description:
This is a dapp that allows admins to manage their subscriptions and view analytics and users to subscribe to an admin's service in order to pay for the admins service (which can be on or off chain). E.g A gym (admin) can use this dapp to manage their subscriptions and gym users (user) can use this dapp to pay for their gym subscription.

### Definitions:
-   **Subscription plan**: mapping([admin][user] => struct SubscriptionPlan) Payment plan that an admin creates in order to charge users for their service. It contains the following fields:
    -   Price: Price of the subscription plan per payment interval.
    -   Payment interval: Interval at which the user will be charged.
    -   Start time: Start time of the subscription plan.
    -   End time: End time of the subscription plan.
    -   Next payment time: Time of the next payment. (for informing but also helps with cancelation so that the user can be removed from the mapping subscriptionsDue which maps a date to a list of users that have a subscription due on that date)
    -   Admin: Address of the admin that created the subscription plan.
    -   Users: List of users that have subscribed to the subscription plan.
### Stakeholders:
- **Admin**: Entity that is using our service to manage their subscriptions.
    -   Has access to the following functionalities:
        -   Create a subscription plan.
        -   View all subscription plans.
        -   View all users that have subscribed to their service.
        -   View analytics of their service.
        -   Withdraw funds from their service.
        -   Update their subscription plan.
        -   Delete their subscription plan.
- **User**: Entity that is using our service to subscribe to an admin's service.


### chainlink products used
- Will use **chainlink automation** to check if payments were made on time and if not the plan is set to innactive.
- Will use **chainlink functions** to inform backend on what email to send to a user or admin.
- (Potentially) will use **chainlink price feeds** to get the price of the subscription plan in ETH.


### Extras
All usd values are with 18 decimals. They are only ever converted to 6 decimals when handling transfers of usdt


### TODO
- Zero checks for all fields in subscription
- admin != user checks
