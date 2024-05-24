import styles from '../styles/Home.module.css';
import { Form, useNotification, Button } from "web3uikit"
import Link from "next/link"

export default function Home() {
  return (
    <div className="text-center">
      <div>
        <h1 className="text-4xl leading-8 p-4"> 
          We help  make subscriptions cheaper and easier
        </h1>
      </div>
      <div className="flex justify-center">
        <Link href="/register">
          <button href="/register" className="text-xl border-blue-800 bg-blue-400 text-white rounded p-2">Sign Up Now</button>
        </Link>
      </div>
      <div className="text-center">
        <h2 className='text-2xl p-4'>About Subscryption</h2>
        <p>Subscyption is a decentralized application (dApp) designed to streamline subscription management and payments for both service providers and their customers. Utilizing the robust capabilities of the Avalanche network, our platform allows businesses to effortlessly manage subscription plans, view detailed analytics, and handle payments on-chain. Subscribers, in turn, can easily manage their subscriptions, make payments, and stay informed about their payment schedules.</p>
        <p>One of the key advantages of using Avalanche is the significantly lower transaction fees compared to traditional payment processors. By leveraging the Avalanche network, Subscyption ensures that both businesses and subscribers benefit from reduced costs, enhancing the overall efficiency and affordability of managing and maintaining subscriptions. </p>
      </div>
    </div>
  );
}
