# Polygon subscription manager

### Description:
This is a dapp that allows admins to manage their subscriptions and view analytics and users to subscribe to an admin's service in order to pay for the admins service (which can be on or off chain). E.g A gym (admin) can use this dapp to manage their subscriptions and gym users (user) can use this dapp to pay for their gym subscription.

### Definitions:
-   **Subscription plan**: mapping([admin][subscriber] => struct SubscriptionPlan) Payment plan that an admin creates in order to charge subscriber for their service. It contains the following fields:
    -   Price: Price of the subscription plan per payment interval.
    -   Payment interval: Interval at which the subscriber will be charged.
    -   Start time: Start time of the subscription plan.
    -   End time: End time of the subscription plan.
    -   Next payment time: Time of the next payment. (for informing but also helps with cancelation so that the subscriber can be removed from the mapping subscriptionsDue which maps a date to a list of subscriber that have a subscription due on that date)
    -   Admin: Address of the admin that created the subscription plan.
    -   subscribers: List of users that have subscribed to the subscription plan.
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
- **User**: Entity that is signed up and has email and name in our database.
- **Subscriber**: Entity that has subscribed to an admin's service.
    -   Has access to the following functionalities:
        -   Subscribe to an admin's service.
        -   Unsubscribe from an admin's service.
        -   View all subscription plans(and next payment deadlines).

### Instructions:
to run the front end:
- Clone the repo
- cd into nextjs-next-js-subscription-manager
- cd into nextjs-blog
- run `npm install`
- run `npm run dev` and open in local host.
- Connect with metamask.

to run the smart contract:
- Clone the repo
- cd into foundry-polygon-subscription-manager
- run `npm install`
- run anvil chain with `anvil`
- `make deploy` to deploy the smart contract