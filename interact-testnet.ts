import {
  makeContractCall,
  makeContractDeploy,
  broadcastTransaction,
  AnchorMode,
  PostConditionMode,
  standardPrincipalCV,
  uintCV,
  boolCV,
  stringAsciiCV,
  contractPrincipalCV,
  callReadOnlyFunction,
  cvToJSON,
  hexToCV,
} from "@stacks/transactions";
import { StacksTestnet } from "@stacks/network";
import { createStacksPrivateKey, getAddressFromPrivateKey, TransactionVersion } from "@stacks/transactions";

// Network configuration
const network = new StacksTestnet();

// Wallet configuration
const mnemonic = "vivid scan vessel favorite output fortune winner pact congress away solution emerge rubber column van mechanic size judge walnut flee shallow raccoon unfold hotel";
const privateKey = createStacksPrivateKey(mnemonic);
const senderAddress = getAddressFromPrivateKey(privateKey.data, TransactionVersion.Testnet);

// Contract details
const contractAddress = "ST2GG7HZZHEB3JHQFXHKD65HZXVRRNV6AYTS2VGMS";
const contractName = "savings-pool";

console.log("Deployer Address:", senderAddress);
console.log("Contract Address:", contractAddress);
console.log("Contract Name:", contractName);

// Helper function to broadcast transaction
async function broadcastTx(transaction: any) {
  try {
    const result = await broadcastTransaction(transaction, network);
    console.log("Transaction broadcasted:", result);
    return result;
  } catch (error) {
    console.error("Error broadcasting transaction:", error);
    throw error;
  }
}

// Helper function to call read-only functions
async function callReadOnly(functionName: string, functionArgs: any[] = []) {
  try {
    const result = await callReadOnlyFunction({
      contractAddress,
      contractName,
      functionName,
      functionArgs,
      network,
      senderAddress,
    });
    
    console.log(`\n=== ${functionName} ===`);
    console.log("Raw result:", result);
    console.log("JSON result:", cvToJSON(result));
    return result;
  } catch (error) {
    console.error(`Error calling ${functionName}:`, error);
    throw error;
  }
}

// Helper function to make contract calls
async function makeCall(functionName: string, functionArgs: any[] = [], fee = 10000) {
  try {
    const transaction = await makeContractCall({
      contractAddress,
      contractName,
      functionName,
      functionArgs,
      senderKey: privateKey.data,
      network,
      anchorMode: AnchorMode.Any,
      fee,
      postConditionMode: PostConditionMode.Allow,
    });

    console.log(`\n=== Calling ${functionName} ===`);
    const result = await broadcastTx(transaction);
    return result;
  } catch (error) {
    console.error(`Error calling ${functionName}:`, error);
    throw error;
  }
}

// Main interaction functions
async function initializePool() {
  console.log("\n🚀 Initializing savings pool...");
  return await makeCall("initialize-pool");
}

async function getPoolStats() {
  console.log("\n📊 Getting pool statistics...");
  return await callReadOnly("get-pool-stats");
}

async function getContractInfo() {
  console.log("\n📋 Getting contract information...");
  return await callReadOnly("get-contract-info");
}

async function isPoolEnabled() {
  console.log("\n✅ Checking if pool is enabled...");
  return await callReadOnly("is-pool-enabled");
}

async function deposit(amount: number) {
  console.log(`\n💰 Depositing ${amount} microSTX...`);
  return await makeCall("deposit", [uintCV(amount)], 15000);
}

async function withdraw(amount: number) {
  console.log(`\n💸 Withdrawing ${amount} microSTX...`);
  return await makeCall("withdraw", [uintCV(amount)], 15000);
}

async function claimInterest() {
  console.log("\n🎁 Claiming interest...");
  return await makeCall("claim-interest", [], 15000);
}

async function getUserDeposit(userAddress: string) {
  console.log(`\n👤 Getting user deposit for ${userAddress}...`);
  return await callReadOnly("get-user-deposit", [standardPrincipalCV(userAddress)]);
}

async function getUserBalance(userAddress: string) {
  console.log(`\n💳 Getting user balance for ${userAddress}...`);
  return await callReadOnly("get-user-balance", [standardPrincipalCV(userAddress)]);
}

async function calculateInterest(userAddress: string) {
  console.log(`\n📈 Calculating interest for ${userAddress}...`);
  return await callReadOnly("calculate-interest", [standardPrincipalCV(userAddress)]);
}

async function getUserHistory(userAddress: string) {
  console.log(`\n📜 Getting user history for ${userAddress}...`);
  return await callReadOnly("get-user-history", [standardPrincipalCV(userAddress)]);
}

async function calculatePotentialInterest(amount: number, blocks: number) {
  console.log(`\n🔮 Calculating potential interest for ${amount} microSTX over ${blocks} blocks...`);
  return await callReadOnly("calculate-potential-interest", [uintCV(amount), uintCV(blocks)]);
}

// Demo function
async function runDemo() {
  try {
    console.log("🎯 Starting Savings Pool Demo");
    console.log("================================");

    // 1. Get contract info
    await getContractInfo();
    
    // 2. Check if pool is enabled
    await isPoolEnabled();
    
    // 3. Get initial pool stats
    await getPoolStats();
    
    // 4. Initialize pool (if needed)
    await initializePool();
    
    // 5. Get pool stats after initialization
    await getPoolStats();
    
    // 6. Check user balance before deposit
    await getUserBalance(senderAddress);
    
    // 7. Make a deposit (5 STX = 5,000,000 microSTX)
    await deposit(5000000);
    
    // Wait a bit for transaction to confirm
    console.log("\n⏳ Waiting for transaction to confirm...");
    await new Promise(resolve => setTimeout(resolve, 30000));
    
    // 8. Check user deposit after deposit
    await getUserDeposit(senderAddress);
    
    // 9. Check user balance after deposit
    await getUserBalance(senderAddress);
    
    // 10. Get updated pool stats
    await getPoolStats();
    
    // 11. Calculate current interest
    await calculateInterest(senderAddress);
    
    // 12. Calculate potential interest for different scenarios
    await calculatePotentialInterest(10000000, 1000); // 10 STX for 1000 blocks
    
    // 13. Get user history
    await getUserHistory(senderAddress);
    
    console.log("\n✅ Demo completed successfully!");
    
  } catch (error) {
    console.error("❌ Demo failed:", error);
  }
}

// Export functions for individual use
export {
  initializePool,
  getPoolStats,
  getContractInfo,
  isPoolEnabled,
  deposit,
  withdraw,
  claimInterest,
  getUserDeposit,
  getUserBalance,
  calculateInterest,
  getUserHistory,
  calculatePotentialInterest,
  runDemo,
};

// Run demo if this file is executed directly
if (require.main === module) {
  runDemo();
}
