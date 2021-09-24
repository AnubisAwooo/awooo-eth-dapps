// SPDX-License-Identifier: MIT
pragma solidity >=0.4.0;

// 投票合约
// tips: 我觉得这个合约逻辑挺混乱的
// 问题在于委托 如果没委托，自己投自己的票那么 weight 和 count 没问题
// 如果委托了别人，别人投票了，直接把权重加到所投的提案上，如果没投票就把权重加到被委托人的权重上，关于 weight 记录的数据混乱不清
contract Ballot {
    // 提案数据结构
    struct Proposal {
        bytes32 name; // 提案的名称
        uint256 count; // 该提案目前的票数
    }

    // 投票人相关信息
    struct Voter {
        uint256 weight; // 该投票人投票所占的权重
        bool voted; // 是否已经投过票
        uint8 vote; // 投票对应的提案编号
        address delegate; // 该投票人投票权的委托对象
    }

    address chairperson; // 投票的主持人
    Proposal[] proposals; // 提案列表
    mapping(address => Voter) voters; // 投票者地址和对应的状态

    // 构造函数 传入提案名称，是 32长度的字节数组
    constructor(bytes32[] memory proposalNames) public {
        chairperson = msg.sender; // 将合约部署人设置为主持人

        // voters[chairperson].weight = 1; // 主持人有一票 为啥主持人也需要一票？不给

        // tips 长度判断要不要？实际上作为主持人部署合约时应该会检查，太多的话出错了给自己找事儿
        // require(proposalNames.length < 2 ** 256 - 1, "proposals are to many");
        require(proposalNames.length < 256, "proposals are to many"); // 限制长度
        require(proposalNames.length > 0, "proposals is empty"); // 限制长度

        // 遍历每一个名字，将名字推入提案列表中
        for (uint256 i = 0; i < proposalNames.length; i++) {
            proposals.push(Proposal({name: proposalNames[i], count: 0}));
        }
    }

    // 只有主持人才能调用 给别人投票的权利
    function giveRightToVote(address voter) public {
        require(msg.sender == chairperson, "only for chairperson"); // 要求调用者必须是主持人
        require(!voters[voter].voted, "voter already added"); // 要求该地址没有投过票
        require(voters[voter].weight == 0, "voter already added"); // 要求该地址投票权重为 0，不为 0 则说明已经给过权重了

        voters[voter].weight = 1; // 投票权重设置为 1
    }

    // 允许将自己的投票机会授权给别人
    function delegate(address to) public {
        Voter storage sender = voters[msg.sender]; // 取出当前授权人的信息 为什么这里要加上 storage 呢？ 表示所有修改要同步到账户存储中吗？待确定

        require(!sender.voted, "already voted"); // 要求未投过票
        require(to != msg.sender, "can not delegate to self"); // 要求不是授权给自己

        // 万一授权的对方也把投票权给别人了，那么要把当前合约调用者的授权穿透转移到那个人身上
        // 不断循环找到没有进行委托的下个接收人
        while (voters[to].delegate != address(0)) {
            // 判断条件是有进行委托则进入循环处理
            to = voters[to].delegate; // 转移被委托人
            require(to != msg.sender, "can not delegate to self by cycling"); // 如果不断循环，又委托回自己了，这是不允许的
        }

        sender.voted = true; // 已经委托给 to 了，当前授权人就相当于已经投票了
        sender.delegate = to; // 记录被委托对象

        Voter storage toDelegate = voters[to]; // 找对被委托人的信息

        if (toDelegate.voted) {
            // 如果这个被委托人已经透过票了
            proposals[toDelegate.vote].count += sender.weight; // 找到这个人投票的提案，并将要委托的票数投出去
        } else {
            // 如果这个被委托人还没有投票
            toDelegate.weight += sender.weight; // 将需要委托的票加到这个被委托人的票里面
        }
    }

    // 投票者根据提案编号进行投票
    function vote(uint8 index) public {
        Voter storage voter = voters[msg.sender]; // 取出当前投票人信息

        require(!voter.voted, "already voted"); // 要未投过票
        require(voter.weight > 0, "not a voter"); // 要求有票数
        require(index < proposals.length, "proposal index is not vaild"); // 要求投票的序号是有效的

        voter.voted = true; // 设置已经投过票
        voter.vote = index; // 保存投票的序号，要是有别人委托过来，需要用到
        proposals[index].count += voter.weight; // 加票数
    }

    // 只读函数查看胜者
    // view 只读不修改 可以不用提交交易就能调用读取值
    // winning 票数最多的提案的序号
    function winningProposal() public view returns (uint8 winning) {
        uint256 winningCount = 0; // 记录当前票数
        // 遍历每一个提案
        for (uint256 p = 0; p < proposals.length; p++) {
            if (proposals[p].count > winningCount) {
                // 如果当前提案的票数多 就记录下来
                // tips 这里用大于 万一等于了怎么办？
                winning = uint8(p); // 记录序号
                winningCount = proposals[p].count; // 记录票数
            }
        }
    }

    // 票数最多的提案的名称
    function winnerName() public view returns (bytes32 name) {
        name = proposals[winningProposal()].name; // 直接调用上个函数得到的结果
    }
}
