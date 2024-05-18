import { ConnectButton } from "web3uikit"
import Link from "next/link"
import { useEffect } from "react"

export default function Header() {
    return (
        <nav className="flex items-center justify-between p-4 bg-gray-200">
            <h1 className="text-2xl font-bold font-sans text-blue-800 border-r-2 pr-4">
            Subscryption
            </h1>
            <div class="border-l border-2 border-gray-300 h-16  "></div>
            <div className="flex items-center p-2  space-x-4 ml-4">
                <Link href="/">
                    <a className="font-sans mr-4 p-4 text-blue-800">Home</a>
                </Link>
                <Link href="/create-subscription">
                    <a className="font-sans mr-4 p-4 text-blue-800">Create Subscription</a>
                </Link>
                <Link href="/activate-subscription">
                    <a className="font-sans mr-4 p-4 text-blue-800">Activate Subscription</a>
                </Link>
                <Link href="/user-subscription-manager">
                    <a className="font-sans mr-4 p-4 text-blue-800">User Subscription Manager</a>
                </Link>
                <Link href="/admin-subscription-manager">
                    <a className="font-sans mr-4 p-4 text-blue-800">Admin Subscription Manager</a>
                </Link>
                <Link href="/admin-analytics">
                    <a className="font-sans mr-4 p-4 text-blue-800">Admin Analytics</a>
                </Link>
                <Link href="/owner-analytics">
                    <a className="font-sans mr-4 p-4 text-blue-800">Owner Analytics</a>
                </Link>

            </div>
            <ConnectButton moralisAuth={false} />
        </nav>
    )
}
