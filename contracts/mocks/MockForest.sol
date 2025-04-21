// // SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.8.0 <0.9.0;

import "../abstracts/ForestToken.sol";
import "../abstracts/extensions/FreezeAddress.sol";
import "../abstracts/extensions/FreezeBalance.sol";
import "../abstracts/extensions/FreezeToken.sol";

contract MockForest is ForestToken, FreezeAddress, FreezeBalance, FreezeToken {
    enum RESTRICT_TYPES { NULL, EQUAL, LESS, GREATER, BETWEEN }

    struct Restrict {
        RESTRICT_TYPES types;
        bool enable;
        uint256 start;
        uint256 end;
    }

    mapping(bytes32 => Restrict) private _restricts;

    /// @custom:event for keep tracking token from root.
    event Transfer(address from, address to, bytes32 indexed root, bytes32 indexed parent, uint256 value);

    constructor(string memory name_, string memory symbol_) ForestToken(name_, symbol_) {}

    modifier checkFrozenRootOrParent(bytes32 tokenId) {
        Forest.Txn memory transaction = _transaction(tokenId);
        if (isTokenFrozen(transaction.root) || isTokenFrozen(transaction.parent)) {
            revert TokenFrozen();
        }
        _;
    }

    modifier checkFrozenLevel(bytes32 tokenId) {
        Restrict memory restrict = getPartition(tokenId);
        if (restrict.types == RESTRICT_TYPES.EQUAL && (restrict.enable)) {
            if (transactionLevel(tokenId) == restrict.start) {
                revert TokenFrozen();
            }
        }
        _;
    }

    modifier checkFrozenBeforeLevel(bytes32 tokenId) {
        Restrict memory restrict = getPartition(tokenId);
        if (restrict.types == RESTRICT_TYPES.LESS && (restrict.enable)) {
            if (transactionLevel(tokenId) < restrict.start) {
                revert TokenFrozen();
            }
        }
        _;
    }
    
    modifier checkFrozenAfterLevel(bytes32 tokenId) {
        Restrict memory restrict = getPartition(tokenId);
        uint256 txnLevel = transactionLevel(tokenId);
        if (restrict.types == RESTRICT_TYPES.GREATER && (restrict.enable)) {
            if (transactionLevel(tokenId) > restrict.start && txnLevel < restrict.end) {
                revert TokenFrozen();
            }
        }
        _;
    }
    
    /** @dev restrict in partitioning style */
    modifier checkFrozenInBetweenLevel(bytes32 tokenId) {
        // check root equal check greater than 'x' and less than 'y'
        Restrict memory restrict = getPartition(tokenId);
        uint256 txnLevel = transactionLevel(tokenId);
        if (restrict.types == RESTRICT_TYPES.BETWEEN && (restrict.enable)) {
            if (txnLevel > restrict.start && txnLevel < restrict.end) {
                revert TokenFrozen();
            }
        }
        _;
    }
    
    /** @notice ERC20 Transfer also emit. */ 
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
        
        super._transfer(from, to, tokenId, value);
        Forest.Txn memory txn = _transaction(tokenId);
        emit Transfer(from, to, txn.root, txn.parent, value);
    }

    function mint(address account, uint256 value) public {
        _mintTransaction(account, value);
    }

    function burn(address account, bytes32 tokenId, uint256 value) public {
        _burnTransaction(account, tokenId, value);
    }

    function setPartition(bytes32 tokenId, uint256 start, uint256 end, RESTRICT_TYPES restrict) public {
        bytes32 rootTokenId = transactionRoot(tokenId);
        _restricts[rootTokenId].types = restrict;
        _restricts[rootTokenId].enable = true;
        _restricts[rootTokenId].start = start;
        _restricts[rootTokenId].end = end;
    }

    function clearPartition(bytes32 tokenId) public {
        delete _restricts[transactionRoot(tokenId)];
    }

    function getPartition(bytes32 tokenId) public view returns (Restrict memory) {
        return _restricts[transactionRoot(tokenId)];
    }
}
