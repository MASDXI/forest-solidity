// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "../policies/FreezeAddress.sol";
import "../policies/FreezePartialTokens.sol";

contract MockERC20 is ERC20, FreezeAddress, FreezePartialTokens {
    constructor(string memory name_, string memory symbol_) ERC20(name_, symbol_) {}

    function transfer(
        address to,
        uint256 value
    )
        public
        override
        checkFrozenBalance(msg.sender, balanceOf(msg.sender))
        checkFrozenAddress(msg.sender, to)
        returns (bool)
    {
        return super.transfer(to, value);
    }

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) public override checkFrozenBalance(from, balanceOf(from)) checkFrozenAddress(from, to) returns (bool) {
        return super.transferFrom(from, to, value);
    }

    function mint(address account, uint256 value) public {
        _mint(account, value);
    }
}
