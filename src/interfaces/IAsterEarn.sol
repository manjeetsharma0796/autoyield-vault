// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/**
 * @title IAsterEarn
 * @notice Minimal interface for AsterDEX Earn (or compatible yield vault) on BNB Chain.
 *        Used as the primary yield source for AutoYield Vault.
 */
interface IAsterEarn {
    /// @notice Deposit underlying asset (e.g. USDT) and accrue yield.
    /// @param amount Amount of asset to deposit.
    function deposit(uint256 amount) external;

    /// @notice Withdraw underlying asset.
    /// @param amount Amount of asset to withdraw.
    function withdraw(uint256 amount) external;

    /// @notice Current balance of this contract's deposits in the earn vault (in asset terms).
    /// @return Balance in underlying asset (same decimals as asset).
    function balanceOf(address account) external view returns (uint256);

    /// @notice Pending rewards harvestable (in underlying asset terms).
    /// @return Amount of rewards that can be harvested.
    function pendingRewards(address account) external view returns (uint256);

    /// @notice Underlying asset (e.g. USDT).
    function asset() external view returns (address);
}
