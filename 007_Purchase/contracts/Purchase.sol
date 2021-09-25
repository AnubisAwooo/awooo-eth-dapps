// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

// 远程购买
// 创建  锁定   失效
// 1. 卖家打 2 倍钱创建
// 1.1 卖家在创建时可以反悔，退钱进入失效
// 1.2 买家在创建状态也打 2 倍钱，进入锁定状态
// 1.2.1 买家收到物品会把钱 3 份给卖家，1 份给买家
// 分析: 买家打钱了，但是卖家不给物品，这时大家都亏 2 份钱
//      卖家给物品了，但是买家不结束合约，这时卖家亏 2份钱+物品 买家亏 2份钱-物品
// 感觉不是那么的公平
contract Purchase {
    // 状态 -> 创建 锁定 失效
    enum State {
        Created,
        Locked,
        Inactive
    }
    uint256 public value; // 价格
    address public seller; // 卖家
    address public buyer; // 买家

    State public state; // 记录状态

    //构造函数
    constructor() public payable {
        seller = msg.sender; // 合约创建者是卖家
        value = msg.value / 2; // tips 创建时传入的值一半？？
        require((2 * value) == msg.value, "Value has to be even."); // 如果不是偶数会报错
    }

    // 条件修改器
    modifier condition(bool _condition) {
        require(_condition);
        _;
    }

    // 修改器 仅买家通过
    modifier onlyBuyer() {
        require(msg.sender == buyer, "Only buyer can call this.");
        _;
    }

    // 修改器 仅卖价通过
    modifier onlySeller() {
        require(msg.sender == seller, "Only seller can call this.");
        _;
    }

    // 修改器 仅指定状态通过
    modifier inState(State _state) {
        require(state == _state, "Invalid state.");
        _;
    }

    event Aborted(); // 中止时间
    event PurchaseConfirmed(); // 购买成功事件
    event ItemReceived(); // 物品收到事件

    ///中止购买并回收以太币。
    ///只能在合约被锁定之前由卖家调用。
    // 仅卖价调用
    // 状态必须是创建状态
    function abort() public onlySeller inState(State.Created) {
        emit Aborted(); // 发出中止事件
        state = State.Inactive; // 修改状态为失效
        seller.transfer(address(this).balance); // 将合约剩下的以太币转回卖家
    }

    /// 买家确认购买。
    /// 交易必须包含 `2 * value` 个以太币。
    /// 以太币会被锁定，直到 confirmReceived 被调用。
    // 状态必须是创建状态
    // 转入的金额必须是构造器传入的一样
    function confirmPurchase()
        public
        payable
        inState(State.Created)
        condition(msg.value == (2 * value))
    {
        emit PurchaseConfirmed(); // 发出购买确认事件
        buyer = msg.sender; // 设置买家
        state = State.Locked; // 修改状态为锁定
    }

    /// 确认你（买家）已经收到商品。
    /// 这会释放被锁定的以太币。
    // 仅买家调用
    // 必须是锁定状态
    function confirmReceived() public onlyBuyer inState(State.Locked) {
        emit ItemReceived(); // 发出物品收到事件
        // 首先修改状态很重要，否则的话，由 `transfer` 所调用的合约可以回调进这里（再次接收以太币）。
        state = State.Inactive; // 设置状态为失效

        // 注意: 这实际上允许买方和卖方阻止退款 - 应该使用取回模式。
        buyer.transfer(value); // 买家只退回当初存入的一半
        seller.transfer(address(this).balance); // 这里退回给卖家 3 * value
    }
}
