import { BigInt, Address } from "@graphprotocol/graph-ts"

import {
  // AdminEthWithdrawalSuccessful as AdminEthWithdrawalSuccessfulEvent,
  // AdminUsdWithdrawalSuccessful as AdminUsdWithdrawalSuccessfulEvent,
  // DayProcessed as DayProcessedEvent,
  InactiveSubscriptionCreated as InactiveSubscriptionCreatedEvent,
  // OwnerEthFeesWithdrawalSuccessful as OwnerEthFeesWithdrawalSuccessfulEvent,
  // OwnerUsdFeesWithdrawalSuccessful as OwnerUsdFeesWithdrawalSuccessfulEvent,
  // OwnershipTransferred as OwnershipTransferredEvent,
  PaymentMade as PaymentMadeEvent,
  SubscriptionActivated as SubscriptionActivatedEvent,
  SubscriptionCancelled as SubscriptionCancelledEvent,
  // UserRegistered as UserRegisteredEvent,
  // UserUnregistered as UserUnregisteredEvent
} from "../generated/SubscriptionManager/SubscriptionManager"
import {
  InactiveSubscription,
  ActiveSubscription
} from "../generated/schema"


function getIdFromEvent(adminAddress: Address, userAddress: Address): string {
  return adminAddress.toHexString() + userAddress.toHexString()
}

// export function handleAdminEthWithdrawalSuccessful(
//   event: AdminEthWithdrawalSuccessfulEvent
// ): void {
//   let entity = new AdminEthWithdrawalSuccessful(
//     event.transaction.hash.concatI32(event.logIndex.toI32())
//   )
//   entity.admin = event.params.admin
//   entity.amount = event.params.amount

//   entity.blockNumber = event.block.number
//   entity.blockTimestamp = event.block.timestamp
//   entity.transactionHash = event.transaction.hash

//   entity.save()
// }

// export function handleAdminUsdWithdrawalSuccessful(
//   event: AdminUsdWithdrawalSuccessfulEvent
// ): void {
//   let entity = new AdminUsdWithdrawalSuccessful(
//     event.transaction.hash.concatI32(event.logIndex.toI32())
//   )
//   entity.admin = event.params.admin
//   entity.amount = event.params.amount

//   entity.blockNumber = event.block.number
//   entity.blockTimestamp = event.block.timestamp
//   entity.transactionHash = event.transaction.hash

//   entity.save()
// }

// export function handleDayProcessed(event: DayProcessedEvent): void {
//   let entity = new DayProcessed(
//     event.transaction.hash.concatI32(event.logIndex.toI32())
//   )
//   entity.day = event.params.day

//   entity.blockNumber = event.block.number
//   entity.blockTimestamp = event.block.timestamp
//   entity.transactionHash = event.transaction.hash

//   entity.save()
// }

export function handleInactiveSubscriptionCreated(
  event: InactiveSubscriptionCreatedEvent
): void {
  let inactiveSubscription = InactiveSubscription.load(getIdFromEvent(event.params.admin, event.params.user))
  if(!inactiveSubscription) {
    inactiveSubscription = new InactiveSubscription(getIdFromEvent(event.params.admin, event.params.user))
  }
  inactiveSubscription.admin = event.params.admin
  inactiveSubscription.user = event.params.user
  inactiveSubscription.price = event.params.price
  inactiveSubscription.paymentInterval = event.params.paymentInterval
  inactiveSubscription.duration = event.params.duration
  inactiveSubscription.blockNumber = event.block.number
  inactiveSubscription.blockTimestamp = event.block.timestamp
  inactiveSubscription.transactionHash = event.transaction.hash

  inactiveSubscription.save()
}

// export function handleOwnerEthFeesWithdrawalSuccessful(
//   event: OwnerEthFeesWithdrawalSuccessfulEvent
// ): void {
//   let entity = new OwnerEthFeesWithdrawalSuccessful(
//     event.transaction.hash.concatI32(event.logIndex.toI32())
//   )
//   entity.owner = event.params.owner
//   entity.amount = event.params.amount

//   entity.blockNumber = event.block.number
//   entity.blockTimestamp = event.block.timestamp
//   entity.transactionHash = event.transaction.hash

//   entity.save()
// }

// export function handleOwnerUsdFeesWithdrawalSuccessful(
//   event: OwnerUsdFeesWithdrawalSuccessfulEvent
// ): void {
//   let entity = new OwnerUsdFeesWithdrawalSuccessful(
//     event.transaction.hash.concatI32(event.logIndex.toI32())
//   )
//   entity.owner = event.params.owner
//   entity.amount = event.params.amount

//   entity.blockNumber = event.block.number
//   entity.blockTimestamp = event.block.timestamp
//   entity.transactionHash = event.transaction.hash

//   entity.save()
// }

// export function handleOwnershipTransferred(
//   event: OwnershipTransferredEvent
// ): void {
//   let entity = new OwnershipTransferred(
//     event.transaction.hash.concatI32(event.logIndex.toI32())
//   )
//   entity.previousOwner = event.params.previousOwner
//   entity.newOwner = event.params.newOwner

//   entity.blockNumber = event.block.number
//   entity.blockTimestamp = event.block.timestamp
//   entity.transactionHash = event.transaction.hash

//   entity.save()
// }

export function handlePaymentMade(event: PaymentMadeEvent): void {

  let activeSubscription = new ActiveSubscription(getIdFromEvent(event.params.admin, event.params.user))
  
  activeSubscription.nextPaymentTime = event.params.nextPaymentTime

  activeSubscription.save()
}

export function handleSubscriptionActivated(
  event: SubscriptionActivatedEvent
): void {

  let inactiveSubscription = InactiveSubscription.load(getIdFromEvent(event.params.admin, event.params.user))
  let activeSubscription = new ActiveSubscription(getIdFromEvent(event.params.admin, event.params.user))

  if(!activeSubscription) {
    activeSubscription = new ActiveSubscription(getIdFromEvent(event.params.admin, event.params.user))
  }

  inactiveSubscription!.admin = Address.fromString('0x000000000000000000000000000000000000dEaD')

  activeSubscription.admin = event.params.admin
  activeSubscription.user = event.params.user
  activeSubscription.price = event.params.price
  activeSubscription.paymentInterval = event.params.paymentInterval
  activeSubscription.startTime = event.params.startTime
  activeSubscription.endTime = event.params.endTime
  activeSubscription.nextPaymentTime = event.params.startTime.plus(event.params.paymentInterval)
  activeSubscription.blockNumber = event.block.number
  activeSubscription.blockTimestamp = event.block.timestamp
  activeSubscription.transactionHash = event.transaction.hash

  inactiveSubscription!.save()
  activeSubscription.save()
}

export function handleSubscriptionCancelled(
  event: SubscriptionCancelledEvent
): void {
  let activeSubscription = new ActiveSubscription(getIdFromEvent(event.params.admin, event.params.user))
  
  activeSubscription.admin = Address.fromString('0x000000000000000000000000000000000000dEaD')

  activeSubscription.save()
}

// export function handleUserRegistered(event: UserRegisteredEvent): void {
//   let entity = new UserRegistered(
//     event.transaction.hash.concatI32(event.logIndex.toI32())
//   )
//   entity.user = event.params.user

//   entity.blockNumber = event.block.number
//   entity.blockTimestamp = event.block.timestamp
//   entity.transactionHash = event.transaction.hash

//   entity.save()
// }

// export function handleUserUnregistered(event: UserUnregisteredEvent): void {
//   let entity = new UserUnregistered(
//     event.transaction.hash.concatI32(event.logIndex.toI32())
//   )
//   entity.user = event.params.user

//   entity.blockNumber = event.block.number
//   entity.blockTimestamp = event.block.timestamp
//   entity.transactionHash = event.transaction.hash

//   entity.save()
// }
