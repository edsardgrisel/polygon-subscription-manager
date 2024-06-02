import styles from '../styles/Home.module.css';
import { useRouter } from 'next/router';
import { Form, useNotification} from "web3uikit"
import { useState, useEffect } from 'react'
import { ethers } from "ethers"
import { useMoralis, useWeb3Contract } from "react-moralis"
import subscriptionManagerAbi from '../constants/subscriptionManagerAbi.json';
import networkMapping from "../constants/networkMapping.json"
import { useQuery } from "@apollo/client"
import { GET_ACTIVE_SUBSCRIPTIONS } from "../constants/subgraph-queries"



export default function Home() {
  const { chainId, account, isWeb3Enabled } = useMoralis()
  const chainString = chainId ? parseInt(chainId).toString() : "31337"
  const subscriptionManagerAddress = networkMapping[chainString].SubscriptionManager[0];
  const dispatch = useNotification()
  const { runContractFunction } = useWeb3Contract()

  


  const {
    loading: activeSubscriptionsLoading,
    error: activeSubscriptionsError,
    data: activeSubscriptions,
} = useQuery(GET_ACTIVE_SUBSCRIPTIONS, {variables: {user: account}})

  async function makeAvaxPayment(subscription) {
    console.log("Proccessing AVAX Payment...")


    const makeAvaxPaymentOptions = {
        abi: subscriptionManagerAbi,
        contractAddress: subscriptionManagerAddress,
        functionName: "makePaymentWithEth",
        params: {
            admin: subscription.admin,
        },
        msgValue: ethers.utils.parseEther("0.03")
    }

    await runContractFunction({
        params: makeAvaxPaymentOptions,
        onSuccess: () => handleMakeAvaxPaymentOptions(),
        onError: (error) => {
            console.log(error)
        },
    
    })

  }
  
    const handleMakeAvaxPaymentOptions = () => {
        dispatch({
            type: "success",
            message: "AVAX Payment Successful",
            position: "topR",
        })

    }







  
  // useEffect(() => {
  //   const fetchData = async () => {
  //     const data = [
  //       {
  //         id: 1,
  //         adminAddress: "0x00",
  //         paymentInterval: 0,
  //         price: 0,
  //         duration: 0,
  //         nextPaymentDeadline: 0,
  //       },
  //       {
  //         id: 2,
  //         adminAddress: "0x00",
  //         paymentInterval: 0,
  //         price: 0,
  //         duration: 0,
  //         nextPaymentDeadline: 0,
  //       },
  //       // Add more objects as needed
  //     ];
  //     setSubscriptions(data);
  //   };

  //   fetchData();
  // }, [account, isWeb3Enabled, chainId]);



  return (
    <div className="flex flex-col">
            <h1 className="py-4 px-4 font-bold text-2xl">Active Subsctriptions</h1>
                <div className="flex flex-wrap">
                    {isWeb3Enabled && chainId ? (
                        activeSubscriptionsLoading && !activeSubscriptions   ? (
                            <div>Loading...</div>
                        ) : (
                          <table className="min-w-full divide-y divide-gray-200">
                          <thead className="bg-gray-50">
                            <tr>
                              <th scope="col" className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                                Admin Address
                              </th>

                              <th scope="col" className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                                Price USD
                              </th>
                              <th scope="col" className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                                Next Payment Deadline
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
                            {console.log(activeSubscriptions)}
                            {activeSubscriptions.activeSubscriptions.map((activeSubscription) => (
                              <tr key={activeSubscription.id}>
                                <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                                  {activeSubscription.admin}
                                </td>

                                <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                                  {ethers.utils.formatUnits(activeSubscription.price).toString()} USD
                                </td>
                                <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                                  {activeSubscription.nextPaymentTime}
                                </td>

                                <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                                  <button className="text-xl border-blue-800 bg-blue-400 text-white rounded p-2" /*onClick={TODO}*/>Pay With USD</button>
                                </td>
                                <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                                  <button className="text-xl border-blue-800 bg-blue-400 text-white rounded p-2" onClick={() => makeAvaxPayment(activeSubscription)}>Pay with Avax</button>
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
  );
}