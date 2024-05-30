import styles from '../styles/Home.module.css';
import { Form, useNotification} from "web3uikit"
import { useState, useEffect } from 'react'
import { ethers } from "ethers"
import { useMoralis, useWeb3Contract } from "react-moralis"
import subscriptionManagerAbi from '../constants/subscriptionManagerAbi.json';
import networkMapping from "../constants/networkMapping.json"


export default function Home() {

  const { chainId, account, isWeb3Enabled } = useMoralis()
  const chainString = chainId ? parseInt(chainId).toString() : "31337"
  const subscriptionManagerAddress = networkMapping[chainString].SubscriptionManager[0];
  const { runContractFunction } = useWeb3Contract()
  const dispatch = useNotification()

  ////////////////////
  
  

  async function createSubscription(data) {
    console.log("Withdrawing USD...")
    const address = data.data[0].inputResult

    const paymentIntervalInDays = data.data[1].inputResult
    const paymentInterval = paymentIntervalInDays * 86400

    const paymentAmount = ethers.utils.parseUnits(data.data[1].inputResult, "ether").toString()

    const durationInDays = data.data[3].inputResult
    const duration = durationInDays * 86400
    
      

    const createSubscriptionOptions = {
        abi: subscriptionManagerAbi,
        contractAddress: subscriptionManagerAddress,
        functionName: "createInactiveSubscription",
        params: {
            price: paymentAmount,
            paymentInterval: paymentInterval,
            duration: duration,
            user:address,
        },
    }

    await runContractFunction({
        params: createSubscriptionOptions,
        onSuccess: () => handleCreateSubscriptionSuccess(),
        onError: (error) => {
            console.log(error)
        },
    })
  }

  const handleCreateSubscriptionSuccess = () => {
      dispatch({
          type: "success",
          message: "Subscription created",
          position: "topR",
      })
  }
  return (
    <div className={styles.container} style={{ paddingBottom: '200px' }}>
      <Form 
          onSubmit={createSubscription}
          data={[
              {
                  name: "Client's wallet address(Avalanche Fuji)",
                  type: "text",
                  value: "",
                  key: "address",
              },
              {
                  name: "Payment interval (days)",
                  type: "number",
                  value: "",
                  key: "paymentInterval",
              },
              {
                name: "Payment per period (USD)",
                type: "number",
                value: "",
                key: "paymentAmount",
              },
              {
                name: "Subscription duration (days)",
                type: "number",
                value: "",
                key: "duration",
            },
          ]}
          title="Create Subscription"
          id="Main Form"
      />
    </div>
  )
}