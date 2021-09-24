// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

// ERC721 标准接口
// NFT (Non-fungible Token) 代币
// 代币精度为 0，每个代币都有独一无二的 tokenId 标识，可以附上一些不同的特征值
// 这里面就没有数量的概念了，是每个地址下面记录了哪些 tokenId，交易的都是 tokenId
abstract contract ERC721 {
    // 转账事件 代币 _tokenId 从地址 _from 转入地址 _to
    event Transfer(
        address indexed _from,
        address indexed _to,
        uint256 _tokenId
    );
    // 授权事件 代币 _tokenId 从拥有者 _owner 授权消费者 _approved
    event Approval(
        address indexed _owner,
        address indexed _approved,
        uint256 _tokenId
    );

    // 必须方法

    // 总供应量方法 返回代币总量
    function totalSupply() public view virtual returns (uint256 totalSupply);

    // 查询余额，查询某账户地址的代币余额
    function balanceOf(address _owner)
        public
        view
        virtual
        returns (uint256 balance);

    // 查询某个标识对应的所有者地址
    function ownerOf(uint256 _tokenId)
        public
        view
        virtual
        returns (address owner);

    // 授权额度 授权消费者 _to 能够从本账户花费 _tokenId 的代币
    function approve(address _to, uint256 _tokenId) public virtual;

    // 被授权后调用该方法将代币 _tokenId 转移给自己
    function tokeOwnership(uint256 _tokenId) public virtual;

    // 转账 将代币 _tokenId 的代币转入地址 to
    function transfer(address _to, uint256 _tokenId) public virtual;

    // 可选方法

    // 代币名称
    function name() public view returns (string memory name) {
        return name;
    }

    // 代币符号
    function symbol() public view returns (string memory symbol) {
        return symbol;
    }

    // 根据序号查找某位拥有者的代币 tokenId
    function tokenOfOwnerByIndex(address _owner, uint256 _index)
        public
        view
        returns (uint256 tokenId)
    {}

    // 查看代币元数据
    function tokenMetadata(uint256 _tokenId)
        public
        view
        returns (string memory infoUrl)
    {}
}
