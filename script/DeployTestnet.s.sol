// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script, console} from "forge-std/Script.sol";
import {AutoYieldVault} from "../src/AutoYieldVault.sol";
import {MockAsterEarn} from "../src/mocks/MockAsterEarn.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title DeployTestnet
 * @notice Deploy MockAsterEarn + AutoYieldVault on BNB Testnet (chainId 97).
 *         AsterDEX Earn is mainnet-only; testnet uses this mock for demo.
 *         After deploy: fund the mock with testnet USDT and set pending rewards so harvest() works.
 */
contract DeployTestnet is Script {
    address constant USDT_BNB_TESTNET = 0x337610d27c682E347C9cD60BD4b3b107C9d34dDd;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        require(block.chainid == 97, "Use BNB Testnet (chainId 97)");

        console.log("Deploying to BNB Chain Testnet (97)...");
        console.log("Deployer:", deployer);
        console.log("USDT:", USDT_BNB_TESTNET);

        vm.startBroadcast(deployerPrivateKey);

        MockAsterEarn mockEarn = new MockAsterEarn(USDT_BNB_TESTNET);
        AutoYieldVault vault = new AutoYieldVault(
            IERC20(USDT_BNB_TESTNET),
            address(mockEarn),
            address(0)
        );

        vm.stopBroadcast();

        console.log("--------------------------------------------------");
        console.log("MockAsterEarn deployed at:", address(mockEarn));
        console.log("AutoYieldVault deployed at:", address(vault));
        console.log("--------------------------------------------------");
        console.log("Next steps:");
        console.log("1. Set in frontend .env: VITE_VAULT_ADDRESS=%s", address(vault));
        console.log("2. Set in root .env: VAULT_ADDRESS=%s", address(vault));
        console.log("3. Get testnet USDT from faucet, approve vault, deposit.");
        console.log("4. To test harvest: send USDT to MockAsterEarn, call setPendingRewards(vault, amount), then harvest().");
    }
}
