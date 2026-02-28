// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IAsterEarn} from "../interfaces/IAsterEarn.sol";

/**
 * @title MockAsterEarn
 * @notice Mock for tests. Tracks deposited balance and simulates yield via setPendingRewards.
 */
contract MockAsterEarn is IAsterEarn {
    using SafeERC20 for IERC20;

    IERC20 public override asset;
    mapping(address => uint256) private _balance;
    mapping(address => uint256) public pendingRewardOf;

    constructor(address _asset) {
        asset = IERC20(_asset);
    }

    function setPendingRewards(address account, uint256 amount) external {
        pendingRewardOf[account] = amount;
    }

    function deposit(uint256 amount) external override {
        asset.safeTransferFrom(msg.sender, address(this), amount);
        _balance[msg.sender] += amount;
    }

    function withdraw(uint256 amount) external override {
        require(_balance[msg.sender] >= amount, "insufficient");
        _balance[msg.sender] -= amount;
        asset.safeTransfer(msg.sender, amount);
    }

    function balanceOf(address account) external view override returns (uint256) {
        return _balance[account];
    }

    function pendingRewards(address account) external view override returns (uint256) {
        return pendingRewardOf[account];
    }

    /// @notice Mock: sends pending rewards to caller (vault) so harvest can use them.
    function claimRewards() external {
        uint256 p = pendingRewardOf[msg.sender];
        if (p > 0) {
            pendingRewardOf[msg.sender] = 0;
            require(asset.balanceOf(address(this)) >= p, "mock: fund me");
            asset.safeTransfer(msg.sender, p);
        }
    }

    /// @notice Tests: fund mock with asset so claimRewards can send.
    function fund(uint256 amount) external {
        asset.safeTransferFrom(msg.sender, address(this), amount);
    }
}
