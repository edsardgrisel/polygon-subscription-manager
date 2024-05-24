import styles from '../styles/Home.module.css';
import { useRouter } from 'next/router';
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
 
  const dispatch = useNotification()


  const { runContractFunction } = useWeb3Contract()

  async function activateSubscriptionWithAvax(data) {
    console.log("Activating Subscription...")

    const adminAddress = data.data[0].inputResult

    const activateSubscriptionWithEthOptions = {
      abi: subscriptionManagerAbi,
      contractAddress: subscriptionManagerAddress,
      functionName: "activateSubscriptionWithEth",
      params: {
        admin: adminAddress,
      },
      msgValue: ethers.utils.parseEther("0.0005")
    }

    await runContractFunction({
        params: activateSubscriptionWithEthOptions,
        onSuccess: () => handleActivateSubscriptionWithEth(),
        onError: (error) => {
            console.log(error)
        },
    
    })

  }
  
  const handleActivateSubscriptionWithEth = () => {
      dispatch({
          type: "success",
          message: "Subscription activated",
          position: "topR",
      })

  }

  ////////////////////////////////////

  async function activateSubscriptionWithUsd(data) {
    console.log("Activating Subscription...")

    const adminAddress = data.data[0].inputResult

    const activateSubscriptionWithStableCoinOptions = {
        abi: subscriptionManagerAbi,
        contractAddress: subscriptionManagerAddress,
        functionName: "activateSubscriptionWithStableCoin",
        params: {
            admin: adminAddress,
        },
    }

    await runContractFunction({
        params: activateSubscriptionWithStableCoinOptions,
        onSuccess: () => handleCreateSubscriptionSuccess(),
        onError: (error) => {
            console.log(error)
        },
    
    })

  }
  
  const handleCreateSubscriptionSuccess = () => {
      dispatch({
          type: "success",
          message: "Subscription activated",
          position: "topR",
      })

  }

    // http://localhost:3000/activate-subscription?address=0x00 
    // can give user a custom url in email to activate subscription

  return (
    <div className={styles.container} style={{ paddingBottom: '200px' }}>
      <Form 
          onSubmit={activateSubscriptionWithAvax}
          data={[
              {
                  name: "Admin wallet address(Avalanche Fuji)",
                  type: "text",
                  value: 0,
                  key: "address",
              },
              
          ]}
          title="Activate Subscription With Avax"
          id="Main Form"
      />
      <Form 
          onSubmit={activateSubscriptionWithUsd}
          data={[
              {
                  name: "Admin wallet address(Avalanche Fuji)",
                  type: "text",
                  value: 0,
                  key: "address",
              },
              
          ]}
          title="Activate Subscription With Usd"
          id="Main Form"
      />
    </div>
  )
}