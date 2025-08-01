// SPDX-License-Identifier: Apache-2.0

import {Forest} from "../libraries/Forest.sol";
import {IERC5615} from "../interfaces/IERC5615.sol";
import {IERC1155} from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import {IERC1155Errors} from "@openzeppelin/contracts/interfaces/draft-IERC6093.sol";
import {ERC1155Utils} from "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Utils.sol";
import {IERC165, ERC165} from "@openzeppelin/contracts/utils/introspection/ERC165.sol";

/**
 * @title Forest Token V2
 * @dev Abstract contract implementing ERC1155 functionalities with transaction management using the Forest library.
 * @notice This contract manages transactions in a forest-like structure using the Forest library.
 * @author Sirawit Techavanitch (sirawit_tec@live4.utcc.ac.th)
 */

abstract contract ForestTokenV2 is ERC165, IERC1155, IERC1155Errors, IERC5615 {
    /** @custom:library */
    using Forest for Forest.DAG;

    /** @custom:storage */
    string private _name;
    string private _symbol;
    string private _uri;
    uint256 private _totalSupplyAll;

    mapping(uint256 => uint256) private _totalSupply;
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    Forest.DAG private _dag;

    /** @custom:constructor */
    constructor(string memory name_, string memory symbol_, string memory uri_) {
        _name = name_;
        _symbol = symbol_;
        _uri = uri_;
    }

    /** @custom:function-private */
    /**
     * @dev helper function from openzeppelin implementation.
     */
    function _asSingletonArrays(
        uint256 element1,
        uint256 element2
    ) private pure returns (uint256[] memory array1, uint256[] memory array2) {
        assembly ("memory-safe") {
            // Load the free memory pointer
            array1 := mload(0x40)
            // Set array length to 1
            mstore(array1, 1)
            // Store the single element at the next word after the length (where content starts)
            mstore(add(array1, 0x20), element1)

            // Repeat for next array locating it right after the first array
            array2 := add(array1, 0x40)
            mstore(array2, 1)
            mstore(add(array2, 0x20), element2)

            // Update the free memory pointer by pointing after the second array
            mstore(0x40, add(array2, 0x40))
        }
    }

    /** @custom:function-internal */
    function _acceptanceCheck(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory values,
        bytes memory data
    ) internal virtual {
        if (to != address(0)) {
            if (ids.length == 1) {
                ERC1155Utils.checkOnERC1155Received(msg.sender, from, to, ids[0], values[0], data);
            } else {
                ERC1155Utils.checkOnERC1155BatchReceived(msg.sender, from, to, ids, values, data);
            }
        }
    }

    function _mint(address to, uint256 value, bytes memory data) internal returns (uint256 id) {
        // createTxn will auto generate new id.
        id = uint256(_dag.createTxn(Forest.Txn(bytes32(0), bytes32(0), value, 0, to), address(0)));
        _totalSupply[id] += value;
        _totalSupplyAll += value;

        emit TransferSingle(msg.sender, address(0), to, id, value);

        (uint256[] memory ids, uint256[] memory values) = _asSingletonArrays(id, value);
        _acceptanceCheck(address(0), to, ids, values, data);
    }

    function _mintBatch(address to, uint256[] memory values, bytes memory data) internal {
        if (to == address(0)) revert();
        uint256 valueLength = values.length;
        uint256 totalSupplyAll;
        uint256[] memory ids = new uint256[](valueLength);
        for (uint256 i = 0; i < valueLength; i++) {
            uint256 value = values[i];
            ids[i] = uint256(_dag.createTxn(Forest.Txn(bytes32(0), bytes32(0), value, 0, to), address(0)));

            totalSupplyAll += value;
        }
        _totalSupplyAll += totalSupplyAll;

        emit TransferBatch(msg.sender, address(0), to, ids, values);

        _acceptanceCheck(address(0), to, ids, values, data);
    }

    function _burn(address from, uint256 id, uint256 value) internal {
        if (from == address(0)) {
            revert ERC1155InvalidSender(address(0));
        }
        _dag.spendTxn(bytes32(id), from, address(0), value);
        unchecked {
            _totalSupply[id] -= value;
            _totalSupplyAll -= value;
        }

        emit TransferSingle(msg.sender, from, address(0), id, value);
    }

    function _burnBatch(address from, uint256[] memory ids, uint256[] memory values) internal {
        if (ids.length != values.length) {
            revert ERC1155InvalidArrayLength(ids.length, values.length);
        }
        if (from == address(0)) {
            revert ERC1155InvalidSender(address(0));
        }
        uint256 totalSupplyAll =  _totalSupply;
        unchecked {
            for (uint256 i = 0; i < ids.length; ++)i {
                _dag.spendTxn(bytes32(ids[i]), from, address(0), values[i]);
                totalSupplyAll -= values[i];
            }
        }
        _totalSupplyAll = totalSupplyAll;

        emit TransferBatch(msg.sender, from, address(0), ids, values);
    }

    function _safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 value,
        bytes memory data
    ) internal virtual {
        if (to == address(0)) {
            revert ERC1155InvalidReceiver(address(0));
        }
        if (from == address(0)) {
            revert ERC1155InvalidSender(address(0));
        }
        _dag.spendTxn(bytes32(id), from, to, value);

        emit TransferSingle(msg.sender, from, to, id, value);

        (uint256[] memory ids, uint256[] memory values) = _asSingletonArrays(id, value);
        _acceptanceCheck(address(0), to, ids, values, data);
    }

    function _safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory values,
        bytes memory data
    ) internal virtual {
        if (ids.length != values.length) {
            revert ERC1155InvalidArrayLength(ids.length, values.length);
        }
        if (to == address(0)) {
            revert ERC1155InvalidReceiver(address(0));
        }
        if (from == address(0)) {
            revert ERC1155InvalidSender(address(0));
        }

        for (uint256 i = 0; i < ids.length; ++i) {
            _dag.spendTxn(bytes32(ids[i]), from, to, values[i]);
        }

        emit TransferBatch(msg.sender, from, to, ids, values);

        _acceptanceCheck(address(0), to, ids, values, data);
    }

    function _setApprovalForAll(address owner, address operator, bool approved) internal virtual {
        if (operator == address(0)) {
            revert ERC1155InvalidOperator(address(0));
        }
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    function _setURI(string memory uri) internal virtual {
        _uri = uri;
    }

    /** @custom:function-public */
    /** @dev See {IERC1155.balanceOf}. */
    function balanceOf(address account, uint256 id) public view virtual override returns (uint256) {
        return _dag.getTxnValue(bytes32(id));
    }

    /** @dev See {IERC1155.balanceOfBatch}. */
    function balanceOfBatch(
        address[] calldata accounts,
        uint256[] calldata ids
    ) public view virtual override returns (uint256[] memory) {
        if (accounts.length != ids.length) {
            revert ERC1155InvalidArrayLength(ids.length, accounts.length);
        }

        uint256[] memory batchBalances = new uint256[](accounts.length);

        for (uint256 i = 0; i < accounts.length; ++i) {
            batchBalances[i] = _dag.getTxnValue(bytes32(ids[i]));
        }
    }

    /** @dev See {IERC1155.isApprovedForAll}. */
    function isApprovedForAll(address account, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[account][operator];
    }

    /** @dev See {IERC20-totalSupply}. */
    function totalSupply() public view returns (uint256) {
        return _totalSupplyAll;
    }

    /** @dev See {IERC20Metadata.name}. */
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /** @dev See {IERC20Metadata.decimals}. */
    function decimals() public pure virtual returns (uint8) {
        return 18;
    }

    /** @dev See {IERC20Metadata.symbol}. */
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    /** @dev See {IERC1155.uri}. */
    function uri(uint256 /** id */) public view returns (string memory) {
        return _uri;
    }

    /** @dev See {IERC1155.safeTransferFrom}. */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 value,
        bytes memory data
    ) public virtual override {
        address sender = msg.sender;
        if (from != sender && !isApprovedForAll(from, sender)) {
            revert ERC1155MissingApprovalForAll(sender, from);
        }
        _safeTransferFrom(from, to, id, value, data);
    }

    /** @dev See {IERC1155.safeBatchTransferFrom}. */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory values,
        bytes memory data
    ) public virtual override {
        address sender = msg.sender;
        if (from != sender && !isApprovedForAll(from, sender)) {
            revert ERC1155MissingApprovalForAll(sender, from);
        }
        _safeBatchTransferFrom(from, to, ids, values, data);
    }

    /** @dev See {IERC1155.safeBatchTransferFrom}. */
    function setApprovalForAll(address operator, bool approved) public virtual {
        _setApprovalForAll(msg.sender, operator, approved);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC1155).interfaceId ||
            interfaceId == type(IERC5615).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /** @dev See {IERC5615-exists}. */
    function exists(uint256 id) external view returns (bool) {
        return _dag.contains(bytes32(id));
    }

    /** @dev See {IERC5615-totalSupply}. */
    function totalSupply(uint256 id) public view returns (uint256) {
        return _dag.getTxnValue(bytes32(id));
    }
}
