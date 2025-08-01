// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.8.0 <0.9.0;

/**
 * @title Unspent Transaction Output Model (UTXO)
 * @notice This library implements the UTXO model for managing transactions on the blockchain.
 * inspired from:
 * https://gist.github.com/alex-miller-0/a5f4de3f811872b7272e66a3697f88de
 * https://github.com/ProjectWyvern/wyvern-ethereum/blob/master/contracts/token/UTXORedeemableToken.sol
 * https://github.com/olegfomenko/utxno
 * @author Sirawit Techavanitch (sirawit_tec@live4.utcc.ac.th)
 */

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";

library UnspentTransactionOutput {
    /** @custom:library */
    using ECDSA for bytes32;
    using MessageHashUtils for bytes32;

    /**
     * @dev Structure representing a transaction.
     */
    struct Txn {
        bytes32 input;
        uint256 value;
        address owner;
        bool spent;
        bytes32 extraData;
    }

    /**
     * @dev Structure representing an input for a transaction.
     */
    struct TxnInput {
        bytes32 outpoint;
        bytes signature;
    }

    /**
     * @dev Structure representing an output for a transaction.
     */
    struct TxnOutput {
        uint256 value;
        address account;
    }

    /**
     * @dev Structure representing a Unspent Tranasction Output.
     */
    struct UTXO {
        mapping(address => uint256) nonces;
        mapping(bytes32 => Txn) txns;
    }

    /**
     * @notice Event emitted when a transaction is created.
     * @param id The identifier of the transaction.
     * @param creator The creator of the transaction.
     * @param owner The owner of the transaction output.
     */
    event TransactionCreated(bytes32 indexed id, address indexed creator, address indexed owner);

    /**
     * @notice Event emitted when a transaction is consumed.
     * @param id The identifier of the transaction.
     */
    event TransactionConsumed(bytes32 indexed id);

    /**
     * @notice Event emitted when a transaction is spent.
     * @param id The identifier of the transaction.
     * @param spender The address that spent the transaction.
     */
    event TransactionSpent(bytes32 indexed id, address indexed spender);

    /**
     * @notice Error thrown when attempting to spend an already spent transaction.
     */
    error TransactionAlreadySpent();

    /**
     * @notice Error thrown when attempting to create a transaction that already exists.
     */
    error TransactionExist();

    /**
     * @notice Error thrown when attempting to access a non-existent transaction.
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
     * @notice Error thrown when the spending value exceeds the transaction value.
     * @param value The value of the transaction.
     * @param spend The amount being spent.
     */
    error TransactionInsufficient(uint256 value, uint256 spend);

    /**
     * @notice Checks if a transaction with the given id exists in the UTXO.
     * @param self The UTXO storage.
     * @param id The identifier of the transaction.
     * @return true if the transaction exists, false otherwise.
     */
    function _transactionExist(UTXO storage self, bytes32 id) private view returns (bool) {
        return self.txns[id].value > 0;
    }

    /**
     * @notice Calculates the hash of a transaction based on the creator and nonce.
     * @param creator The creator of the transaction.
     * @param nonce The nonce associated with the creator.
     * @return The calculated transaction hash.
     */
    function calcTxnHash(address creator, uint256 nonce) internal view returns (bytes32) {
        return keccak256(abi.encode(block.chainid, creator, nonce));
    }

    /**
     * @notice Creates a new transaction output in the UTXO.
     * @param self The UTXO storage.
     * @param txnOutput The transaction output details.
     * @param input The input identifier of the transaction.
     * @param creator The creator of the transaction.
     */
    function createTxn(
        UTXO storage self,
        TxnOutput memory txnOutput,
        bytes32 input,
        address creator,
        bytes32 extraData
    ) internal {
        if (txnOutput.value == 0) {
            revert TransactionZeroValue();
        }
        uint256 nonce = self.nonces[creator];
        bytes32 id = calcTxnHash(creator, self.nonces[creator]);
        self.txns[id] = Txn(input, txnOutput.value, txnOutput.account, false, extraData);
        unchecked {
            self.nonces[creator] = nonce++;
        }

        emit TransactionCreated(id, creator, txnOutput.account);
    }

    /**
     * @notice Spends a transaction in the UTXO.
     * @param self The UTXO storage.
     * @param txnInput The transaction input details.
     * @param account The account spending the transaction.
     */
    function spendTxn(UTXO storage self, TxnInput memory txnInput, address account) internal {
        if (!_transactionExist(self, txnInput.outpoint)) {
            revert TransactionNotExist();
        }
        if (getTxnSpent(self, txnInput.outpoint)) {
            revert TransactionAlreadySpent();
        }
        if (
            keccak256(abi.encodePacked(txnInput.outpoint)).toEthSignedMessageHash().recover(txnInput.signature) ==
            address(0)
        ) {
            revert TransactionUnauthorized();
        }
        self.txns[txnInput.outpoint].spent = true;

        emit TransactionSpent(txnInput.outpoint, account);
    }

    /**
     * @notice Consumes (marks as spent without require signature) a transaction in the UTXO.
     * @param self The UTXO storage.
     * @param id The identifier of the transaction to consume.
     */
    function consumeTxn(UTXO storage self, bytes32 id) internal {
        if (!_transactionExist(self, id)) {
            revert TransactionNotExist();
        }
        self.txns[id].spent = true;

        emit TransactionConsumed(id);
    }

    /**
     * @notice merge multiple transaction into single transaction.
     * @param self The UTXO storage.
     * @param ids The array of the identifiers of the transaction to merge.
     */
    function mergeTxn(UTXO storage self, bytes32[] memory ids) internal {
        // @TODO
    }

    /**
     * @notice Retrieves the details of a transaction from the UTXO.
     * @param self The UTXO storage.
     * @param id The identifier of the transaction.
     * @return The transaction details.
     */
    function transaction(UTXO storage self, bytes32 id) internal view returns (Txn memory) {
        return self.txns[id];
    }

    /**
     * @notice Retrieves the input identifier of a transaction from the UTXO.
     * @param self The UTXO storage.
     * @param id The identifier of the transaction.
     * @return The transaction input identifier.
     */
    function getTxn(UTXO storage self, bytes32 id) internal view returns (bytes32) {
        return self.txns[id].input;
    }

    /**
     * @notice Retrieves the transaction input of a transaction from the UTXO.
     * @param self The UTXO storage.
     * @param id The identifier of the transaction.
     * @return The transaction input.
     */
    function getTxnInput(UTXO storage self, bytes32 id) internal view returns (bytes32) {
        return self.txns[id].input;
    }

    /**
     * @notice Retrieves the value of a transaction from the UTXO.
     * @param self The UTXO storage.
     * @param id The identifier of the transaction.
     * @return The transaction value.
     */
    function getTxnValue(UTXO storage self, bytes32 id) internal view returns (uint256) {
        return self.txns[id].value;
    }

    /**
     * @notice Checks if a transaction in the UTXO has been spent.
     * @param self The UTXO storage.
     * @param id The identifier of the transaction.
     * @return true if the transaction has been spent, false otherwise.
     */
    function getTxnSpent(UTXO storage self, bytes32 id) internal view returns (bool) {
        return self.txns[id].spent;
    }

    /**
     * @notice Retrieves the owner of a transaction in the UTXO.
     * @param self The UTXO storage.
     * @param id The identifier of the transaction.
     * @return The owner address of the transaction.
     */
    function getTxnOwner(UTXO storage self, bytes32 id) internal view returns (address) {
        return self.txns[id].owner;
    }

    /**
     * @notice Retrieves the owner of a transaction in the UTXO.
     * @param self The UTXO storage.
     * @param id The identifier of the transaction.
     * @return The extraData  of the transaction.
     */
    function getTxnExtraData(UTXO storage self, bytes32 id) internal view returns (bytes32) {
        return self.txns[id].extraData;
    }

    /**
     * @notice Retrieves the number of transactions associated with an account in the UTXO.
     * @param self The UTXO storage.
     * @param account The account address.
     * @return The count of transactions.
     */
    function getTxnCount(UTXO storage self, address account) internal view returns (uint256) {
        return self.nonces[account];
    }
}
