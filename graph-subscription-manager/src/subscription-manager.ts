import {
  AdminEthWithdrawalSuccessful as AdminEthWithdrawalSuccessfulEvent,
  AdminUsdWithdrawalSuccessful as AdminUsdWithdrawalSuccessfulEvent,
  DayProcessed as DayProcessedEvent,
  InactiveSubscriptionCreated as InactiveSubscriptionCreatedEvent,
  OwnerEthFeesWithdrawalSuccessful as OwnerEthFeesWithdrawalSuccessfulEvent,
  OwnerUsdFeesWithdrawalSuccessful as OwnerUsdFeesWithdrawalSuccessfulEvent,
  OwnershipTransferred as OwnershipTransferredEvent,
  PaymentMade as PaymentMadeEvent,
  SubscriptionActivated as SubscriptionActivatedEvent,
  SubscriptionCancelled as SubscriptionCancelledEvent,
  UserRegistered as UserRegisteredEvent,
  UserUnregistered as UserUnregisteredEvent
} from "../generated/SubscriptionManager/SubscriptionManager"
import {
  AdminEthWithdrawalSuccessful,
  AdminUsdWithdrawalSuccessful,
  DayProcessed,
  InactiveSubscriptionCreated,
  OwnerEthFeesWithdrawalSuccessful,
  OwnerUsdFeesWithdrawalSuccessful,
  OwnershipTransferred,
  PaymentMade,
  SubscriptionActivated,
  SubscriptionCancelled,
  UserRegistered,
  UserUnregistered
} from "../generated/schema"

export function handleAdminEthWithdrawalSuccessful(
  event: AdminEthWithdrawalSuccessfulEvent
): void {
  let entity = new AdminEthWithdrawalSuccessful(
    event.transaction.hash.concatI32(event.logIndex.toI32())
  )
  entity.admin = event.params.admin
  entity.amount = event.params.amount

  entity.blockNumber = event.block.number
  entity.blockTimestamp = event.block.timestamp
  entity.transactionHash = event.transaction.hash

  entity.save()
}

export function handleAdminUsdWithdrawalSuccessful(
  event: AdminUsdWithdrawalSuccessfulEvent
): void {
  let entity = new AdminUsdWithdrawalSuccessful(
    event.transaction.hash.concatI32(event.logIndex.toI32())
  )
  entity.admin = event.params.admin
  entity.amount = event.params.amount

  entity.blockNumber = event.block.number
  entity.blockTimestamp = event.block.timestamp
  entity.transactionHash = event.transaction.hash

  entity.save()
}

export function handleDayProcessed(event: DayProcessedEvent): void {
  let entity = new DayProcessed(
    event.transaction.hash.concatI32(event.logIndex.toI32())
  )
  entity.day = event.params.day

  entity.blockNumber = event.block.number
  entity.blockTimestamp = event.block.timestamp
  entity.transactionHash = event.transaction.hash

  entity.save()
}

export function handleInactiveSubscriptionCreated(
  event: InactiveSubscriptionCreatedEvent
): void {
  let entity = new InactiveSubscriptionCreated(
    event.transaction.hash.concatI32(event.logIndex.toI32())
  )
  entity.admin = event.params.admin
  entity.user = event.params.user
  entity.price = event.params.price
  entity.paymentInterval = event.params.paymentInterval
  entity.duration = event.params.duration

  entity.blockNumber = event.block.number
  entity.blockTimestamp = event.block.timestamp
  entity.transactionHash = event.transaction.hash

  entity.save()
}

export function handleOwnerEthFeesWithdrawalSuccessful(
  event: OwnerEthFeesWithdrawalSuccessfulEvent
): void {
  let entity = new OwnerEthFeesWithdrawalSuccessful(
    event.transaction.hash.concatI32(event.logIndex.toI32())
  )
  entity.owner = event.params.owner
  entity.amount = event.params.amount

  entity.blockNumber = event.block.number
  entity.blockTimestamp = event.block.timestamp
  entity.transactionHash = event.transaction.hash

  entity.save()
}

export function handleOwnerUsdFeesWithdrawalSuccessful(
  event: OwnerUsdFeesWithdrawalSuccessfulEvent
): void {
  let entity = new OwnerUsdFeesWithdrawalSuccessful(
    event.transaction.hash.concatI32(event.logIndex.toI32())
  )
  entity.owner = event.params.owner
  entity.amount = event.params.amount

  entity.blockNumber = event.block.number
  entity.blockTimestamp = event.block.timestamp
  entity.transactionHash = event.transaction.hash

  entity.save()
}

export function handleOwnershipTransferred(
  event: OwnershipTransferredEvent
): void {
  let entity = new OwnershipTransferred(
    event.transaction.hash.concatI32(event.logIndex.toI32())
  )
  entity.previousOwner = event.params.previousOwner
  entity.newOwner = event.params.newOwner

  entity.blockNumber = event.block.number
  entity.blockTimestamp = event.block.timestamp
  entity.transactionHash = event.transaction.hash

  entity.save()
}

export function handlePaymentMade(event: PaymentMadeEvent): void {
  let entity = new PaymentMade(
    event.transaction.hash.concatI32(event.logIndex.toI32())
  )
  entity.admin = event.params.admin
  entity.user = event.params.user
  entity.price = event.params.price
  entity.nextPaymentTime = event.params.nextPaymentTime

  entity.blockNumber = event.block.number
  entity.blockTimestamp = event.block.timestamp
  entity.transactionHash = event.transaction.hash

  entity.save()
}

export function handleSubscriptionActivated(
  event: SubscriptionActivatedEvent
): void {
  let entity = new SubscriptionActivated(
    event.transaction.hash.concatI32(event.logIndex.toI32())
  )
  entity.admin = event.params.admin
  entity.user = event.params.user
  entity.price = event.params.price
  entity.paymentInterval = event.params.paymentInterval
  entity.startTime = event.params.startTime
  entity.endTime = event.params.endTime

  entity.blockNumber = event.block.number
  entity.blockTimestamp = event.block.timestamp
  entity.transactionHash = event.transaction.hash

  entity.save()
}

export function handleSubscriptionCancelled(
  event: SubscriptionCancelledEvent
): void {
  let entity = new SubscriptionCancelled(
    event.transaction.hash.concatI32(event.logIndex.toI32())
  )
  entity.admin = event.params.admin
  entity.user = event.params.user

  entity.blockNumber = event.block.number
  entity.blockTimestamp = event.block.timestamp
  entity.transactionHash = event.transaction.hash

  entity.save()
}

export function handleUserRegistered(event: UserRegisteredEvent): void {
  let entity = new UserRegistered(
    event.transaction.hash.concatI32(event.logIndex.toI32())
  )
  entity.user = event.params.user

  entity.blockNumber = event.block.number
  entity.blockTimestamp = event.block.timestamp
  entity.transactionHash = event.transaction.hash

  entity.save()
}

export function handleUserUnregistered(event: UserUnregisteredEvent): void {
  let entity = new UserUnregistered(
    event.transaction.hash.concatI32(event.logIndex.toI32())
  )
  entity.user = event.params.user

  entity.blockNumber = event.block.number
  entity.blockTimestamp = event.block.timestamp
  entity.transactionHash = event.transaction.hash

  entity.save()
}
