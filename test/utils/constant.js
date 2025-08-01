/** constant of token metadata */
export const tokenMetadata = {
  name: "mock",
  symbol: "mock",
};

/** constant of token amount */
export const amount = 1000n;

/** constant of frozen token amount */
export const frozenAmount = 100n;

/** constant of transfer function */
export const transfer = {
  utxo: "transfer(address,bytes32,uint256,bytes)",
  forest: "transfer(address,bytes32,uint256)",
};

/** constant of transferFrom function */
export const transferFrom = {
  utxo: "transferFrom(address,address,bytes32,uint256,bytes)",
  forest: "transferFrom(address,address,bytes32,uint256)",
};
