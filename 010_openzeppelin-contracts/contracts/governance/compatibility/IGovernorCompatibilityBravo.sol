// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IGovernor.sol";

/**
 * 抽象合约 拓展 Governor 合约增加未实现的函数   Bravo是什么意思？？
 * @dev Interface extension that adds missing functions to the {Governor} core to provide `GovernorBravo` compatibility.
 *
 * _Available since v4.3._
 */
abstract contract IGovernorCompatibilityBravo is IGovernor {
    /**
     * 提案和提出者的混合结构体 实际上不给兼容层使用
     * @dev Proposal structure from Compound Governor Bravo. Not actually used by the compatibility layer, as
     * {{proposal}} returns a very different structure.
     */
    struct Proposal {
        uint256 id;
        address proposer;
        uint256 eta;
        address[] targets;
        uint256[] values;
        string[] signatures;
        bytes[] calldatas;
        uint256 startBlock;
        uint256 endBlock;
        uint256 forVotes;
        uint256 againstVotes;
        uint256 abstainVotes;
        bool canceled;
        bool executed;
        mapping(address => Receipt) receipts;
    }

    /**
     * 收据结构体？？
     * @dev Receipt structure from Compound Governor Bravo
     */
    struct Receipt {
        bool hasVoted;
        uint8 support;
        uint96 votes;
    }

    /**
     * 法定票数 公开函数 只读 可重写
     * @dev Part of the Governor Bravo's interface.
     */
    function quorumVotes() public view virtual returns (uint256);

    /**
     * 所有已经提交提案的官方记录 公开函数 只读 可重写
     * @dev Part of the Governor Bravo's interface: _"The official record of all proposals ever proposed"_.
     */
    function proposals(uint256)
        public
        view
        virtual
        returns (
            uint256 id,
            address proposer,
            uint256 eta,
            uint256 startBlock,
            uint256 endBlock,
            uint256 forVotes,
            uint256 againstVotes,
            uint256 abstainVotes,
            bool canceled,
            bool executed
        );

    /**
     * 提交新提案的函数 公开函数 可重写
     * @dev Part of the Governor Bravo's interface: _"Function used to propose a new proposal"_.
     */
    function propose(
        address[] memory targets,
        uint256[] memory values,
        string[] memory signatures,
        bytes[] memory calldatas,
        string memory description
    ) public virtual returns (uint256);

    /**
     * 已经成功的提案进入队列 公开函数 可重写
     * @dev Part of the Governor Bravo's interface: _"Queues a proposal of state succeeded"_.
     */
    function queue(uint256 proposalId) public virtual;

    /**
     * eta 到达的进入队列的提案进行执行操作 公开函数 可支付 可重写
     * @dev Part of the Governor Bravo's interface: _"Executes a queued proposal if eta has passed"_.
     */
    function execute(uint256 proposalId) public payable virtual;

    /**
     * 取消提案 仅限提案发起者或者发起者委托放弃门槛满足 公开函数 可重写
     * @dev Cancels a proposal only if sender is the proposer, or proposer delegates dropped below proposal threshold.
     */
    function cancel(uint256 proposalId) public virtual;

    /**
     * 获取提案的内容 公开函数 只读 可重写
     * @dev Part of the Governor Bravo's interface: _"Gets actions of a proposal"_.
     */
    function getActions(uint256 proposalId)
        public
        view
        virtual
        returns (
            address[] memory targets,
            uint256[] memory values,
            string[] memory signatures,
            bytes[] memory calldatas
        );

    /**
     * 获取某提案某投票者的收据 公开函数 只读 可重写
     * @dev Part of the Governor Bravo's interface: _"Gets the receipt for a voter on a given proposal"_.
     */
    function getReceipt(uint256 proposalId, address voter) public view virtual returns (Receipt memory);

    /**
     * 能够成为提案提出者的门槛投票数量 公开函数 只读 可重写  是不是应该有个提案提供投票啊
     * @dev Part of the Governor Bravo's interface: _"The number of votes required in order for a voter to become a proposer"_.
     */
    function proposalThreshold() public view virtual returns (uint256);
}
