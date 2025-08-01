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
        uint96 level;
        address owner;
    }

    /**
     * @dev Structure representing a DAG.
     */
    struct DAG {
        mapping(address => uint256) nonces;
        mapping(bytes32 => uint96) hierarchy;
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
    event TransactionSpent(bytes32 indexed root, bytes32 id, uint256 value);

    /**
     * @notice Error thrown when a transaction is unauthorized.
     */
    error TransactionUnauthorized();

    /**
     * @notice Error thrown when trying to create a transaction with zero value.
     */
    error TransactionZeroValue();

    error TransactionInvalidReceiver(address receiver);

    /**
     * @notice Error thrown when the spending value exceeds the transaction value.
     * @param value The value of the transaction.
     * @param spend The amount being spent.
     */
    error TransactionInsufficient(uint256 value, uint256 spend);

    /** @custom:function-private */
    function _createTxn(DAG storage self, Txn memory newTxn, address spender) private returns (bytes32 newId) {
        newId = calcTxnHash(spender, self.nonces[spender]);
        self.txns[newId] = Txn(newId, newTxn.parent, newTxn.value, newTxn.level, newTxn.owner);
        unchecked {
            self.nonces[spender]++;
        }

        emit TransactionCreated(newId, newTxn.root, spender);
    }

    /** @custom:function-internal */
    function contains(DAG storage self, bytes32 id) internal view returns (bool) {
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

    function createTxn(DAG storage self, Txn memory newTxn, address spender) internal returns (bytes32) {
        if (newTxn.value == 0) revert TransactionZeroValue();
        if (newTxn.owner == address(0)) revert TransactionInvalidReceiver(address(0));
        return _createTxn(self, newTxn, spender);
    }

    function spendTxn(DAG storage self, bytes32 id, address spender, address to, uint256 value) internal {
        Txn storage ptr = self.txns[id];
        if (spender != ptr.owner) revert TransactionUnauthorized();
        uint256 currentValue = ptr.value;
        if (value == 0 || value > currentValue) revert TransactionInsufficient(currentValue, value);
        bytes32 currentRoot = ptr.root;
        unchecked {
            ptr.value = currentValue - value;
            uint96 newLevel = (ptr.level + 1);
            if (to != address(0)) {
                _createTxn(self, Txn(currentRoot, id, value, newLevel, to), spender);
                if (newLevel > self.hierarchy[currentRoot]) {
                    self.hierarchy[currentRoot] = newLevel;
                }
            }
        }

        emit TransactionSpent(currentRoot, id, value);
    }
}
