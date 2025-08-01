// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.8.0 <0.9.0;

/**
 * @title FreezeAddress
 * @dev Abstract contract for managing frozen addresses, not implementing access control.
 * @notice This contract allows freezing and unfreezing of addresses. It does not include access control mechanisms.
 * @author Sirawit Techavanitch (sirawit_tec@live4.utcc.ac.th)
 */

abstract contract FreezeAddress {
    /** @custom:storage */
    mapping(address => bool) private _frozen;

    /** @custom:errors */
    error AddressFrozen();
    error AddressNotFrozen();

    /** @custom:events */
    event FrozenAddress(address indexed account, bool indexed auth);

    /** @custom:modifier */
    modifier checkFrozenAddress(address from, address to) {
        if (isFrozen(from) || isFrozen(to)) {
            revert AddressFrozen();
        }
        _;
    }

    /** @custom:function-private */
    /**
     * @notice Internal function to update the frozen status of an address.
     * @param account The address to update.
     * @param auth The new frozen status. True to freeze the address, false to unfreeze.
     */
    function _updateFreezeAddress(address account, bool auth) private {
        _frozen[account] = auth;
        emit FrozenAddress(account, auth);
    }

    /**
     * @notice Freezes the specified address.
     * @param account The address to freeze.
     */
    function freezeAddress(address account) public {
        if (_frozen[account]) {
            revert AddressFrozen();
        }
        _updateFreezeAddress(account, true);
    }

    /**
     * @notice Unfreezes the specified address.
     * @param account The address to unfreeze.
     */
    function unfreezeAddress(address account) public {
        if (!_frozen[account]) {
            revert AddressNotFrozen();
        }
        _updateFreezeAddress(account, false);
    }

    /**
     * @notice Checks if the specified address is frozen.
     * @param account The address to check.
     * @return A boolean indicating if the address is frozen (true) or not (false).
     */
    function isFrozen(address account) public view returns (bool) {
        return _frozen[account];
    }
}
