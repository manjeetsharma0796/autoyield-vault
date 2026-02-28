// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script, console} from "forge-std/Script.sol";
import {AutoYieldVault} from "../src/AutoYieldVault.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract DeployAutoYieldVault is Script {
    // ─────────────────────────────────────────────
    //  BNB Chain Mainnet Addresses
    // ─────────────────────────────────────────────
    address constant USDT_BNB_MAINNET = 0x55d398326f99059fF775485246999027B3197955;
    address constant ASTER_EARN_BNB_MAINNET = 0x2F31ab8950c50080E77999fa456372f276952fD8;

    // ─────────────────────────────────────────────
    //  BNB Chain Testnet Addresses
    // ─────────────────────────────────────────────
    address constant USDT_BNB_TESTNET = 0x337610d27c682E347C9cD60BD4b3b107C9d34dDd;
    address constant ASTER_EARN_BNB_TESTNET = 0x0000000000000000000000000000000000000000; // replace with testnet deploy

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        // Detect chain
        uint256 chainId = block.chainid;
        address usdt;
        address asterEarn;

        if (chainId == 56) {
            // BNB Chain Mainnet
            usdt = USDT_BNB_MAINNET;
            asterEarn = ASTER_EARN_BNB_MAINNET;
            console.log("Deploying to BNB Chain Mainnet...");
        } else if (chainId == 97) {
            // BNB Chain Testnet
            usdt = USDT_BNB_TESTNET;
            asterEarn = ASTER_EARN_BNB_TESTNET;
            console.log("Deploying to BNB Chain Testnet...");
        } else {
            revert("Unsupported chain. Use BNB Mainnet (56) or Testnet (97).");
        }

        console.log("Deployer:", deployer);
        console.log("USDT:", usdt);
        console.log("AsterEarn:", asterEarn);

        vm.startBroadcast(deployerPrivateKey);

        AutoYieldVault vault = new AutoYieldVault(
            IERC20(usdt),
            asterEarn,
            address(0) // no stack receiver; 100% to AsterDEX
        );

        vm.stopBroadcast();

        console.log("--------------------------------------------------");
        console.log("AutoYieldVault deployed at:", address(vault));
        console.log("Share token name:", vault.name());
        console.log("Share token symbol:", vault.symbol());
        console.log("Underlying asset:", vault.asset());
        console.log("AsterEarn:", address(vault.asterEarn()));
        console.log("--------------------------------------------------");
        console.log("Next: verify on BSCScan with:");
        console.log("forge verify-contract", address(vault), "src/AutoYieldVault.sol:AutoYieldVault");
    }
}