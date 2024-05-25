import { newMockEvent } from "matchstick-as"
import { ethereum, Address, BigInt } from "@graphprotocol/graph-ts"
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
} from "../generated/SubscriptionManager/SubscriptionManager"

export function createAdminEthWithdrawalSuccessfulEvent(
  admin: Address,
  amount: BigInt
): AdminEthWithdrawalSuccessful {
  let adminEthWithdrawalSuccessfulEvent =
    changetype<AdminEthWithdrawalSuccessful>(newMockEvent())

  adminEthWithdrawalSuccessfulEvent.parameters = new Array()

  adminEthWithdrawalSuccessfulEvent.parameters.push(
    new ethereum.EventParam("admin", ethereum.Value.fromAddress(admin))
  )
  adminEthWithdrawalSuccessfulEvent.parameters.push(
    new ethereum.EventParam("amount", ethereum.Value.fromUnsignedBigInt(amount))
  )

  return adminEthWithdrawalSuccessfulEvent
}

export function createAdminUsdWithdrawalSuccessfulEvent(
  admin: Address,
  amount: BigInt
): AdminUsdWithdrawalSuccessful {
  let adminUsdWithdrawalSuccessfulEvent =
    changetype<AdminUsdWithdrawalSuccessful>(newMockEvent())

  adminUsdWithdrawalSuccessfulEvent.parameters = new Array()

  adminUsdWithdrawalSuccessfulEvent.parameters.push(
    new ethereum.EventParam("admin", ethereum.Value.fromAddress(admin))
  )
  adminUsdWithdrawalSuccessfulEvent.parameters.push(
    new ethereum.EventParam("amount", ethereum.Value.fromUnsignedBigInt(amount))
  )

  return adminUsdWithdrawalSuccessfulEvent
}

export function createDayProcessedEvent(day: BigInt): DayProcessed {
  let dayProcessedEvent = changetype<DayProcessed>(newMockEvent())

  dayProcessedEvent.parameters = new Array()

  dayProcessedEvent.parameters.push(
    new ethereum.EventParam("day", ethereum.Value.fromUnsignedBigInt(day))
  )

  return dayProcessedEvent
}

export function createInactiveSubscriptionCreatedEvent(
  admin: Address,
  user: Address,
  price: BigInt,
  paymentInterval: BigInt,
  duration: BigInt
): InactiveSubscriptionCreated {
  let inactiveSubscriptionCreatedEvent =
    changetype<InactiveSubscriptionCreated>(newMockEvent())

  inactiveSubscriptionCreatedEvent.parameters = new Array()

  inactiveSubscriptionCreatedEvent.parameters.push(
    new ethereum.EventParam("admin", ethereum.Value.fromAddress(admin))
  )
  inactiveSubscriptionCreatedEvent.parameters.push(
    new ethereum.EventParam("user", ethereum.Value.fromAddress(user))
  )
  inactiveSubscriptionCreatedEvent.parameters.push(
    new ethereum.EventParam("price", ethereum.Value.fromUnsignedBigInt(price))
  )
  inactiveSubscriptionCreatedEvent.parameters.push(
    new ethereum.EventParam(
      "paymentInterval",
      ethereum.Value.fromUnsignedBigInt(paymentInterval)
    )
  )
  inactiveSubscriptionCreatedEvent.parameters.push(
    new ethereum.EventParam(
      "duration",
      ethereum.Value.fromUnsignedBigInt(duration)
    )
  )

  return inactiveSubscriptionCreatedEvent
}

export function createOwnerEthFeesWithdrawalSuccessfulEvent(
  owner: Address,
  amount: BigInt
): OwnerEthFeesWithdrawalSuccessful {
  let ownerEthFeesWithdrawalSuccessfulEvent =
    changetype<OwnerEthFeesWithdrawalSuccessful>(newMockEvent())

  ownerEthFeesWithdrawalSuccessfulEvent.parameters = new Array()

  ownerEthFeesWithdrawalSuccessfulEvent.parameters.push(
    new ethereum.EventParam("owner", ethereum.Value.fromAddress(owner))
  )
  ownerEthFeesWithdrawalSuccessfulEvent.parameters.push(
    new ethereum.EventParam("amount", ethereum.Value.fromUnsignedBigInt(amount))
  )

  return ownerEthFeesWithdrawalSuccessfulEvent
}

export function createOwnerUsdFeesWithdrawalSuccessfulEvent(
  owner: Address,
  amount: BigInt
): OwnerUsdFeesWithdrawalSuccessful {
  let ownerUsdFeesWithdrawalSuccessfulEvent =
    changetype<OwnerUsdFeesWithdrawalSuccessful>(newMockEvent())

  ownerUsdFeesWithdrawalSuccessfulEvent.parameters = new Array()

  ownerUsdFeesWithdrawalSuccessfulEvent.parameters.push(
    new ethereum.EventParam("owner", ethereum.Value.fromAddress(owner))
  )
  ownerUsdFeesWithdrawalSuccessfulEvent.parameters.push(
    new ethereum.EventParam("amount", ethereum.Value.fromUnsignedBigInt(amount))
  )

  return ownerUsdFeesWithdrawalSuccessfulEvent
}

export function createOwnershipTransferredEvent(
  previousOwner: Address,
  newOwner: Address
): OwnershipTransferred {
  let ownershipTransferredEvent = changetype<OwnershipTransferred>(
    newMockEvent()
  )

  ownershipTransferredEvent.parameters = new Array()

  ownershipTransferredEvent.parameters.push(
    new ethereum.EventParam(
      "previousOwner",
      ethereum.Value.fromAddress(previousOwner)
    )
  )
  ownershipTransferredEvent.parameters.push(
    new ethereum.EventParam("newOwner", ethereum.Value.fromAddress(newOwner))
  )

  return ownershipTransferredEvent
}

export function createPaymentMadeEvent(
  admin: Address,
  user: Address,
  price: BigInt,
  nextPaymentTime: BigInt
): PaymentMade {
  let paymentMadeEvent = changetype<PaymentMade>(newMockEvent())

  paymentMadeEvent.parameters = new Array()

  paymentMadeEvent.parameters.push(
    new ethereum.EventParam("admin", ethereum.Value.fromAddress(admin))
  )
  paymentMadeEvent.parameters.push(
    new ethereum.EventParam("user", ethereum.Value.fromAddress(user))
  )
  paymentMadeEvent.parameters.push(
    new ethereum.EventParam("price", ethereum.Value.fromUnsignedBigInt(price))
  )
  paymentMadeEvent.parameters.push(
    new ethereum.EventParam(
      "nextPaymentTime",
      ethereum.Value.fromUnsignedBigInt(nextPaymentTime)
    )
  )

  return paymentMadeEvent
}

export function createSubscriptionActivatedEvent(
  admin: Address,
  user: Address,
  price: BigInt,
  paymentInterval: BigInt,
  startTime: BigInt,
  endTime: BigInt
): SubscriptionActivated {
  let subscriptionActivatedEvent = changetype<SubscriptionActivated>(
    newMockEvent()
  )

  subscriptionActivatedEvent.parameters = new Array()

  subscriptionActivatedEvent.parameters.push(
    new ethereum.EventParam("admin", ethereum.Value.fromAddress(admin))
  )
  subscriptionActivatedEvent.parameters.push(
    new ethereum.EventParam("user", ethereum.Value.fromAddress(user))
  )
  subscriptionActivatedEvent.parameters.push(
    new ethereum.EventParam("price", ethereum.Value.fromUnsignedBigInt(price))
  )
  subscriptionActivatedEvent.parameters.push(
    new ethereum.EventParam(
      "paymentInterval",
      ethereum.Value.fromUnsignedBigInt(paymentInterval)
    )
  )
  subscriptionActivatedEvent.parameters.push(
    new ethereum.EventParam(
      "startTime",
      ethereum.Value.fromUnsignedBigInt(startTime)
    )
  )
  subscriptionActivatedEvent.parameters.push(
    new ethereum.EventParam(
      "endTime",
      ethereum.Value.fromUnsignedBigInt(endTime)
    )
  )

  return subscriptionActivatedEvent
}

export function createSubscriptionCancelledEvent(
  admin: Address,
  user: Address
): SubscriptionCancelled {
  let subscriptionCancelledEvent = changetype<SubscriptionCancelled>(
    newMockEvent()
  )

  subscriptionCancelledEvent.parameters = new Array()

  subscriptionCancelledEvent.parameters.push(
    new ethereum.EventParam("admin", ethereum.Value.fromAddress(admin))
  )
  subscriptionCancelledEvent.parameters.push(
    new ethereum.EventParam("user", ethereum.Value.fromAddress(user))
  )

  return subscriptionCancelledEvent
}

export function createUserRegisteredEvent(user: Address): UserRegistered {
  let userRegisteredEvent = changetype<UserRegistered>(newMockEvent())

  userRegisteredEvent.parameters = new Array()

  userRegisteredEvent.parameters.push(
    new ethereum.EventParam("user", ethereum.Value.fromAddress(user))
  )

  return userRegisteredEvent
}

export function createUserUnregisteredEvent(user: Address): UserUnregistered {
  let userUnregisteredEvent = changetype<UserUnregistered>(newMockEvent())

  userUnregisteredEvent.parameters = new Array()

  userUnregisteredEvent.parameters.push(
    new ethereum.EventParam("user", ethereum.Value.fromAddress(user))
  )

  return userUnregisteredEvent
}
