// SPDX-License-Identifier: Apache-2.0

import {Forest} from "../libraries/Forest.sol";
import {IERC1155} from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import {IERC5615} from "../interfaces/IERC5615.sol";
import {IERC1155Errors} from "@openzeppelin/contracts/interfaces/draft-IERC6093.sol";

/**
 * @title Forest Token V2
 * @dev Abstract contract implementing ERC1155 functionalities with transaction management using the Forest library.
 * @notice This contract manages transactions in a forest-like structure using the Forest library.
 * @author Sirawit Techavanitch (sirawit_tec@live4.utcc.ac.th)
 */

abstract contract ForestTokenV2 is IERC1155, IERC1155Errors, IERC5615 {
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

    /** @custom:function-internal */
    function _mint(address to, uint256 value) internal returns (uint256 id) {
        address operator = msg.sender;
        // createTxn will auto generate new id.
        id = uint256(_dag.createTxn(Forest.Txn(bytes32(0), bytes32(0), value, 0, to), address(0)));
        _totalSupply[id] += value;
        _totalSupplyAll += value;

        emit TransferSingle(operator, address(0), to, id, value);
        // @TODO check on receive
    }

    function _mintBatch(address to, uint256[] memory values, bytes memory data) internal {
        if (to == address(0)) revert();
        uint256 valueLength = values.length;
        address operator = msg.sender;
        uint256 totalSupplyAll;
        uint256[] memory ids = new uint256[](valueLength);
        for (uint256 i = 0; i < valueLength; i++) {
            uint256 value = values[i];
            ids[i] = uint256(_dag.createTxn(Forest.Txn(bytes32(0), bytes32(0), value, 0, to), address(0)));

            totalSupplyAll += value;
        }
        _totalSupplyAll += totalSupplyAll;

        emit TransferBatch(operator, address(0), to, ids, values);
        // @TODO check on receive
    }

    function _burn(address from, uint256 id, uint256 value) internal {
        address operator = msg.sender;
        _dag.spendTxn(bytes32(id), from, address(0), value);
        unchecked {
            _totalSupply[id] -= value;
            _totalSupplyAll -= value;
        }

        emit TransferSingle(operator, from, address(0), id, value);
    }

    function _burnBatch(address from, uint256[] memory ids, uint256[] memory values) internal {
        if (ids.length != values.length) {
            revert ERC1155InvalidArrayLength(ids.length, values.length);
        }
        if (from == address(0)) revert();

        address operator = msg.sender;
        for (uint256 i = 0; i < ids.length; i++) {
            _dag.spendTxn(bytes32(ids[i]), from, address(0), values[i]);
        }

        emit TransferBatch(operator, from, address(0), ids, values);
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
        address operator = msg.sender;
        _dag.spendTxn(bytes32(id), from, to, value);

        emit TransferSingle(operator, from, to, id, value);
        // @TODO check on receive
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

        address operator = msg.sender;

        for (uint256 i = 0; i < ids.length; ++i) {
            _dag.spendTxn(bytes32(ids[i]), from, to, values[i]);
        }

        emit TransferBatch(operator, from, to, ids, values);
        // @TODO check on receive
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
        // @TODO
        // require(from == msg.sender || isApprovedForAll[from][msg.sender], "!OWNER_OR_APPROVED");
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
        // @TODO
        // require(from == msg.sender || isApprovedForAll[from][msg.sender], "!OWNER_OR_APPROVED");
        _safeBatchTransferFrom(from, to, ids, values, data);
    }

    /** @dev See {IERC5615-exists}. */
    function exists(uint256 id) external view returns (bool) {
        return _dag.contains(bytes32(id));
    }

    /** @dev See {IERC5615-totalSupply}. */
    function totalSupply(uint256 id) public view returns (uint256) {
        return _dag.getTxnValue(bytes32(id));
    }

    /** @custom:function-external */
}
