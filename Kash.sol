// SPDX-License-Identifier: MIT
pragma solidity 0.8.33;

// Sửa lỗi "Global Import" bằng cách chỉ định rõ thành phần cần dùng
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {ERC20Burnable} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract Kash is ERC20, ERC20Burnable, Ownable {
    // Custom errors
    error TradingClosed(); 
    error Blacklisted(); 
    error TxLimit(); 
    error WalletLimit(); 
    error LimitsGone();

    // Khai báo hằng số và biến trạng thái với visibility rõ ràng
    uint256 public constant MAX_SUPPLY = 52_000_000 ether;
    uint256 public maxLimit = 104_000 ether;
    
    bool public tradingOpen;
    bool public limitsActive = true;

    mapping(address => bool) public blacklisted;
    mapping(address => bool) public excluded;

    // Constructor đã được chuẩn hóa
    constructor() ERC20("Kash", "KASH") Ownable(msg.sender) {
        excluded[msg.sender] = true;
        excluded[address(this)] = true;
        _mint(msg.sender, MAX_SUPPLY);
    }

    // Các hàm external để tối ưu gas hơn public
    function startTrading() external onlyOwner {
        tradingOpen = true;
    }

    function removeLimits() external onlyOwner {
        limitsActive = false;
    }

    function setBlacklist(address acc, bool state) external onlyOwner {
        blacklisted[acc] = state;
    }

    function setExcluded(address acc, bool state) external onlyOwner {
        excluded[acc] = state;
    }
    
    function setMaxLimit(uint256 amount) external onlyOwner {
        if(!limitsActive) revert LimitsGone();
        maxLimit = amount * 1 ether;
    }

    /**
     * @dev Ghi đè hàm _update để kiểm tra logic giao dịch
     */
    function _update(address from, address to, uint256 val) internal override {
        // Miễn trừ cho Mint/Burn/Whitelist
        if (from == address(0) || to == address(0) || excluded[from] || excluded[to]) {
            super._update(from, to, val);
            return;
        }

        // Kiểm tra trạng thái giao dịch
        if (!tradingOpen) revert TradingClosed();
        if (blacklisted[from] || blacklisted[to]) revert Blacklisted();

        // Kiểm tra giới hạn (nếu còn hiệu lực)
        if (limitsActive) {
            uint256 _maxLimit = maxLimit; // Caching để tiết kiệm gas
            if (val > _maxLimit) revert TxLimit();
            
            unchecked {
                if (balanceOf(to) + val > _maxLimit) revert WalletLimit();
            }
        }
        
        super._update(from, to, val);
    }
}