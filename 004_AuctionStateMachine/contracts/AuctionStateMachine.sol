// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

// 利用状态机的思路实现盲拍
contract AuctionStateMachine {
    enum Stages {
        AcceptingBlindedBids,
        RevealBids,
        PayBeneficiary,
        Finished
    }

    Stages public stage = Stages.AcceptingBlindedBids;

    uint256 public creationTime = block.timestamp;

    address public beneficiary;

    // 修好器函数 判断是否指定状态
    modifier atStage(Stages _stage) {
        require(stage == _stage);
        _;
    }

    // 修改器函数 变更到下一个状态
    modifier transitionNext() {
        _;
        nextStage();
    }

    // 变更到下一个状态
    function nextStage() internal {
        stage = Stages(uint256(stage) + 1);
    }

    // 修改器函数 判断是否要修改到下一个状态
    modifier timeTransitions() {
        if (
            stage == Stages.AcceptingBlindedBids &&
            block.timestamp >= creationTime + 10 days
        ) {
            // 当前是接受出价状态 但是时间已经过期
            nextStage();
        }
        if (
            stage == Stages.RevealBids &&
            block.timestamp >= creationTime + 12 days
        ) {
            // 当前是揭晓状态 但是时间已经过期
            nextStage();
        }
        _;
    }

    // 出价函数
    // payable 可支付
    // timeTransitions 修改器判断是否要更改状态
    // atStage(Stages.AcceptingBlindedBids) 指定当前函数必须是接受出价状态才能进入
    function bid()
        public
        payable
        timeTransitions
        atStage(Stages.AcceptingBlindedBids)
    {
        //
    }

    // 揭晓函数
    // timeTransitions 修改器判断是否要更改状态
    // atStage(Stages.RevealBids) 指定当前函数必须是揭晓状态才能进入
    function reveal() public timeTransitions atStage(Stages.RevealBids) {
        //
    }

    // 结束拍卖
    // timeTransitions 修改器判断是否要更改状态
    // atStage(Stages.PayBeneficiary) 指定当前函数必须是支付状态才能进入
    // transitionNext 支付完成后直接进入结束状态 这个方法就再也进不去了
    function auctionEnd()
        public
        timeTransitions
        atStage(Stages.PayBeneficiary)
        transitionNext
    {
        //
    }
}
