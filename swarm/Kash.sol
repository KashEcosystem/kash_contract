// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {ERC20Burnable} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title Kash Token
 * @dev Token tối ưu hóa với các tính năng: Blacklist, Trading Toggle và Transaction Limits.
 */
contract Kash is ERC20, ERC20Burnable, Ownable {
    // Các lỗi tùy chỉnh giúp tiết kiệm Gas hơn so với dùng require + string
    error TradingClosed(); 
    error Blacklisted(); 
    error TxLimitExceeded(); 
    error WalletLimitExceeded(); 
    error LimitsAlreadyDisabled();

    // Các biến trạng thái được tối ưu hóa
    uint256 public constant MAX_SUPPLY = 52_000_000 * 10**18;
    uint256 public maxLimit = 104_000 * 10**18; // 0.2% của tổng cung
    bool public tradingOpen = false;
    bool public limitsActive = true;

    mapping(address => bool) public blacklisted;
    mapping(address => bool) public excluded;

    constructor() ERC20("Kash", "KASH") Ownable(msg.sender) {
        excluded[msg.sender] = true;
        excluded[address(this)] = true;
        _mint(msg.sender, MAX_SUPPLY);
    }

    // Các hàm quản trị cho chủ sở hữu
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
        if(!limitsActive) revert LimitsAlreadyDisabled();
        maxLimit = amount * 10**18;
    }

    /**
     * @dev Ghi đè hàm _update theo tiêu chuẩn OpenZeppelin v5.0.
     * Đây là nơi thực hiện các kiểm tra bảo mật cho mỗi giao dịch.
     */
    function _update(address from, address to, uint256 amount) internal override {
        // 1. Luôn cho phép các địa chỉ được loại trừ (Owner, Contract chính) hoặc các thao tác Mint/Burn
        if (from == address(0) || to == address(0) || excluded[from] || excluded[to]) {
            super._update(from, to, amount);
            return;
        }

        // 2. Kiểm tra trạng thái giao dịch
        if (!tradingOpen) revert TradingClosed();
        if (blacklisted[from] || blacklisted[to]) revert Blacklisted();

        // 3. Kiểm tra các giới hạn nếu đang kích hoạt
        if (limitsActive) {
            if (amount > maxLimit) revert TxLimitExceeded();
            if (balanceOf(to) + amount > maxLimit) revert WalletLimitExceeded();
        }
        
        super._update(from, to, amount);
    }
}