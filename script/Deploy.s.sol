// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script, console} from "forge-std/Script.sol";
import {GoldToken} from "../src/GoldToken.sol";
import {GoldFaucet} from "../src/GoldFaucet.sol";
import {OwnaFarmNFT} from "../src/OwnaFarmNFT.sol";
import {OwnaFarmVault} from "../src/OwnaFarmVault.sol";

contract DeployOwnaFarm is Script {
    uint256 public constant FAUCET_INITIAL_DEPOSIT = 1_000_000 * 1e18;
    
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        vm.startBroadcast(deployerPrivateKey);
        
        // 1. Deploy GoldToken (deployer gets 100M GOLD)
        GoldToken gold = new GoldToken();
        console.log("GoldToken deployed:", address(gold));
        
        // 2. Deploy Faucet
        GoldFaucet faucet = new GoldFaucet(address(gold));
        console.log("GoldFaucet deployed:", address(faucet));
        
        // 3. Fund faucet with 1M GOLD
        gold.approve(address(faucet), FAUCET_INITIAL_DEPOSIT);
        faucet.deposit(FAUCET_INITIAL_DEPOSIT);
        console.log("Faucet funded with:", FAUCET_INITIAL_DEPOSIT / 1e18, "GOLD");
        
        // 4. Deploy OwnaFarmNFT
        OwnaFarmNFT farm = new OwnaFarmNFT(address(gold));
        console.log("OwnaFarmNFT deployed:", address(farm));
        
        // 5. Deploy Vault
        OwnaFarmVault vault = new OwnaFarmVault(address(gold));
        vault.setFarmNFT(address(farm));
        console.log("OwnaFarmVault deployed:", address(vault));
        
        vm.stopBroadcast();
        
        console.log("\n========== DEPLOYMENT COMPLETE ==========");
        console.log("Network: Mantle Sepolia (Chain ID: 5003)");
        console.log("RPC: https://rpc.sepolia.mantle.xyz");
        console.log("Explorer: https://sepolia.mantlescan.xyz");
        console.log("\n--- Contract Addresses ---");
        console.log("GoldToken:     ", address(gold));
        console.log("GoldFaucet:    ", address(faucet));
        console.log("OwnaFarmNFT:   ", address(farm));
        console.log("OwnaFarmVault: ", address(vault));
        console.log("\n--- Faucet Info ---");
        console.log("Claim Amount: 10,000 GOLD per claim");
        console.log("Cooldown: 24 hours");
        console.log("==========================================");
    }
}
