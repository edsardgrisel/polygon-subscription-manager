import styles from '../styles/Home.module.css';
import { useRouter } from 'next/router';
import { Form, useNotification} from "web3uikit"
import { useState, useEffect } from 'react'
import { ethers } from "ethers"
import { useMoralis, useWeb3Contract } from "react-moralis"
import subscriptionManagerAbi from '../constants/subscriptionManagerAbi.json';
import networkMapping from "../constants/networkMapping.json"
import { useQuery } from "@apollo/client"
import { GET_INACTIVE_SUBSCRIPTIONS } from "../constants/subgraph-queries"


export default function Home() {
  const { chainId, account, isWeb3Enabled } = useMoralis()
  const chainString = chainId ? parseInt(chainId).toString() : "31337"
  const subscriptionManagerAddress = networkMapping[chainString].SubscriptionManager[0];
 
  const dispatch = useNotification()

  const {
      loading: inactiveSubscriptionsLoading,
      error: inactiveSubscriptionsError,
      data: inactiveSubscriptions,
  } = useQuery(GET_INACTIVE_SUBSCRIPTIONS, {variables: {user: account}})



  const { runContractFunction } = useWeb3Contract()

  async function activateWithAvax(subscription) {
    console.log("Activating Subscription...")

    const activateSubscriptionWithAvaxOptions = {
      abi: subscriptionManagerAbi,
      contractAddress: subscriptionManagerAddress,
      functionName: "activateSubscriptionWithEth",
      params: {
        admin: subscription.admin,
      },
      msgValue: ethers.utils.parseEther(subscription.price.toString())
    }

    await runContractFunction({
        params: activateSubscriptionWithAvaxOptions,
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
    <div className="flex flex-col">
            <h1 className="py-4 px-4 font-bold text-2xl">Activate Subsctriptions</h1>
                <div className="flex flex-wrap">
                    {isWeb3Enabled && chainId ? (
                        inactiveSubscriptionsLoading   ? (
                            <div>Loading...</div>
                        ) : (
                          <table className="min-w-full divide-y divide-gray-200">
                          <thead className="bg-gray-50">
                            <tr>
                              <th scope="col" className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                                Admin Address
                              </th>
                              <th scope="col" className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                                Payment Interval
                              </th>
                              <th scope="col" className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                                Price
                              </th>
                              <th scope="col" className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                                Duration
                              </th>
                              <th scope="col" className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                                Make USD Payment
                              </th>
                              <th scope="col" className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                                Make AVAX Payment
                              </th>

                              
            
                              {/* Add more headers for other data fields */}
                            </tr>
                          </thead>
                          <tbody className="bg-white divide-y divide-gray-200">
                            {console.log(inactiveSubscriptions)}
                            {inactiveSubscriptions.inactiveSubscriptions.map((inactiveSubscription) => (
                              <tr key={inactiveSubscription.id}>
                                <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                                  {inactiveSubscription.admin}
                                </td>
                                <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                                  {inactiveSubscription.paymentInterval}
                                </td>
                                <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                                  {inactiveSubscription.price}
                                </td>
                                <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                                  {inactiveSubscription.duration}
                                </td>

                                <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                                  <button className="text-xl border-blue-800 bg-blue-400 text-white rounded p-2" /*onClick={TODO}*/>Activate With USD</button>
                                </td>
                                <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                                  <button className="text-xl border-blue-800 bg-blue-400 text-white rounded p-2" onClick={() => activateWithAvax(inactiveSubscription)}>Activate with Avax</button>
                                </td>

                              </tr>
                            ))}
                          </tbody>
                        </table>
                        )
                    ) : (
                        <div>Web3 Currently Not Enabled</div>
                    )}
                </div>
    </div>
  )
}










/*<div className={styles.container} style={{ paddingBottom: '200px' }}>
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
    </div>*/