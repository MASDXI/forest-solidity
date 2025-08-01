// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.8.0 <0.9.0;

import "../abstracts/ForestTokenV2.sol";
// import "../policies/FreezeAddress.sol";
// import "../policies/FreezeBalance.sol";

// @TODO
contract MockForestV2 is ForestTokenV2 /**, FreezeAddress, FreezeBalance*/ {
    constructor(string memory name_, string memory symbol_) ForestTokenV2(name_, symbol_, "") {}

    function mint(address account, uint256 value) public {
        _mint(account, value, "");
    }
}
