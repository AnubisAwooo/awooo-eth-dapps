// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * 计数工具
 * @title Counters
 * @author Matt Condon (@shrugs)
 * 提供一个只能够增加 减少 或 重置的计数器。可以用于追踪元素的个数，如 ERC721 标准 ids 或者 统计请求 ids
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        //  这个变量不应该被用户直接访问：交互必须受到库函数限制。 在 solidity 0.5.2 版本，这不是强制的，所以有一个新的 issue4637 提议增加这个特性。
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    // 获取当前计数器的数值 内部函数 只读
    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    // 计数器自增 1 内部函数
    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    // 计数器自减 1 内部函数
    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    // 计数器重置为 0 内部函数
    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}
