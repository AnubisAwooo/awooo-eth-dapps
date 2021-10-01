// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Address.sol";
import "../utils/Context.sol";

/**
 * 分散支付
 * @title PaymentSplitter
 * 本合约支持将以太币分割给一系列账户。发送者不需要知道以太币将要以这种方式分割，因为都是由合约透明的处理。
 * @dev This contract allows to split Ether payments among a group of accounts. The sender does not need to be aware
 * that the Ether will be split in this way, since it is handled transparently by the contract.
 *
 * 分割可以是每个账户相等 或者 任意比例。默认的方式给每个账户分配一定的份额。每个账户能够从本合约中取得一定比例的以太币。
 * The split can be in equal parts or in any other arbitrary proportion. The way this is specified is by assigning each
 * account to a number of shares. Of all the Ether that this contract receives, each account will then be able to claim
 * an amount proportional to the percentage of total shares they were assigned.
 *
 * 支付分割遵循 pull payment 模型。这意味着支付不是自动化转到账户，而是记录在合约里，当实际的支付函数被调用，就触发了一个叫 release 的分割步骤。
 * `PaymentSplitter` follows a _pull payment_ model. This means that payments are not automatically forwarded to the
 * accounts but kept in this contract, and the actual transfer is triggered as a separate step by calling the {release}
 * function.
 */
contract PaymentSplitter is Context {
    event PayeeAdded(address account, uint256 shares); // 收款人增加事件
    event PaymentReleased(address to, uint256 amount); // 支付释放事件
    event PaymentReceived(address from, uint256 amount); //  支付接收事件

    uint256 private _totalShares; // 总份额
    uint256 private _totalReleased; // 已经分发出去的金额

    mapping(address => uint256) private _shares; // 每个地址所占的份额
    mapping(address => uint256) private _released; // 每个地址已经分发的金额
    address[] private _payees; // 接收人地址列表

    /**
     * 构造器创建实例
     * @dev Creates an instance of `PaymentSplitter` where each account in `payees` is assigned the number of shares at
     * the matching position in the `shares` array.
     *
     * All addresses in `payees` must be non-zero. Both arrays must have the same non-zero length, and there must be no
     * duplicates in `payees`.
     */
    constructor(address[] memory payees, uint256[] memory shares_) payable {
        require(payees.length == shares_.length, "PaymentSplitter: payees and shares length mismatch");
        require(payees.length > 0, "PaymentSplitter: no payees");

        for (uint256 i = 0; i < payees.length; i++) {
            _addPayee(payees[i], shares_[i]);
        }
    }

    /**
     * 合约接收到以太币后会触发日志 注意，这里的事件不是完全可靠的，某些情况下合约会接收到以太币但不触发这个方法。这里仅仅关联可靠的事件，并非实际分割的以太币。
     * 外部函数 可支付 可重写
     * @dev The Ether received will be logged with {PaymentReceived} events. Note that these events are not fully
     * reliable: it's possible for a contract to receive Ether without triggering this function. This only affects the
     * reliability of the events, and not the actual splitting of Ether.
     *
     * To learn more about this see the Solidity documentation for
     * https://solidity.readthedocs.io/en/latest/contracts.html#fallback-function[fallback
     * functions].
     */
    receive() external payable virtual {
        emit PaymentReceived(_msgSender(), msg.value); // 接收以太币事件
    }

    /**
     * 获取总份额 公开函数 只读
     * @dev Getter for the total shares held by payees.
     */
    function totalShares() public view returns (uint256) {
        return _totalShares;
    }

    /**
     * 获取已经分发的资金总额 公开函数 只读
     * @dev Getter for the total amount of Ether already released.
     */
    function totalReleased() public view returns (uint256) {
        return _totalReleased;
    }

    /**
     * 获取某地址的金额 公开函数 只读
     * @dev Getter for the amount of shares held by an account.
     */
    function shares(address account) public view returns (uint256) {
        return _shares[account];
    }

    /**
     * 获取某账户已经分发的金额 公开函数 只读
     * @dev Getter for the amount of Ether already released to a payee.
     */
    function released(address account) public view returns (uint256) {
        return _released[account];
    }

    /**
     * 按序号获取收款人地址 公开函数 只读
     * @dev Getter for the address of the payee number `index`.
     */
    function payee(uint256 index) public view returns (address) {
        return _payees[index];
    }

    /**
     * 向某地址发放资金 公开函数 可重写
     * 这个方法是每个地址都可以调用的，谁愿意支付手续费呢？
     * @dev Triggers a transfer to `account` of the amount of Ether they are owed, according to their percentage of the
     * total shares and their previous withdrawals.
     */
    function release(address payable account) public virtual {
        require(_shares[account] > 0, "PaymentSplitter: account has no shares"); // 要求所占份额大于 0

        uint256 totalReceived = address(this).balance + _totalReleased; // 计算所有收到的金额，当前余额+已经发放出去的金额
        uint256 payment = (totalReceived * _shares[account]) / _totalShares - _released[account]; // 计算本次应当支付的金额，总 * 份额 / 总份额 - 已经发放的金额

        require(payment != 0, "PaymentSplitter: account is not due payment"); // 要求发放金额不为 0

        _released[account] = _released[account] + payment; // 记录已经释放金额
        _totalReleased = _totalReleased + payment; // 记录已经释放的总金额

        Address.sendValue(account, payment); // 发放资金
        emit PaymentReleased(account, payment); // 触发资金分发事件
    }

    /**
     * 增加收款人 私有函数
     * @dev Add a new payee to the contract.
     * @param account The address of the payee to add.
     * @param shares_ The number of shares owned by the payee.
     */
    function _addPayee(address account, uint256 shares_) private {
        require(account != address(0), "PaymentSplitter: account is the zero address"); // 要求账户不是空地址
        require(shares_ > 0, "PaymentSplitter: shares are 0"); // 要求所占的份额不为 0
        require(_shares[account] == 0, "PaymentSplitter: account already has shares"); // 要求未分配过份额

        _payees.push(account); // 记录地址
        _shares[account] = shares_; // 记录份额
        _totalShares = _totalShares + shares_; // 记入总份额
        emit PayeeAdded(account, shares_); // 触发收款人增加事件
    }
}
