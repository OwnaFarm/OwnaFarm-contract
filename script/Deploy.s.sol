// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script, console} from "forge-std/Script.sol";
import {GoldToken} from "../src/GoldToken.sol";
import {GoldFaucet} from "../src/GoldFaucet.sol";
import {OwnaFarmNFT} from "../src/OwnaFarmNFT.sol";
import {OwnaFarmVault} from "../src/OwnaFarmVault.sol";

contract DeployOwnaFarm is Script {
    uint256 public constant FAUCET_DEPOSIT = 1_000_000 * 1e18;
    uint256 public constant FARM_YIELD_RESERVE = 500_000 * 1e18;
    
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        vm.startBroadcast(deployerPrivateKey);
        
        GoldToken gold = new GoldToken();
        console.log("GoldToken:", address(gold));
        
        GoldFaucet faucet = new GoldFaucet(address(gold));
        console.log("GoldFaucet:", address(faucet));
        
        OwnaFarmNFT farm = new OwnaFarmNFT(address(gold));
        console.log("OwnaFarmNFT:", address(farm));
        
        OwnaFarmVault vault = new OwnaFarmVault(address(gold));
        vault.setFarmNFT(address(farm));
        console.log("OwnaFarmVault:", address(vault));
        
        gold.approve(address(faucet), FAUCET_DEPOSIT);
        faucet.deposit(FAUCET_DEPOSIT);
        console.log("Faucet funded:", FAUCET_DEPOSIT / 1e18, "GOLD");
        
        gold.transfer(address(farm), FARM_YIELD_RESERVE);
        console.log("Farm yield reserve:", FARM_YIELD_RESERVE / 1e18, "GOLD");
        
        vm.stopBroadcast();
        
        console.log("\n=== DEPLOYMENT COMPLETE ===");
        console.log("Network: Mantle Sepolia");
        console.log("Chain ID: 5003");
    }
}
