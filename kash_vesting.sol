// SPDX-License-Identifier: MIT
pragma solidity ^0.8.33;

// SỬA 1: Dùng ngoặc nhọn {} để Remix không báo lỗi nhập toàn cục
import {VestingWallet} from "@openzeppelin/contracts/finance/VestingWallet.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract KashVestingWallet is VestingWallet {
    constructor(
        address beneficiary,
        uint64 startTimestamp,
        uint64 durationSeconds
    ) VestingWallet(beneficiary, startTimestamp, durationSeconds) {}
}

contract KashVestingFactory is Ownable {

    struct VestingInfo {
        address walletAddress;
        address beneficiary;
        string category; 
    }

    VestingInfo[] public deployedVestings;

    event VestingCreated(address indexed wallet, address indexed beneficiary, string category);

    // SỬA 2: Khai báo lỗi ngắn gọn (Custom Error) giúp tiết kiệm Gas và tắt cảnh báo chuỗi dài
    error InvalidAddress();

    constructor() Ownable(msg.sender) {}

    function createVesting(
        address beneficiary,
        uint64 startTimestamp,
        uint64 durationSeconds,
        string memory category
    ) public onlyOwner returns (address) {
        // SỬA 3: Dùng if + revert thay vì require
        if (beneficiary == address(0)) {
            revert InvalidAddress();
        }

        KashVestingWallet newVesting = new KashVestingWallet(
            beneficiary,
            startTimestamp,
            durationSeconds
        );

        deployedVestings.push(VestingInfo({
            walletAddress: address(newVesting),
            beneficiary: beneficiary,
            category: category
        }));

        emit VestingCreated(address(newVesting), beneficiary, category);
        return address(newVesting);
    }

    function getVestingCount() public view returns (uint256) {
        return deployedVestings.length;
    }

    // LƯU Ý: Nếu Remix vẫn báo "Gas vô hạn" ở hàm này thì BỎ QUA.
    // Vì đây là hàm xem (View), không mất tiền thật nên không sao cả.
    function getVestingInfo(uint256 index) public view returns (VestingInfo memory) {
        return deployedVestings[index];
    }
}