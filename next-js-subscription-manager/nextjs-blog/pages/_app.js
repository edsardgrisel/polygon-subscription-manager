import { MoralisProvider } from "react-moralis"
import { NotificationProvider } from "web3uikit"
import "../styles/global.css"
import Header from "../components/Header"
import Head from "next/head"
import { ApolloProvider, ApolloClient, InMemoryCache } from "@apollo/client"
import { Source } from "graphql"

const client = new ApolloClient({
    uri: process.env.NEXT_PUBLIC_SUBGRAPH_URL,
    cache: new InMemoryCache(),
})

function MyApp({ Component, pageProps }) {
    return (
        <div>
            <Head>
                <title>Subscryption</title>
                <meta name="description" content="Generated by create next app" />
                <link rel="icon" href="/favicon.ico" />
            </Head>

            <MoralisProvider initializeOnMount={false}>
                <ApolloProvider client={client}>
                    <NotificationProvider>
                        <Header />
                        <div className="bg-blue-100">
                            <Component  {...pageProps} />
                        </div>
                    </NotificationProvider>
                </ApolloProvider>
            </MoralisProvider>
        </div>
    )
}

export default MyApp
