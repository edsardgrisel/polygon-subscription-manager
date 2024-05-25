import {
  assert,
  describe,
  test,
  clearStore,
  beforeAll,
  afterAll
} from "matchstick-as/assembly/index"
import { Address, BigInt } from "@graphprotocol/graph-ts"
import { AdminEthWithdrawalSuccessful } from "../generated/schema"
import { AdminEthWithdrawalSuccessful as AdminEthWithdrawalSuccessfulEvent } from "../generated/SubscriptionManager/SubscriptionManager"
import { handleAdminEthWithdrawalSuccessful } from "../src/subscription-manager"
import { createAdminEthWithdrawalSuccessfulEvent } from "./subscription-manager-utils"

// Tests structure (matchstick-as >=0.5.0)
// https://thegraph.com/docs/en/developer/matchstick/#tests-structure-0-5-0

describe("Describe entity assertions", () => {
  beforeAll(() => {
    let admin = Address.fromString("0x0000000000000000000000000000000000000001")
    let amount = BigInt.fromI32(234)
    let newAdminEthWithdrawalSuccessfulEvent =
      createAdminEthWithdrawalSuccessfulEvent(admin, amount)
    handleAdminEthWithdrawalSuccessful(newAdminEthWithdrawalSuccessfulEvent)
  })

  afterAll(() => {
    clearStore()
  })

  // For more test scenarios, see:
  // https://thegraph.com/docs/en/developer/matchstick/#write-a-unit-test

  test("AdminEthWithdrawalSuccessful created and stored", () => {
    assert.entityCount("AdminEthWithdrawalSuccessful", 1)

    // 0xa16081f360e3847006db660bae1c6d1b2e17ec2a is the default address used in newMockEvent() function
    assert.fieldEquals(
      "AdminEthWithdrawalSuccessful",
      "0xa16081f360e3847006db660bae1c6d1b2e17ec2a-1",
      "admin",
      "0x0000000000000000000000000000000000000001"
    )
    assert.fieldEquals(
      "AdminEthWithdrawalSuccessful",
      "0xa16081f360e3847006db660bae1c6d1b2e17ec2a-1",
      "amount",
      "234"
    )

    // More assert options:
    // https://thegraph.com/docs/en/developer/matchstick/#asserts
  })
})
