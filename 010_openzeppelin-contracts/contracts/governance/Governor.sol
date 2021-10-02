// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/cryptography/ECDSA.sol";
import "../utils/cryptography/draft-EIP712.sol";
import "../utils/introspection/ERC165.sol";
import "../utils/math/SafeCast.sol";
import "../utils/Address.sol";
import "../utils/Context.sol";
import "../utils/Timers.sol";
import "./IGovernor.sol";

/**
 * 抽象合约 管理系统核心  设计成能够拓展成各种模块
 * @dev Core of the governance system, designed to be extended though various modules.
 *
 * This contract is abstract and requires several function to be implemented in various modules:
 *
 * - 统计方法必须被实现
 * - A counting module must implement {quorum}, {_quorumReached}, {_voteSucceeded} and {_countVote}
 * - 投票方法必须实现
 * - A voting module must implement {getVotes}
 * - 另外，投票周期也要被实现
 * - Additionanly, the {votingPeriod} must also be implemented
 *
 * _Available since v4.3._
 */
abstract contract Governor is Context, ERC165, EIP712, IGovernor {
    using SafeCast for uint256; // 对 uint256 结构使用 SafeCast 库，感觉像是 go 或者 rust 那种实现了方法，用 . 调用函数
    using Timers for Timers.BlockNumber; // 对 Timer 的 BlockNumber 结构体使用 Timers 库

    bytes32 public constant BALLOT_TYPEHASH = keccak256("Ballot(uint256 proposalId,uint8 support)"); // 投票类型的 hash

    struct ProposalCore {
        Timers.BlockNumber voteStart; // 投票开始时间
        Timers.BlockNumber voteEnd; // 投票结束时间 讲真，再看 IGovernor 接口时，以为 blocknumber 是块序号
        bool executed; // 是否执行
        bool canceled; // 是否取消 以上应该就能确定一个提案所处的状态了
    }

    string private _name; // 应该是合约的名字

    mapping(uint256 => ProposalCore) private _proposals; // 提案编号对应的一些信息

    /**
     * 修改器 要求仅管理者调用
     * 一些模块可能重写 _executor 方法来确保修改器与执行模型想一致
     * @dev Restrict access to governor executing address. Some module might override the _executor function to make
     * sure this modifier is consistant with the execution model.
     */
    modifier onlyGovernance() {
        require(_msgSender() == _executor(), "Governor: onlyGovernance");
        _;
    }

    /**
     * 构造器 传入名称 注意 EIP712 的构造函数
     * @dev Sets the value for {name} and {version}
     */
    constructor(string memory name_) EIP712(name_, version()) {
        _name = name_;
    }

    /**
     * 接收以太币时检查发送者 外部函数 可支付 可重写
     * @dev Function to receive ETH that will be handled by the governor (disabled if executor is a third party contract)
     */
    receive() external payable virtual {
        require(_executor() == address(this));
    }

    /**
     * ERC165 标准  公开函数 只读 可重写 重写 IERC165 和 ERC165 的方法
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC165) returns (bool) {
        return interfaceId == type(IGovernor).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * 获取合约名称 公开函数 只读 可重写
     * @dev See {IGovernor-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * 获取版本 公开函数 只读 可重写  貌似可以改成 pure  what？这里产生一个疑问，如果重写方法能把 pure 的方法改成 view 吗？
     * @dev See {IGovernor-version}.
     */
    function version() public view virtual override returns (string memory) {
        return "1";
    }

    /**
     * 对提案内容进行 hash  公开函数 纯函数 可重写
     * @dev See {IGovernor-hashProposal}.
     *
     * 提案 id 是通过 hash 进过 RLC 编码的 targets 数组、values 数组、calldatas 数组和描述 hash。
     * 提案 id 可以从提案数据中产生，这些数据是事件 ProposalCreated 的一部分。在提案提交之前，提案 id 都可以提前计算出。
     * The proposal id is produced by hashing the RLC encoded `targets` array, the `values` array, the `calldatas` array
     * and the descriptionHash (bytes32 which itself is the keccak256 hash of the description string). This proposal id
     * can be produced from the proposal data which is part of the {ProposalCreated} event. It can even be computed in
     * advance, before the proposal is submitted.
     *
     * 注意链 id 和合约地址不是提案 id 的计算内容。通常向相同的提案会有相同的 id，即使提交到不同链的的管理合约中。
     * 这意味着想要执行多次相同的操作，应该修改提案的描述信息避免提案 id 冲突。
     * Note that the chainId and the governor address are not part of the proposal id computation. Consequently, the
     * same proposal (with same operation and same description) will have the same id if submitted on multiple governors
     * accross multiple networks. This also means that in order to execute the same operation twice (on the same
     * governor) the proposer will have to change the description in order to avoid proposal id conflicts.
     */
    function hashProposal(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        bytes32 descriptionHash
    ) public pure virtual override returns (uint256) {
        return uint256(keccak256(abi.encode(targets, values, calldatas, descriptionHash)));
    }

    /**
     * 获取提案状态 公开函数 只读 可重写
     * @dev See {IGovernor-state}.
     */
    function state(uint256 proposalId) public view virtual override returns (ProposalState) {
        ProposalCore memory proposal = _proposals[proposalId];

        if (proposal.executed) {
            return ProposalState.Executed;
        } else if (proposal.canceled) {
            return ProposalState.Canceled;
        } else if (proposal.voteStart.isPending()) {
            return ProposalState.Pending;
        } else if (proposal.voteEnd.isPending()) {
            return ProposalState.Active;
        } else if (proposal.voteEnd.isExpired()) {
            return
                _quorumReached(proposalId) && _voteSucceeded(proposalId)
                    ? ProposalState.Succeeded
                    : ProposalState.Defeated;
        } else {
            revert("Governor: unknown proposal id");
        }
    }

    /**
     * 获取提案的开始时间 公开函数 只读 可重写
     * @dev See {IGovernor-proposalSnapshot}.
     */
    function proposalSnapshot(uint256 proposalId) public view virtual override returns (uint256) {
        return _proposals[proposalId].voteStart.getDeadline();
    }

    /**
     * 获取提案投票结束时间 公开函数 只读 可重写
     * @dev See {IGovernor-proposalDeadline}.
     */
    function proposalDeadline(uint256 proposalId) public view virtual override returns (uint256) {
        return _proposals[proposalId].voteEnd.getDeadline();
    }

    /**
     * 投票人数是否达到门槛 内部函数 只读 可重写
     * @dev Amount of votes already cast passes the threshold limit.
     */
    function _quorumReached(uint256 proposalId) internal view virtual returns (bool);

    /**
     * 投票是否成功 内部函数 只读 可重写
     * @dev Is the proposal successful or not.
     */
    function _voteSucceeded(uint256 proposalId) internal view virtual returns (bool);

    /**
     * 统计投票？ 不知道啥意思 内部函数 可重写
     * @dev Register a vote with a given support and voting weight.
     *
     * Note: Support is generic and can represent various things depending on the voting system used.
     */
    function _countVote(
        uint256 proposalId,
        address account,
        uint8 support,
        uint256 weight
    ) internal virtual;

    /**
     * 提交一个提案？ 公开函数 可重写
     * @dev See {IGovernor-propose}.
     */
    function propose(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        string memory description
    ) public virtual override returns (uint256) {
        uint256 proposalId = hashProposal(targets, values, calldatas, keccak256(bytes(description))); // 计算提案 id

        require(targets.length == values.length, "Governor: invalid proposal length"); // 要求长度一致
        require(targets.length == calldatas.length, "Governor: invalid proposal length"); // 要求长度一致
        require(targets.length > 0, "Governor: empty proposal"); // 长度必须大于0

        ProposalCore storage proposal = _proposals[proposalId]; // 取出提案的对象
        require(proposal.voteStart.isUnset(), "Governor: proposal already exists"); // 要求提案信息未记录过

        uint64 snapshot = block.number.toUint64() + votingDelay().toUint64(); // 这就看不明白了，block.number 是块的序号 + 投票开始延时
        uint64 deadline = snapshot + votingPeriod().toUint64(); // 投票周期

        proposal.voteStart.setDeadline(snapshot); // 记录投票开始时间
        proposal.voteEnd.setDeadline(deadline); // 记录投票结束时间

        // 触发提案创建事件
        emit ProposalCreated(
            proposalId,
            _msgSender(),
            targets,
            values,
            new string[](targets.length),
            calldatas,
            snapshot,
            deadline,
            description
        );

        return proposalId;
    }

    /**
     * 提案执行 公开函数 可支付 可重写  这个方法谁都能调用
     * @dev See {IGovernor-execute}.
     */
    function execute(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        bytes32 descriptionHash
    ) public payable virtual override returns (uint256) {
        uint256 proposalId = hashProposal(targets, values, calldatas, descriptionHash); // 计算提案 id

        ProposalState status = state(proposalId); // 取得提案状态
        require(
            status == ProposalState.Succeeded || status == ProposalState.Queued, // 要求状态是完成 或者 队列中 what？不知道队列中的状态从哪来的
            "Governor: proposal not successful"
        );
        _proposals[proposalId].executed = true; // 记录为已执行

        emit ProposalExecuted(proposalId); // 触发提案执行事件

        _execute(proposalId, targets, values, calldatas, descriptionHash); // 进行执行操作

        return proposalId;
    }

    /**
     * 执行提案 内部函数 可重写
     * @dev Internal execution mechanism. Can be overriden to implement different execution mechanism
     */
    function _execute(
        uint256, /* proposalId */
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        bytes32 /*descriptionHash*/
    ) internal virtual {
        string memory errorMessage = "Governor: call reverted without message";
        for (uint256 i = 0; i < targets.length; ++i) {
            (bool success, bytes memory returndata) = targets[i].call{value: values[i]}(calldatas[i]); // 所谓的执行提案就是调用其他合约的方法
            Address.verifyCallResult(success, returndata, errorMessage);
        }
    }

    /**
     * 取消提案 内部函数 可重写
     * 内部取消方法：检查提案时间，防止再次提交，标记取消和已经执行的提案区分开来
     * @dev Internal cancel mechanism: locks up the proposal timer, preventing it from being re-submitted. Marks it as
     * canceled to allow distinguishing it from executed proposals.
     *
     * Emits a {IGovernor-ProposalCanceled} event.
     */
    function _cancel(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        bytes32 descriptionHash
    ) internal virtual returns (uint256) {
        uint256 proposalId = hashProposal(targets, values, calldatas, descriptionHash); // 计算提案 id
        ProposalState status = state(proposalId); // 取得提案状态

        // 要求不是取消状态 也不是过期状态 也不是执行状态
        require(
            status != ProposalState.Canceled && status != ProposalState.Expired && status != ProposalState.Executed,
            "Governor: proposal not active"
        );
        _proposals[proposalId].canceled = true; // 记录为取消

        emit ProposalCanceled(proposalId); // 触发提案取消事件

        return proposalId;
    }

    /**
     * 投票 公开函数 可重写
     * @dev See {IGovernor-castVote}.
     */
    function castVote(uint256 proposalId, uint8 support) public virtual override returns (uint256) {
        address voter = _msgSender();
        return _castVote(proposalId, voter, support, "");
    }

    /**
     * 投票 公开函数 可重写
     * @dev See {IGovernor-castVoteWithReason}.
     */
    function castVoteWithReason(
        uint256 proposalId,
        uint8 support,
        string calldata reason
    ) public virtual override returns (uint256) {
        address voter = _msgSender();
        return _castVote(proposalId, voter, support, reason);
    }

    /**
     * 通过签名方式投票 地址是通过计算出来的 公开函数 可重写
     * @dev See {IGovernor-castVoteBySig}.
     */
    function castVoteBySig(
        uint256 proposalId,
        uint8 support,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual override returns (uint256) {
        address voter = ECDSA.recover(
            _hashTypedDataV4(keccak256(abi.encode(BALLOT_TYPEHASH, proposalId, support))),
            v,
            r,
            s
        );
        return _castVote(proposalId, voter, support, "");
    }

    /**
     * 内部投票函数 内部函数 可重写
     * @dev Internal vote casting mechanism: Check that the vote is pending, that it has not been cast yet, retrieve
     * voting weight using {IGovernor-getVotes} and call the {_countVote} internal function.
     *
     * Emits a {IGovernor-VoteCast} event.
     */
    function _castVote(
        uint256 proposalId,
        address account,
        uint8 support,
        string memory reason
    ) internal virtual returns (uint256) {
        ProposalCore storage proposal = _proposals[proposalId];
        require(state(proposalId) == ProposalState.Active, "Governor: vote not currently active");

        uint256 weight = getVotes(account, proposal.voteStart.getDeadline()); // 计算票数
        _countVote(proposalId, account, support, weight);

        emit VoteCast(account, proposalId, support, weight, reason);

        return weight;
    }

    /**
     * 获取执行者 内部函数 只读 可重写
     * @dev Address through which the governor executes action. Will be overloaded by module that execute actions
     * through another contract such as a timelock.
     */
    function _executor() internal view virtual returns (address) {
        return address(this);
    }
}
