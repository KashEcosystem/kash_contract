// SPDX-License-Identifier: MIT
// Contract Kcash - Chuẩn Ethereum Mainnet L1
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Kcash is ERC20, Ownable {
    
    // Khởi tạo token với tên "Kcash" và ký hiệu "KASH" (bạn có thể sửa ký hiệu trong ngoặc kép nếu muốn)
    constructor() ERC20("Kcash", "KASH") Ownable(msg.sender) {
        // In ngay 52 triệu token về ví chủ sở hữu một lần duy nhất để tiết kiệm gas
        _mint(msg.sender, 52000000 * 10 ** decimals());
    }
}