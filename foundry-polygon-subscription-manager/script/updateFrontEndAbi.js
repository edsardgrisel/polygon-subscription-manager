const fs = require('fs');

// Read the contract output file
const contractOutput = fs.readFileSync('./out/SubscriptionManager.sol/SubscriptionManager.json', 'utf8');

// Parse the JSON
const contractJson = JSON.parse(contractOutput);

// Get the ABI
const abi = contractJson.abi;

// Write the ABI to a file
fs.writeFileSync('../next-js-subscription-manager/nextjs-blog/constants/subscription-manager-abi.json.json', JSON.stringify(abi, null, 2));