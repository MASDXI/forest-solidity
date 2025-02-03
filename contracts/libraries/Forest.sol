// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.8.0 <0.9.0;

/**
 * @title Forest Model Library
 * @notice Library containing data structures and functions for managing txs within a forest-like structure.
 * @author Sirawit Techavanitch (sirawit_tec@live4.utcc.ac.th)
 */
library Forest {
    struct Tx {
        bytes32 root;
        bytes32 parent;
        uint256 value;
        uint256 level;
        address owner;
    }

    struct DAG {
        mapping(address => uint256) nonces;
        mapping(bytes32 => uint256) hierarchy;
        mapping(bytes32 => Tx) txs;
    }

    event TransactionCreated(bytes32 indexed root, bytes32 id, address indexed from);
    event TransactionSpent(bytes32 indexed id, uint256 value);

    error TransactionNotExist();
    error TransactionUnauthorized();
    error TransactionInsufficient(uint256 value, uint256 spend);
    error TransactionZeroValue();

    function contains(DAG storage self, bytes32 id) private view returns (bool) {
        return self.txs[id].value != uint256(0);
    }

    function calcTxHash(address account, uint256 nonce) internal view returns (bytes32) {
        return keccak256(abi.encode(block.chainid, account, nonce));
    }

    function getTx(DAG storage self, bytes32 id) internal view returns (Tx memory) {
        return self.txs[id];
    }

    function getTxLevel(DAG storage self, bytes32 id) internal view returns (uint256) {
        return self.txs[id].level;
    }

    function getTxParent(DAG storage self, bytes32 id) internal view returns (bytes32) {
        return self.txs[id].parent;
    }

    function getTxRoot(DAG storage self, bytes32 id) internal view returns (bytes32) {
        return self.txs[id].root;
    }

    function getTxValue(DAG storage self, bytes32 id) internal view returns (uint256) {
        return self.txs[id].value;
    }

    function getTxCount(DAG storage self, address account) internal view returns (uint256) {
        return self.nonces[account];
    }

    function getTxHierarchy(DAG storage self, bytes32 id) internal view returns (uint256) {
        return self.hierarchy[id];
    }

    function createTx(DAG storage self, Tx memory newTx, address spender) internal {
        if (newTx.value == 0) revert TransactionZeroValue();
        bytes32 newId = calcTxHash(spender, self.nonces[spender]);
        self.txs[newId] = newTx;
        unchecked {
            self.nonces[spender]++;
        }

        emit TransactionCreated(newId, newTx.root, spender);
    }

    function spendTx(DAG storage self, bytes32 id, address spender, address to, uint256 value) internal {
        Tx storage ptr = self.txs[id];
        if (msg.sender != ptr.owner) revert TransactionUnauthorized();
        uint256 currentValue = ptr.value;
        if (currentValue == 0) revert TransactionNotExist();
        if (value > currentValue) revert TransactionInsufficient(currentValue, value);
        unchecked {
            ptr.value = currentValue - value;
            bytes32 currentRoot = ptr.root;
            uint256 currentHierarchy = self.hierarchy[currentRoot];
            uint256 newLevel = (ptr.level + 1);
            createTx(self, Tx(currentRoot, id, value, newLevel, to), spender);
            if (newLevel > currentHierarchy) {
                self.hierarchy[currentRoot] = newLevel;
            }
        }

        emit TransactionSpent(id, value);
    }
}
