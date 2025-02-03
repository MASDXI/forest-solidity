// // SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.8.0 <0.9.0;

import "../abstracts/ForestToken.sol";
import "../abstracts/extensions/FreezeAddress.sol";
import "../abstracts/extensions/FreezeBalance.sol";
import "../abstracts/extensions/FreezeToken.sol";

contract MockForest is ForestToken, FreezeAddress, FreezeBalance, FreezeToken {
    /// @custom:event for keep tracking token from root.
    event Transfer(address from, address to, bytes32 indexed root, bytes32 indexed parent, uint256 value);

    constructor(string memory name_, string memory symbol_) ForestToken(name_, symbol_) {}

    modifier checkFrozenRootOrParent(bytes32 tokenId) {
        Forest.Tx memory transaction = _transaction(tokenId);
        if (isTokenFrozen(transaction.root) || isTokenFrozen(transaction.parent)) {
            revert TokenFrozen();
        }
        _;
    }

    // TODO
    // modifier checkFrozenLevel(bytes32 tokenId) {
        // check root equal check equal
        // _;
    // }

    // TODO
    // modifier checkFrozenBeforeLevel(bytes32 tokenId)  
        // check root equal and check less than
        // _;
    // }

    // TODO
    // modifier checkFrozenAfterLevel(bytes32 tokenId)  
        // check root equal check greater than
        // _;
    // }
    
    // TODO
    // modifier checkFrozenInBetweenLevel(bytes32 tokenId)
        // check root equal check greater than 'x' and less than 'y'
        // _;
    // }

    function _transfer(
        address from,
        address to,
        bytes32 tokenId,
        uint256 value
    )
        internal
        virtual
        override
        checkFrozenBalance(from, balanceOf(from))
        checkFrozenAddress(to, to)
        checkFrozenRootOrParent(tokenId)
        checkFrozenToken(tokenId)
    {
        /// @notice ERC20 Transfer also emit.
        super._transfer(from, to, tokenId, value);
        Forest.Tx memory txn = _transaction(tokenId);
        emit Transfer(from, to, txn.root, txn.parent, value);
    }

    function mint(address account, uint256 value) public {
        _mintTransaction(account, value);
    }

    function burn(address account, bytes32 tokenId, uint256 value) public {
        _burnTransaction(account, tokenId, value);
    }
}
