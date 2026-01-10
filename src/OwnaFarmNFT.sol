// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract OwnaFarmNFT is ERC1155, AccessControl, ReentrancyGuard {
    using SafeERC20 for IERC20;
    
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    
    struct Invoice {
        string offtaker;
        uint128 targetFund;
        uint128 fundedAmount;
        uint16 yieldBps;
        uint32 duration;
        uint32 createdAt;
        bool active;
    }
    
    struct Investment {
        uint128 amount;
        uint32 tokenId;
        uint32 investedAt;
        bool claimed;
    }
    
    IERC20 public immutable GOLD;
    uint32 public nextTokenId = 1;
    
    mapping(uint256 => Invoice) public invoices;
    mapping(address => Investment[]) private _investments;
    
    event InvoiceCreated(uint256 indexed tokenId, string offtaker, uint256 target, uint16 yieldBps);
    event Invested(address indexed investor, uint256 indexed tokenId, uint256 amount);
    event Harvested(address indexed investor, uint256 indexed investmentId, uint256 principal, uint256 yield);
    
    constructor(address _gold) ERC1155("") {
        GOLD = IERC20(_gold);
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ADMIN_ROLE, msg.sender);
    }
    
    function createInvoice(
        string calldata offtaker,
        uint128 targetFund,
        uint16 yieldBps,
        uint32 duration
    ) external onlyRole(ADMIN_ROLE) returns (uint256 tokenId) {
        tokenId = nextTokenId++;
        invoices[tokenId] = Invoice({
            offtaker: offtaker,
            targetFund: targetFund,
            fundedAmount: 0,
            yieldBps: yieldBps,
            duration: duration,
            createdAt: uint32(block.timestamp),
            active: true
        });
        emit InvoiceCreated(tokenId, offtaker, targetFund, yieldBps);
    }
    
    function invest(uint256 tokenId, uint128 amount) external nonReentrant {
        Invoice storage inv = invoices[tokenId];
        require(inv.active, "Inactive");
        require(inv.fundedAmount + amount <= inv.targetFund, "Exceeds target");
        
        GOLD.safeTransferFrom(msg.sender, address(this), amount);
        inv.fundedAmount += amount;
        
        _mint(msg.sender, tokenId, amount, "");
        
        _investments[msg.sender].push(Investment({
            amount: amount,
            tokenId: uint32(tokenId),
            investedAt: uint32(block.timestamp),
            claimed: false
        }));
        
        emit Invested(msg.sender, tokenId, amount);
    }
    
    function harvest(uint256 investmentIdx) external nonReentrant {
        Investment storage investment = _investments[msg.sender][investmentIdx];
        require(!investment.claimed, "Already claimed");
        
        Invoice storage inv = invoices[investment.tokenId];
        require(block.timestamp >= investment.investedAt + inv.duration, "Not mature");
        
        investment.claimed = true;
        
        uint256 yieldAmount = (uint256(investment.amount) * inv.yieldBps) / 10000;
        uint256 total = investment.amount + yieldAmount;
        
        _burn(msg.sender, investment.tokenId, investment.amount);
        GOLD.safeTransfer(msg.sender, total);
        
        emit Harvested(msg.sender, investmentIdx, investment.amount, yieldAmount);
    }
    
    function getInvestments(address investor) external view returns (Investment[] memory) {
        return _investments[investor];
    }
    
    function getInvestmentCount(address investor) external view returns (uint256) {
        return _investments[investor].length;
    }
    
    function getAvailableInvoices() external view returns (uint256[] memory tokenIds, Invoice[] memory data) {
        uint256 count;
        for (uint256 i = 1; i < nextTokenId; i++) {
            if (invoices[i].active && invoices[i].fundedAmount < invoices[i].targetFund) count++;
        }
        
        tokenIds = new uint256[](count);
        data = new Invoice[](count);
        uint256 idx;
        
        for (uint256 i = 1; i < nextTokenId; i++) {
            if (invoices[i].active && invoices[i].fundedAmount < invoices[i].targetFund) {
                tokenIds[idx] = i;
                data[idx] = invoices[i];
                idx++;
            }
        }
    }
    
    function deactivateInvoice(uint256 tokenId) external onlyRole(ADMIN_ROLE) {
        invoices[tokenId].active = false;
    }
    
    function supportsInterface(bytes4 interfaceId) public view override(ERC1155, AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
    
    function setTokenURI(string calldata newUri) external onlyRole(ADMIN_ROLE) {
        _setURI(newUri);
    }
}
