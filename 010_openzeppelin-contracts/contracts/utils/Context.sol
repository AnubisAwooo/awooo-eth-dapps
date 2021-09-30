// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * 为当前执行内容提供信息 包括交易的发送者和交易数据。
 * 尽管这些信息可以通过 msg.sender 和 msg.data 获取，但不应该通过这种方式直接取得，因为发送并支付执行的账户可能并不是实际的调用者。
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    /// 获取当前执行的调用者 内部函数 只读 可被重写
    /// 仅是上级调用者
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    /// 获取当前执行的调用数据 内部函数 只读 可被重写
    /// 仅是上级调用者带的数据 同类型还有 msg.sig  msg.value
    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}
