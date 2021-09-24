// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

// 简单拍卖
contract SimpleAuction {
    address payable public beneficiary; // 最终受益人
    uint256 public auctionEnd; //拍卖结束的时间戳 单位秒

    address public highestBidder; //当前出价最高者
    uint256 public highestBid; //当前最高出价

    mapping(address => uint256) pendingReturns; //记录每个人曾经是第一的人的出价，退回时使用

    bool ended; // 拍卖是否结束标识

    // 出现更高价格引发的事件
    event HighestBidIncreased(address bidder, uint256 amount);
    // 竞拍结束时引发的事件
    event AuctionEnded(address winner, uint256 amount);

    // 构造函数 初始化
    constructor(uint256 activeTime, address payable _beneficiary) public {
        beneficiary = _beneficiary;
        auctionEnd = block.timestamp + activeTime;
    }

    // 竞拍者出价
    function bid() public payable {
        require(block.timestamp <= auctionEnd, "auction is over"); // 要求区块时间小于结束时间
        // 要求出价大于当前最高价
        require(
            msg.value > highestBid,
            "value must greater than highest bid price"
        );

        // 把上次的出价记录进等待退回的记录
        // tips 如果同一个地址出价多次怎么算，能不能叠加上次出的价格？如果叠加的话，那么上面的判断都要修正一下了
        if (highestBidder != address(0)) {
            // 如果有出价记录
            pendingReturns[highestBidder] += highestBid; // += 用的是对的，出价多次也能提走啊，不然可惨了
        }

        highestBidder = msg.sender; //  记录出价人
        highestBid = msg.value; // 记录出价

        emit HighestBidIncreased(highestBidder, highestBid); // 发个事件
    }

    // 被超过后可以把自己的钱提走
    // tips 那么就基本不存在出价 2 次的问题了，但是，这就需要竞拍者先提再出价，浪费了一次手续费呢
    function withdraw() public returns (bool) {
        uint256 amount = pendingReturns[msg.sender]; // 取出可提出余额

        // 1 检查
        if (amount > 0) {
            // 2 修改
            pendingReturns[msg.sender] = 0;
            // 3 执行
            if (!msg.sender.send(amount)) {
                // 4 错误恢复
                pendingReturns[msg.sender] = amount;
                return false;
            }
        }

        return true;
    }

    // 进行结束
    function doAuctionEnd() public {
        require(block.timestamp >= auctionEnd, "not the time"); // 要求时间在结束时间之后
        require(!ended, "ended already"); // 要加未进行过结束指令

        ended = true; // 设置结束标识

        emit AuctionEnded(highestBidder, highestBid); // 发个事件

        beneficiary.transfer(highestBid); // 给受益人转账
    }
}
