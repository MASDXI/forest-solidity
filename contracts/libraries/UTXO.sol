// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.8.0 <0.9.0;

/**
 * @title Unspent Transaction Output Model (UTXO)
 * @notice This library implements the UTXO model for managing transactions on the blockchain.
 * @author Sirawit Techavanitch (sirawit_tec@live4.utcc.ac.th)
 */
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";

// @TODO merging UTXO.

library UnspentTransactionOutput {
    using ECDSA for bytes32;
    using MessageHashUtils for bytes32;

    /**
     * @dev Structure representing a transaction.
     */
    struct Tx {
        bytes32 input;
        uint256 value;
        address owner;
        bool spent;
        bytes32 extraData;
    }

    /**
     * @dev Structure representing an input for a transaction.
     */
    struct TxInput {
        bytes32 outpoint;
        bytes signature;
    }

    /**
     * @dev Structure representing an output for a transaction.
     */
    struct TxOutput {
        uint256 value;
        address account;
    }

    /**
     * @dev Structure representing a Unspent Tranasction Output.
     */
    struct UTXO {
        mapping(address => uint256) nonces;
        mapping(bytes32 => Tx) txs;
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
        return self.txs[id].value > 0;
    }

    /**
     * @notice Calculates the hash of a transaction based on the creator and nonce.
     * @param creator The creator of the transaction.
     * @param nonce The nonce associated with the creator.
     * @return The calculated transaction hash.
     */
    function calcTxHash(address creator, uint256 nonce) internal view returns (bytes32) {
        return keccak256(abi.encode(block.chainid, creator, nonce));
    }

    /**
     * @notice Creates a new transaction output in the UTXO.
     * @param self The UTXO storage.
     * @param txOutput The transaction output details.
     * @param input The input identifier of the transaction.
     * @param creator The creator of the transaction.
     */
    function createTx(
        UTXO storage self,
        TxOutput memory txOutput,
        bytes32 input,
        address creator,
        bytes32 extraData
    ) internal {
        if (txOutput.value == 0) {
            revert TransactionZeroValue();
        }
        uint256 nonce = self.nonces[creator];
        bytes32 id = calcTxHash(creator, self.nonces[creator]);
        self.txs[id] = Tx(input, txOutput.value, txOutput.account, false, extraData);
        unchecked {
            self.nonces[creator] = nonce++;
        }

        emit TransactionCreated(id, creator, txOutput.account);
    }

    /**
     * @notice Spends a transaction in the UTXO.
     * @param self The UTXO storage.
     * @param txInput The transaction input details.
     * @param account The account spending the transaction.
     */
    function spendTx(UTXO storage self, TxInput memory txInput, address account) internal {
        if (!_transactionExist(self, txInput.outpoint)) {
            revert TransactionNotExist();
        }
        if (getTxSpent(self, txInput.outpoint)) {
            revert TransactionAlreadySpent();
        }
        if (
            keccak256(abi.encodePacked(txInput.outpoint)).toEthSignedMessageHash().recover(txInput.signature) ==
            address(0)
        ) {
            revert TransactionUnauthorized();
        }
        self.txs[txInput.outpoint].spent = true;

        emit TransactionSpent(txInput.outpoint, account);
    }

    /**
     * @notice Consumes (marks as spent without require signature) a transaction in the UTXO.
     * @param self The UTXO storage.
     * @param id The identifier of the transaction to consume.
     */
    function consumeTx(UTXO storage self, bytes32 id) internal {
        if (!_transactionExist(self, id)) {
            revert TransactionNotExist();
        }
        self.txs[id].spent = true;

        emit TransactionConsumed(id);
    }

    /**
     * @notice Retrieves the details of a transaction from the UTXO.
     * @param self The UTXO storage.
     * @param id The identifier of the transaction.
     * @return The transaction details.
     */
    function transaction(UTXO storage self, bytes32 id) internal view returns (Tx memory) {
        return self.txs[id];
    }

    /**
     * @notice Retrieves the input identifier of a transaction from the UTXO.
     * @param self The UTXO storage.
     * @param id The identifier of the transaction.
     * @return The transaction input identifier.
     */
    function getTx(UTXO storage self, bytes32 id) internal view returns (bytes32) {
        return self.txs[id].input;
    }

    /**
     * @notice Retrieves the transaction input of a transaction from the UTXO.
     * @param self The UTXO storage.
     * @param id The identifier of the transaction.
     * @return The transaction input.
     */
    function getTxInput(UTXO storage self, bytes32 id) internal view returns (bytes32) {
        return self.txs[id].input;
    }

    /**
     * @notice Retrieves the value of a transaction from the UTXO.
     * @param self The UTXO storage.
     * @param id The identifier of the transaction.
     * @return The transaction value.
     */
    function getTxValue(UTXO storage self, bytes32 id) internal view returns (uint256) {
        return self.txs[id].value;
    }

    /**
     * @notice Checks if a transaction in the UTXO has been spent.
     * @param self The UTXO storage.
     * @param id The identifier of the transaction.
     * @return true if the transaction has been spent, false otherwise.
     */
    function getTxSpent(UTXO storage self, bytes32 id) internal view returns (bool) {
        return self.txs[id].spent;
    }

    /**
     * @notice Retrieves the owner of a transaction in the UTXO.
     * @param self The UTXO storage.
     * @param id The identifier of the transaction.
     * @return The owner address of the transaction.
     */
    function getTxOwner(UTXO storage self, bytes32 id) internal view returns (address) {
        return self.txs[id].owner;
    }

    /**
     * @notice Retrieves the owner of a transaction in the UTXO.
     * @param self The UTXO storage.
     * @param id The identifier of the transaction.
     * @return The extraData  of the transaction.
     */
    function getTxExtraData(UTXO storage self, bytes32 id) internal view returns (bytes32) {
        return self.txs[id].extraData;
    }

    /**
     * @notice Retrieves the number of transactions associated with an account in the UTXO.
     * @param self The UTXO storage.
     * @param account The account address.
     * @return The count of transactions.
     */
    function getTxCount(UTXO storage self, address account) internal view returns (uint256) {
        return self.nonces[account];
    }
}
