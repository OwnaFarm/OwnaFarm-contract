// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract GoldFaucet is AccessControl, ReentrancyGuard {
    using SafeERC20 for IERC20;
    
    error CooldownActive();
    error FaucetEmpty();
    
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    
    IERC20 public immutable GOLD;
    uint256 public claimAmount = 10_000 * 1e18;
    uint256 public cooldownTime = 24 hours;
    
    mapping(address => uint256) public lastClaimed;
    mapping(address => uint256) public totalClaimed;
    
    event Claimed(address indexed user, uint256 amount);
    event Deposited(address indexed depositor, uint256 amount);
    event ClaimAmountUpdated(uint256 newAmount);
    event CooldownUpdated(uint256 newCooldown);
    event Withdrawn(address indexed to, uint256 amount);
    
    constructor(address gold_) {
        GOLD = IERC20(gold_);
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ADMIN_ROLE, msg.sender);
    }
    
    function claim() external nonReentrant {
        if (!canClaim(msg.sender)) revert CooldownActive();
        uint256 balance = GOLD.balanceOf(address(this));
        if (balance < claimAmount) revert FaucetEmpty();
        
        lastClaimed[msg.sender] = block.timestamp;
        unchecked { totalClaimed[msg.sender] += claimAmount; }
        
        GOLD.safeTransfer(msg.sender, claimAmount);
        emit Claimed(msg.sender, claimAmount);
    }
    
    function canClaim(address user) public view returns (bool) {
        uint256 last = lastClaimed[user];
        return last == 0 || block.timestamp >= last + cooldownTime;
    }
    
    function timeUntilNextClaim(address user) external view returns (uint256) {
        if (canClaim(user)) return 0;
        return (lastClaimed[user] + cooldownTime) - block.timestamp;
    }
    
    function deposit(uint256 amount) external {
        GOLD.safeTransferFrom(msg.sender, address(this), amount);
        emit Deposited(msg.sender, amount);
    }
    
    function setClaimAmount(uint256 newAmount) external onlyRole(ADMIN_ROLE) {
        claimAmount = newAmount;
        emit ClaimAmountUpdated(newAmount);
    }
    
    function setCooldownTime(uint256 newCooldown) external onlyRole(ADMIN_ROLE) {
        cooldownTime = newCooldown;
        emit CooldownUpdated(newCooldown);
    }
    
    function withdraw(uint256 amount) external onlyRole(ADMIN_ROLE) {
        GOLD.safeTransfer(msg.sender, amount);
        emit Withdrawn(msg.sender, amount);
    }

    function withdrawAll() external onlyRole(ADMIN_ROLE) {
        uint256 balance = GOLD.balanceOf(address(this));
        GOLD.safeTransfer(msg.sender, balance);
        emit Withdrawn(msg.sender, balance);
    }
}
