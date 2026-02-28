// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script, console} from "forge-std/Script.sol";

interface IAutoYieldVault {
    function harvest() external;
    function harvestReady() external view returns (bool);
    function pendingRewards() external view returns (uint256);
}

/**
 * @title RunCycleHarvest
 * @notice One-click script: call harvest() on the deployed vault.
 *         Use: VAULT_ADDRESS=0x... forge script script/RunCycle.s.sol:RunCycleHarvest --rpc-url $RPC --broadcast -vvvv
 */
contract RunCycleHarvest is Script {
    function run() external {
        address vaultAddr = vm.envAddress("VAULT_ADDRESS");
        IAutoYieldVault vault = IAutoYieldVault(vaultAddr);
        console.log("Vault:", vaultAddr);
        console.log("Harvest ready:", vault.harvestReady());
        console.log("Pending rewards:", vault.pendingRewards());
        uint256 pk = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(pk);
        vault.harvest();
        vm.stopBroadcast();
        console.log("Harvest tx broadcast.");
    }
}
