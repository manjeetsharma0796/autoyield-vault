import { useState, useEffect, useCallback } from "react";
import { BrowserProvider, Contract, formatUnits, parseUnits } from "ethers";
import { VAULT_ABI, ERC20_ABI } from "./abis/Vault";
import {
  VAULT_ADDRESS,
  ASSET_ADDRESS,
  BNB_CHAIN_ID,
  BNB_TESTNET_CHAIN_ID,
  RPC_URLS,
} from "./config";

function App() {
  const [provider, setProvider] = useState<BrowserProvider | null>(null);
  const [account, setAccount] = useState<string | null>(null);
  const [chainId, setChainId] = useState<number | null>(null);
  const [tvl, setTvl] = useState<string>("0");
  const [sharePrice, setSharePrice] = useState<string>("0");
  const [userShares, setUserShares] = useState<string>("0");
  const [userAssets, setUserAssets] = useState<string>("0");
  const [userAssetBalance, setUserAssetBalance] = useState<string>("0");
  const [harvestReady, setHarvestReady] = useState(false);
  const [pendingRewards, setPendingRewards] = useState<string>("0");
  const [depositAmount, setDepositAmount] = useState("");
  const [withdrawAmount, setWithdrawAmount] = useState("");
  const [txPending, setTxPending] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const vaultAddress = VAULT_ADDRESS;
  const isSupported =
    chainId === BNB_CHAIN_ID || chainId === BNB_TESTNET_CHAIN_ID;

  const loadVaultData = useCallback(async () => {
    if (!provider || !vaultAddress) return;
    try {
      const vault = new Contract(vaultAddress, VAULT_ABI, provider);
      const assetAddr = await vault.asset();
      const asset = new Contract(assetAddr, ERC20_ABI, provider);
      const decimals = await asset.decimals();
      const [totalAssets, price, ready, pending] = await Promise.all([
        vault.totalAssets(),
        vault.sharePrice(),
        vault.harvestReady(),
        vault.pendingRewards(),
      ]);
      setTvl(formatUnits(totalAssets, decimals));
      setSharePrice(formatUnits(price, 18));
      setHarvestReady(ready);
      setPendingRewards(formatUnits(pending, decimals));
    } catch (e) {
      console.error("loadVaultData", e);
    }
  }, [provider, vaultAddress]);

  const loadUserData = useCallback(async () => {
    if (!provider || !account || !vaultAddress) return;
    try {
      const vault = new Contract(vaultAddress, VAULT_ABI, provider);
      const asset = new Contract(ASSET_ADDRESS, ERC20_ABI, provider);
      const [shares, assetDecimals] = await Promise.all([
        vault.balanceOf(account),
        asset.decimals(),
      ]);
      setUserShares(formatUnits(shares, 18));
      const assets = await vault.convertToAssets(shares);
      setUserAssets(formatUnits(assets, assetDecimals));
      const bal = await asset.balanceOf(account);
      setUserAssetBalance(formatUnits(bal, assetDecimals));
    } catch (e) {
      console.error("loadUserData", e);
    }
  }, [provider, account, vaultAddress]);

  useEffect(() => {
    loadVaultData();
    const t = setInterval(loadVaultData, 15000);
    return () => clearInterval(t);
  }, [loadVaultData]);

  useEffect(() => {
    loadUserData();
  }, [loadUserData]);

  const connect = async () => {
    setError(null);
    try {
      const w = (window as unknown as { ethereum?: { request: (a: unknown) => Promise<unknown> } }).ethereum;
      if (!w) {
        setError("MetaMask not found. Install MetaMask.");
        return;
      }
      const p = new BrowserProvider(w);
      const accounts = (await w.request({ method: "eth_requestAccounts" })) as string[];
      const network = await p.getNetwork();
      setProvider(p);
      setAccount(accounts[0] ?? null);
      setChainId(Number(network.chainId));
    } catch (e) {
      setError((e as Error).message);
    }
  };

  const switchToBNB = async () => {
    const w = (window as unknown as { ethereum?: { request: (a: unknown) => Promise<unknown> } }).ethereum;
    if (!w) return;
    const target = chainId === BNB_CHAIN_ID ? BNB_TESTNET_CHAIN_ID : BNB_CHAIN_ID;
    await w.request({
      method: "wallet_switchEthereumChain",
      params: [{ chainId: `0x${target.toString(16)}` }],
    });
    setChainId(target);
  };

  const deposit = async () => {
    if (!provider || !account || !vaultAddress || !depositAmount) return;
    setError(null);
    setTxPending(true);
    try {
      const signer = await provider.getSigner();
      const asset = new Contract(ASSET_ADDRESS, ERC20_ABI, signer);
      const vault = new Contract(vaultAddress, VAULT_ABI, signer);
      const decimals = await asset.decimals();
      const amount = parseUnits(depositAmount, decimals);
      const allowance = await asset.allowance(account, vaultAddress);
      if (allowance < amount) {
        const txApprove = await asset.approve(vaultAddress, amount);
        await txApprove.wait();
      }
      const tx = await vault.deposit(amount, account);
      await tx.wait();
      setDepositAmount("");
      await loadVaultData();
      await loadUserData();
    } catch (e) {
      setError((e as Error).message);
    } finally {
      setTxPending(false);
    }
  };

  const withdraw = async () => {
    if (!provider || !account || !vaultAddress || !withdrawAmount) return;
    setError(null);
    setTxPending(true);
    try {
      const signer = await provider.getSigner();
      const asset = new Contract(ASSET_ADDRESS, ERC20_ABI, signer);
      const vault = new Contract(vaultAddress, VAULT_ABI, signer);
      const decimals = await asset.decimals();
      const amount = parseUnits(withdrawAmount, decimals);
      const tx = await vault.withdraw(amount, account, account);
      await tx.wait();
      setWithdrawAmount("");
      await loadVaultData();
      await loadUserData();
    } catch (e) {
      setError((e as Error).message);
    } finally {
      setTxPending(false);
    }
  };

  const harvest = async () => {
    if (!provider || !vaultAddress || !harvestReady) return;
    setError(null);
    setTxPending(true);
    try {
      const signer = await provider.getSigner();
      const vault = new Contract(vaultAddress, VAULT_ABI, signer);
      const tx = await vault.harvest();
      await tx.wait();
      await loadVaultData();
      await loadUserData();
    } catch (e) {
      setError((e as Error).message);
    } finally {
      setTxPending(false);
    }
  };

  return (
    <div className="app">
      <header className="header">
        <div className="brand">
          <span className="logo">ay</span>
          <h1>AutoYield Vault</h1>
        </div>
        <p className="tagline">Self-driving yield. No admin. No keys. AsterDEX Earn + BNB Chain.</p>
        <div className="header-actions">
          {account ? (
            <>
              <span className="chain">
                {chainId === BNB_CHAIN_ID ? "BNB Mainnet" : chainId === BNB_TESTNET_CHAIN_ID ? "BNB Testnet" : `Chain ${chainId}`}
              </span>
              {!isSupported && (
                <button type="button" className="btn btn-ghost" onClick={switchToBNB}>
                  Switch to BNB
                </button>
              )}
              <span className="address">{`${account.slice(0, 6)}…${account.slice(-4)}`}</span>
            </>
          ) : (
            <button type="button" className="btn btn-primary" onClick={connect}>
              Connect Wallet
            </button>
          )}
        </div>
      </header>

      {error && (
        <div className="banner error">
          {error}
        </div>
      )}

      {!vaultAddress ? (
        <div className="banner info">
          Set VITE_VAULT_ADDRESS in .env to point to the deployed vault.
        </div>
      ) : (
        <main className="main">
          <section className="stats">
            <div className="stat">
              <span className="label">TVL</span>
              <span className="value">${tvl}</span>
            </div>
            <div className="stat">
              <span className="label">Share price</span>
              <span className="value">${sharePrice}</span>
            </div>
            <div className="stat">
              <span className="label">Pending rewards</span>
              <span className="value">${pendingRewards}</span>
            </div>
            <div className="stat">
              <span className="label">Harvest</span>
              <span className="value">{harvestReady ? "Ready" : "Cooldown"}</span>
            </div>
          </section>

          <section className="actions">
            <div className="card">
              <h2>Deposit USDT</h2>
              <p className="muted">Deposit into the vault. Capital is deployed to AsterDEX Earn.</p>
              {account && (
                <p className="small">Balance: {userAssetBalance} USDT</p>
              )}
              <div className="row">
                <input
                  type="text"
                  placeholder="0.00"
                  value={depositAmount}
                  onChange={(e) => setDepositAmount(e.target.value)}
                  disabled={!account || txPending}
                />
                <button
                  type="button"
                  className="btn btn-primary"
                  onClick={deposit}
                  disabled={!account || !depositAmount || txPending}
                >
                  Deposit
                </button>
              </div>
            </div>

            <div className="card">
              <h2>Withdraw</h2>
              <p className="muted">Redeem USDT. Your share of the vault is withdrawn.</p>
              {account && (
                <p className="small">Your position: {userAssets} USDT ({userShares} shares)</p>
              )}
              <div className="row">
                <input
                  type="text"
                  placeholder="0.00"
                  value={withdrawAmount}
                  onChange={(e) => setWithdrawAmount(e.target.value)}
                  disabled={!account || txPending}
                />
                <button
                  type="button"
                  className="btn btn-outline"
                  onClick={withdraw}
                  disabled={!account || !withdrawAmount || txPending}
                >
                  Withdraw
                </button>
              </div>
            </div>

            <div className="card highlight">
              <h2>Run cycle (Harvest)</h2>
              <p className="muted">Anyone can call. Compounds rewards; 0.1% to caller. 1h cooldown.</p>
              <button
                type="button"
                className="btn btn-accent"
                onClick={harvest}
                disabled={!account || !harvestReady || txPending}
              >
                {harvestReady ? "Harvest" : "Cooldown"}
              </button>
            </div>
          </section>

          <footer className="footer">
            <p>Built for Riquid Hackathon — Protect · Automate · Stack · Integrate</p>
            <p className="small">100% non-custodial · AsterDEX Earn · BNB Chain</p>
          </footer>
        </main>
      )}

      <style>{`
        .app { min-height: 100vh; }
        .header {
          padding: 1.5rem 2rem;
          border-bottom: 1px solid var(--border);
          display: flex;
          flex-wrap: wrap;
          align-items: center;
          gap: 1rem;
        }
        .brand { display: flex; align-items: center; gap: 0.75rem; }
        .logo {
          width: 40px; height: 40px; border-radius: 10px;
          background: linear-gradient(135deg, var(--accent), var(--accent-dim));
          color: var(--bg); font-weight: 700; font-size: 1rem;
          display: flex; align-items: center; justify-content: center;
          font-family: var(--font-mono);
        }
        .header h1 { margin: 0; font-size: 1.35rem; font-weight: 700; }
        .tagline { margin: 0; color: var(--muted); font-size: 0.9rem; flex: 1; }
        .header-actions { display: flex; align-items: center; gap: 0.75rem; }
        .chain { font-size: 0.8rem; color: var(--muted); }
        .address { font-family: var(--font-mono); font-size: 0.85rem; color: var(--muted); }
        .banner { padding: 0.75rem 2rem; text-align: center; }
        .banner.error { background: rgba(248,113,113,0.15); color: var(--danger); }
        .banner.info { background: var(--surface); color: var(--muted); }
        .main { max-width: 900px; margin: 0 auto; padding: 2rem; }
        .stats {
          display: grid; grid-template-columns: repeat(auto-fit, minmax(140px, 1fr));
          gap: 1rem; margin-bottom: 2rem;
        }
        .stat {
          background: var(--surface); border: 1px solid var(--border);
          border-radius: 12px; padding: 1rem;
        }
        .stat .label { display: block; font-size: 0.8rem; color: var(--muted); margin-bottom: 0.25rem; }
        .stat .value { font-size: 1.25rem; font-weight: 600; font-family: var(--font-mono); }
        .actions { display: flex; flex-direction: column; gap: 1.5rem; }
        .card {
          background: var(--surface); border: 1px solid var(--border);
          border-radius: 12px; padding: 1.5rem;
        }
        .card.highlight { border-color: var(--accent-dim); }
        .card h2 { margin: 0 0 0.5rem; font-size: 1.1rem; }
        .card .muted { margin: 0 0 0.75rem; color: var(--muted); font-size: 0.9rem; }
        .card .small { margin: 0 0 0.5rem; font-size: 0.8rem; color: var(--muted); }
        .row { display: flex; gap: 0.75rem; align-items: center; }
        .row input {
          flex: 1; padding: 0.75rem 1rem; border-radius: 8px;
          border: 1px solid var(--border); background: var(--bg); color: var(--text);
          font-size: 1rem;
        }
        .btn {
          padding: 0.75rem 1.25rem; border-radius: 8px; border: none;
          font-weight: 600; font-size: 0.9rem;
        }
        .btn:disabled { opacity: 0.5; cursor: not-allowed; }
        .btn-primary { background: var(--accent); color: var(--bg); }
        .btn-outline { background: transparent; color: var(--accent); border: 2px solid var(--accent); }
        .btn-accent { background: var(--accent); color: var(--bg); }
        .btn-ghost { background: transparent; color: var(--muted); }
        .footer { margin-top: 3rem; padding-top: 2rem; border-top: 1px solid var(--border); text-align: center; color: var(--muted); font-size: 0.9rem; }
        .footer .small { margin-top: 0.25rem; font-size: 0.8rem; }
      `}</style>
    </div>
  );
}

export default App;
