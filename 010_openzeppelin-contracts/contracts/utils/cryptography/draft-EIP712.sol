// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ECDSA.sol";

/**
 * EIP712 是一个 hash 和 sign 类型结构数据的标准。
 * @dev https://eips.ethereum.org/EIPS/eip-712[EIP 712] is a standard for hashing and signing of typed structured data.
 *
 * 编码特殊内容很常见，但在 Solidity 里面却不容易实现。本合约不实现具体的编码。本协议要求联合使用 abi.encode 和 keccak256对需要的类型信息进行编码。
 * The encoding specified in the EIP is very generic, and such a generic implementation in Solidity is not feasible,
 * thus this contract does not implement the encoding itself. Protocols need to implement the type-specific encoding
 * they need in their contracts using a combination of `abi.encode` and `keccak256`.
 *
 * 本合约要求实现 EIP712 域分隔符，作为编码格式的一部分。下一步通过 ECDSA 签名获得的数字信息
 * This contract implements the EIP 712 domain separator ({_domainSeparatorV4}) that is used as part of the encoding
 * scheme, and the final step of the encoding to obtain the message digest that is then signed via ECDSA
 * ({_hashTypedDataV4}).
 *
 * 域分分隔符实现被设计成尽可能高效，并避免在其他分叉链上进行重放攻击。
 * The implementation of the domain separator was designed to be as efficient as possible while still properly updating
 * the chain id to protect against replay attacks on an eventual fork of the chain.
 *
 * tips 注释也不是一个人写的，有的人用 Note 有的人用 NOTE
 * 本合约实现的版本被称为 v4 ...
 * NOTE: This contract implements the version of the encoding known as "v4", as implemented by the JSON RPC method
 * https://docs.metamask.io/guide/signing-data.html[`eth_signTypedDataV4` in MetaMask].
 *
 * _Available since v3.4._
 */
abstract contract EIP712 {
    /* solhint-disable var-name-mixedcase */
    // 缓存域分隔符作为不可变变量，同时缓存与之相符的链 id，为了当链 id 更改时使域分隔符失效。
    // Cache the domain separator as an immutable value, but also store the chain id that it corresponds to, in order to
    // invalidate the cached domain separator if the chain id changes.
    bytes32 private immutable _CACHED_DOMAIN_SEPARATOR; // 缓存域分隔符
    uint256 private immutable _CACHED_CHAIN_ID; // 缓存链 ID

    bytes32 private immutable _HASHED_NAME; // name 的 hash
    bytes32 private immutable _HASHED_VERSION; // version 的 hash
    bytes32 private immutable _TYPE_HASH; // 类型 hash

    /* solhint-enable var-name-mixedcase */

    /**
     * 构造器 初始化域分隔符 和 参数缓存
     * @dev Initializes the domain separator and parameter caches.
     *
     * The meaning of `name` and `version` is specified in
     * https://eips.ethereum.org/EIPS/eip-712#definition-of-domainseparator[EIP 712]:
     *
     * - name：签名域用户可读的名称 例如 dapp 或协议的名字
     * - `name`: the user readable name of the signing domain, i.e. the name of the DApp or the protocol.
     * - version：签名域的当前主要版本
     * - `version`: the current major version of the signing domain.
     *
     * NOTE: These parameters cannot be changed except through a xref:learn::upgrading-smart-contracts.adoc[smart
     * contract upgrade].
     */
    constructor(string memory name, string memory version) {
        bytes32 hashedName = keccak256(bytes(name)); // name 的 hash
        bytes32 hashedVersion = keccak256(bytes(version)); // version 的 hash
        // 这个像方法签名那种
        bytes32 typeHash = keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );
        _HASHED_NAME = hashedName;
        _HASHED_VERSION = hashedVersion;
        _CACHED_CHAIN_ID = block.chainid; // 直接读取链 id
        _CACHED_DOMAIN_SEPARATOR = _buildDomainSeparator(typeHash, hashedName, hashedVersion); // what？貌似和链 id 没啥关系 方法内部使用的 chainid
        _TYPE_HASH = typeHash;
    }

    /**
     * 获取当前链的域分隔符 内部函数 只读
     * @dev Returns the domain separator for the current chain.
     */
    function _domainSeparatorV4() internal view returns (bytes32) {
        if (block.chainid == _CACHED_CHAIN_ID) {
            return _CACHED_DOMAIN_SEPARATOR;
        } else {
            return _buildDomainSeparator(_TYPE_HASH, _HASHED_NAME, _HASHED_VERSION); // 如果链 id 换了，就重新计算
        }
    }

    // 计算域分隔符 私有函数 只读
    function _buildDomainSeparator(
        bytes32 typeHash,
        bytes32 nameHash,
        bytes32 versionHash
    ) private view returns (bytes32) {
        return keccak256(abi.encode(typeHash, nameHash, versionHash, block.chainid, address(this))); // 合约地址也包含在内
    }

    /**
     * 获取全部编码的 EIP712 信息的 hash
     * @dev Given an already https://eips.ethereum.org/EIPS/eip-712#definition-of-hashstruct[hashed struct], this
     * function returns the hash of the fully encoded EIP712 message for this domain.
     *
     * This hash can be used together with {ECDSA-recover} to obtain the signer of a message. For example:
     *
     * ```solidity
     * bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(
     *     keccak256("Mail(address to,string contents)"),
     *     mailTo,
     *     keccak256(bytes(mailContents))
     * )));
     * address signer = ECDSA.recover(digest, signature);
     * ```
     */
    function _hashTypedDataV4(bytes32 structHash) internal view virtual returns (bytes32) {
        return ECDSA.toTypedDataHash(_domainSeparatorV4(), structHash);
    }
}
