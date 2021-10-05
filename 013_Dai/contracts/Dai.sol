/**
 *Submitted for verification at Etherscan.io on 2019-11-14
 */

// hevm: flattened sources of /nix/store/8xb41r4qd0cjb63wcrxf1qmfg88p0961-dss-6fd7de0/src/dai.sol
pragma solidity =0.5.12;

// 部署于 https://cn.etherscan.com/address/0x6b175474e89094c44da98b954eedeac495271d0f

////// /nix/store/8xb41r4qd0cjb63wcrxf1qmfg88p0961-dss-6fd7de0/src/lib.sol
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

/* pragma solidity 0.5.12; */

contract LibNote {
    event LogNote(
        bytes4 indexed sig,
        address indexed usr,
        bytes32 indexed arg1,
        bytes32 indexed arg2,
        bytes data
    ) anonymous; // 日志名称不加入索引

    // 修改器 note 意思是 当前函数代码执行完毕后，发布日志
    modifier note() {
        _;
        assembly {
            // log an 'anonymous' event with a constant 6 words of calldata
            // and four indexed topics: selector, caller, arg1 and arg2
            let mark := msize // end of memory ensures zero
            mstore(0x40, add(mark, 288)) // update free memory pointer
            mstore(mark, 0x20) // bytes type data offset
            mstore(add(mark, 0x20), 224) // bytes size (padded)
            calldatacopy(add(mark, 0x40), 0, 224) // bytes payload
            log4(
                mark,
                288, // calldata
                shl(224, shr(224, calldataload(0))), // msg.sig
                caller, // msg.sender
                calldataload(4), // arg1
                calldataload(36) // arg2
            )
        }
    }
}

////// /nix/store/8xb41r4qd0cjb63wcrxf1qmfg88p0961-dss-6fd7de0/src/dai.sol
// Copyright (C) 2017, 2018, 2019 dbrock, rain, mrchico

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.

/* pragma solidity 0.5.12; */

/* import "./lib.sol"; */

contract Dai is LibNote {
    // --- Auth ---
    mapping(address => uint256) public wards; // ward 守卫

    // 设置某地址为守卫 外部函数 记录日志 必须是守卫才能调用
    function rely(address guy) external note auth {
        wards[guy] = 1;
    }

    // 取消某地址为守卫 外部函数 记录日志 必须是守卫才能调用
    function deny(address guy) external note auth {
        wards[guy] = 0;
    }

    // 修改器 要求调用者是守卫地址
    modifier auth() {
        require(wards[msg.sender] == 1, "Dai/not-authorized");
        _;
    }

    // --- ERC20 Data ---
    string public constant name = "Dai Stablecoin"; // 币名称
    string public constant symbol = "DAI"; // 符号
    string public constant version = "1"; // 版本
    uint8 public constant decimals = 18; // 精度
    uint256 public totalSupply; // 总供应量

    mapping(address => uint256) public balanceOf; // 每个地址对应的余额
    mapping(address => mapping(address => uint256)) public allowance; // 每个地址给予其他地址的额度
    mapping(address => uint256) public nonces; // 地址对应的 nonces 这个貌似是签名要查的 nonce？？

    event Approval(address indexed src, address indexed guy, uint256 wad); // 授权事件
    event Transfer(address indexed src, address indexed dst, uint256 wad); // 转账事件

    // --- Math ---
    function add(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x + y) >= x); // 检查相加溢出
    }

    function sub(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x - y) <= x); // 建擦相减溢出
    }

    // --- EIP712 niceties ---
    bytes32 public DOMAIN_SEPARATOR;
    // bytes32 public constant PERMIT_TYPEHASH = keccak256("Permit(address holder,address spender,uint256 nonce,uint256 expiry,bool allowed)");
    bytes32 public constant PERMIT_TYPEHASH =
        0xea2aa0a1be11a07ed86d755c93467f4f82362b452371d1ba94d1715123511acb;

    // 构造器
    constructor(uint256 chainId_) public {
        wards[msg.sender] = 1; // 将合约部署者设置为守卫地址
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256(
                    "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
                ),
                keccak256(bytes(name)),
                keccak256(bytes(version)),
                chainId_,
                address(this)
            )
        );
    }

    // --- Token ---
    function transfer(address dst, uint256 wad) external returns (bool) {
        return transferFrom(msg.sender, dst, wad);
    }

    function transferFrom(
        address src,
        address dst,
        uint256 wad
    ) public returns (bool) {
        require(balanceOf[src] >= wad, "Dai/insufficient-balance"); // 要求余额大于转账额度
        if (src != msg.sender && allowance[src][msg.sender] != uint256(-1)) {
            // 如果调用者不是出钱方，需要进一步判断允许额度，如果是全是 1，就是最大允许额度，表示不限制，也不会因为本次转账调整额度
            require(
                allowance[src][msg.sender] >= wad, // 要求允许额度大于本次转账额度
                "Dai/insufficient-allowance"
            );
            allowance[src][msg.sender] = sub(allowance[src][msg.sender], wad); // 设置新的额度
        }
        balanceOf[src] = sub(balanceOf[src], wad); // 出钱方减去余额
        balanceOf[dst] = add(balanceOf[dst], wad); // 收钱方增加余额
        emit Transfer(src, dst, wad); // 触发事件
        return true;
    }

    // 铸币函数 外部 仅限守卫地址 直接给某用户地址增加余额，同时增加总供应量
    function mint(address usr, uint256 wad) external auth {
        balanceOf[usr] = add(balanceOf[usr], wad);
        totalSupply = add(totalSupply, wad);
        emit Transfer(address(0), usr, wad); // 触发转账事件 转出人是空地址
    }

    // 销毁函数 外部
    function burn(address usr, uint256 wad) external {
        require(balanceOf[usr] >= wad, "Dai/insufficient-balance"); // 要求出钱人拥有的余额大于要销毁的额度
        if (usr != msg.sender && allowance[usr][msg.sender] != uint256(-1)) {
            // 进一步检查是销毁自己的钱还是销毁别人允许的额度，如果是别人的钱，要再检查额度对不对
            require(
                allowance[usr][msg.sender] >= wad,
                "Dai/insufficient-allowance"
            );
            allowance[usr][msg.sender] = sub(allowance[usr][msg.sender], wad);
        }
        balanceOf[usr] = sub(balanceOf[usr], wad); // 出钱方余额减去
        totalSupply = sub(totalSupply, wad); // 总供应量减去
        emit Transfer(usr, address(0), wad); // 触发转账事件 转入方是空地址  why？ 这个出钱方我觉得应该写调用者地址
    }

    // 授权函数
    function approve(address usr, uint256 wad) external returns (bool) {
        allowance[msg.sender][usr] = wad;
        emit Approval(msg.sender, usr, wad);
        return true;
    }

    // 别名函数
    // --- Alias ---
    // push 把调用方的钱转给目标地址
    function push(address usr, uint256 wad) external {
        transferFrom(msg.sender, usr, wad);
    }

    // pull 把目标地址的钱转给自己
    function pull(address usr, uint256 wad) external {
        transferFrom(usr, msg.sender, wad);
    }

    // 移动，把某地址的钱转给另一个地址
    function move(
        address src,
        address dst,
        uint256 wad
    ) external {
        transferFrom(src, dst, wad);
    }

    // --- Approve by signature ---
    // 通过签名方式进行授权
    function permit(
        address holder, // 持有方
        address spender, // 花费方
        uint256 nonce, // 签名的 nonce
        uint256 expiry, // 过期时间
        bool allowed, // 是否允许，这里的意思是 要么授权全部额度，要么取消额度
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        // 计算 hash 值
        // 要不断加深签名方式的使用流程
        // 1. 目标是验证 ecrecover(digest, v, r, s) 通过，并获取地址？？ 偏置向量？好像是随机数，r 我猜是公钥， s 是私钥签名的结果，整个验证通过后把公钥生成的地址返回
        // 1.1 就要计算 digest 的值，通用的计算方法是 hash 一个字节数组
        //     前缀 "\x19\x01"
        //     域分隔符统一标准是 EIP712Domain(string name,string version,uint256 chainId,address verifyingContract) 加具体参数的 hash 结果
        //         这样即使改变链 id 这个值就不一样了 我觉得不应该叫什么域分割符，明明就是标识而已 名字 版本 链id 合约地址，任何一个不一样都会改变
        //     参数合并 类似域分隔符的生成一样 标识符号 Permit(address holder,address spender,uint256 nonce,uint256 expiry,bool allowed) 的 hash 具体值在后面
        // 2. 以上验证通过后，可以证明，传入参数是正确的，调用者确实是有 hodler 的私钥的，不管这个签名是从哪里来的，是自己主动发起的，还是把签名好的内容给别人，别人再发交易
        //      主要是是证明有私钥的人同意了这个授权
        // 备注：调用这个方法时，先准备前 5 个参数，再利用私钥签名 5 个参数构成的 digest 得到 v r s。就可以调用方法了。
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                keccak256(
                    abi.encode(
                        PERMIT_TYPEHASH,
                        holder,
                        spender,
                        nonce,
                        expiry,
                        allowed
                    )
                )
            )
        );

        require(holder != address(0), "Dai/invalid-address-0"); // 要求持有钱的人不是空地址
        require(holder == ecrecover(digest, v, r, s), "Dai/invalid-permit"); // 要求签名正确
        require(expiry == 0 || now <= expiry, "Dai/permit-expired"); // 要求过期时间不在当前时间之后  0 表示不限制过期时间
        require(nonce == nonces[holder]++, "Dai/invalid-nonce"); // nonce 比较要相等，之后再进行自增
        uint256 wad = allowed ? uint256(-1) : 0; // 要么授权全部额度，要么取消所有额度
        allowance[holder][spender] = wad; // 记录授权额度
        emit Approval(holder, spender, wad); // 触发日志
    }
}
