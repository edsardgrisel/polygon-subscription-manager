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

  
  const [subscriptions, setSubscriptions] = useState([]);




  async function makeAvaxPayment(subscription) {
    console.log("Proccessing AVAX Payment...")


    const makeAvaxPaymentOptions = {
        abi: subscriptionManagerAbi,
        contractAddress: subscriptionManagerAddress,
        functionName: "makePaymentWithEth",
        params: {
            admin: subscription.adminAddress,
        },
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







  
  useEffect(() => {
    const fetchData = async () => {
      const data = [
        {
          id: 1,
          adminAddress: "0x00",
          paymentInterval: 0,
          price: 0,
          duration: 0,
          nextPaymentDeadline: 0,
        },
        {
          id: 2,
          adminAddress: "0x00",
          paymentInterval: 0,
          price: 0,
          duration: 0,
          nextPaymentDeadline: 0,
        },
        // Add more objects as needed
      ];
      setSubscriptions(data);
    };

    fetchData();
  }, [account, isWeb3Enabled, chainId]);



  return (
    <div className="flex flex-col">
      <div className="-my-2 overflow-x-auto sm:-mx-6 lg:-mx-8">
        <div className="py-2 align-middle inline-block min-w-full sm:px-6 lg:px-8">
          <div className="shadow overflow-hidden border-b border-gray-200 sm:rounded-lg">
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
                    Next Payment Deadline
                  </th>
                  <th scope="col" className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Make USD Payment
                  </th>
                  <th scope="col" className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Make AVAX Payment
                  </th>
                  <th scope="col" className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Cancel Subscription
                  </th>
                  

                  {/* Add more headers for other data fields */}
                </tr>
              </thead>
              <tbody className="bg-white divide-y divide-gray-200">
                {subscriptions.map((subscription) => (
                  <tr key={subscription.id}>
                    <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                      {subscription.adminAddress}
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                      {subscription.paymentInterval}
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                      {subscription.price}
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                      {subscription.duration}
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                      {subscription.nextPaymentDeadline}
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                      <button className="text-xl border-blue-800 bg-blue-400 text-white rounded p-2" /*onClick={TODO}*/>Make Usd Payment</button>
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                      <button className="text-xl border-blue-800 bg-blue-400 text-white rounded p-2" onClick={() => makeAvaxPayment(subscription)}>Make AVAX Payment</button>
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                      <button className="text-xl border-blue-800 bg-blue-400 text-white rounded p-2">Cancel Subscription</button>
                    </td>
                    {/* Add more cells for other data fields */}
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>
      </div>
    </div>
  );
}