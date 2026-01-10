// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {ERC20Burnable} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ERC20Permit} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";

contract GoldToken is ERC20, ERC20Burnable, Ownable, ERC20Permit {
    uint256 public constant INITIAL_SUPPLY = 100_000_000 * 1e18;
    
    event Minted(address indexed to, uint256 amount);
    
    constructor() ERC20("OwnaFarm Gold", "GOLD") Ownable(msg.sender) ERC20Permit("OwnaFarm Gold") {
        _mint(msg.sender, INITIAL_SUPPLY);
    }
    
    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
        emit Minted(to, amount);
    }
}
