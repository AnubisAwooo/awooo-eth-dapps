// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IGovernor.sol";

/**
 * IGovernor 拓展支持 时间锁定
 * @dev Extension of the {IGovernor} for timelock supporting modules.
 *
 * _Available since v4.3._
 */
abstract contract IGovernorTimelock is IGovernor {
    event ProposalQueued(uint256 proposalId, uint256 eta); // 提案队列中事件

    // 时间锁定 公开函数 只读 可重写
    function timelock() public view virtual returns (address);

    // 提案？？ 公开函数 只读 可重写
    function proposalEta(uint256 proposalId) public view virtual returns (uint256);

    // 提案进入队列 公开函数 可重写
    function queue(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        bytes32 descriptionHash
    ) public virtual returns (uint256 proposalId);
}
