// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract GoldFaucet is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;
    
    IERC20 public immutable GOLD;
    
    uint256 public claimAmount = 10_000 * 1e18;
    uint256 public cooldownTime = 24 hours;
    
    mapping(address => uint256) public lastClaimed;
    mapping(address => uint256) public totalClaimed;
    
    event Claimed(address indexed user, uint256 amount);
    event Deposited(address indexed depositor, uint256 amount);
    event ClaimAmountUpdated(uint256 oldAmount, uint256 newAmount);
    event CooldownUpdated(uint256 oldCooldown, uint256 newCooldown);
    event Withdrawn(address indexed to, uint256 amount);
    
    constructor(address _gold) Ownable(msg.sender) {
        GOLD = IERC20(_gold);
    }
    
    function claim() external nonReentrant {
        require(canClaim(msg.sender), "Cooldown active");
        require(getBalance() >= claimAmount, "Faucet empty");
        
        lastClaimed[msg.sender] = block.timestamp;
        totalClaimed[msg.sender] += claimAmount;
        
        GOLD.safeTransfer(msg.sender, claimAmount);
        emit Claimed(msg.sender, claimAmount);
    }
    
    function canClaim(address user) public view returns (bool) {
        if (lastClaimed[user] == 0) return true;
        return block.timestamp >= lastClaimed[user] + cooldownTime;
    }
    
    function timeUntilNextClaim(address user) external view returns (uint256) {
        if (canClaim(user)) return 0;
        return (lastClaimed[user] + cooldownTime) - block.timestamp;
    }
    
    function getBalance() public view returns (uint256) {
        return GOLD.balanceOf(address(this));
    }
    
    function deposit(uint256 amount) external {
        GOLD.safeTransferFrom(msg.sender, address(this), amount);
        emit Deposited(msg.sender, amount);
    }
    
    function setClaimAmount(uint256 newAmount) external onlyOwner {
        emit ClaimAmountUpdated(claimAmount, newAmount);
        claimAmount = newAmount;
    }
    
    function setCooldownTime(uint256 newCooldown) external onlyOwner {
        emit CooldownUpdated(cooldownTime, newCooldown);
        cooldownTime = newCooldown;
    }
    
    function withdraw(uint256 amount) external onlyOwner {
        GOLD.safeTransfer(msg.sender, amount);
        emit Withdrawn(msg.sender, amount);
    }
    
    function withdrawAll() external onlyOwner {
        uint256 balance = getBalance();
        GOLD.safeTransfer(msg.sender, balance);
        emit Withdrawn(msg.sender, balance);
    }
}
