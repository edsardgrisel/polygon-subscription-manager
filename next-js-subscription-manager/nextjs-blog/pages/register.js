import styles from '../styles/Home.module.css';
import { useRouter } from 'next/router';
import { Button, Form, useNotification} from "web3uikit"
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

    async function registerUser(data) {
        console.log("Registering...")
  
        const name = data.data[0].inputResult
        const emailAddress = data.data[1].inputResult

        // @todo Do backend stuff
  
        const registerUserOptions = {
            abi: subscriptionManagerAbi,
            contractAddress: subscriptionManagerAddress,
            functionName: "registerUser",
            params: {
                user: account
            }
        }
  
        await runContractFunction({
            params: registerUserOptions,
            onSuccess: () => handleRegisterUserSuccess(),
            onError: (error) => {
                console.log(error)
            },
        
        })
  
      }
    
      const handleRegisterUserSuccess = () => {
          dispatch({
              type: "success",
              message: "Registered User",
              position: "topR",
          })
  
      }

      ///////////////////////////

      async function unregisterUser(data) {
        console.log("Unregistering User...")
        // @todo Do backend stuff
  
        const registerUserOptions = {
            abi: subscriptionManagerAbi,
            contractAddress: subscriptionManagerAddress,
            functionName: "unregisterUser",
            params: {
                user: account
            }
        }
  
        await runContractFunction({
            params: registerUserOptions,
            onSuccess: () => handleUnregisterUserSuccess(),
            onError: (error) => {
                console.log(error)
            },
        
        })
      }
    
      const handleUnregisterUserSuccess = () => {
          dispatch({
              type: "success",
              message: "Unregistered User",
              position: "topR",
          })
  
      }
     
  return (
    <div className={styles.container} style={{ paddingBottom: '300px' }}>
            <Form
                onSubmit={registerUser}
                data={[
                    {
                        name: "Name",
                        type: "text",
                        value: "",
                        key: "name",
                    },
                    {
                        name: "Email Address",
                        type: "email",
                        value: "",
                        key: "emailAddress",
                    },
                ]}
                title="Register for Subscyption"
                id="Main Form"
            />
            <Button onClick={unregisterUser} text="Unregister" />
                
        </div>
  )
}