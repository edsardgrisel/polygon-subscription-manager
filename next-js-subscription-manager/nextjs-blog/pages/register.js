import styles from '../styles/Home.module.css';
import { Form} from "web3uikit"


export default function Home() {

    async function registerUser(data) {
        console.log("Approving...")
        const name = data.data[0].inputResult
        const emailAddress = data.data[1].inputResult
        const price = ethers.utils.parseUnits(data.data[2].inputResult, "ether").toString()




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
                        type: "number",
                        value: "",
                        key: "emailAddress",
                    },
                ]}
                title="Register for Subscyption"
                id="Main Form"
            />
        </div>
  )
}