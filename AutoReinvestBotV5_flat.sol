// SPDX-License-Identifier: MIT
// Sources flattened with hardhat v2.28.6 https://hardhat.org


// File @openzeppelin/contracts/utils/introspection/IERC165.sol@v5.6.1

// Original license: SPDX_License_Identifier: MIT
// OpenZeppelin Contracts (last updated v5.4.0) (utils/introspection/IERC165.sol)

pragma solidity >=0.4.16;

/**
 * @dev Interface of the ERC-165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[ERC].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[ERC section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}


// File @openzeppelin/contracts/interfaces/IERC165.sol@v5.6.1

// Original license: SPDX_License_Identifier: MIT
// OpenZeppelin Contracts (last updated v5.4.0) (interfaces/IERC165.sol)

pragma solidity >=0.4.16;


// File @openzeppelin/contracts/token/ERC20/IERC20.sol@v5.6.1

// Original license: SPDX_License_Identifier: MIT
// OpenZeppelin Contracts (last updated v5.4.0) (token/ERC20/IERC20.sol)

pragma solidity >=0.4.16;

/**
 * @dev Interface of the ERC-20 standard as defined in the ERC.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the value of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the value of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves a `value` amount of tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 value) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets a `value` amount of tokens as the allowance of `spender` over the
     * caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 value) external returns (bool);

    /**
     * @dev Moves a `value` amount of tokens from `from` to `to` using the
     * allowance mechanism. `value` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 value) external returns (bool);
}


// File @openzeppelin/contracts/interfaces/IERC20.sol@v5.6.1

// Original license: SPDX_License_Identifier: MIT
// OpenZeppelin Contracts (last updated v5.4.0) (interfaces/IERC20.sol)

pragma solidity >=0.4.16;


// File @openzeppelin/contracts/interfaces/IERC1363.sol@v5.6.1

// Original license: SPDX_License_Identifier: MIT
// OpenZeppelin Contracts (last updated v5.4.0) (interfaces/IERC1363.sol)

pragma solidity >=0.6.2;


/**
 * @title IERC1363
 * @dev Interface of the ERC-1363 standard as defined in the https://eips.ethereum.org/EIPS/eip-1363[ERC-1363].
 *
 * Defines an extension interface for ERC-20 tokens that supports executing code on a recipient contract
 * after `transfer` or `transferFrom`, or code on a spender contract after `approve`, in a single transaction.
 */
interface IERC1363 is IERC20, IERC165 {
    /*
     * Note: the ERC-165 identifier for this interface is 0xb0202a11.
     * 0xb0202a11 ===
     *   bytes4(keccak256('transferAndCall(address,uint256)')) ^
     *   bytes4(keccak256('transferAndCall(address,uint256,bytes)')) ^
     *   bytes4(keccak256('transferFromAndCall(address,address,uint256)')) ^
     *   bytes4(keccak256('transferFromAndCall(address,address,uint256,bytes)')) ^
     *   bytes4(keccak256('approveAndCall(address,uint256)')) ^
     *   bytes4(keccak256('approveAndCall(address,uint256,bytes)'))
     */

    /**
     * @dev Moves a `value` amount of tokens from the caller's account to `to`
     * and then calls {IERC1363Receiver-onTransferReceived} on `to`.
     * @param to The address which you want to transfer to.
     * @param value The amount of tokens to be transferred.
     * @return A boolean value indicating whether the operation succeeded unless throwing.
     */
    function transferAndCall(address to, uint256 value) external returns (bool);

    /**
     * @dev Moves a `value` amount of tokens from the caller's account to `to`
     * and then calls {IERC1363Receiver-onTransferReceived} on `to`.
     * @param to The address which you want to transfer to.
     * @param value The amount of tokens to be transferred.
     * @param data Additional data with no specified format, sent in call to `to`.
     * @return A boolean value indicating whether the operation succeeded unless throwing.
     */
    function transferAndCall(address to, uint256 value, bytes calldata data) external returns (bool);

    /**
     * @dev Moves a `value` amount of tokens from `from` to `to` using the allowance mechanism
     * and then calls {IERC1363Receiver-onTransferReceived} on `to`.
     * @param from The address which you want to send tokens from.
     * @param to The address which you want to transfer to.
     * @param value The amount of tokens to be transferred.
     * @return A boolean value indicating whether the operation succeeded unless throwing.
     */
    function transferFromAndCall(address from, address to, uint256 value) external returns (bool);

    /**
     * @dev Moves a `value` amount of tokens from `from` to `to` using the allowance mechanism
     * and then calls {IERC1363Receiver-onTransferReceived} on `to`.
     * @param from The address which you want to send tokens from.
     * @param to The address which you want to transfer to.
     * @param value The amount of tokens to be transferred.
     * @param data Additional data with no specified format, sent in call to `to`.
     * @return A boolean value indicating whether the operation succeeded unless throwing.
     */
    function transferFromAndCall(address from, address to, uint256 value, bytes calldata data) external returns (bool);

    /**
     * @dev Sets a `value` amount of tokens as the allowance of `spender` over the
     * caller's tokens and then calls {IERC1363Spender-onApprovalReceived} on `spender`.
     * @param spender The address which will spend the funds.
     * @param value The amount of tokens to be spent.
     * @return A boolean value indicating whether the operation succeeded unless throwing.
     */
    function approveAndCall(address spender, uint256 value) external returns (bool);

    /**
     * @dev Sets a `value` amount of tokens as the allowance of `spender` over the
     * caller's tokens and then calls {IERC1363Spender-onApprovalReceived} on `spender`.
     * @param spender The address which will spend the funds.
     * @param value The amount of tokens to be spent.
     * @param data Additional data with no specified format, sent in call to `spender`.
     * @return A boolean value indicating whether the operation succeeded unless throwing.
     */
    function approveAndCall(address spender, uint256 value, bytes calldata data) external returns (bool);
}


// File @openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol@v5.6.1

// Original license: SPDX_License_Identifier: MIT
// OpenZeppelin Contracts (last updated v5.5.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.20;


/**
 * @title SafeERC20
 * @dev Wrappers around ERC-20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    /**
     * @dev An operation with an ERC-20 token failed.
     */
    error SafeERC20FailedOperation(address token);

    /**
     * @dev Indicates a failed `decreaseAllowance` request.
     */
    error SafeERC20FailedDecreaseAllowance(address spender, uint256 currentAllowance, uint256 requestedDecrease);

    /**
     * @dev Transfer `value` amount of `token` from the calling contract to `to`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        if (!_safeTransfer(token, to, value, true)) {
            revert SafeERC20FailedOperation(address(token));
        }
    }

    /**
     * @dev Transfer `value` amount of `token` from `from` to `to`, spending the approval given by `from` to the
     * calling contract. If `token` returns no value, non-reverting calls are assumed to be successful.
     */
    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        if (!_safeTransferFrom(token, from, to, value, true)) {
            revert SafeERC20FailedOperation(address(token));
        }
    }

    /**
     * @dev Variant of {safeTransfer} that returns a bool instead of reverting if the operation is not successful.
     */
    function trySafeTransfer(IERC20 token, address to, uint256 value) internal returns (bool) {
        return _safeTransfer(token, to, value, false);
    }

    /**
     * @dev Variant of {safeTransferFrom} that returns a bool instead of reverting if the operation is not successful.
     */
    function trySafeTransferFrom(IERC20 token, address from, address to, uint256 value) internal returns (bool) {
        return _safeTransferFrom(token, from, to, value, false);
    }

    /**
     * @dev Increase the calling contract's allowance toward `spender` by `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     *
     * IMPORTANT: If the token implements ERC-7674 (ERC-20 with temporary allowance), and if the "client"
     * smart contract uses ERC-7674 to set temporary allowances, then the "client" smart contract should avoid using
     * this function. Performing a {safeIncreaseAllowance} or {safeDecreaseAllowance} operation on a token contract
     * that has a non-zero temporary allowance (for that particular owner-spender) will result in unexpected behavior.
     */
    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 oldAllowance = token.allowance(address(this), spender);
        forceApprove(token, spender, oldAllowance + value);
    }

    /**
     * @dev Decrease the calling contract's allowance toward `spender` by `requestedDecrease`. If `token` returns no
     * value, non-reverting calls are assumed to be successful.
     *
     * IMPORTANT: If the token implements ERC-7674 (ERC-20 with temporary allowance), and if the "client"
     * smart contract uses ERC-7674 to set temporary allowances, then the "client" smart contract should avoid using
     * this function. Performing a {safeIncreaseAllowance} or {safeDecreaseAllowance} operation on a token contract
     * that has a non-zero temporary allowance (for that particular owner-spender) will result in unexpected behavior.
     */
    function safeDecreaseAllowance(IERC20 token, address spender, uint256 requestedDecrease) internal {
        unchecked {
            uint256 currentAllowance = token.allowance(address(this), spender);
            if (currentAllowance < requestedDecrease) {
                revert SafeERC20FailedDecreaseAllowance(spender, currentAllowance, requestedDecrease);
            }
            forceApprove(token, spender, currentAllowance - requestedDecrease);
        }
    }

    /**
     * @dev Set the calling contract's allowance toward `spender` to `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful. Meant to be used with tokens that require the approval
     * to be set to zero before setting it to a non-zero value, such as USDT.
     *
     * NOTE: If the token implements ERC-7674, this function will not modify any temporary allowance. This function
     * only sets the "standard" allowance. Any temporary allowance will remain active, in addition to the value being
     * set here.
     */
    function forceApprove(IERC20 token, address spender, uint256 value) internal {
        if (!_safeApprove(token, spender, value, false)) {
            if (!_safeApprove(token, spender, 0, true)) revert SafeERC20FailedOperation(address(token));
            if (!_safeApprove(token, spender, value, true)) revert SafeERC20FailedOperation(address(token));
        }
    }

    /**
     * @dev Performs an {ERC1363} transferAndCall, with a fallback to the simple {ERC20} transfer if the target has no
     * code. This can be used to implement an {ERC721}-like safe transfer that relies on {ERC1363} checks when
     * targeting contracts.
     *
     * Reverts if the returned value is other than `true`.
     */
    function transferAndCallRelaxed(IERC1363 token, address to, uint256 value, bytes memory data) internal {
        if (to.code.length == 0) {
            safeTransfer(token, to, value);
        } else if (!token.transferAndCall(to, value, data)) {
            revert SafeERC20FailedOperation(address(token));
        }
    }

    /**
     * @dev Performs an {ERC1363} transferFromAndCall, with a fallback to the simple {ERC20} transferFrom if the target
     * has no code. This can be used to implement an {ERC721}-like safe transfer that relies on {ERC1363} checks when
     * targeting contracts.
     *
     * Reverts if the returned value is other than `true`.
     */
    function transferFromAndCallRelaxed(
        IERC1363 token,
        address from,
        address to,
        uint256 value,
        bytes memory data
    ) internal {
        if (to.code.length == 0) {
            safeTransferFrom(token, from, to, value);
        } else if (!token.transferFromAndCall(from, to, value, data)) {
            revert SafeERC20FailedOperation(address(token));
        }
    }

    /**
     * @dev Performs an {ERC1363} approveAndCall, with a fallback to the simple {ERC20} approve if the target has no
     * code. This can be used to implement an {ERC721}-like safe transfer that rely on {ERC1363} checks when
     * targeting contracts.
     *
     * NOTE: When the recipient address (`to`) has no code (i.e. is an EOA), this function behaves as {forceApprove}.
     * Oppositely, when the recipient address (`to`) has code, this function only attempts to call {ERC1363-approveAndCall}
     * once without retrying, and relies on the returned value to be true.
     *
     * Reverts if the returned value is other than `true`.
     */
    function approveAndCallRelaxed(IERC1363 token, address to, uint256 value, bytes memory data) internal {
        if (to.code.length == 0) {
            forceApprove(token, to, value);
        } else if (!token.approveAndCall(to, value, data)) {
            revert SafeERC20FailedOperation(address(token));
        }
    }

    /**
     * @dev Imitates a Solidity `token.transfer(to, value)` call, relaxing the requirement on the return value: the
     * return value is optional (but if data is returned, it must not be false).
     *
     * @param token The token targeted by the call.
     * @param to The recipient of the tokens
     * @param value The amount of token to transfer
     * @param bubble Behavior switch if the transfer call reverts: bubble the revert reason or return a false boolean.
     */
    function _safeTransfer(IERC20 token, address to, uint256 value, bool bubble) private returns (bool success) {
        bytes4 selector = IERC20.transfer.selector;

        assembly ("memory-safe") {
            let fmp := mload(0x40)
            mstore(0x00, selector)
            mstore(0x04, and(to, shr(96, not(0))))
            mstore(0x24, value)
            success := call(gas(), token, 0, 0x00, 0x44, 0x00, 0x20)
            // if call success and return is true, all is good.
            // otherwise (not success or return is not true), we need to perform further checks
            if iszero(and(success, eq(mload(0x00), 1))) {
                // if the call was a failure and bubble is enabled, bubble the error
                if and(iszero(success), bubble) {
                    returndatacopy(fmp, 0x00, returndatasize())
                    revert(fmp, returndatasize())
                }
                // if the return value is not true, then the call is only successful if:
                // - the token address has code
                // - the returndata is empty
                success := and(success, and(iszero(returndatasize()), gt(extcodesize(token), 0)))
            }
            mstore(0x40, fmp)
        }
    }

    /**
     * @dev Imitates a Solidity `token.transferFrom(from, to, value)` call, relaxing the requirement on the return
     * value: the return value is optional (but if data is returned, it must not be false).
     *
     * @param token The token targeted by the call.
     * @param from The sender of the tokens
     * @param to The recipient of the tokens
     * @param value The amount of token to transfer
     * @param bubble Behavior switch if the transfer call reverts: bubble the revert reason or return a false boolean.
     */
    function _safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value,
        bool bubble
    ) private returns (bool success) {
        bytes4 selector = IERC20.transferFrom.selector;

        assembly ("memory-safe") {
            let fmp := mload(0x40)
            mstore(0x00, selector)
            mstore(0x04, and(from, shr(96, not(0))))
            mstore(0x24, and(to, shr(96, not(0))))
            mstore(0x44, value)
            success := call(gas(), token, 0, 0x00, 0x64, 0x00, 0x20)
            // if call success and return is true, all is good.
            // otherwise (not success or return is not true), we need to perform further checks
            if iszero(and(success, eq(mload(0x00), 1))) {
                // if the call was a failure and bubble is enabled, bubble the error
                if and(iszero(success), bubble) {
                    returndatacopy(fmp, 0x00, returndatasize())
                    revert(fmp, returndatasize())
                }
                // if the return value is not true, then the call is only successful if:
                // - the token address has code
                // - the returndata is empty
                success := and(success, and(iszero(returndatasize()), gt(extcodesize(token), 0)))
            }
            mstore(0x40, fmp)
            mstore(0x60, 0)
        }
    }

    /**
     * @dev Imitates a Solidity `token.approve(spender, value)` call, relaxing the requirement on the return value:
     * the return value is optional (but if data is returned, it must not be false).
     *
     * @param token The token targeted by the call.
     * @param spender The spender of the tokens
     * @param value The amount of token to transfer
     * @param bubble Behavior switch if the transfer call reverts: bubble the revert reason or return a false boolean.
     */
    function _safeApprove(IERC20 token, address spender, uint256 value, bool bubble) private returns (bool success) {
        bytes4 selector = IERC20.approve.selector;

        assembly ("memory-safe") {
            let fmp := mload(0x40)
            mstore(0x00, selector)
            mstore(0x04, and(spender, shr(96, not(0))))
            mstore(0x24, value)
            success := call(gas(), token, 0, 0x00, 0x44, 0x00, 0x20)
            // if call success and return is true, all is good.
            // otherwise (not success or return is not true), we need to perform further checks
            if iszero(and(success, eq(mload(0x00), 1))) {
                // if the call was a failure and bubble is enabled, bubble the error
                if and(iszero(success), bubble) {
                    returndatacopy(fmp, 0x00, returndatasize())
                    revert(fmp, returndatasize())
                }
                // if the return value is not true, then the call is only successful if:
                // - the token address has code
                // - the returndata is empty
                success := and(success, and(iszero(returndatasize()), gt(extcodesize(token), 0)))
            }
            mstore(0x40, fmp)
        }
    }
}


// File @openzeppelin/contracts/utils/StorageSlot.sol@v5.6.1

// Original license: SPDX_License_Identifier: MIT
// OpenZeppelin Contracts (last updated v5.1.0) (utils/StorageSlot.sol)
// This file was procedurally generated from scripts/generate/templates/StorageSlot.js.

pragma solidity ^0.8.20;

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC-1967 implementation slot:
 * ```solidity
 * contract ERC1967 {
 *     // Define the slot. Alternatively, use the SlotDerivation library to derive the slot.
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(newImplementation.code.length > 0);
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * TIP: Consider using this library along with {SlotDerivation}.
 */
library StorageSlot {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    struct Int256Slot {
        int256 value;
    }

    struct StringSlot {
        string value;
    }

    struct BytesSlot {
        bytes value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        assembly ("memory-safe") {
            r.slot := slot
        }
    }

    /**
     * @dev Returns a `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        assembly ("memory-safe") {
            r.slot := slot
        }
    }

    /**
     * @dev Returns a `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        assembly ("memory-safe") {
            r.slot := slot
        }
    }

    /**
     * @dev Returns a `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        assembly ("memory-safe") {
            r.slot := slot
        }
    }

    /**
     * @dev Returns a `Int256Slot` with member `value` located at `slot`.
     */
    function getInt256Slot(bytes32 slot) internal pure returns (Int256Slot storage r) {
        assembly ("memory-safe") {
            r.slot := slot
        }
    }

    /**
     * @dev Returns a `StringSlot` with member `value` located at `slot`.
     */
    function getStringSlot(bytes32 slot) internal pure returns (StringSlot storage r) {
        assembly ("memory-safe") {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `StringSlot` representation of the string storage pointer `store`.
     */
    function getStringSlot(string storage store) internal pure returns (StringSlot storage r) {
        assembly ("memory-safe") {
            r.slot := store.slot
        }
    }

    /**
     * @dev Returns a `BytesSlot` with member `value` located at `slot`.
     */
    function getBytesSlot(bytes32 slot) internal pure returns (BytesSlot storage r) {
        assembly ("memory-safe") {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BytesSlot` representation of the bytes storage pointer `store`.
     */
    function getBytesSlot(bytes storage store) internal pure returns (BytesSlot storage r) {
        assembly ("memory-safe") {
            r.slot := store.slot
        }
    }
}


// File @openzeppelin/contracts/utils/ReentrancyGuard.sol@v5.6.1

// Original license: SPDX_License_Identifier: MIT
// OpenZeppelin Contracts (last updated v5.5.0) (utils/ReentrancyGuard.sol)

pragma solidity ^0.8.20;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If EIP-1153 (transient storage) is available on the chain you're deploying at,
 * consider using {ReentrancyGuardTransient} instead.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 *
 * IMPORTANT: Deprecated. This storage-based reentrancy guard will be removed and replaced
 * by the {ReentrancyGuardTransient} variant in v6.0.
 *
 * @custom:stateless
 */
abstract contract ReentrancyGuard {
    using StorageSlot for bytes32;

    // keccak256(abi.encode(uint256(keccak256("openzeppelin.storage.ReentrancyGuard")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant REENTRANCY_GUARD_STORAGE =
        0x9b779b17422d0df92223018b32b4d1fa46e071723d6817e2486d003becc55f00;

    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant NOT_ENTERED = 1;
    uint256 private constant ENTERED = 2;

    /**
     * @dev Unauthorized reentrant call.
     */
    error ReentrancyGuardReentrantCall();

    constructor() {
        _reentrancyGuardStorageSlot().getUint256Slot().value = NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    /**
     * @dev A `view` only version of {nonReentrant}. Use to block view functions
     * from being called, preventing reading from inconsistent contract state.
     *
     * CAUTION: This is a "view" modifier and does not change the reentrancy
     * status. Use it only on view functions. For payable or non-payable functions,
     * use the standard {nonReentrant} modifier instead.
     */
    modifier nonReentrantView() {
        _nonReentrantBeforeView();
        _;
    }

    function _nonReentrantBeforeView() private view {
        if (_reentrancyGuardEntered()) {
            revert ReentrancyGuardReentrantCall();
        }
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be NOT_ENTERED
        _nonReentrantBeforeView();

        // Any calls to nonReentrant after this point will fail
        _reentrancyGuardStorageSlot().getUint256Slot().value = ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _reentrancyGuardStorageSlot().getUint256Slot().value = NOT_ENTERED;
    }

    /**
     * @dev Returns true if the reentrancy guard is currently set to "entered", which indicates there is a
     * `nonReentrant` function in the call stack.
     */
    function _reentrancyGuardEntered() internal view returns (bool) {
        return _reentrancyGuardStorageSlot().getUint256Slot().value == ENTERED;
    }

    function _reentrancyGuardStorageSlot() internal pure virtual returns (bytes32) {
        return REENTRANCY_GUARD_STORAGE;
    }
}


// File contracts/AutoReinvestBotV5.sol

// Original license: SPDX_License_Identifier: MIT
pragma solidity 0.8.20;



// ── External interfaces ───────────────────────────────────────────────────────

interface IUniswapV3Factory {
    function getPool(address tokenA, address tokenB, uint24 fee) external view returns (address);
}

interface IUniswapV3Pool {
    function slot0() external view returns (
        uint160 sqrtPriceX96,
        int24 tick,
        uint16, uint16, uint16, uint16, bool
    );
}

interface INonfungiblePositionManager {
    struct CollectParams {
        uint256 tokenId;
        address recipient;
        uint128 amount0Max;
        uint128 amount1Max;
    }
    struct IncreaseLiquidityParams {
        uint256 tokenId;
        uint256 amount0Desired;
        uint256 amount1Desired;
        uint256 amount0Min;
        uint256 amount1Min;
        uint256 deadline;
    }
    function collect(CollectParams calldata params) external returns (uint256 amount0, uint256 amount1);
    function positions(uint256 tokenId) external view returns (
        uint96  nonce,
        address operator,
        address token0,
        address token1,
        uint24  fee,
        int24   tickLower,
        int24   tickUpper,
        uint128 liquidity,
        uint256 feeGrowthInside0LastX128,
        uint256 feeGrowthInside1LastX128,
        uint128 tokensOwed0,
        uint128 tokensOwed1
    );
    function increaseLiquidity(IncreaseLiquidityParams calldata params)
        external returns (uint128 liquidity, uint256 amount0, uint256 amount1);
}

interface ISwapRouter {
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24  fee;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }
    function exactInputSingle(ExactInputSingleParams calldata params) external returns (uint256 amountOut);
}

/// @dev Minimal interface for the TIME staking contract
interface ITimeStaking {
    function stake(uint256 amount) external;
    function unstake(uint256 amount) external;
    function claimWldReward() external;
    function pendingWldReward(address staker) external view returns (uint256);
    function stakedBalance(address staker) external view returns (uint256);
    function totalStaked() external view returns (uint256);
}

// ── Main contract ─────────────────────────────────────────────────────────────

contract AutoReinvestBotV5 is ReentrancyGuard {
    using SafeERC20 for IERC20;

    // ── World Chain — Uniswap V3 (lowercase, no checksum needed) ─────────────
    // solhint-disable-next-line
    address public constant POSITION_MANAGER = 0xec12a9F9a09f50550686363766Cc153D03c27b5e;
    // solhint-disable-next-line
    address public constant SWAP_ROUTER      = 0x091AD9e2e6e5eD44c1c66dB50e49A601F9f36cF6;
    // solhint-disable-next-line
    address public constant UNISWAP_FACTORY  = 0x7a5028BDa40e7B173C278C5342087826455ea25a;

    // ── Tokens & staking ──────────────────────────────────────────────────────
    address public immutable WLD;
    address public immutable H2O;
    address public immutable BTCH2O;
    address public immutable TIME_TOKEN;
    address public immutable STAKING_CONTRACT;   // TIME staking → rewards in WLD

    // ── Multi-owner ───────────────────────────────────────────────────────────
    address public primaryOwner;
    mapping(address => bool) public isOwner;
    address[] public ownerList;

    // ── Config ────────────────────────────────────────────────────────────────
    uint256 public reinvestIntervalSecs;  // target interval (used by off-chain bot)
    uint256 public reserveFeeBps;         // commission kept as reserve (basis points)
    uint256 public h2oShareBps;           // % of remaining → H2O
    uint256 public btch2oShareBps;        // % of remaining → BTCH2O
                                          // remainder → Uniswap V3 liquidity
    bool    public paused;
    uint256 public lastReinvestAt;

    // ── Uniswap V3 positions ──────────────────────────────────────────────────
    mapping(uint256 => bool) public isManaged;
    mapping(uint256 => bool) public inRange;
    uint256[] public managedPositions;

    // ── Reserves (commission wallet) ──────────────────────────────────────────
    mapping(address => uint256) public reserve;

    // ── Events ────────────────────────────────────────────────────────────────
    event OwnerAdded(address indexed owner);
    event OwnerRemoved(address indexed owner);
    event PositionAdded(uint256 indexed tokenId);
    event PositionRemoved(uint256 indexed tokenId);
    event FeesCollected(uint256 indexed tokenId, uint256 amount0, uint256 amount1);
    event StakingRewardClaimed(uint256 wldAmount);
    event Swapped(address indexed tokenIn, address indexed tokenOut, uint256 amountIn, uint256 amountOut);
    event SwapFailed(address indexed tokenIn, address indexed tokenOut, uint256 amountIn, bytes reason);
    event LiquidityAdded(uint256 indexed tokenId, uint128 liquidity);
    event ReserveWithdrawn(address indexed token, address indexed to, uint256 amount);
    event ConfigUpdated(string key, uint256 value);
    event ContractPaused(bool isPaused);
    event ReinvestCompleted(uint256 timestamp, uint256 totalWLD);
    event TimeStaked(uint256 amount);
    event TimeUnstaked(uint256 amount);

    // ── Modifiers ─────────────────────────────────────────────────────────────

    modifier onlyOwner() {
        require(isOwner[msg.sender], "Not an owner");
        _;
    }

    modifier notPaused() {
        require(!paused, "Contract is paused");
        _;
    }

    // ── Constructor ───────────────────────────────────────────────────────────

    constructor(
        address _WLD,
        address _H2O,
        address _BTCH2O,
        address _timeToken,
        address _stakingContract
    ) {
        WLD              = _WLD;
        H2O              = _H2O;
        BTCH2O           = _BTCH2O;
        TIME_TOKEN       = _timeToken;
        STAKING_CONTRACT = _stakingContract;

        primaryOwner = msg.sender;
        isOwner[msg.sender] = true;
        ownerList.push(msg.sender);

        // Defaults
        reinvestIntervalSecs = 300;   // 5 minutes
        reserveFeeBps        = 200;   // 2 %
        h2oShareBps          = 4000;  // 40 %
        btch2oShareBps       = 3000;  // 30 %
                                      // 30 % → reinvest in Uniswap V3
    }

    // ── Owner management ──────────────────────────────────────────────────────

    function addOwner(address newOwner) external onlyOwner {
        require(newOwner != address(0), "Zero address");
        require(!isOwner[newOwner], "Already owner");
        isOwner[newOwner] = true;
        ownerList.push(newOwner);
        emit OwnerAdded(newOwner);
    }

    function removeOwner(address owner) external {
        require(msg.sender == primaryOwner, "Only primary owner");
        require(owner != primaryOwner, "Cannot remove primary owner");
        require(isOwner[owner], "Not an owner");
        isOwner[owner] = false;
        for (uint256 i = 0; i < ownerList.length; i++) {
            if (ownerList[i] == owner) {
                ownerList[i] = ownerList[ownerList.length - 1];
                ownerList.pop();
                break;
            }
        }
        emit OwnerRemoved(owner);
    }

    function getOwners() external view returns (address[] memory) {
        return ownerList;
    }

    // ── Configuration ─────────────────────────────────────────────────────────

    function setReinvestInterval(uint256 secs) external onlyOwner {
        require(secs >= 60, "Min 60s");
        reinvestIntervalSecs = secs;
        emit ConfigUpdated("reinvestIntervalSecs", secs);
    }

    function setReserveFeeBps(uint256 bps) external onlyOwner {
        require(bps <= 2000, "Max 20%");
        reserveFeeBps = bps;
        emit ConfigUpdated("reserveFeeBps", bps);
    }

    function setDistribution(uint256 _h2oShareBps, uint256 _btch2oShareBps) external onlyOwner {
        require(_h2oShareBps + _btch2oShareBps <= 10000, "Exceeds 100%");
        h2oShareBps    = _h2oShareBps;
        btch2oShareBps = _btch2oShareBps;
        emit ConfigUpdated("h2oShareBps",    _h2oShareBps);
        emit ConfigUpdated("btch2oShareBps", _btch2oShareBps);
    }

    function setPaused(bool _paused) external onlyOwner {
        paused = _paused;
        emit ContractPaused(_paused);
    }

    // ── TIME staking helpers (manual — not automated) ─────────────────────────

    /// @notice Stake TIME tokens from this contract into the TIME staking contract.
    ///         Owner must first send TIME tokens to this contract address.
    function stakeTime(uint256 amount) external onlyOwner {
        require(amount > 0, "Zero amount");
        IERC20(TIME_TOKEN).forceApprove(STAKING_CONTRACT, amount);
        ITimeStaking(STAKING_CONTRACT).stake(amount);
        IERC20(TIME_TOKEN).forceApprove(STAKING_CONTRACT, 0);
        emit TimeStaked(amount);
    }

    /// @notice Unstake TIME tokens from the staking contract back to this contract.
    function unstakeTime(uint256 amount) external onlyOwner {
        require(amount > 0, "Zero amount");
        ITimeStaking(STAKING_CONTRACT).unstake(amount);
        emit TimeUnstaked(amount);
    }

    /// @notice Pending WLD reward for this contract in the TIME staking.
    function pendingStakingReward() external view returns (uint256) {
        return ITimeStaking(STAKING_CONTRACT).pendingWldReward(address(this));
    }

    /// @notice TIME staked by this contract.
    function stakedTimeBalance() external view returns (uint256) {
        return ITimeStaking(STAKING_CONTRACT).stakedBalance(address(this));
    }

    // ── Position management ───────────────────────────────────────────────────

    function addPosition(uint256 tokenId) external onlyOwner {
        require(!isManaged[tokenId], "Already managed");
        managedPositions.push(tokenId);
        isManaged[tokenId] = true;
        _updateRange(tokenId);
        emit PositionAdded(tokenId);
    }

    function removePosition(uint256 tokenId) external onlyOwner {
        require(isManaged[tokenId], "Not managed");
        isManaged[tokenId] = false;
        for (uint256 i = 0; i < managedPositions.length; i++) {
            if (managedPositions[i] == tokenId) {
                managedPositions[i] = managedPositions[managedPositions.length - 1];
                managedPositions.pop();
                break;
            }
        }
        emit PositionRemoved(tokenId);
    }

    function getManagedPositions() external view returns (uint256[] memory) {
        return managedPositions;
    }

    function updateRanges(uint256[] calldata tokenIds) external onlyOwner {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            if (isManaged[tokenIds[i]]) _updateRange(tokenIds[i]);
        }
    }

    function _updateRange(uint256 tokenId) internal {
        (
            ,
            ,
            address t0,
            address t1,
            uint24 fee,
            int24  tLower,
            int24  tUpper,
            ,,,,
        ) = INonfungiblePositionManager(POSITION_MANAGER).positions(tokenId);

        address pool = IUniswapV3Factory(UNISWAP_FACTORY).getPool(t0, t1, fee);
        if (pool != address(0)) {
            (, int24 tick,,,,,) = IUniswapV3Pool(pool).slot0();
            inRange[tokenId] = (tick >= tLower && tick <= tUpper);
        }
    }

    // ── Core: claim staking rewards only ─────────────────────────────────────

    /// @notice Claim WLD rewards from TIME staking and distribute them.
    function claimStakingRewards(uint256 deadline) external onlyOwner notPaused nonReentrant {
        uint256 before = IERC20(WLD).balanceOf(address(this));

        // Claim — if it fails nothing bad happens
        try ITimeStaking(STAKING_CONTRACT).claimWldReward() {
            // success
        } catch {
            // no rewards or error — exit gracefully
            return;
        }

        uint256 gained = IERC20(WLD).balanceOf(address(this)) - before;
        if (gained == 0) return;

        emit StakingRewardClaimed(gained);
        _distributeWLD(gained, managedPositions, deadline);

        lastReinvestAt = block.timestamp;
        emit ReinvestCompleted(block.timestamp, gained);
    }

    // ── Core: collect Uniswap V3 fees only ───────────────────────────────────

    function collectFees(
        uint256[] calldata tokenIds,
        uint256 deadline
    ) external onlyOwner notPaused nonReentrant {
        uint256 totalWLD = _collectUniswapFees(tokenIds);
        if (totalWLD == 0) return;
        _distributeWLD(totalWLD, tokenIds, deadline);
        lastReinvestAt = block.timestamp;
        emit ReinvestCompleted(block.timestamp, totalWLD);
    }

    // ── Core: collect everything in one tx ───────────────────────────────────

    /// @notice Claim TIME staking rewards + collect Uniswap fees + distribute all WLD.
    function collectAll(
        uint256[] calldata tokenIds,
        uint256 deadline
    ) external onlyOwner notPaused nonReentrant {
        uint256 before = IERC20(WLD).balanceOf(address(this));

        // 1 — Claim TIME staking rewards (non-reverting)
        try ITimeStaking(STAKING_CONTRACT).claimWldReward() {
            uint256 stakingGain = IERC20(WLD).balanceOf(address(this)) - before;
            if (stakingGain > 0) emit StakingRewardClaimed(stakingGain);
        } catch { }

        // 2 — Collect Uniswap V3 fees
        _collectUniswapFees(tokenIds);

        // 3 — Distribute all new WLD (balance minus already-accounted reserve)
        uint256 totalNew = IERC20(WLD).balanceOf(address(this)) - before;
        if (totalNew == 0) return;

        _distributeWLD(totalNew, tokenIds, deadline);
        lastReinvestAt = block.timestamp;
        emit ReinvestCompleted(block.timestamp, totalNew);
    }

    // ── Internal helpers ──────────────────────────────────────────────────────

    function _collectUniswapFees(uint256[] calldata tokenIds) internal returns (uint256 totalWLD) {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 id = tokenIds[i];
            if (!isManaged[id]) continue;

            (,, address token0,,,,,,,,,) =
                INonfungiblePositionManager(POSITION_MANAGER).positions(id);

            try INonfungiblePositionManager(POSITION_MANAGER).collect(
                INonfungiblePositionManager.CollectParams({
                    tokenId:    id,
                    recipient:  address(this),
                    amount0Max: type(uint128).max,
                    amount1Max: type(uint128).max
                })
            ) returns (uint256 a0, uint256 a1) {
                emit FeesCollected(id, a0, a1);
                totalWLD += (token0 == WLD ? a0 : a1);
            } catch { }
        }
    }

    /// @notice Distribute WLD: reserve → H2O swap → BTCH2O swap → reinvest in LP.
    ///         Swaps are wrapped in try/catch — failure keeps tokens in contract.
    function _distributeWLD(
        uint256 totalWLD,
        uint256[] memory tokenIds,
        uint256 deadline
    ) internal {
        uint256 reserveAmt = (totalWLD * reserveFeeBps) / 10000;
        reserve[WLD]      += reserveAmt;
        uint256 remaining  = totalWLD - reserveAmt;

        uint256 h2oAmt    = (remaining * h2oShareBps)    / 10000;
        uint256 btch2oAmt = (remaining * btch2oShareBps) / 10000;
        uint256 reinvest  = remaining - h2oAmt - btch2oAmt;

        if (h2oAmt    > 0) _swapSafe(WLD, H2O,    h2oAmt,    deadline);
        if (btch2oAmt > 0) _swapSafe(WLD, BTCH2O, btch2oAmt, deadline);

        if (reinvest > 0 && tokenIds.length > 0) {
            uint256 perPos = reinvest / tokenIds.length;
            for (uint256 i = 0; i < tokenIds.length; i++) {
                if (inRange[tokenIds[i]] && perPos > 0) {
                    _addLiquiditySafe(tokenIds[i], perPos, deadline);
                }
            }
        }
    }

    /// @notice Swap with try/catch — never reverts, failed swaps leave tokens in contract.
    function _swapSafe(
        address tokenIn,
        address tokenOut,
        uint256 amtIn,
        uint256 deadline
    ) internal {
        IERC20(tokenIn).forceApprove(SWAP_ROUTER, amtIn);

        try ISwapRouter(SWAP_ROUTER).exactInputSingle(
            ISwapRouter.ExactInputSingleParams({
                tokenIn:           tokenIn,
                tokenOut:          tokenOut,
                fee:               3000,
                recipient:         address(this),
                deadline:          deadline,
                amountIn:          amtIn,
                amountOutMinimum:  0,       // sin slippage — libre
                sqrtPriceLimitX96: 0
            })
        ) returns (uint256 amtOut) {
            IERC20(tokenIn).forceApprove(SWAP_ROUTER, 0);
            emit Swapped(tokenIn, tokenOut, amtIn, amtOut);
        } catch (bytes memory reason) {
            IERC20(tokenIn).forceApprove(SWAP_ROUTER, 0);
            emit SwapFailed(tokenIn, tokenOut, amtIn, reason);
            // tokens remain in contract — not lost
        }
    }

    /// @notice Add liquidity with try/catch — never reverts.
    function _addLiquiditySafe(
        uint256 tokenId,
        uint256 amtWLD,
        uint256 deadline
    ) internal {
        (,, address token0,,,,,,,,,) =
            INonfungiblePositionManager(POSITION_MANAGER).positions(tokenId);

        address t0Addr = token0 == WLD ? WLD : H2O;
        address t1Addr = token0 == WLD ? H2O : WLD;

        IERC20(t0Addr).forceApprove(POSITION_MANAGER, amtWLD);
        IERC20(t1Addr).forceApprove(POSITION_MANAGER, amtWLD);

        try INonfungiblePositionManager(POSITION_MANAGER).increaseLiquidity(
            INonfungiblePositionManager.IncreaseLiquidityParams({
                tokenId:        tokenId,
                amount0Desired: amtWLD,
                amount1Desired: amtWLD,
                amount0Min:     0,
                amount1Min:     0,
                deadline:       deadline
            })
        ) returns (uint128 liq, uint256, uint256) {
            emit LiquidityAdded(tokenId, liq);
        } catch { }

        IERC20(t0Addr).forceApprove(POSITION_MANAGER, 0);
        IERC20(t1Addr).forceApprove(POSITION_MANAGER, 0);
    }

    // ── Reserve management ────────────────────────────────────────────────────

    function withdrawReserve(address token, uint256 amount, address to) external onlyOwner {
        require(reserve[token] >= amount, "Insufficient reserve");
        reserve[token] -= amount;
        IERC20(token).safeTransfer(to, amount);
        emit ReserveWithdrawn(token, to, amount);
    }

    function withdrawAll(address token, address to) external onlyOwner {
        uint256 bal = IERC20(token).balanceOf(address(this));
        require(bal > 0, "Nothing to withdraw");
        IERC20(token).safeTransfer(to, bal);
        emit ReserveWithdrawn(token, to, bal);
    }

    // ── Views ─────────────────────────────────────────────────────────────────

    function getConfig() external view returns (
        uint256 _reinvestIntervalSecs,
        uint256 _reserveFeeBps,
        uint256 _h2oShareBps,
        uint256 _btch2oShareBps,
        bool    _paused,
        uint256 _lastReinvestAt
    ) {
        return (
            reinvestIntervalSecs,
            reserveFeeBps,
            h2oShareBps,
            btch2oShareBps,
            paused,
            lastReinvestAt
        );
    }

    function getPosition(uint256 tokenId) external view returns (
        address token0,
        address token1,
        uint24  fee,
        int24   tickLower,
        int24   tickUpper,
        uint128 liquidity,
        uint128 tokensOwed0,
        uint128 tokensOwed1,
        bool    managed,
        bool    isInRange
    ) {
        (
            ,
            ,
            token0,
            token1,
            fee,
            tickLower,
            tickUpper,
            liquidity,
            ,
            ,
            tokensOwed0,
            tokensOwed1
        ) = INonfungiblePositionManager(POSITION_MANAGER).positions(tokenId);
        managed   = isManaged[tokenId];
        isInRange = inRange[tokenId];
    }

    function getReserves() external view returns (
        uint256 wldReserve,
        uint256 h2oReserve,
        uint256 btch2oReserve
    ) {
        return (reserve[WLD], reserve[H2O], reserve[BTCH2O]);
    }

    function getStakingInfo() external view returns (
        uint256 stakedTime,
        uint256 pendingWLD,
        uint256 totalStakedInContract
    ) {
        stakedTime            = ITimeStaking(STAKING_CONTRACT).stakedBalance(address(this));
        pendingWLD            = ITimeStaking(STAKING_CONTRACT).pendingWldReward(address(this));
        totalStakedInContract = ITimeStaking(STAKING_CONTRACT).totalStaked();
    }
}
