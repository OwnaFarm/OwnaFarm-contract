// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {GoldToken} from "../src/GoldToken.sol";
import {GoldFaucet} from "../src/GoldFaucet.sol";
import {OwnaFarmNFT} from "../src/OwnaFarmNFT.sol";
import {OwnaFarmVault} from "../src/OwnaFarmVault.sol";

contract OwnaFarmTest is Test {
    GoldToken gold;
    GoldFaucet faucet;
    OwnaFarmNFT farm;
    OwnaFarmVault vault;
    
    address admin = address(1);
    address investor1 = address(2);
    address investor2 = address(3);
    
    uint256 constant CLAIM_AMOUNT = 10_000 * 1e18;
    
    function setUp() public {
        vm.startPrank(admin);
        
        gold = new GoldToken();
        faucet = new GoldFaucet(address(gold));
        farm = new OwnaFarmNFT(address(gold));
        vault = new OwnaFarmVault(address(gold));
        vault.setFarmNFT(address(farm));
        
        // Fund faucet
        gold.approve(address(faucet), 1_000_000 * 1e18);
        faucet.deposit(1_000_000 * 1e18);
        
        // Fund farm contract for yield payments
        gold.transfer(address(farm), 100_000 * 1e18);
        
        vm.stopPrank();
    }
    
    // ============ FAUCET TESTS ============
    
    function test_FaucetClaim() public {
        vm.prank(investor1);
        faucet.claim();
        assertEq(gold.balanceOf(investor1), CLAIM_AMOUNT);
    }
    
    function test_FaucetCannotClaimTwice() public {
        vm.startPrank(investor1);
        faucet.claim();
        
        vm.expectRevert("Cooldown active");
        faucet.claim();
        vm.stopPrank();
    }
    
    function test_FaucetClaimAfterCooldown() public {
        vm.startPrank(investor1);
        faucet.claim();
        
        // Fast forward 24 hours
        vm.warp(block.timestamp + 24 hours + 1);
        
        faucet.claim();
        assertEq(gold.balanceOf(investor1), CLAIM_AMOUNT * 2);
        vm.stopPrank();
    }
    
    function test_FaucetTimeUntilNextClaim() public {
        vm.prank(investor1);
        faucet.claim();
        
        uint256 timeLeft = faucet.timeUntilNextClaim(investor1);
        assertGt(timeLeft, 0);
        assertLe(timeLeft, 24 hours);
    }
    
    // ============ GOLD TOKEN TESTS ============
    
    function test_GoldInitialSupply() public view {
        assertEq(gold.balanceOf(admin), gold.INITIAL_SUPPLY() - 1_100_000 * 1e18);
    }
    
    function test_GoldMintOnlyOwner() public {
        vm.prank(investor1);
        vm.expectRevert();
        gold.mint(investor1, 1000e18);
    }
    
    // ============ INVOICE TESTS ============
    
    function test_CreateInvoice() public {
        vm.prank(admin);
        uint256 tokenId = farm.createInvoice("PT Indofood", 50_000e18, 1800, 30 days);
        
        (string memory offtaker, uint128 target,, uint16 yieldBps,,,) = farm.invoices(tokenId);
        assertEq(offtaker, "PT Indofood");
        assertEq(target, 50_000e18);
        assertEq(yieldBps, 1800);
    }
    
    function test_Invest() public {
        vm.prank(admin);
        uint256 tokenId = farm.createInvoice("PT Mayora", 50_000e18, 1500, 30 days);
        
        // Investor claims from faucet and invests
        vm.startPrank(investor1);
        faucet.claim();
        gold.approve(address(farm), CLAIM_AMOUNT);
        farm.invest(tokenId, uint128(CLAIM_AMOUNT));
        
        assertEq(farm.balanceOf(investor1, tokenId), CLAIM_AMOUNT);
        assertEq(farm.getInvestmentCount(investor1), 1);
        vm.stopPrank();
    }
    
    function test_MultipleInvestors() public {
        vm.prank(admin);
        uint256 tokenId = farm.createInvoice("PT ABC", 20_000e18, 1000, 30 days);
        
        // Investor 1
        vm.startPrank(investor1);
        faucet.claim();
        gold.approve(address(farm), CLAIM_AMOUNT);
        farm.invest(tokenId, uint128(CLAIM_AMOUNT));
        vm.stopPrank();
        
        // Investor 2
        vm.startPrank(investor2);
        faucet.claim();
        gold.approve(address(farm), CLAIM_AMOUNT);
        farm.invest(tokenId, uint128(CLAIM_AMOUNT));
        vm.stopPrank();
        
        (,, uint128 funded,,,,) = farm.invoices(tokenId);
        assertEq(funded, CLAIM_AMOUNT * 2);
    }
    
    function test_Harvest() public {
        vm.prank(admin);
        uint256 tokenId = farm.createInvoice("PT ABC", 50_000e18, 1000, 1 days);
        
        vm.startPrank(investor1);
        faucet.claim();
        gold.approve(address(farm), CLAIM_AMOUNT);
        farm.invest(tokenId, uint128(CLAIM_AMOUNT));
        vm.stopPrank();
        
        // Fast forward past maturity
        vm.warp(block.timestamp + 2 days);
        
        vm.prank(investor1);
        farm.harvest(0);
        
        // 10,000 GOLD + 10% yield = 11,000 GOLD
        uint256 expectedBalance = CLAIM_AMOUNT + (CLAIM_AMOUNT * 1000 / 10000);
        assertEq(gold.balanceOf(investor1), expectedBalance);
    }
    
    function test_GetAvailableInvoices() public {
        vm.startPrank(admin);
        farm.createInvoice("Company A", 10_000e18, 1000, 30 days);
        farm.createInvoice("Company B", 20_000e18, 1500, 60 days);
        farm.createInvoice("Company C", 30_000e18, 2000, 90 days);
        vm.stopPrank();
        
        (uint256[] memory ids,) = farm.getAvailableInvoices();
        assertEq(ids.length, 3);
    }
    
    function test_DeactivateInvoice() public {
        vm.startPrank(admin);
        uint256 tokenId = farm.createInvoice("PT Test", 10_000e18, 1000, 30 days);
        farm.deactivateInvoice(tokenId);
        vm.stopPrank();
        
        (,,,,,,bool active) = farm.invoices(tokenId);
        assertFalse(active);
    }
    
    // ============ REVERT TESTS ============
    
    function test_RevertWhen_InvestExceedsTarget() public {
        vm.prank(admin);
        uint256 tokenId = farm.createInvoice("PT Test", 5_000e18, 1000, 30 days);
        
        vm.startPrank(investor1);
        faucet.claim();
        gold.approve(address(farm), CLAIM_AMOUNT);
        
        vm.expectRevert("Exceeds target");
        farm.invest(tokenId, uint128(CLAIM_AMOUNT));
        vm.stopPrank();
    }
    
    function test_RevertWhen_HarvestBeforeMaturity() public {
        vm.prank(admin);
        uint256 tokenId = farm.createInvoice("PT Test", 50_000e18, 1000, 30 days);
        
        vm.startPrank(investor1);
        faucet.claim();
        gold.approve(address(farm), CLAIM_AMOUNT);
        farm.invest(tokenId, uint128(CLAIM_AMOUNT));
        
        vm.expectRevert("Not mature");
        farm.harvest(0);
        vm.stopPrank();
    }
    
    function test_RevertWhen_InvestInactiveInvoice() public {
        vm.startPrank(admin);
        uint256 tokenId = farm.createInvoice("PT Test", 50_000e18, 1000, 30 days);
        farm.deactivateInvoice(tokenId);
        vm.stopPrank();
        
        vm.startPrank(investor1);
        faucet.claim();
        gold.approve(address(farm), CLAIM_AMOUNT);
        
        vm.expectRevert("Inactive");
        farm.invest(tokenId, uint128(CLAIM_AMOUNT));
        vm.stopPrank();
    }
    
    function test_RevertWhen_DoubleHarvest() public {
        vm.prank(admin);
        uint256 tokenId = farm.createInvoice("PT ABC", 50_000e18, 1000, 1 days);
        
        vm.startPrank(investor1);
        faucet.claim();
        gold.approve(address(farm), CLAIM_AMOUNT);
        farm.invest(tokenId, uint128(CLAIM_AMOUNT));
        vm.stopPrank();
        
        vm.warp(block.timestamp + 2 days);
        
        vm.startPrank(investor1);
        farm.harvest(0);
        
        vm.expectRevert("Already claimed");
        farm.harvest(0);
        vm.stopPrank();
    }
}
