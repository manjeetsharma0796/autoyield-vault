# Run everything on BNB Testnet

## 1. Install Foundry (if not already)

```bash
# Windows (PowerShell)
irm getfoundry.sh | iex

# Or see https://book.getfoundry.sh/getting-started/installation
```

## 2. Environment

```bash
cp .env.example .env
```

Edit `.env`:

- `PRIVATE_KEY` — your testnet wallet private key (with testnet BNB for gas)
- `BNB_TESTNET_RPC_URL` — e.g. `https://data-seed-prebsc-1-s1.binance.org:8545/`

## 3. Build and test

```bash
cd C:\workspace\bnb\autoyield-vault
forge build
forge test -vvv
```

## 4. Deploy to BNB Testnet

```bash
forge script script/DeployTestnet.s.sol:DeployTestnet \
  --rpc-url $env:BNB_TESTNET_RPC_URL \
  --broadcast \
  -vvvv
```

On Windows PowerShell use `$env:BNB_TESTNET_RPC_URL`; on bash use `$BNB_TESTNET_RPC_URL`.

Copy the printed **AutoYieldVault** address.

## 5. Configure frontend

```bash
cd frontend
cp .env.example .env
```

Edit `frontend/.env`:

- `VITE_VAULT_ADDRESS` = the vault address from step 4
- `VITE_ASSET_ADDRESS` = `0x337610d27c682E347C9cD60BD4b3b107C9d34dDd` (testnet USDT)

## 6. Run frontend

```bash
cd frontend
npm install
npm run dev
```

Open http://localhost:5173. In MetaMask switch to **BNB Smart Chain Testnet** (chainId 97), then connect and use Deposit / Withdraw / Harvest.

## 7. Get testnet USDT

Use a [BNB testnet faucet](https://www.bnbchain.org/en/testnet-faucet) to get testnet BNB and testnet USDT (or the testnet USDT contract’s faucet if available). Approve the vault for USDT, then deposit.

## 8. Test harvest (optional)

On testnet, yield is simulated via the mock:

1. Send some testnet USDT to the **MockAsterEarn** contract address (printed in step 4).
2. Call `setPendingRewards(vaultAddress, amount)` on the MockAsterEarn contract (e.g. via BSCScan testnet).
3. Wait 1 hour or use a script that warps time (tests only). Then call `harvest()` on the vault (from the UI or RunCycle script).

## 9. Run harvest from CLI (optional)

```bash
# In root .env set VAULT_ADDRESS to your deployed vault
forge script script/RunCycle.s.sol:RunCycleHarvest \
  --rpc-url $env:BNB_TESTNET_RPC_URL \
  --broadcast \
  -vvvv
```
