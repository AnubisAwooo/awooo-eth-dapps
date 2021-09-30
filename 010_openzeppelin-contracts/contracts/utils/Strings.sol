// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * 字符串操作
 * @dev String operations.
 */
library Strings {
    /// 16 进制字符常量
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * 256 位无符号数字转变成 10 进制字符串  内部函数 纯函数
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        // 统计数字长度 10 进制长度
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits); // 指定长度的字节数组
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10))); // 存入对应数字的字符
            value /= 10;
        }
        return string(buffer); // 将字节数组转变成字符串
    }

    /**
     * 256 无符号数字变成 16 进制表示的数字字符串 内部函数 纯函数
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        // 计算长度 多少个 8 位
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * 256 无符号数字变成 16 进制表示的数字字符串 内部函数 纯函数
     * length 输入的不对的话，会出错
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}
