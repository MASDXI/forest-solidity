---
Title: "Forest: A Data Structure to Unlocking Control & Traceability in Digital Currency System"
Description: "Forest is a token-based model leveraging DAG-inspired structures to enhance traceability and AML/CFT compliance"
Author: "Sirawit Techavanitch <sirawit_tec@utcc.ac.th>"
Status: "Draft"
Purpose: "Dissertation"
---

<h1 align="center">
<img src="./docs/assets/banner.png" width="450"/>
</h1>

## Abstract

Forest is a [DAG](https://www.geeksforgeeks.org/introduction-to-directed-acyclic-graph/)-inspired token model designed to enhance traceability and regulatory compliance in digital currency systems. By introducing hierarchical token tracking, it enables efficient enforcement on any token linked to suspicious activity with level/root. Enforcement actions, such as freezing specific tokens or partitioning all tokens with relational links, are optimized to operate at O(1) complexity.

## Motivation

The present-day Central Bank Digital Currency concept aims to utilize the advantages of blockchain or Distributed Ledger Technology (DLT) that provide immutability, transparency, and security, and adopts smart contracts, which plays a key feature in creating programmable money. However, technology itself gives an advantage and eliminates the problem ideally of compliance with the regulator and AML/CFT standard, but it does not seem practical to be done in the real world and is not efficiently responsible for the financial crime or incidents that occur in the open network of economic.

## Specification

The key words “MUST”, “MUST NOT”, “REQUIRED”, “SHALL”, “SHALL NOT”, “SHOULD”, “SHOULD NOT”, “RECOMMENDED”, “NOT RECOMMENDED”, “MAY”, and “OPTIONAL” in this document are to be interpreted as described in RFC 2119 and RFC 8174.

```Solidity
// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.8.0 <0.9.0;

/**
 * @title Interface for Forest
 */

interface IForest {
    // events
    event TransactionCreated(bytes32 indexed root, bytes32 id, address indexed from);
    event TransactionSpent(bytes32 indexed id, uint256 value);

    // errors
    error TransactionNotExist();
    error TransactionInsufficient(uint256 value, uint256 spend);
    error TransactionZeroValue();

    // functions
    function hierarchyOfGraph(bytes32 tokenId) external view returns (uint256);
    function levelOfToken(bytes32 tokenId) external view returns (uint256);
    function ownerOfToken(bytes32 tokenId) external view returns (address);
    function parentOfToken(bytes32 tokenId) external view returns (bytes32);
    function rootOfToken(bytes32 tokenId) external view returns (bytes32);
    function tokenExists(bytes32 tokenId) external view returns (bool);
    function valueOfToken(bytes32 tokenId) external view returns (uint256);
    function transfer(address to, bytes32 tokenId, uint256 value) external returns (bool);
    function transferFrom(address from, address to, bytes32 tokenId, uint256 value) external returns (bool);
}
```

### Function Behavior

#### Create Transaction

- The `value` of the transaction **MUST NOT** be zero. If `value` is 0, the function **MUST** revert.
- The transaction **MUST** be assigned a unique `id`. The `id` **SHOULD** be derived using the deterministic hashing function.
- The new transaction **MUST** include the correct parent field:
  If the transaction is derived (e.g., created by spender), the `parent` field **MUST** reference the `id` of the original transaction.
  If the transaction is a `root` transaction, the parent field **MAY** be set to `0x0`.
- The events `TransactionCreated` **MUST** emit when created new transaction.

#### Spend Transaction

- The spending action **MUST** verify that the transaction with the given `id` exists. If not function **SHOULD** return `false` or revert.
- The `value` to be spent **MUST NOT** exceed the `value` of the transaction. If it does, the function **MUST** revert.
- The `hierarchy` of the transaction's `root` **MUST** be incremented if the new transaction's level exceeds the current `hierarchy`.
- The events `TransactionSpent` **MUST** emit when spending transaction.

#### Merging Transaction

- to merging two or multiple transactions into new one transaction all transactions **MUST** have the same transaction `root`
- new transaction from merging will be

$tx^k$: The highest transaction level from transactions that will be merging.  
$tx^l$: The transaction level of the merged transaction.
``` math
tx^l = tx^k + 1
```  

### Additional useful function

- `totalTokenAtLevel` return the total token from given `level` and root `tokenId` useful when restrict token at level and want to know total amount token that affect.
- `totalAddressAtLevel` return the total address from given `level` and root `tokenId` useful when restrict token at level and want to know total address that affect.

## Rationale

| Features                                                                  | ERC-20 | UTXO | Forest |
| ------------------------------------------------------------------------- | ------ | ---- | ------ |
| Freeze the `sender` account.                                              | ✓      | ✓    | ✓      |
| Freeze the `recipient` account.                                           | ✓      | ✓    | ✓      |
| Freeze the certain `amount` token.                                        | ✗      | ✓    | ✓      |
| Freeze the specifics `tokenId` or `txId`.                                 | ✗      | ✓    | ✓      |
| Freeze the specifics `tokenId` or `TxId` that relevant to the root.       | ✗      | ✓    | ✓      |
| Freeze all `tokenId` or `TxId` before or after specifics hierarchy level. | ✗      | ✗    | ✓      |

- `ERC-20` provide events and keep tracking each `Transfer`,  
  but the problem is the `ERC-20` model can't separate `clean money` from `dirty money`,  
  due to the `ERC-20` not have `tokenId` to keep tracking each token when it's move.
- `UTXO` facing challenge to combine multiple `UnspentTransaction` and spent as one,  
  in case, user want to spend value that greater that selected `UnspentTransaction`.  
  Possible solution: prepare and batching as an array,  
  `UTXO` maintain the amount of money or group of money in each individual transaction.  
  Each `UnspentTransaction` is not underlying any account,
  so to spend the transaction, the caller needs to be the owner of the transaction that needs to be spent.
- `Forest` use to modify an existing state rather than create a new transaction, like in `UTXO` do,  
  it allows spending the transaction multiple times till it's met `0`, The `Forest` model enables tracking of child/subtree structures,  
  providing a hierarchical view of token flows and relationships,  
  which is not possible in traditional token standards like [`ERC-20`](https://eips.ethereum.org/EIPS/eip-20), [`ERC-1400`](https://polymath.network/erc-1400), and [`ERC-3643`](https://eips.ethereum.org/EIPS/eip-3643).

### Granular Policy Enforcement

- Restrict the transaction with specific `TxId`.  
- Restrict all transaction with specific `TxLevel`.  
  - before `TxLevel` `x`
  - after `TxLevel` `x` 
  - between `TxLevel` `x` and `y`
- Restrict all transaction with specific root `TxId`.  

### Transaction Network Diagrams

<div align="center">
  <img src="./docs/assets/diagrams/Forest.svg" width="800"/>
</div>

<div align="center">
  <img src="./docs/assets/diagrams/Forest_Sort.svg" width="400"/>
</div>

`Forest` provide reverse topological sorting natively cause each `Transaction` store the `parent` transaction, so it's can iterable `parent` back to the `root` of the DAG.

### Discussion

- To get rid of selecting `tokenId` it's can use the concept of First-In-First-Out (FIFO) store the transaction in `DoubleEndedQueue`, `Heap`, and `LinkedList`.
- `Forest` concept and be applied into application specific by built on top of [`cosmos-sdk`](https://github.com/cosmos/cosmos-sdk), [`hyperledger/fabric`](https://github.com/hyperledger/fabric), and [`polkadot-sdk`](https://github.com/paritytech/polkadot-sdk).

## Security Considerations

### Denial Of Service

Run out of gas problem due to the operation consuming higher gas if transferring multiple groups of small tokens or loop transfer.

### Gas Limit Vulnerabilities

Exceeds block gas limit if the blockchain has a block gas limit lower than the gas used in the transaction.

### Data Fragmentation

The `Forest` model tracks all assets within the system, which can be represented mathematically as

$A^d:$ The decimals of the asset.  
$A^t:$ The total supply of the asset.  
$A^s:$ The possible asset represent in transaction.  

```math
A^s = A^t \times A^d
```

While this ensures precision, the high granularity can increase storage needs.
Traditional finance often uses simpler `decimals` like `2`, `4` or `6`, avoiding excessive detail.
Adopting similar strategies could help balance granularity with efficiency. Or limit value as `MINIMUM` spending.

### High Complexity

`Forest` may introduce potential vulnerabilities or misbehave when applied with other smart contract.

## Copyright

Copyright 2024-2025 Sirawit Techavanitch. Licensed under the [Apache-2.0](./LICENSE)
