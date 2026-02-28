// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test, console} from "forge-std/Test.sol";
import {AutoYieldVault} from "../src/AutoYieldVault.sol";
import {MockAsterEarn} from "../src/mocks/MockAsterEarn.sol";
import {MockERC20} from "../src/mocks/MockERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract AutoYieldVaultTest is Test {
    AutoYieldVault vault;
    MockAsterEarn asterEarn;
    MockERC20 asset;

    address user1 = address(0x1);
    address user2 = address(0x2);
    address harvester = address(0x3);

    function setUp() public {
        asset = new MockERC20("USDT", "USDT", 18);
        asset.mint(address(this), 1_000_000e18);
        asterEarn = new MockAsterEarn(address(asset));
        vault = new AutoYieldVault(IERC20(address(asset)), address(asterEarn), address(0));

        asset.approve(address(vault), type(uint256).max);
        asset.mint(address(asterEarn), 1_000_000e18);
    }

    function test_Deposit_MintsShares() public {
        uint256 amount = 1000e18;
        uint256 shares = vault.deposit(amount, user1);
        assertGt(shares, 0);
        assertEq(vault.balanceOf(user1), shares);
        assertEq(vault.totalAssets(), amount);
        assertEq(asterEarn.balanceOf(address(vault)), amount);
    }

    function test_Deposit_DeploysToAsterEarn() public {
        vault.deposit(1000e18, user1);
        assertEq(asterEarn.balanceOf(address(vault)), 1000e18);
    }

    function test_TotalAssets_IncludesDeployed() public {
        vault.deposit(500e18, user1);
        assertEq(vault.totalAssets(), 500e18);
    }

    function test_Withdraw_ReturnsAssets() public {
        vault.deposit(1000e18, user1);
        uint256 before = asset.balanceOf(user1);
        vm.prank(user1);
        vault.withdraw(500e18, user1, user1);
        assertEq(asset.balanceOf(user1) - before, 500e18);
        assertEq(vault.totalAssets(), 500e18);
    }

    function test_Harvest_CompoundsRewards() public {
        vault.deposit(1000e18, user1);
        asterEarn.setPendingRewards(address(vault), 100e18);
        asset.transfer(address(asterEarn), 100e18);
        vm.warp(block.timestamp + 1 hours + 1);
        vault.harvest();
        assertEq(asterEarn.balanceOf(address(vault)), 1000e18 + 99e18); // 99.9% compounded
    }

    function test_Harvest_PaysCallerFee() public {
        vault.deposit(1000e18, user1);
        asterEarn.setPendingRewards(address(vault), 100e18);
        asset.transfer(address(asterEarn), 100e18);
        vm.warp(block.timestamp + 1 hours + 1);
        uint256 before = asset.balanceOf(harvester);
        vm.prank(harvester);
        vault.harvest();
        assertEq(asset.balanceOf(harvester) - before, 0.1e18); // 0.1%
    }

    function test_Harvest_RevertsOnCooldown() public {
        vault.deposit(1000e18, user1);
        vm.warp(block.timestamp + 1 hours + 1);
        vault.harvest();
        vm.expectRevert(AutoYieldVault.HarvestCooldown.selector);
        vault.harvest();
    }

    function test_Harvest_IncreasesSharePrice() public {
        vault.deposit(1000e18, user1);
        uint256 priceBefore = vault.sharePrice();
        asterEarn.setPendingRewards(address(vault), 100e18);
        asset.transfer(address(asterEarn), 100e18);
        vm.warp(block.timestamp + 1 hours + 1);
        vault.harvest();
        assertGt(vault.sharePrice(), priceBefore);
    }

    function test_HarvestReady_ReturnsFalseBeforeCooldown() public {
        vault.deposit(100e18, user1);
        vm.warp(block.timestamp + 30 minutes);
        assertFalse(vault.harvestReady());
    }

    function test_HarvestReady_ReturnsTrueAfterCooldown() public {
        vault.deposit(100e18, user1);
        vm.warp(block.timestamp + 1 hours + 1);
        assertTrue(vault.harvestReady());
    }

    function test_MultiUser_ProportionalYield() public {
        vm.startPrank(user1);
        asset.mint(user1, 10000e18);
        asset.approve(address(vault), type(uint256).max);
        vault.deposit(1000e18, user1);
        vm.stopPrank();
        vm.startPrank(user2);
        asset.mint(user2, 10000e18);
        asset.approve(address(vault), type(uint256).max);
        vault.deposit(1000e18, user2);
        vm.stopPrank();
        asterEarn.setPendingRewards(address(vault), 100e18);
        asset.transfer(address(asterEarn), 100e18);
        vm.warp(block.timestamp + 1 hours + 1);
        vault.harvest();
        uint256 share1 = vault.balanceOf(user1);
        uint256 share2 = vault.balanceOf(user2);
        assertEq(share1, share2);
        uint256 assets1 = vault.convertToAssets(share1);
        uint256 assets2 = vault.convertToAssets(share2);
        assertEq(assets1, assets2);
    }

    function testFuzz_Deposit_Withdraw(uint256 depositAmount) public {
        depositAmount = bound(depositAmount, 1e18, 100_000e18);
        vault.deposit(depositAmount, user1);
        uint256 shares = vault.balanceOf(user1);
        vm.prank(user1);
        vault.withdraw(depositAmount, user1, user1);
        assertEq(vault.balanceOf(user1), 0);
        assertEq(asset.balanceOf(user1), depositAmount);
    }
}
