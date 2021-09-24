// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

// 盲拍
contract BlindAuction {
    // 出价的数据结构
    struct Bid {
        bytes32 blindedBid; // 加密后的出价
        uint256 deposit; // 出价时所付的金额 tips 每个人的出价上限还是知道的
    }

    address payable public beneficiary; // 受益人

    uint256 public biddingEnd; // 出价结束时间戳 单位秒
    uint256 public revealEnd; // 揭晓期结束的时间戳 单位秒
    bool public ended; //  合约是否结束

    mapping(address => Bid[]) public bids; // 各出价这屡次出价记录
    address public highestBidder; // 揭晓每次出价后，当前最高出价者
    uint256 public highestBid; // 揭晓每次出价后，当前最高出价

    mapping(address => uint256) pendingReturns; // 需要退回的金额

    event AuctionEnded(address winner, uint256 highestBid); // 竞拍结束的事件

    // 构造函数
    constructor(
        uint256 bidding, // 出价时间
        uint256 reveal, // 揭晓时间
        address payable beneficy // 受益人
    ) public {
        beneficiary = beneficy;
        biddingEnd = block.timestamp + bidding; // 计算出价截止时间
        revealEnd = biddingEnd + reveal; // 计算揭晓截止时间
    }

    // 修改器函数 要求在指定时间之前调用
    modifier onlyBefore(uint256 _time) {
        require(block.timestamp < _time);
        _;
    }
    // 修改器函数 要求在指定时间之后调用
    modifier onlyAfter(uint256 _time) {
        require(block.timestamp > _time);
        _;
    }

    // 出价函数 利用修改器必须在出价截止时间之前
    function bid(bytes32 _blindedBid) public payable onlyBefore(biddingEnd) {
        bids[msg.sender].push(
            Bid({blindedBid: _blindedBid, deposit: msg.value}) // 直接把出价信息存入
        );
    }

    // 揭晓函数 顺便退费 利用修改器必须在出价截止时间之后、揭晓截止时间之前
    function reveal(
        uint256[] memory _values, // 出价时真正的值
        bool[] memory _fake, // 该价格是否参与出价
        bytes32[] memory _secret // 为了防止其他人遍历猜价格，用字符串的秘钥参与 hash，那么别人就无法猜出来了
    ) public onlyAfter(biddingEnd) onlyBefore(revealEnd) {
        uint256 length = bids[msg.sender].length; // 获取曾经出价次数

        require(length > 0, "length can not be 0"); // 出价了的人才可以继续

        require(_values.length == length, "wrong length"); // 比较传入参数长度是否一致
        require(_fake.length == length, "wrong length");
        require(_secret.length == length, "wrong length");

        uint256 refund; // 需要退回的钱

        // 遍历每一次出价分别处理
        for (uint256 i = 0; i < length; i++) {
            Bid storage _bid = bids[msg.sender][i]; // 取出第 i 次出价信息
            (uint256 value, bool fake, bytes32 secret) = (
                _values[i],
                _fake[i],
                _secret[i]
            ); // 取出对应的传入参数
            if (_bid.blindedBid != keccak256(abi.encode(value, fake, secret))) {
                // 验证加密情况，正确的参数才能得到之前出价给的加密后的信息 1.验证
                continue;
            }
            refund += _bid.deposit; // 把当前金额加入退回的金额里
            if (!fake && _bid.deposit >= value) {
                // 不是假的 并且 当时存入的金额大于加密用的数量
                if (placeBid(msg.sender, value)) {
                    // 如果把真实的数量进行出价成功 tips 价格比之前的高
                    refund -= value; // 就把这部分真实出价的数额减去，不退回
                }
            }
            // 把正确加入退回数量的地址置空，这样下次再进入就 continue 了，同样也是防止重复取钱 2. 修改
            // 用户完全可以自己取出指定序号的钱，除非这个钱高出最高价，这样就会流入那部分数额进入拍卖体系
            _bid.blindedBid = bytes32(0);
        }
        msg.sender.transfer(refund); // 把失败的和万一是最高价扣除后剩下的部分退回账户 3.行动
    }

    // 提回被别人出价超过自己出的金额
    function withdraw() public {
        uint256 amount = pendingReturns[msg.sender];
        if (amount > 0) {
            pendingReturns[msg.sender] = 0;
            msg.sender.transfer(amount);
        }
    }

    // 结束拍卖
    function auctionEnd() public onlyAfter(revealEnd) {
        require(!ended, "wait");
        ended = true;
        emit AuctionEnded(highestBidder, highestBid);
        beneficiary.transfer(highestBid);
    }

    // 进行出价 通过揭晓之后内部调取出价
    function placeBid(address bidder, uint256 value)
        internal
        returns (bool success)
    {
        if (value <= highestBid) {
            return false;
        }
        if (highestBidder != address(0)) {
            pendingReturns[highestBidder] += highestBid; // 曾经是第一的出价，进入记录，将来取回
        }
        highestBid = value;
        highestBidder = bidder;
        return true;
    }
}
