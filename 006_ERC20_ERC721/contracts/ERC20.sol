// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

// ERC20 标准接口
abstract contract ERC20 {
    // 代币名称
    string public constant name = "Token Name";
    // 代币符号
    string public constant symbol = "SYM";
    // 代币精度
    uint8 public constant decimals = 18;

    // 转账事件 金额 value 从地址 from 转入地址 to
    event Transfer(address indexed from, address indexed to, uint256 value);
    // 授权事件 金额 value 从拥有者 owner 授权消费者 spender
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    // 总供应量方法 返回代币总量
    function totalSupply() public view virtual returns (uint256 supply);

    // 查询余额，查询某账户地址的代币余额
    function balanceOf(address who) public view virtual returns (uint256 value);

    // 查询额度，查询代币拥有者允许消费者花费的额度
    function allowance(address owner, address spender)
        public
        virtual
        returns (uint256 _allowance);

    // 转账 将数量 value 的代币转入地址 to
    function transfer(address to, uint256 value)
        public
        virtual
        returns (bool ok);

    // 转账 将拥有者 from 的代币转入地址 to，数量为 value
    function transferFrom(
        address from,
        address to,
        uint256 value
    ) public virtual returns (bool ok);

    // 授权额度 授权消费者 spender 能够从本账户花费 value 数量的代币
    // tips 这个方法貌似一般都是叠加的，实际上具体实现随意，直接本次设定为 value 也可以
    function approve(address spender, uint256 value)
        public
        virtual
        returns (bool ok);
}
