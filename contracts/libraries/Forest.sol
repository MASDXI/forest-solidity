// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.8.0 <0.9.0;

/**
 * @title Forest Model Library
 * @notice Library containing data structures and functions for managing txns within a forest-like structure.
 * @author Sirawit Techavanitch (sirawit_tec@live4.utcc.ac.th)
 */

library Forest {
    /**
     * @dev Structure representing a transaction.
     */
    struct Txn {
        bytes32 root;
        bytes32 parent;
        uint256 value;
        uint256 level;
        address owner;
    }

    /**
     * @dev Structure representing a DAG.
     */
    struct DAG {
        mapping(address => uint256) nonces;
        mapping(bytes32 => uint256) hierarchy;
        mapping(bytes32 => Txn) txns;
    }

    /**
     * @notice Event emitted when a transaction is created.
     * @param id The identifier of the transaction.
     * @param root The root of the transaction.
     * @param from The spender of the transaction.
     */
    event TransactionCreated(bytes32 indexed root, bytes32 id, address indexed from);

    /**
     * @notice Event emitted when a transaction is spent.
     * @param id The identifier of the transaction.
     * @param value The value that spent from the transaction.
     */
    event TransactionSpent(bytes32 indexed id, uint256 value);

    /**
     * @notice Error thrown when attempting to spend an not exist transaction.
     */
    error TransactionNotExist();

    /**
     * @notice Error thrown when a transaction is unauthorized.
     */
    error TransactionUnauthorized();

    /**
     * @notice Error thrown when trying to create a transaction with zero value.
     */
    error TransactionZeroValue();

    /**
     * @notice Error thrown when trying to merge over 255 transactions.
     */
    error TransactionMergeSizeExceed();

    /**
     * @notice Error thrown when the spending value exceeds the transaction value.
     * @param value The value of the transaction.
     * @param spend The amount being spent.
     */
    error TransactionInsufficient(uint256 value, uint256 spend);

    function contains(DAG storage self, bytes32 id) private view returns (bool) {
        return self.txns[id].value != uint256(0);
    }

    function calcTxnHash(address account, uint256 nonce) internal view returns (bytes32) {
        return keccak256(abi.encode(block.chainid, account, nonce));
    }

    function getTxn(DAG storage self, bytes32 id) internal view returns (Txn memory) {
        return self.txns[id];
    }

    function getTxnLevel(DAG storage self, bytes32 id) internal view returns (uint256) {
        return self.txns[id].level;
    }

    function getTxnParent(DAG storage self, bytes32 id) internal view returns (bytes32) {
        return self.txns[id].parent;
    }

    function getTxnRoot(DAG storage self, bytes32 id) internal view returns (bytes32) {
        return self.txns[id].root;
    }

    function getTxnValue(DAG storage self, bytes32 id) internal view returns (uint256) {
        return self.txns[id].value;
    }

    function getTxnCount(DAG storage self, address account) internal view returns (uint256) {
        return self.nonces[account];
    }

    function getTxnHierarchy(DAG storage self, bytes32 id) internal view returns (uint256) {
        return self.hierarchy[id];
    }

    function getTxnOwner(DAG storage self, bytes32 id) internal view returns (address) {
        return self.txns[id].owner;
    }

    function createTxn(DAG storage self, Txn memory newTxn, address spender) internal {
        if (newTxn.value == 0) revert TransactionZeroValue();
        bytes32 newId = calcTxnHash(spender, self.nonces[spender]);
        self.txns[newId] = Txn(newId, newTxn.parent, newTxn.value, newTxn.level, newTxn.owner);
        unchecked {
            self.nonces[spender]++;
        }

        emit TransactionCreated(newId, newTxn.root, spender);
    }

    function spendTxn(DAG storage self, bytes32 id, address spender, address to, uint256 value) internal {
        Txn storage ptr = self.txns[id];
        if (msg.sender != ptr.owner) revert TransactionUnauthorized();
        uint256 currentValue = ptr.value;
        if (currentValue == 0) revert TransactionNotExist();
        if (value > currentValue) revert TransactionInsufficient(currentValue, value);
        unchecked {
            ptr.value = currentValue - value;
            bytes32 currentRoot = ptr.root;
            uint256 currentHierarchy = self.hierarchy[currentRoot];
            uint256 newLevel = (ptr.level + 1);
            if (to != address(0)) {
                createTxn(self, Txn(currentRoot, id, value, newLevel, to), spender);
                if (newLevel > currentHierarchy) {
                    self.hierarchy[currentRoot] = newLevel;
                }
            }
        }

        emit TransactionSpent(id, value);
    }

    /**
     * @notice not suitable for use in production.
     */
    function mergeTxn(DAG storage self, bytes32[] memory ids) internal {
        uint256 txnsLength = ids.length;
        if (txnsLength >= 255) revert TransactionMergeSizeExceed();
        Txn memory ptr = getTxn(self, ids[0]);
        if (msg.sender != ptr.owner) revert TransactionUnauthorized();
        Txn memory txn;
        unchecked {
            for (uint8 index = 1; index < txnsLength; index++) {
                txn = getTxn(self, ids[index]);
                if (ptr.root == txn.root && ptr.owner == txn.owner) {
                    self.txns[ids[index]].value = 0;
                    ptr.value += txn.value;
                    if (ptr.level < txn.level) {
                        ptr.level = txn.level;
                    }
                }
            }
            createTxn(self, ptr, ptr.owner);
            if (ptr.level > self.hierarchy[ids[0]]) {
                self.hierarchy[ids[0]] = ptr.level;
            }
        }
    }
}
