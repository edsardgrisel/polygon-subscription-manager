import { gql } from "@apollo/client"

const GET_INACTIVE_SUBSCRIPTIONS = gql`
    query GetInactiveSubscriptions($user: Bytes) {
        inactiveSubscriptions(first: 5
            where: {
                     user: $user, admin_not: "0x000000000000000000000000000000000000dead" 
                }
            ) {
            id
            admin
            user
            paymentInterval
            price
            duration
            
            }
    }
`

const GET_ACTIVE_SUBSCRIPTIONS = gql`
    query GetActiveSubscriptions($user: Bytes) {
        activeSubscriptions(first: 5
            where: {
                     user: $user, admin_not: "0x000000000000000000000000000000000000dead" 
                }
            ) {
            id
            admin
            user
            paymentInterval
            price
            nextPaymentTime
            }
    }
`


export { GET_INACTIVE_SUBSCRIPTIONS, GET_ACTIVE_SUBSCRIPTIONS }
