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
 
  const dispatch = useNotification()
  const [usdBalance, setUsdBalance] = useState("0")
  const [avaxBalance, setAvaxBalance] = useState("0")

  const { runContractFunction } = useWeb3Contract()

  // withdraw USD //
  async function withdrawUsd(data) {
      console.log("Withdrawing USD...")
      const amountUsdToWithdraw = ethers.utils
          .parseUnits(data.data[0].inputResult, "ether")
          .toString()

      const withdrawUsdOptions = {
          abi: subscriptionManagerAbi,
          contractAddress: subscriptionManagerAddress,
          functionName: "withdrawOwnerUsdFeesEarnings",
          params: {
              amount: amountUsdToWithdraw,
          },
      }

      await runContractFunction({
          params: withdrawUsdOptions,
          onSuccess: () => handleWithdrawUsdSuccess(amountUsdToWithdraw),
          onError: (error) => {
              console.log(error)
          },
      })
  }

  const handleWithdrawUsdSuccess = (amountUsdToWithdraw) => {
      dispatch({
          type: "success",
          message: "Withdrawing " + ethers.utils.formatUnits(amountUsdToWithdraw) + " USDC. (Need to fix decimals)",
          position: "topR",
      })
  }

  // withdraw AVAX //
  async function withdrawAvax(data) {
    console.log("Withdrawing AVAX...")
    const amountAvaxToWithdraw = ethers.utils
        .parseUnits(data.data[0].inputResult, "ether")
        .toString()

    const withdrawAvaxOptions = {
        abi: subscriptionManagerAbi,
        contractAddress: subscriptionManagerAddress,
        functionName: "withdrawOwnerEthFeesEarnings",
        params: {
            amount: amountAvaxToWithdraw,
        },
    }
    console.log(amountAvaxToWithdraw);
    await runContractFunction({
        params: withdrawAvaxOptions,
        onSuccess: () => handleWithdrawAvaxSuccess(amountAvaxToWithdraw),
        onError: (error) => {
            console.log(error)
        },
    })
}

const handleWithdrawAvaxSuccess = (amountAvaxToWithdraw) => {
    dispatch({
        type: "success",
        message: "Withdrawing " + ethers.utils.formatUnits(amountAvaxToWithdraw) + " AVAX.",
        position: "topR",
    })
}  

  async function setupUI() {
    // get usd balance
      const returnedUsdProceeds = await runContractFunction({
          params: {
              abi: subscriptionManagerAbi,
              contractAddress: subscriptionManagerAddress,
              functionName: "getTotalUsdFeesEarnings",
              params: {
                  admin: account,
              },
          },
          onError: (usdError) => console.log(usdError),
      })
      if (returnedUsdProceeds) {
        console.log(returnedUsdProceeds);
        setUsdBalance(ethers.utils.formatUnits(returnedUsdProceeds, 6))
      }
      // get avax balance
      const returnedAvaxProceeds = await runContractFunction({
        params: {
            abi: subscriptionManagerAbi,
            contractAddress: subscriptionManagerAddress,
            functionName: "getTotalEthFeesEarnings",
            params: {
                admin: account,
            },
        },
        onError: (avaxError) => console.log(avaxError),
      })
      if (returnedAvaxProceeds) {
        setAvaxBalance(ethers.utils.formatUnits(returnedAvaxProceeds, "ether"))
      }
      if(usdBalance) console.log(usdBalance);
  }

  useEffect(() => {
      setupUI()
  }, [usdBalance, avaxBalance, account, isWeb3Enabled, chainId])



  return (
    <div style={{ paddingBottom: '200px' }}>
      <div className="flex">
      <div className="p-5">
          <h1 className="text-2xl leading-8 p-4"> 
            USD Earnings: {usdBalance}
          </h1>
          <Form 
            className='text-center'
            onSubmit={withdrawUsd}
            data={[
              {
                  name: "USD amount to withdraw",
                  type: "number",
                  value: 0,
                  key: "usdAmount",
              },
              
          ]}
            id="Main Form"
          />
        </div>
        <div className="p-5">
          <h1 className="text-2xl leading-8 p-4"> 
            Avax Earnings: {avaxBalance}
          </h1>
          <Form 
            className='text-center'
            onSubmit={withdrawAvax}
            data={[
              {
                  name: "AVAX amount to withdraw",
                  type: "number",
                  value: 0,
                  key: "usdAmount",
              },
              
          ]}
            id="Main Form"
          />
        </div>
      </div>
    </div>
  )
}