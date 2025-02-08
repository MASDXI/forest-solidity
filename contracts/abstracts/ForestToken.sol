// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.8.0 <0.9.0;

import {Forest} from "../libraries/Forest.sol";
import {IForest} from "../interfaces/IForest.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/**
 * @title Forest Token
 * @dev Abstract contract implementing ERC20 functionalities with transaction management using the Forest library.
 * @notice This contract manages transactions in a forest-like structure using the Forest library.
 * @author Sirawit Techavanitch (sirawit_tec@live4.utcc.ac.th)
 */
abstract contract ForestToken is ERC20, IForest {
    using Forest for Forest.DAG;
    
    Forest.DAG private _dag;

    /**
     * @dev Constructor to initialize the ERC20 token with a name and symbol.
     * @param name_ The name of the token.
     * @param symbol_ The symbol of the token.
     */
    constructor(string memory name_, string memory symbol_) ERC20(name_, symbol_) {}

    /**
     * @dev Retrieves the details of a transaction.
     * @param tokenId The identifier of the transaction.
     * @return The transaction details.
     */
    function _transaction(bytes32 tokenId) internal view returns (Forest.Tx memory) {
        return _dag.getTx(tokenId);
    }

    function transactionLevel(bytes32 tokenId) internal view returns (uint256) {
        return _dag.getTxLevel(tokenId);
    }

    function transactionParent(bytes32 tokenId) internal view returns (bytes32) {
        return _dag.getTxParent(tokenId);
    }

    function transactionRoot(bytes32 tokenId) internal view returns (bytes32) {
        return _dag.getTxRoot(tokenId);
    }

    function transactionValue(bytes32 tokenId) internal view returns (uint256) {
        return _dag.getTxValue(tokenId);
    }

    function transactionCount(address account) internal view returns (uint256) {
        return _dag.getTxCount(account);
    }

    function transactionHierarchy(bytes32 tokenId) internal view returns (uint256) {
        return _dag.getTxHierarchy(tokenId);
    }

    /**
     * @dev Internal function to transfer tokens and manage transactions within the forest.
     * @param from The sender address.
     * @param to The recipient address.
     * @param tokenId The identifier of the transaction.
     * @param value The amount of tokens to transfer.
     */
    function _transfer(address from, address to, bytes32 tokenId, uint256 value) internal virtual {
        _dag.spendTx(tokenId, from, to, value);
        _update(from, to, value);
    }

    /**
     * @dev Internal function to mint tokens and create a new transaction within the forest.
     * @param account The recipient address.
     * @param value The amount of tokens to mint.
     */
    function _mintTransaction(address account, uint256 value) internal {
        _dag.createTx(Forest.Tx(bytes32(0), bytes32(0), value, 0, account), address(0));
        _mint(account, value);
    }

    /**
     * @dev Internal function to burn tokens and manage transactions within the forest.
     * @param account The address owning the tokens.
     * @param tokenId The identifier of the transaction.
     * @param value The amount of tokens to burn.
     */
    function _burnTransaction(address account, bytes32 tokenId, uint256 value) internal {
       _dag.spendTx(tokenId, account, address(0), value);
        _burn(account, value);
    }

    /**
     * @dev Overrides the ERC20 transfer function to revert.
     * @param to The recipient address.
     * @param value The amount of tokens to transfer.
     * @return Always reverts with ERC20TransferNotSupported error.
     */
    function transfer(address to, uint256 value) public virtual override returns (bool) {
        revert ERC20TransferNotSupported();
    }

    /**
     * @inheritdoc IForest
     */
    function transfer(address to, bytes32 tokenId, uint256 value) public virtual override returns (bool) {
        _transfer(msg.sender, to, tokenId, value);
        return true;
    }

    /**
     * @dev Overrides the ERC20 transferFrom function to revert.
     * @param from The sender address.
     * @param to The recipient address.
     * @param value The amount of tokens to transfer.
     * @return Always reverts with ERC20TransferFromNotSupported error.
     */
    function transferFrom(address from, address to, uint256 value) public virtual override returns (bool) {
        revert ERC20TransferFromNotSupported();
    }

    /**
     * @inheritdoc IForest
     */
    function transferFrom(
        address from,
        address to,
        bytes32 tokenId,
        uint256 value
    ) public virtual override returns (bool) {
        _spendAllowance(from, msg.sender, value);
        _transfer(from, to, tokenId, value);
        return true;
    }
}
