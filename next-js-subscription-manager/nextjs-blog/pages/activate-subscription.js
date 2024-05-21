import styles from '../styles/Home.module.css';
import { Form} from "web3uikit"
import { useRouter } from 'next/router';


export default function Home() {
    const router = useRouter();
    const { address } = router.query;

    async function activateSubscription(data) {
        console.log("Approving...")
        const address = data.data[0].inputResult

    }

    // http://localhost:3000/activate-subscription?address=0x00 
    // can give user a custom url in email to activate subscription

  return (
    <div className={styles.container} style={{ paddingBottom: '200px' }}>
      <Form 
          onSubmit={activateSubscription}
          data={[
              {
                  name: "Admin wallet address(Avalanche Fuji)",
                  type: "text",
                  value: address || "",
                  key: "address",
              },
              
          ]}
          title="Activate Subscription"
          id="Main Form"
      />
    </div>
  )
}