// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";

contract GoldToken is ERC20, ERC20Burnable, Ownable, ERC20Permit {
    using SafeERC20 for IERC20;
    
    uint256 public constant INITIAL_SUPPLY = 100_000_000 * 1e18;
    
    event Minted(address indexed to, uint256 amount);
    
    constructor() 
        ERC20("OwnaFarm Gold", "GOLD") 
        Ownable(msg.sender) 
        ERC20Permit("OwnaFarm Gold") 
    {
        _mint(msg.sender, INITIAL_SUPPLY);
    }
    
    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
        emit Minted(to, amount);
    }
}
