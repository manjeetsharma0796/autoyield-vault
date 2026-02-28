export const BNB_CHAIN_ID = 56;
export const BNB_TESTNET_CHAIN_ID = 97;

export const RPC_URLS: Record<number, string> = {
  [BNB_CHAIN_ID]: "https://bsc-dataseed.binance.org/",
  [BNB_TESTNET_CHAIN_ID]: "https://data-seed-prebsc-1-s1.binance.org:8545/",
};

export const VAULT_ADDRESS =
  (import.meta.env.VITE_VAULT_ADDRESS as string) || "";
// Default USDT: mainnet. For testnet set VITE_ASSET_ADDRESS=0x337610d27c682E347C9cD60BD4b3b107C9d34dDd
export const ASSET_ADDRESS =
  (import.meta.env.VITE_ASSET_ADDRESS as string) ||
  "0x55d398326f99059fF775485246999027B3197955";
