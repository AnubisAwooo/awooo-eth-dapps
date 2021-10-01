// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/introspection/ERC165.sol";

/**
 * 抽象合约 定义 Governor 的接口  这个好像是一个投票合约
 * @dev Interface of the {Governor} core.
 *
 * _Available since v4.3._
 */
abstract contract IGovernor is IERC165 {
    // 提案状态
    enum ProposalState {
        Pending,
        Active,
        Canceled,
        Defeated,
        Succeeded,
        Queued,
        Expired,
        Executed
    }

    /**
     * 提案创建事件
     * @dev Emitted when a proposal is created.
     */
    event ProposalCreated(
        uint256 proposalId,
        address proposer,
        address[] targets,
        uint256[] values,
        string[] signatures,
        bytes[] calldatas,
        uint256 startBlock,
        uint256 endBlock,
        string description
    );

    /**
     * 提案取消事件
     * @dev Emitted when a proposal is canceled.
     */
    event ProposalCanceled(uint256 proposalId);

    /**
     * 提案执行事件
     * @dev Emitted when a proposal is executed.
     */
    event ProposalExecuted(uint256 proposalId);

    /**
     * 提案投票事件
     * @dev Emitted when a vote is cast.
     *
     * Note: `support` values should be seen as buckets. There interpretation depends on the voting module used.
     */
    event VoteCast(address indexed voter, uint256 proposalId, uint8 support, uint256 weight, string reason);

    /**
     * 获取合约名称 公开函数 只读 可重写
     * 根据 ERC712 可使用 name 作为签名辨识
     * @notice module:core
     * @dev Name of the governor instance (used in building the ERC712 domain separator).
     */
    function name() public view virtual returns (string memory);

    /**
     * 获取版本 公开函数 只读 可重写
     * @notice module:core
     * @dev Version of the governor instance (used in building the ERC712 domain separator). Default: "1"
     */
    function version() public view virtual returns (string memory);

    /**
     * 计票模式 公开函数 纯函数 可重写
     * @notice module:voting
     * 返回一个用于描述投票计票类型的字符串。用于被前端 UI 参考显示正确的投票选项并解释结果。这个字符串形式是 URL 编码的键值对序列。
     * @dev A description of the possible `support` values for {castVote} and the way these votes are counted, meant to
     * be consumed by UIs to show correct vote options and interpret the results. The string is a URL-encoded sequence of
     * key-value pairs that each describe one aspect, for example `support=bravo&quorum=for,abstain`.
     *
     * There are 2 standard keys: `support` and `quorum`.
     *
     * - `support=bravo` refers to the vote options 0 = For, 1 = Against, 2 = Abstain, as in `GovernorBravo`.
     * - `quorum=bravo` means that only For votes are counted towards quorum.
     * - `quorum=for,abstain` means that both For and Abstain votes are counted towards quorum.
     *
     * NOTE: The string can be decoded by the standard
     * https://developer.mozilla.org/en-US/docs/Web/API/URLSearchParams[`URLSearchParams`]
     * JavaScript class.
     */
    // solhint-disable-next-line func-name-mixedcase
    function COUNTING_MODE() public pure virtual returns (string memory);

    /**
     * 通过提案详情构建提案 id  公开函数 纯函数 可重写
     * @notice module:core
     * @dev Hashing function used to (re)build the proposal id from the proposal details..
     */
    function hashProposal(
        address[] calldata targets,
        uint256[] calldata values,
        bytes[] calldata calldatas,
        bytes32 descriptionHash
    ) public pure virtual returns (uint256);

    /**
     * 查看提案的状态 公开函数 只读 可重写
     * @notice module:core
     * @dev Current state of a proposal, following Compound's convention
     */
    function state(uint256 proposalId) public view virtual returns (ProposalState);

    /**
     * 能够获取某提案的投票详情的区块号 公开函数 只读 可重写
     * @notice module:core
     * @dev block number used to retrieve user's votes and quorum.
     */
    function proposalSnapshot(uint256 proposalId) public view virtual returns (uint256);

    /**
     * 获取提案截止时间 公开函数 只读 可重写
     * 投票结束时间
     * @notice module:core
     * @dev timestamp at which votes close.
     */
    function proposalDeadline(uint256 proposalId) public view virtual returns (uint256);

    /**
     * 在提案创建和投票开始之前，延迟提案的开始的块的序号。 公开函数 只读 可重写
     * @notice module:user-config
     * @dev delay, in number of block, between the proposal is created and the vote starts. This can be increassed to
     * leave time for users to buy voting power, of delegate it, before the voting of a proposal starts.
     */
    function votingDelay() public view virtual returns (uint256);

    /**
     * 在投票开始并且未结束时，延迟提案的结束的块的序号。 公开函数 只读 可重写
     * @notice module:user-config
     * @dev delay, in number of blocks, between the vote start and vote ends.
     *
     * Note: the {votingDelay} can delay the start of the vote. This must be considered when setting the voting
     * duration compared to the voting delay.
     */
    function votingPeriod() public view virtual returns (uint256);

    /**
     * 法定人数？？提案通过要求的最小投票人数 公开函数 只读 可重写
     * @notice module:user-config
     * @dev Minimum number of cast voted required for a proposal to be successful.
     *
     *  snaphot 单词应该拼错了吧
     * blockNumber 参数 ？？？ 看不明白
     * Note: The `blockNumber` parameter corresponds to the snaphot used for counting vote. This allows to scale the
     * quroum depending on values such as the totalSupply of a token at this block (see {ERC20Votes}).
     */
    function quorum(uint256 blockNumber) public view virtual returns (uint256);

    /**
     * 获取拥有票数 在指定块之前  公开函数 只读 可重写
     * @notice module:reputation
     * @dev Voting power of an `account` at a specific `blockNumber`.
     *
     * 本方法可以通过多种方式实现，例如读取委托的数量
     * Note: this can be implemented in a number of ways, for example by reading the delegated balance from one (or
     * multiple), {ERC20Votes} tokens.
     */
    function getVotes(address account, uint256 blockNumber) public view virtual returns (uint256);

    /**
     * 查询是否已经给某提案投票 公开函数 只读 可重写
     * @notice module:voting
     * @dev Returns weither `account` has cast a vote on `proposalId`.
     */
    function hasVoted(uint256 proposalId, address account) public view virtual returns (bool);

    /**
     * 创建一个新的提案 公开函数 可重写
     * @dev Create a new proposal. Vote start {IGovernor-votingDelay} blocks after the proposal is created and ends
     * {IGovernor-votingPeriod} blocks after the voting starts.
     *
     * Emits a {ProposalCreated} event.
     */
    function propose(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        string memory description
    ) public virtual returns (uint256 proposalId);

    /**
     * 执行一个投票成功的提案 要求法定投票人数满足，投票成功，并且截止线已经达到。 公开函数 可支付 可重写
     * @dev Execute a successful proposal. This requires the quorum to be reached, the vote to be successful, and the
     * deadline to be reached.
     *
     * Emits a {ProposalExecuted} event.
     *
     * Note: some module can modify the requirements for execution, for example by adding an additional timelock.
     */
    function execute(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        bytes32 descriptionHash
    ) public payable virtual returns (uint256 proposalId);

    /**
     * 投票 公开函数
     * @dev Cast a vote
     *
     * Emits a {VoteCast} event.
     */
    function castVote(uint256 proposalId, uint8 support) public virtual returns (uint256 balance);

    /**
     * 投票带原因  公开函数 可重写
     * @dev Cast a with a reason
     *
     * Emits a {VoteCast} event.
     */
    function castVoteWithReason(
        uint256 proposalId,
        uint8 support,
        string calldata reason
    ) public virtual returns (uint256 balance);

    /**
     * 投票用签名方式 公开函数 可重写
     * @dev Cast a vote using the user cryptographic signature.
     *
     * Emits a {VoteCast} event.
     */
    function castVoteBySig(
        uint256 proposalId,
        uint8 support,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual returns (uint256 balance);
}
