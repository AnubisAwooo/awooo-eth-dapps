// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

// 权限控制合约
contract AccessControl {
    // 合约中存储一个映射，需要对这个数据的访问权限进行控制
    mapping(bytes32 => string) secretsMap;

    // 管理员账户数组，可以添加管理员 读 和 写
    address[] admins;
    // 读白名单
    address[] allowedReaders;
    // 写白名单
    address[] allowedWriters;

    constructor(address[] memory initialAdmins) public {
        admins = initialAdmins;
    }

    // 判断用户数组是否包含某用户 这是一个工具方法，判断用户集合是否包含某用户
    function isAllowed(address user, address[] storage allowedUsers)
        private
        returns (bool)
    {
        for (uint256 i = 0; i < allowedUsers.length; i++) {
            if (allowedUsers[i] == user) {
                return true;
            }
        }
        return false;
    }

    // 修改器方法 有权限才能继续
    // 如此复杂因为，read 不修改数据，用户可以虚拟任何有权限的地址来进行读取，虚拟机不会验证调用者的签名，所以需要在合约里面判断用户
    // 前提是方法是 view 的，但是我加不上这个关键字啊？？
    // msg.sig 是 keccak256("read(uint8,bytes32,bytes32,bytes24)") 的前 4 个字节 这里是 0xbcbb0181
    // 私钥进行签名前还要连带函数签名进行补齐为 32 字节
    // tips 问题来了，签名不要带参数的吗，不然反复利用这个签名调用这个方法算个什么事？这个问题需要研究
    // 读权限控制很无聊啊，想读内容的话，甚至可以修改虚拟机，debug 也能通过的，直接读取账户存储信息得了，何必这么麻烦。
    modifier onlyAllowedReaders(
        uint8 v,
        bytes32 r,
        bytes32 s
    ) {
        bytes32 hash = msg.sig;
        address reader = ecrecover(hash, v, r, s); // 说实话，没看懂这个怎么操作的，我对签名内容和流程不熟悉，以后要加强
        require(isAllowed(reader, allowedReaders));
        _;
    }

    // 修改器方法 有写权限才放行
    modifier onlyAllowedWriters() {
        require(isAllowed(msg.sender, allowedWriters));
        _;
    }

    // 修改器方法 有管理员权限才放行
    modifier onlyAdmins() {
        require(isAllowed(msg.sender, admins));
        _;
    }

    // 不知道为什么 view 加不上去
    // 读数据 通过修改器签名验证获得真的有对应私钥的地址，并且这个地址有读权限才能继续
    function read(
        uint8 v,
        bytes32 r,
        bytes32 s,
        bytes24 key
    ) public onlyAllowedReaders(v, r, s) returns (string memory) {
        return secretsMap[key];
    }

    // 写数据 修改器判断权限
    function write(bytes24 key, string memory value) public onlyAllowedWriters {
        secretsMap[key] = value;
    }

    // 加读权限 修改器判断管理员权限
    function addAuthorizedReader(address a) public onlyAdmins {
        allowedReaders.push(a);
    }

    // 加写权限 修改器判断管理员权限
    function addAuthorizedWriter(address a) public onlyAdmins {
        allowedWriters.push(a);
    }

    // 加管理员 修改器判断管理员权限
    function addAdmin(address a) public onlyAdmins {
        admins.push(a);
    }
}
