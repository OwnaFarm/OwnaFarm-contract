// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract OwnaFarmVault is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;
    
    IERC20 public immutable GOLD;
    address public farmNFT;
    
    uint256 public totalYieldReserve;
    
    event YieldDeposited(uint256 amount);
    event YieldWithdrawn(address indexed to, uint256 amount);
    event FarmNFTSet(address indexed farmNFT);
    
    constructor(address _gold) Ownable(msg.sender) {
        GOLD = IERC20(_gold);
    }
    
    function setFarmNFT(address _farmNFT) external onlyOwner {
        farmNFT = _farmNFT;
        emit FarmNFTSet(_farmNFT);
    }
    
    function depositYield(uint256 amount) external onlyOwner {
        GOLD.safeTransferFrom(msg.sender, address(this), amount);
        totalYieldReserve += amount;
        emit YieldDeposited(amount);
    }
    
    function withdrawYield(address to, uint256 amount) external nonReentrant {
        require(msg.sender == farmNFT, "Only FarmNFT");
        require(amount <= totalYieldReserve, "Insufficient reserve");
        totalYieldReserve -= amount;
        GOLD.safeTransfer(to, amount);
        emit YieldWithdrawn(to, amount);
    }
    
    function getYieldReserve() external view returns (uint256) {
        return totalYieldReserve;
    }
    
    function emergencyWithdraw(address token, uint256 amount) external onlyOwner {
        IERC20(token).safeTransfer(msg.sender, amount);
    }
}
