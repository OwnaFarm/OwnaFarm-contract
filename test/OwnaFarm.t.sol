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
    address farmer1 = address(4);
    address farmer2 = address(5);
    address investor1 = address(2);
    address investor2 = address(3);
    
    uint256 constant CLAIM_AMOUNT = 10_000 * 1e18;
    bytes32 constant OFFTAKER_A = keccak256("PT Indofood");
    bytes32 constant OFFTAKER_B = keccak256("PT Mayora");
    
    function setUp() public {
        vm.startPrank(admin);
        
        gold = new GoldToken();
        faucet = new GoldFaucet(address(gold));
        farm = new OwnaFarmNFT(address(gold));
        vault = new OwnaFarmVault(address(gold));
        vault.setFarmNFT(address(farm));
        
        gold.approve(address(faucet), 1_000_000 * 1e18);
        faucet.deposit(1_000_000 * 1e18);
        gold.transfer(address(farm), 100_000 * 1e18);
        
        vm.stopPrank();
    }
    
    // ============ INVOICE SUBMISSION FLOW ============
    
    function test_FarmerCanSubmitInvoice() public {
        vm.prank(farmer1);
        uint256 tokenId = farm.submitInvoice(OFFTAKER_A, 50_000e18, 1800, 30 days);
        
        assertEq(tokenId, 1);
        assertEq(farm.getPendingCount(), 1);
        
        (address farmer,,,,,,, bytes32 offtakerId) = farm.invoices(tokenId);
        assertEq(farmer, farmer1);
        assertEq(offtakerId, OFFTAKER_A);
    }
    
    function test_MultipleFarmersCanSubmit() public {
        vm.prank(farmer1);
        farm.submitInvoice(OFFTAKER_A, 50_000e18, 1800, 30 days);
        
        vm.prank(farmer2);
        farm.submitInvoice(OFFTAKER_B, 30_000e18, 1500, 60 days);
        
        assertEq(farm.getPendingCount(), 2);
    }
    
    // ============ ADMIN APPROVAL FLOW ============
    
    function test_AdminCanApproveInvoice() public {
        vm.prank(farmer1);
        uint256 tokenId = farm.submitInvoice(OFFTAKER_A, 50_000e18, 1800, 30 days);
        
        assertEq(farm.getPendingCount(), 1);
        assertEq(farm.getAvailableCount(), 0);
        
        vm.prank(admin);
        farm.approveInvoice(tokenId);
        
        assertEq(farm.getPendingCount(), 0);
        assertEq(farm.getAvailableCount(), 1);
    }
    
    function test_AdminCanRejectInvoice() public {
        vm.prank(farmer1);
        uint256 tokenId = farm.submitInvoice(OFFTAKER_A, 50_000e18, 1800, 30 days);
        
        vm.prank(admin);
        farm.rejectInvoice(tokenId);
        
        assertEq(farm.getPendingCount(), 0);
        assertEq(farm.getAvailableCount(), 0);
    }
    
    function test_RevertWhen_NonAdminApproves() public {
        vm.prank(farmer1);
        uint256 tokenId = farm.submitInvoice(OFFTAKER_A, 50_000e18, 1800, 30 days);
        
        vm.prank(investor1);
        vm.expectRevert();
        farm.approveInvoice(tokenId);
    }
    
    // ============ INVESTMENT FLOW ============
    
    function test_InvestorCanInvestInApprovedInvoice() public {
        vm.prank(farmer1);
        uint256 tokenId = farm.submitInvoice(OFFTAKER_A, 50_000e18, 1500, 30 days);
        
        vm.prank(admin);
        farm.approveInvoice(tokenId);
        
        vm.startPrank(investor1);
        faucet.claim();
        gold.approve(address(farm), CLAIM_AMOUNT);
        farm.invest(tokenId, uint128(CLAIM_AMOUNT));
        
        assertEq(farm.balanceOf(investor1, tokenId), 1);
        assertEq(farm.investmentCount(investor1), 1);
        vm.stopPrank();
    }
    
    function test_RevertWhen_InvestInPendingInvoice() public {
        vm.prank(farmer1);
        uint256 tokenId = farm.submitInvoice(OFFTAKER_A, 50_000e18, 1500, 30 days);
        // NOT approved
        
        vm.startPrank(investor1);
        faucet.claim();
        gold.approve(address(farm), CLAIM_AMOUNT);
        vm.expectRevert(OwnaFarmNFT.InvoiceNotApproved.selector);
        farm.invest(tokenId, uint128(CLAIM_AMOUNT));
        vm.stopPrank();
    }
    
    function test_InvoiceRemovedWhenFullyFunded() public {
        vm.prank(farmer1);
        uint256 tokenId = farm.submitInvoice(OFFTAKER_A, uint128(CLAIM_AMOUNT), 1000, 30 days);
        
        vm.prank(admin);
        farm.approveInvoice(tokenId);
        assertEq(farm.getAvailableCount(), 1);
        
        vm.startPrank(investor1);
        faucet.claim();
        gold.approve(address(farm), CLAIM_AMOUNT);
        farm.invest(tokenId, uint128(CLAIM_AMOUNT));
        vm.stopPrank();
        
        assertEq(farm.getAvailableCount(), 0);
    }
    
    // ============ HARVEST FLOW ============
    
    function test_Harvest() public {
        vm.prank(farmer1);
        uint256 tokenId = farm.submitInvoice(OFFTAKER_A, 50_000e18, 1000, 1 days);
        
        vm.prank(admin);
        farm.approveInvoice(tokenId);
        
        vm.startPrank(investor1);
        faucet.claim();
        gold.approve(address(farm), CLAIM_AMOUNT);
        farm.invest(tokenId, uint128(CLAIM_AMOUNT));
        vm.stopPrank();
        
        vm.warp(block.timestamp + 2 days);
        
        vm.prank(investor1);
        farm.harvest(0);
        
        // 10,000 + 10% yield = 11,000
        uint256 expectedBalance = CLAIM_AMOUNT + (CLAIM_AMOUNT * 1000 / 10000);
        assertEq(gold.balanceOf(investor1), expectedBalance);
    }
    
    function test_RevertWhen_HarvestBeforeMaturity() public {
        vm.prank(farmer1);
        uint256 tokenId = farm.submitInvoice(OFFTAKER_A, 50_000e18, 1000, 30 days);
        
        vm.prank(admin);
        farm.approveInvoice(tokenId);
        
        vm.startPrank(investor1);
        faucet.claim();
        gold.approve(address(farm), CLAIM_AMOUNT);
        farm.invest(tokenId, uint128(CLAIM_AMOUNT));
        vm.expectRevert(OwnaFarmNFT.NotMature.selector);
        farm.harvest(0);
        vm.stopPrank();
    }
    
    function test_RevertWhen_DoubleHarvest() public {
        vm.prank(farmer1);
        uint256 tokenId = farm.submitInvoice(OFFTAKER_A, 50_000e18, 1000, 1 days);
        
        vm.prank(admin);
        farm.approveInvoice(tokenId);
        
        vm.startPrank(investor1);
        faucet.claim();
        gold.approve(address(farm), CLAIM_AMOUNT);
        farm.invest(tokenId, uint128(CLAIM_AMOUNT));
        vm.stopPrank();
        
        vm.warp(block.timestamp + 2 days);
        
        vm.startPrank(investor1);
        farm.harvest(0);
        vm.expectRevert(OwnaFarmNFT.AlreadyClaimed.selector);
        farm.harvest(0);
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
        vm.expectRevert(GoldFaucet.CooldownActive.selector);
        faucet.claim();
        vm.stopPrank();
    }
    
    // ============ PAGINATION TESTS ============
    
    function test_PendingPagination() public {
        vm.startPrank(farmer1);
        for (uint i; i < 5; i++) {
            farm.submitInvoice(bytes32(i), 10_000e18, 1000, 30 days);
        }
        vm.stopPrank();
        
        (uint256[] memory page1,) = farm.getPendingInvoices(0, 2);
        assertEq(page1.length, 2);
        
        (uint256[] memory page2,) = farm.getPendingInvoices(2, 2);
        assertEq(page2.length, 2);
    }
    
    function test_AvailablePagination() public {
        vm.startPrank(farmer1);
        for (uint i; i < 5; i++) {
            farm.submitInvoice(bytes32(i), 10_000e18, 1000, 30 days);
        }
        vm.stopPrank();
        
        vm.startPrank(admin);
        for (uint i = 1; i <= 5; i++) {
            farm.approveInvoice(i);
        }
        vm.stopPrank();
        
        (uint256[] memory page1,) = farm.getAvailableInvoices(0, 2);
        assertEq(page1.length, 2);
    }
    
    // ============ VAULT TESTS ============
    
    function test_VaultCannotSetFarmNFTTwice() public {
        vm.prank(admin);
        vm.expectRevert(OwnaFarmVault.FarmNFTAlreadySet.selector);
        vault.setFarmNFT(address(0x123));
    }
}
