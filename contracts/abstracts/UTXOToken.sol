// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.8.0 <0.9.0;

import {UnspentTransactionOutput as UTXO} from "../libraries/UTXO.sol";
import {IUTXO} from "../interfaces/IUTXO.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/**
 * @title UTXO Token Contract
 * @dev This contract extends ERC20 functionality to manage tokens using Unspent Transaction Output (UTXO) model.
 * It provides methods to handle token transactions using UTXO data structures.
 * Implements the IUTXO interface.
 */

abstract contract UTXOToken is ERC20, IUTXO {
    /** @custom:library */
    using UTXO for UTXO.UTXO;

    /** @custom:storage */
    UTXO.UTXO private _UTXO;

    /**
     * @dev Constructor to initialize the ERC20 token with a name and symbol.
     * @param name_ The name of the token.
     * @param symbol_ The symbol of the token.
     */
    constructor(string memory name_, string memory symbol_) ERC20(name_, symbol_) {}

    /**
     * @dev Internal function to fetch a transaction details based on the token ID.
     * @param tokenId The identifier of the token transaction.
     * @return A `Transaction` structure containing transaction details.
     */
    function _transaction(bytes32 tokenId) internal view returns (UTXO.Tx memory) {
        return _UTXO.transaction(tokenId);
    }

    /**
     * @dev Internal function to execute a token transfer using an UTXO-based approach.
     * @param from The sender address.
     * @param to The recipient address.
     * @param tokenId The identifier of the token transaction.
     * @param value The amount of tokens to transfer.
     * @param signature The signature associated with the transaction.
     * @param extraData The extra data for transaction output.
     */
    function _transfer(
        address from,
        address to,
        bytes32 tokenId,
        uint256 value,
        bytes memory signature,
        bytes32 extraData
    ) internal virtual {
        uint256 txValue = _UTXO.getTxValue(tokenId);
        if (txValue < value) {
            revert UTXO.TransactionInsufficient(txValue, value);
        }
        _UTXO.spendTx(UTXO.TxInput(tokenId, signature), from);
        txValue = txValue - value;
        if (txValue != 0) {
            _UTXO.createTx(
                UTXO.TxOutput(value, to),
                tokenId,
                from,
                extraData
            );
        }
        // update account-based balance
        _update(from, to, value);
    }

    /**
     * @dev Internal function to mint tokens and create a transaction for the minted tokens.
     * @param account The address that will receive the minted tokens.
     * @param value The amount of tokens to mint and transfer.
     * @param extraData The extra data for transaction output.
     */
    function _mintTransaction(address account, uint256 value, bytes32 extraData) internal {
        _UTXO.createTx(
            UTXO.TxOutput(value, account),
            bytes32(0),
            address(0),
            extraData
        );
        // update account-based balance
        _mint(account, value);
    }

    /**
     * @dev Internal function to burn tokens and handle the corresponding UTXO transaction.
     * @param account The address from which tokens will be burned.
     * @param tokenId The identifier of the token transaction to be burned.
     * @param value The amount of tokens to burn.
     * @param extraData The extra data for transaction output.
     */
    function _burnTransaction(address account, bytes32 tokenId, uint256 value, bytes32 extraData) internal {
        uint256 txValue = _UTXO.getTxValue(tokenId);
        if (txValue < value) {
            revert UTXO.TransactionInsufficient(txValue, value);
        }
        txValue = txValue - value;
        _UTXO.consumeTx(tokenId);
        if (txValue != 0) {
            _UTXO.createTx(
                UTXO.TxOutput(value, account),
                tokenId,
                account,
                extraData
            );
        }
        // update account-based balance
        _burn(account, value);
    }

    /**
     * @dev Function to fetch a transaction details based on the token ID.
     * @param tokenId The identifier of the token transaction.
     * @return A `Transaction` structure containing transaction details.
     */
    function transaction(bytes32 tokenId) public view returns (UTXO.Tx memory) {
        return _transaction(tokenId);
    }

    /**
     * @dev Function to the value of a UTXO transaction identified by its token ID.
     * @param tokenId The identifier of the UTXO transaction.
     * @return The value of the UTXO associated with the specified token ID.
     */
    function transactionValue(bytes32 tokenId) public view returns (uint256) {
        return _UTXO.getTxValue(tokenId);
    }

    /**
     * @dev Function to fetch the input of a UTXO transaction identified by its token ID.
     * @param tokenId The identifier of the UTXO transaction.
     * @return The input associated with the specified UTXO token ID.
     */
    function transactionInput(bytes32 tokenId) public view returns (bytes32) {
        return _UTXO.getTxInput(tokenId);
    }

    /**
     * @dev Function to fetch the owner of a UTXO transaction identified by its token ID.
     * @param tokenId The identifier of the UTXO transaction.
     * @return The address of the owner of the UTXO associated with the specified token ID.
     */
    function transactionOwner(bytes32 tokenId) public view returns (address) {
        return _UTXO.getTxOwner(tokenId);
    }

    /**
     * @dev Function to fetch the extra data of a UTXO transaction identified by its token ID.
     * @param tokenId The identifier of the UTXO transaction.
     * @return The extra data of the UTXO associated with the specified token ID.
     */
    function transactionExtraData(bytes32 tokenId) public view returns (bytes32) {
        return _UTXO.getTxExtraData(tokenId);
    }

    /**
     * @dev Function to checks whether a UTXO transaction has been spent, identified by its token ID.
     * @param tokenId The identifier of the UTXO transaction.
     * @return True if the UTXO associated with the specified token ID has been spent, false otherwise.
     */
    function transactionSpent(bytes32 tokenId) public view returns (bool) {
        return _UTXO.getTxSpent(tokenId);
    }

    /**
     * @dev Function to transfer tokens (not supported in this contract).
     */
    function transfer(address to, uint256 value) public virtual override returns (bool) {
        revert ERC20TransferNotSupported();
    }

    /**
     * @inheritdoc IUTXO
     */
    function transfer(
        address to,
        bytes32 tokenId,
        uint256 value,
        bytes memory signature
    ) public virtual override returns (bool) {
        _transfer(msg.sender, to, tokenId, value, signature, bytes32(""));
        return true;
    }

    /**
     * @dev Function to transfer tokens from one address to another (not supported in this contract).
     */
    function transferFrom(address from, address to, uint256 value) public virtual override returns (bool) {
        revert ERC20TransferFromNotSupported();
    }

    /**
     * @inheritdoc IUTXO
     */
    function transferFrom(
        address from,
        address to,
        bytes32 tokenId,
        uint256 value,
        bytes memory signature
    ) public virtual override returns (bool) {
        _spendAllowance(from, msg.sender, value);
        _transfer(from, to, tokenId, value, signature, bytes32(""));
        return true;
    }
}
