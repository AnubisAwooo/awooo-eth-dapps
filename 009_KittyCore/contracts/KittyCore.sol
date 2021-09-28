/// https://etherscan.io/address/0x06012c8cf97bead5deae237070f9587f8e7a266d#code
/// Submitted for verification at Etherscan.io on 2017-11-28
pragma solidity ^0.4.11;

/// 所有者合约拥有一个所有者，提供基本的授权控制函数，简化的用户权限的实现
contract Ownable {
    address public owner; // 所有者地址

    /// 构造函数设置所有者
    function Ownable() {
        owner = msg.sender;
    }

    /// 修改器前置验证所有权
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    /// 转移所有权函数，要求当前所有者调用
    /// 传入新的所有者地址 非 0 地址
    function transferOwnership(address newOwner) onlyOwner {
        if (newOwner != address(0)) {
            owner = newOwner;
        }
    }
}

/// ERC721  NFT 代币接口 Non-Fungible Tokens
contract ERC721 {
    // Required methods
    function totalSupply() public view returns (uint256 total);

    function balanceOf(address _owner) public view returns (uint256 balance);

    function ownerOf(uint256 _tokenId) external view returns (address owner);

    function approve(address _to, uint256 _tokenId) external;

    function transfer(address _to, uint256 _tokenId) external;

    function transferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) external;

    // Events
    event Transfer(address from, address to, uint256 tokenId);
    event Approval(address owner, address approved, uint256 tokenId);

    // Optional
    // function name() public view returns (string name);
    // function symbol() public view returns (string symbol);
    // function tokensOfOwner(address _owner) external view returns (uint256[] tokenIds);
    // function tokenMetadata(uint256 _tokenId, string _preferredTransport) public view returns (string infoUrl);

    /// ERC165 提供函数检查是否实现了某函数
    // ERC-165 Compatibility (https://github.com/ethereum/EIPs/issues/165)
    function supportsInterface(bytes4 _interfaceID)
        external
        view
        returns (bool);
}

// // Auction wrapper functions

// Auction wrapper functions

/// what？ 基因科学接口
contract GeneScienceInterface {
    /// 是否实现了基因科学？
    function isGeneScience() public pure returns (bool);

    /// 混合基因 母猫基因 公猫基因 目标块？ -> 下一代基因
    function mixGenes(
        uint256 genes1,
        uint256 genes2,
        uint256 targetBlock
    ) public returns (uint256);
}

/// 管理特殊访问权限的门面
contract KittyAccessControl {
    // 4 个角色
    // CEO 角色 任命其他角色 改变依赖的合约的地址 唯一可以停止加密猫的角色 在合约初始化时设置
    // CFO 角色 可以从机密猫和它的拍卖合约中提出资金
    // COO 角色 可以释放第 0 代加密猫 创建推广猫咪
    // 这些权限被详细的分开。虽然 CEO 可以给指派任何角色，但 CEO 并不能够直接做这些角色的工作。
    // 并非有意限制，而是尽量少使用 CEO 地址。使用的越少，账户被破坏的可能性就越小。

    /// 合约升级事件
    event ContractUpgrade(address newContract);

    // 每种角色的地址，也有可能是合约的地址.
    address public ceoAddress;
    address public cfoAddress;
    address public cooAddress;

    // 保持关注变量 paused 是否为真，一旦为真，大部分操作是不能够实行的
    bool public paused = false;

    /// 修改器仅限 CEO
    modifier onlyCEO() {
        require(msg.sender == ceoAddress);
        _;
    }

    ///  修改器仅限 CFO
    modifier onlyCFO() {
        require(msg.sender == cfoAddress);
        _;
    }

    /// 修改器仅限 COO
    modifier onlyCOO() {
        require(msg.sender == cooAddress);
        _;
    }

    /// 修改器仅限管理层(CEO 或 CFO 或 COO)
    modifier onlyCLevel() {
        require(
            msg.sender == cooAddress ||
                msg.sender == ceoAddress ||
                msg.sender == cfoAddress
        );
        _;
    }

    /// 设置新的 CEO 地址 仅限 CEO 操作
    function setCEO(address _newCEO) external onlyCEO {
        require(_newCEO != address(0));

        ceoAddress = _newCEO;
    }

    /// 设置新的 CFO 地址 仅限 CEO 操作
    function setCFO(address _newCFO) external onlyCEO {
        require(_newCFO != address(0));

        cfoAddress = _newCFO;
    }

    /// 设置新的 COO 地址 仅限 CEO 操作
    function setCOO(address _newCOO) external onlyCEO {
        require(_newCOO != address(0));

        cooAddress = _newCOO;
    }

    // OpenZeppelin 提供了很多合约方便使用，每个都应该研究一下
    /*** Pausable functionality adapted from OpenZeppelin ***/

    /// 修改器仅限没有停止合约
    modifier whenNotPaused() {
        require(!paused);
        _;
    }

    /// 修改器仅限已经停止合约
    modifier whenPaused() {
        require(paused);
        _;
    }

    /// 停止函数 仅限管理层 未停止时 调用
    /// 在遇到 bug 或者 检测到非法牟利 这时需要限制损失
    /// 仅可外部调用
    function pause() external onlyCLevel whenNotPaused {
        paused = true;
    }

    /// 开始合约 仅限 CEO 已经停止时 调用
    /// 不能给 CFO 或 COO 权限，因为万一他们账户被盗。
    /// 注意这个方法不是外部的，公开表明可以被子合约调用
    function unpause() public onlyCEO whenPaused {
        // can't unpause if contract was upgraded
        // what? 如果合约升级了，不能被停止？？
        paused = false;
    }
}

/// 加密猫的基合约 包含所有普通结构体 事件 和 基本变量
contract KittyBase is KittyAccessControl {
    /*** EVENTS ***/

    /// 出生事件
    /// giveBirth 方法触发
    /// 第 0 代猫咪被创建也会被触发
    event Birth(
        address owner,
        uint256 kittyId,
        uint256 matronId,
        uint256 sireId,
        uint256 genes
    );

    /// 转账事件是 ERC721 定义的标准时间，这里猫咪第一次被赋予所有者也会触发
    event Transfer(address from, address to, uint256 tokenId);

    /*** DATA TYPES ***/

    /// 猫咪的主要结构体，加密猫里的每个猫都要用这个结构体表示。务必确保这个结构体使用 2 个 256 位的字数。
    /// 由于以太坊自己包装跪着，这个结构体中顺序很重要（改动就不满足 2 个 256 要求了）
    struct Kitty {
        // 猫咪的基因是 256 位，格式是 sooper-sekret 不知道这是什么格式？？
        uint256 genes;
        // 出生的时间戳
        uint64 birthTime;
        // 这只猫可以再次进行繁育活动的最小时间戳 公猫和母猫都用这个时间戳 冷却时间？！
        uint64 cooldownEndBlock;
        // 下面 ID 用于记录猫咪的父母，对于第 0 代猫咪，设置为 0
        // 采用 32 位数字，最大仅有 4 亿多点，目前够用了 截止目前 2021-09-26 有 200 万个猫咪了
        uint32 matronId;
        uint32 sireId;
        // 母猫怀孕的话，设置为公猫的 id，否则是 0。非 0 表明猫咪怀孕了。
        // 当新的猫出生时需要基因物质。
        uint32 siringWithId;
        // 当前猫咪的冷却时间，是冷却时间数组的序号。第 0 代猫咪开始为 0，其他的猫咪是代数除以 2，每次成功繁育后都要自增 1
        uint16 cooldownIndex;
        // 代数 直接由合约创建出来的是第 0 代，其他出生的猫咪由父母最大代数加 1
        uint16 generation;
    }

    /*** 常量 ***/

    /// 冷却时间查询表
    /// 设计目的是鼓励玩家不要老拿一只猫进行繁育
    /// 最大冷却时间是一周
    uint32[14] public cooldowns = [
        uint32(1 minutes),
        uint32(2 minutes),
        uint32(5 minutes),
        uint32(10 minutes),
        uint32(30 minutes),
        uint32(1 hours),
        uint32(2 hours),
        uint32(4 hours),
        uint32(8 hours),
        uint32(16 hours),
        uint32(1 days),
        uint32(2 days),
        uint32(4 days),
        uint32(7 days)
    ];

    // 目前每个块之间的时间间隔估计
    uint256 public secondsPerBlock = 15;

    /*** 存储 ***/

    /// 所有猫咪数据的列表 ID 就是猫咪在这个列表的序号
    /// id 为 0 的猫咪是神秘生物，生育了第 0 代猫咪
    Kitty[] kitties;

    /// 猫咪 ID 对应所有者的映射，第 0 代猫咪也有
    mapping(uint256 => address) public kittyIndexToOwner;

    //// 所有者对拥有猫咪数量的映射 是 ERC721 接口 balanceOf 的底层数据支持
    mapping(address => uint256) ownershipTokenCount;

    /// 猫咪对应的授权地址，授权地址可以取得猫咪的所有权 对应 ERC721 接口 transferFrom 方法
    mapping(uint256 => address) public kittyIndexToApproved;

    /// 猫咪对应授权对方可以进行繁育的数据结构 对方可以通过 breedWith 方法进行猫咪繁育
    mapping(uint256 => address) public sireAllowedToAddress;

    /// 定时拍卖合约的地址 点对点销售的合约 也是第 0 代猫咪每 15 分钟初始化的地方
    SaleClockAuction public saleAuction;

    /// 繁育拍卖合约地址 需要和销售拍卖分开 二者有很大区别，分开为好
    SiringClockAuction public siringAuction;

    /// 内部给予猫咪所有者的方法 仅本合约可用 what？感觉这个方法子类应该也可以调用啊？？？
    function _transfer(
        address _from,
        address _to,
        uint256 _tokenId
    ) internal {
        // Since the number of kittens is capped to 2^32 we can't overflow this
        // 对应地址所拥有的数量加 1
        ownershipTokenCount[_to]++;
        // 设置所有权
        kittyIndexToOwner[_tokenId] = _to;
        // 第 0 代猫咪最开始没有 from，后面才会有
        if (_from != address(0)) {
            // 如果有所有者
            // 所有者猫咪数量减 1
            ownershipTokenCount[_from]--;
            // 该猫咪设置过的允许繁育的地址删除 不能被上一个所有者设置的别人可以繁育继续有效
            delete sireAllowedToAddress[_tokenId];
            // 该猫咪设置过的允许授权的地址删除 不能被上一个所有者设置的别人可以拿走继续有效
            delete kittyIndexToApproved[_tokenId];
        }
        // 触发所有权变更事件，第 0 代猫咪创建之后，也会触发事件
        Transfer(_from, _to, _tokenId);
    }

    /// 创建猫咪并存储的内部方法 不做权限参数检查，必须保证传入参数是正确的 会触发出生和转移事件
    /// @param _matronId 母猫 id  第 0 代的话是 0
    /// @param _sireId  公猫 id  第 0 代的话是 0
    /// @param _generation 代数，必须先计算好
    /// @param _genes 基因
    /// @param _owner 初始所有者 (except for the unKitty, ID 0)
    function _createKitty(
        uint256 _matronId,
        uint256 _sireId,
        uint256 _generation,
        uint256 _genes,
        address _owner
    ) internal returns (uint256) {
        // 这些检查是非严格检查，调用这应当确保参数是有效的，本方法依据是个非常昂贵的调用，不要再耗费 gas 检查参数了
        require(_matronId == uint256(uint32(_matronId)));
        require(_sireId == uint256(uint32(_sireId)));
        require(_generation == uint256(uint16(_generation)));

        // 新猫咪的冷却序号是代数除以 2
        uint16 cooldownIndex = uint16(_generation / 2);
        if (cooldownIndex > 13) {
            cooldownIndex = 13;
        }

        Kitty memory _kitty = Kitty({
            genes: _genes,
            birthTime: uint64(now),
            cooldownEndBlock: 0,
            matronId: uint32(_matronId),
            sireId: uint32(_sireId),
            siringWithId: 0,
            cooldownIndex: cooldownIndex,
            generation: uint16(_generation)
        });
        uint256 newKittenId = kitties.push(_kitty) - 1;

        // 确保是 32 位id
        require(newKittenId == uint256(uint32(newKittenId)));

        // 触发出生事件
        Birth(
            _owner,
            newKittenId,
            uint256(_kitty.matronId),
            uint256(_kitty.sireId),
            _kitty.genes
        );

        // 触发所有权转移事件
        _transfer(0, _owner, newKittenId);

        return newKittenId;
    }

    /// 设置估计的每个块间隔，这里检查必须小于 1 分钟了
    /// 必须管理层调用 外部函数
    function setSecondsPerBlock(uint256 secs) external onlyCLevel {
        require(secs < cooldowns[0]);
        secondsPerBlock = secs;
    }
}

/// 外部合约 返回猫咪的元数据 只有一个方法返回字节数组数据
contract ERC721Metadata {
    /// 给 id 返回字节数组数据，能转化为字符串
    /// what？ 这都是写死的数据，不知道有什么用
    function getMetadata(uint256 _tokenId, string)
        public
        view
        returns (bytes32[4] buffer, uint256 count)
    {
        if (_tokenId == 1) {
            buffer[0] = "Hello World! :D";
            count = 15;
        } else if (_tokenId == 2) {
            buffer[0] = "I would definitely choose a medi";
            buffer[1] = "um length string.";
            count = 49;
        } else if (_tokenId == 3) {
            buffer[0] = "Lorem ipsum dolor sit amet, mi e";
            buffer[1] = "st accumsan dapibus augue lorem,";
            buffer[2] = " tristique vestibulum id, libero";
            buffer[3] = " suscipit varius sapien aliquam.";
            count = 128;
        }
    }
}

/// 加密猫核心合约的门面 管理权限
contract KittyOwnership is KittyBase, ERC721 {
    /// ERC721 接口
    string public constant name = "CryptoKitties";
    string public constant symbol = "CK";

    // 元数据合约
    ERC721Metadata public erc721Metadata;

    /// 方法签名常量，ERC165 要求的方法
    bytes4 constant InterfaceSignature_ERC165 =
        bytes4(keccak256("supportsInterface(bytes4)"));

    /// ERC721 要求的方法签名
    /// 字节数组的 ^ 运算时什么意思??
    /// 我明白了，ERC721 是一堆方法，不用一各一个验证，这么多方法一起合成一个值，这个值有就行了
    bytes4 constant InterfaceSignature_ERC721 =
        bytes4(keccak256("name()")) ^
            bytes4(keccak256("symbol()")) ^
            bytes4(keccak256("totalSupply()")) ^
            bytes4(keccak256("balanceOf(address)")) ^
            bytes4(keccak256("ownerOf(uint256)")) ^
            bytes4(keccak256("approve(address,uint256)")) ^
            bytes4(keccak256("transfer(address,uint256)")) ^
            bytes4(keccak256("transferFrom(address,address,uint256)")) ^
            bytes4(keccak256("tokensOfOwner(address)")) ^
            bytes4(keccak256("tokenMetadata(uint256,string)"));

    /// 实现 ERC165 的方法
    function supportsInterface(bytes4 _interfaceID)
        external
        view
        returns (bool)
    {
        // DEBUG ONLY
        //require((InterfaceSignature_ERC165 == 0x01ffc9a7) && (InterfaceSignature_ERC721 == 0x9a20483d));

        return ((_interfaceID == InterfaceSignature_ERC165) ||
            (_interfaceID == InterfaceSignature_ERC721));
    }

    /// 设置元数据合约地址，原来这个地址是可以修改的，那么就可以更新了 仅限 CEO 修改
    function setMetadataAddress(address _contractAddress) public onlyCEO {
        erc721Metadata = ERC721Metadata(_contractAddress);
    }

    /// 内部工具函数，这些函数被假定输入参数是有效的。 参数校验留给公开方法处理。

    /// 检查指定地址是否拥有某只猫咪 内部函数
    function _owns(address _claimant, uint256 _tokenId)
        internal
        view
        returns (bool)
    {
        return kittyIndexToOwner[_tokenId] == _claimant;
    }

    /// 检查某只猫咪收被授权给某地址 内部函数
    function _approvedFor(address _claimant, uint256 _tokenId)
        internal
        view
        returns (bool)
    {
        return kittyIndexToApproved[_tokenId] == _claimant;
    }

    /// 猫咪收被授权给地址 这样该地址就能够通过 transferFrom 方法取得所有权 内部函数
    /// 同一时间只允许有一个授权地址，如果地址是 0 的话，表示清除授权
    /// 该方法不触发事件，故意不触发事件。当前方法和transferFrom方法一起在拍卖中使用，拍卖触发授权事件没有意义。
    function _approve(uint256 _tokenId, address _approved) internal {
        kittyIndexToApproved[_tokenId] = _approved;
    }

    /// 返回某地址拥有的数量 这也是 ERC721 的方法
    function balanceOf(address _owner) public view returns (uint256 count) {
        return ownershipTokenCount[_owner];
    }

    /// 转移猫咪给其他地址 修改器检查只在非停止状态下允许转移 外部函数
    /// 如果是转移给其他合约的地址，请清楚行为的后果，否则有可能永久失去这只猫咪
    function transfer(address _to, uint256 _tokenId) external whenNotPaused {
        // 要求地址不为 0
        require(_to != address(0));
        /// 禁止转移给加密猫合约地址 本合约地址不应该拥有任何一只猫咪 除了再创建第 0 代并且还没进入拍卖的时候
        require(_to != address(this));
        /// 禁止转移给销售拍卖和繁育拍卖地址，销售拍卖对加密猫的所有权仅限于通过 授权 和 transferFrom 的方式
        require(_to != address(saleAuction));
        require(_to != address(siringAuction));

        // 要求调用方拥有这只猫咪
        require(_owns(msg.sender, _tokenId));

        // 更改所有权 清空授权 触发转移事件
        _transfer(msg.sender, _to, _tokenId);
    }

    /// 授权给其他地址 修改器检查只在非停止状态下允许 外部函数
    /// 其他合约可以通过transferFrom取得所有权。这个方法被期望在授权给合约地址，参入地址为 0 的话就表明清除授权
    /// ERC721 要求方法
    function approve(address _to, uint256 _tokenId) external whenNotPaused {
        // 要求调用方拥有这只猫咪
        require(_owns(msg.sender, _tokenId));

        // 进行授权
        _approve(_tokenId, _to);

        // 触发授权事件
        Approval(msg.sender, _to, _tokenId);
    }

    /// 取得猫咪所有权 修改器检查只在非停止状态下允许 外部函数
    /// ERC721 要求方法
    function transferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) external whenNotPaused {
        // 检查目标地址不是 0
        require(_to != address(0));
        // 禁止转移给当前合约
        require(_to != address(this));
        // 检查调用者是否有被授权，猫咪所有者地址是否正确
        require(_approvedFor(msg.sender, _tokenId));
        require(_owns(_from, _tokenId));

        // 更改所有权 清空授权 触发转移事件
        _transfer(_from, _to, _tokenId);
    }

    /// 目前所有猫咪数量 公开方法 只读
    /// ERC721 要求方法
    function totalSupply() public view returns (uint256) {
        return kitties.length - 1;
    }

    /// 查询某只猫咪的所有者 外部函数 只读
    /// ERC721 要求方法
    function ownerOf(uint256 _tokenId) external view returns (address owner) {
        owner = kittyIndexToOwner[_tokenId];

        require(owner != address(0));
    }

    /// 返回某地址拥有的所有猫咪 id 列表 外部函数 只读
    /// 这个方法不应该被合约调用，因为太消耗 gas
    /// 这方法返回一个动态数组，仅支持 web3 调用，不支持合约对合约的调用
    function tokensOfOwner(address _owner)
        external
        view
        returns (uint256[] ownerTokens)
    {
        uint256 tokenCount = balanceOf(_owner);

        if (tokenCount == 0) {
            // 返回空数组
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            uint256 totalCats = totalSupply();
            uint256 resultIndex = 0;

            // 遍历所有的猫咪如果地址相符就记录
            uint256 catId;

            for (catId = 1; catId <= totalCats; catId++) {
                if (kittyIndexToOwner[catId] == _owner) {
                    result[resultIndex] = catId;
                    resultIndex++;
                }
            }

            return result;
        }
    }

    /// 内存拷贝方法
    function _memcpy(
        uint256 _dest,
        uint256 _src,
        uint256 _len
    ) private view {
        // Copy word-length chunks while possible
        // 32 位一块一块复制
        for (; _len >= 32; _len -= 32) {
            assembly {
                // 取出原地址 放到目标地址
                mstore(_dest, mload(_src))
            }
            _dest += 32;
            _src += 32;
        }

        // Copy remaining bytes
        // what? 剩下的部分看不明白了 这个指数运算啥意思啊
        uint256 mask = 256**(32 - _len) - 1;
        assembly {
            let srcpart := and(mload(_src), not(mask))
            let destpart := and(mload(_dest), mask)
            mstore(_dest, or(destpart, srcpart))
        }
    }

    /// 转换成字符串
    function _toString(bytes32[4] _rawBytes, uint256 _stringLength)
        private
        view
        returns (string)
    {
        // 先得到指定长度的字符串
        var outputString = new string(_stringLength);
        uint256 outputPtr;
        uint256 bytesPtr;

        assembly {
            // what？ 这是取出指定变量的地址？？
            outputPtr := add(outputString, 32)
            // 为啥这个就直接当地址用了？？
            bytesPtr := _rawBytes
        }

        _memcpy(outputPtr, bytesPtr, _stringLength);

        return outputString;
    }

    /// 返回指定猫咪的元数据 包含 URI 信息
    function tokenMetadata(uint256 _tokenId, string _preferredTransport)
        external
        view
        returns (string infoUrl)
    {
        // 要求元数据合约地址指定
        require(erc721Metadata != address(0));
        bytes32[4] memory buffer;
        uint256 count;
        (buffer, count) = erc721Metadata.getMetadata(
            _tokenId,
            _preferredTransport
        );

        return _toString(buffer, count);
    }
}

/// 加密猫核心合约的门面 管理猫咪生育 妊娠 和 出生
contract KittyBreeding is KittyOwnership {
    /// 怀孕事件  当 2 只猫咪成功的饲养并怀孕
    event Pregnant(
        address owner,
        uint256 matronId,
        uint256 sireId,
        uint256 cooldownEndBlock
    );

    /// 自动出生费？ breedWithAuto方法使用，这个费用会在 giveBirth 方法中转变成 gas 消耗
    /// 可以被 COO 动态更新
    uint256 public autoBirthFee = 2 finney;

    // 怀孕的猫咪计数
    uint256 public pregnantKitties;

    /// 基于科学 兄弟合约 实现基因混合算法，，
    GeneScienceInterface public geneScience;

    /// 设置基因合约 仅限 CEO 调用
    function setGeneScienceAddress(address _address) external onlyCEO {
        GeneScienceInterface candidateContract = GeneScienceInterface(_address);

        require(candidateContract.isGeneScience()); // 要求是基因科学合约

        geneScience = candidateContract;
    }

    /// 检查猫咪是否准备好繁育了 内部函数 只读 要求冷却时间结束
    function _isReadyToBreed(Kitty _kit) internal view returns (bool) {
        // 额外检查冷却结束的块 我们同样需要建擦猫咪是否有等待出生？？ 在猫咪怀孕结束和出生事件之间存在一些时间周期？？莫名其妙
        // In addition to checking the cooldownEndBlock, we also need to check to see if
        // the cat has a pending birth; there can be some period of time between the end
        // of the pregnacy timer and the birth event.
        return
            (_kit.siringWithId == 0) &&
            (_kit.cooldownEndBlock <= uint64(block.number));
    }

    /// 检查公猫是否授权和这个母猫繁育 内部函数 只读 如果是同一个所有者，或者公猫已经授权给母猫的地址，返回 true
    function _isSiringPermitted(uint256 _sireId, uint256 _matronId)
        internal
        view
        returns (bool)
    {
        address matronOwner = kittyIndexToOwner[_matronId];
        address sireOwner = kittyIndexToOwner[_sireId];

        return (matronOwner == sireOwner ||
            sireAllowedToAddress[_sireId] == matronOwner);
    }

    /// 设置猫咪的冷却时间 基于当前冷却时间序号 同时增加冷却时间序号除非达到最大序号 内部函数
    function _triggerCooldown(Kitty storage _kitten) internal {
        // 计算估计冷却的块
        _kitten.cooldownEndBlock = uint64(
            (cooldowns[_kitten.cooldownIndex] / secondsPerBlock) + block.number
        );

        // 繁育序号加一 最大是 13，冷却时间数组的最大长度，本来也可以数组的长度，但是这里硬编码进常量，为了节省 gas 费
        if (_kitten.cooldownIndex < 13) {
            _kitten.cooldownIndex += 1;
        }
    }

    /// 授权繁育 外部函数 仅限非停止状态
    /// 地址是将要和猫咪繁育的猫咪的所有者 设置 0 地址表明取消繁育授权
    function approveSiring(address _addr, uint256 _sireId)
        external
        whenNotPaused
    {
        require(_owns(msg.sender, _sireId)); // 检查猫咪所有权
        sireAllowedToAddress[_sireId] = _addr; // 记录允许地址
    }

    /// 设置自动出生费 外部函数 仅限 COO
    function setAutoBirthFee(uint256 val) external onlyCOO {
        autoBirthFee = val;
    }

    /// 是否准备好出生 私有 只读
    function _isReadyToGiveBirth(Kitty _matron) private view returns (bool) {
        return
            (_matron.siringWithId != 0) &&
            (_matron.cooldownEndBlock <= uint64(block.number));
    }

    /// 检查猫咪是否准备好繁育 公开 只读
    function isReadyToBreed(uint256 _kittyId) public view returns (bool) {
        require(_kittyId > 0);
        Kitty storage kit = kitties[_kittyId];
        return _isReadyToBreed(kit);
    }

    /// 是否猫咪怀孕了 公开 只读
    function isPregnant(uint256 _kittyId) public view returns (bool) {
        require(_kittyId > 0);
        // 如果 siringWithId 被设置了表明就是怀孕了
        return kitties[_kittyId].siringWithId != 0;
    }

    /// 内部检查公猫和母猫是不是个有效对 不检查所有权
    function _isValidMatingPair(
        Kitty storage _matron,
        uint256 _matronId,
        Kitty storage _sire,
        uint256 _sireId
    ) private view returns (bool) {
        // 不能是自己
        if (_matronId == _sireId) {
            return false;
        }

        // 母猫的妈妈不能是公猫 母猫的爸爸不能是公猫
        if (_matron.matronId == _sireId || _matron.sireId == _sireId) {
            return false;
        }
        // 公猫的妈妈不能是母猫 公猫的爸爸不能是母猫
        if (_sire.matronId == _matronId || _sire.sireId == _matronId) {
            return false;
        }

        // 如果公猫或母猫的妈妈是第 0 代猫咪，允许繁育
        // We can short circuit the sibling check (below) if either cat is
        // gen zero (has a matron ID of zero).
        if (_sire.matronId == 0 || _matron.matronId == 0) {
            return true;
        }

        // 讲真我对加密猫的血缘检查无语了，什么乱七八糟的
        // 猫咪不能与带血缘关系的繁育，同妈妈 或 公猫的妈妈和母猫的爸爸是同一个
        if (
            _sire.matronId == _matron.matronId ||
            _sire.matronId == _matron.sireId
        ) {
            return false;
        }
        // 同爸爸 或 公猫的爸爸和母猫的妈妈是同一个
        if (
            _sire.sireId == _matron.matronId || _sire.sireId == _matron.sireId
        ) {
            return false;
        }

        // Everything seems cool! Let's get DTF.
        return true;
    }

    /// 内部检查是否可以通过拍卖进行繁育
    function _canBreedWithViaAuction(uint256 _matronId, uint256 _sireId)
        internal
        view
        returns (bool)
    {
        Kitty storage matron = kitties[_matronId];
        Kitty storage sire = kitties[_sireId];
        return _isValidMatingPair(matron, _matronId, sire, _sireId);
    }

    /// 检查 2 只猫咪是否可以繁育 外部函数 只读 检查所有权授权 不检查猫咪是否准备好繁育 在冷却时间期间是不能繁育成功的
    function canBreedWith(uint256 _matronId, uint256 _sireId)
        external
        view
        returns (bool)
    {
        require(_matronId > 0);
        require(_sireId > 0);
        Kitty storage matron = kitties[_matronId];
        Kitty storage sire = kitties[_sireId];
        return
            _isValidMatingPair(matron, _matronId, sire, _sireId) &&
            _isSiringPermitted(_sireId, _matronId);
    }

    /// 内部工具函数初始化繁育 假定所有的繁育要求已经满足 内部函数
    function _breedWith(uint256 _matronId, uint256 _sireId) internal {
        // 获取猫咪信息
        Kitty storage sire = kitties[_sireId];
        Kitty storage matron = kitties[_matronId];

        // 标记母猫怀孕 指向公猫
        matron.siringWithId = uint32(_sireId);

        // 设置冷却时间
        _triggerCooldown(sire);
        _triggerCooldown(matron);

        // 情况授权繁育地址，似乎多次一句，这里可以避免困惑
        // tips 如果别人指向授权给某个人。每次繁育后还要继续设置，岂不是很烦躁
        delete sireAllowedToAddress[_matronId];
        delete sireAllowedToAddress[_sireId];

        // 怀孕的猫咪计数加 1
        pregnantKitties++;

        //  触发怀孕事件
        Pregnant(
            kittyIndexToOwner[_matronId],
            _matronId,
            _sireId,
            matron.cooldownEndBlock
        );
    }

    /// 自动哺育一个猫咪 外部函数 可支付 仅限非停止状态
    /// 哺育一个猫咪 作为母猫提供者，和公猫提供者 或 被授权的公猫
    /// 猫咪是否会怀孕 或 完全失败  要看 giveBirth 函数给与的预支付的费用
    function breedWithAuto(uint256 _matronId, uint256 _sireId)
        external
        payable
        whenNotPaused
    {
        require(msg.value >= autoBirthFee); // 要求大于自动出生费

        require(_owns(msg.sender, _matronId)); // 要求是母猫所有者

        // 哺育操作期间 允许猫咪被拍卖 拍卖的事情这里不关心
        // 对于母猫：这个方法的调用者不会是母猫的所有者，因为猫咪的所有者是拍卖合约 拍卖合约不会调用繁育方法
        // 对于公猫：统一，公猫也属于拍卖合约，转移猫咪会清除繁育授权
        // 因此我们不花费 gas 费检查猫咪是否属于拍卖合约

        // 检查猫咪是否都属于调用者 或 公猫是给与授权的
        require(_isSiringPermitted(_sireId, _matronId));

        Kitty storage matron = kitties[_matronId]; // 获取母猫信息

        require(_isReadyToBreed(matron)); // 确保母猫不是怀孕状态 或者 哺育冷却期

        Kitty storage sire = kitties[_sireId]; // 获取公猫信息

        require(_isReadyToBreed(sire)); // 确保公猫不是怀孕状态 或者 哺育冷却期

        require(_isValidMatingPair(matron, _matronId, sire, _sireId)); // 确保猫咪是有效的匹配

        _breedWith(_matronId, _sireId); // 进行繁育任务
    }

    /// 已经有怀孕的猫咪 才能 出生 外部函数 仅限非暂停状态
    /// 如果怀孕并且妊娠时间已经过了 联合基因创建一个新的猫咪
    /// 新的猫咪所有者是母猫的所有者
    /// 知道成功的结束繁育，公猫和母猫才会进入下个准备阶段
    /// 注意任何人可以调用这个方法 只要他们愿意支付 gas 费用 但是新猫咪仍然属于母猫的所有者
    function giveBirth(uint256 _matronId)
        external
        whenNotPaused
        returns (uint256)
    {
        Kitty storage matron = kitties[_matronId]; // 获取母猫信息

        require(matron.birthTime != 0); // 要求母猫是有效的猫咪

        // Check that the matron is pregnant, and that its time has come!
        require(_isReadyToGiveBirth(matron)); // 要求母猫准备好生猫咪 是怀孕状态并且时间已经到了

        uint256 sireId = matron.siringWithId; // 公猫 id
        Kitty storage sire = kitties[sireId]; // 公猫信息

        uint16 parentGen = matron.generation; // 母猫代数
        if (sire.generation > matron.generation) {
            parentGen = sire.generation; // 如果公猫代数高，则用公猫代数
        }

        // 调用混合基因的方法
        uint256 childGenes = geneScience.mixGenes(
            matron.genes,
            sire.genes,
            matron.cooldownEndBlock - 1
        );

        // 制作新猫咪
        address owner = kittyIndexToOwner[_matronId];
        uint256 kittenId = _createKitty(
            _matronId,
            matron.siringWithId,
            parentGen + 1,
            childGenes,
            owner
        );

        delete matron.siringWithId; // 清空母猫的配对公猫 id

        pregnantKitties--; // 每次猫咪出生，计数器减 1

        msg.sender.send(autoBirthFee); // 支付给调用方自动出生费用

        return kittenId; // 返回猫咪 id
    }
}

/// 定时拍卖核心 包含 结构 变量 内置方法
contract ClockAuctionBase {
    // 一个 NFT 拍卖的表示
    struct Auction {
        // NFT 当前所有者
        address seller;
        // 开始拍卖的价格 单位 wei
        uint128 startingPrice;
        // 结束买卖的价格 单位 wei
        uint128 endingPrice;
        // 拍卖持续时间 单位秒
        uint64 duration;
        // 拍卖开始时间 如果是 0 表示拍卖已经结束
        uint64 startedAt;
    }

    // 关联的 NFT 合约
    ERC721 public nonFungibleContract;

    // 每次拍卖收税 0-10000 对应这 0%-100%
    uint256 public ownerCut;

    // 每只猫对应的拍卖信息
    mapping(uint256 => Auction) tokenIdToAuction;

    /// 拍卖创建事件
    event AuctionCreated(
        uint256 tokenId,
        uint256 startingPrice,
        uint256 endingPrice,
        uint256 duration
    );
    /// 拍卖成功事件
    event AuctionSuccessful(
        uint256 tokenId,
        uint256 totalPrice,
        address winner
    );
    /// 拍卖取消事件
    event AuctionCancelled(uint256 tokenId);

    /// 某地址是否拥有某只猫咪 内部函数 只读
    function _owns(address _claimant, uint256 _tokenId)
        internal
        view
        returns (bool)
    {
        return (nonFungibleContract.ownerOf(_tokenId) == _claimant);
    }

    /// 托管猫咪 将猫咪托管给当前拍卖合约
    function _escrow(address _owner, uint256 _tokenId) internal {
        // it will throw if transfer fails
        nonFungibleContract.transferFrom(_owner, this, _tokenId);
    }

    /// NFT 转账 内部函数
    function _transfer(address _receiver, uint256 _tokenId) internal {
        // it will throw if transfer fails
        nonFungibleContract.transfer(_receiver, _tokenId);
    }

    /// 增加拍卖 触发拍卖事件 内部函数
    function _addAuction(uint256 _tokenId, Auction _auction) internal {
        // Require that all auctions have a duration of
        // at least one minute. (Keeps our math from getting hairy!)
        require(_auction.duration >= 1 minutes);

        tokenIdToAuction[_tokenId] = _auction;

        // 触发拍卖创建事件
        AuctionCreated(
            uint256(_tokenId),
            uint256(_auction.startingPrice),
            uint256(_auction.endingPrice),
            uint256(_auction.duration)
        );
    }

    /// 取消拍卖 触发取消事件 内部函数
    function _cancelAuction(uint256 _tokenId, address _seller) internal {
        _removeAuction(_tokenId);
        _transfer(_seller, _tokenId);
        AuctionCancelled(_tokenId);
    }

    /// 计算价格并转移 NFT 给胜者 内部函数
    function _bid(uint256 _tokenId, uint256 _bidAmount)
        internal
        returns (uint256)
    {
        // 获取拍卖数据
        Auction storage auction = tokenIdToAuction[_tokenId];

        // 要求拍卖属于激活状态
        require(_isOnAuction(auction));

        // 要求出价不低于当前价格
        uint256 price = _currentPrice(auction);
        require(_bidAmount >= price);

        // 获取卖家地址
        address seller = auction.seller;

        // 移除这个猫咪的拍卖
        _removeAuction(_tokenId);

        // 转账给卖家
        if (price > 0) {
            // 计算拍卖费用
            uint256 auctioneerCut = _computeCut(price);
            uint256 sellerProceeds = price - auctioneerCut;

            // 进行转账
            // 在一个复杂的方法中惊调用转账方法是不被鼓励的，因为可能遇到可重入个攻击或者拒绝服务攻击.
            // 我们明确的通过移除拍卖来防止充入攻击，卖价用 DOS 操作只能攻击他自己的资产
            // 如果真有意外发生，可以通过调用取消拍卖
            seller.transfer(sellerProceeds);
        }

        // 计算超出的额度
        uint256 bidExcess = _bidAmount - price;

        // 返还超出的费用
        msg.sender.transfer(bidExcess);

        // 触发拍卖成功事件
        AuctionSuccessful(_tokenId, price, msg.sender);

        return price;
    }

    /// 删除拍卖 内部函数
    function _removeAuction(uint256 _tokenId) internal {
        delete tokenIdToAuction[_tokenId];
    }

    /// 判断拍卖是否为激活状态 内部函数 只读
    function _isOnAuction(Auction storage _auction)
        internal
        view
        returns (bool)
    {
        return (_auction.startedAt > 0);
    }

    /// 计算当前价格 内部函数 只读
    /// 需要 2 个函数
    /// 当前函数 计算事件  另一个 计算价格
    function _currentPrice(Auction storage _auction)
        internal
        view
        returns (uint256)
    {
        uint256 secondsPassed = 0;

        // 确保正值
        if (now > _auction.startedAt) {
            secondsPassed = now - _auction.startedAt;
        }

        return
            _computeCurrentPrice(
                _auction.startingPrice,
                _auction.endingPrice,
                _auction.duration,
                secondsPassed
            );
    }

    /// 计算拍卖的当前价格 内部函数 纯计算
    function _computeCurrentPrice(
        uint256 _startingPrice,
        uint256 _endingPrice,
        uint256 _duration,
        uint256 _secondsPassed
    ) internal pure returns (uint256) {
        // 没有是有 SafeMath 或类似的函数，是因为所有公开方法 时间最大值是 64 位 货币最大只是 128 位
        if (_secondsPassed >= _duration) {
            // 超出时间就是最后的价格
            return _endingPrice;
        } else {
            // 线性插值？？ 讲真我觉得不算拍卖，明明是插值价格
            int256 totalPriceChange = int256(_endingPrice) -
                int256(_startingPrice);

            int256 currentPriceChange = (totalPriceChange *
                int256(_secondsPassed)) / int256(_duration);

            int256 currentPrice = int256(_startingPrice) + currentPriceChange;

            return uint256(currentPrice);
        }
    }

    /// 收取拍卖费用 内部函数 只读
    function _computeCut(uint256 _price) internal view returns (uint256) {
        return (_price * ownerCut) / 10000;
    }
}

/// 可停止的合约
contract Pausable is Ownable {
    event Pause(); // 停止事件
    event Unpause(); // 继续事件

    bool public paused = false; // what？ 不是已经有一个 paused 了吗？？ 上面的是管理层控制的中止 这个是所有者控制的中止 合约很多

    modifier whenNotPaused() {
        require(!paused);
        _;
    }

    modifier whenPaused() {
        require(paused);
        _;
    }

    function pause() onlyOwner whenNotPaused returns (bool) {
        paused = true;
        Pause();
        return true;
    }

    function unpause() onlyOwner whenPaused returns (bool) {
        paused = false;
        Unpause();
        return true;
    }
}

/// 定时拍卖
contract ClockAuction is Pausable, ClockAuctionBase {
    /// ERC721 接口的方法常量 ERC165 接口返回
    bytes4 constant InterfaceSignature_ERC721 = bytes4(0x9a20483d);

    /// 构造器函数 传入 nft 合约地址和手续费率
    function ClockAuction(address _nftAddress, uint256 _cut) public {
        require(_cut <= 10000);
        ownerCut = _cut;

        ERC721 candidateContract = ERC721(_nftAddress);
        require(candidateContract.supportsInterface(InterfaceSignature_ERC721));
        nonFungibleContract = candidateContract;
    }

    /// 提出余额 外部方法
    function withdrawBalance() external {
        address nftAddress = address(nonFungibleContract);

        // 要求是所有者或 nft 合约
        require(msg.sender == owner || msg.sender == nftAddress);
        // 使用 send 确保就算转账失败也能继续运行
        bool res = nftAddress.send(this.balance);
    }

    /// 创建一个新的拍卖 外部方法 仅限非停止状态
    function createAuction(
        uint256 _tokenId,
        uint256 _startingPrice,
        uint256 _endingPrice,
        uint256 _duration,
        address _seller
    ) external whenNotPaused {
        require(_startingPrice == uint256(uint128(_startingPrice))); // 检查开始价格
        require(_endingPrice == uint256(uint128(_endingPrice))); // 检查结束价格
        require(_duration == uint256(uint64(_duration))); // 检查拍卖持续时间

        require(_owns(msg.sender, _tokenId)); // 检查所有者权限
        _escrow(msg.sender, _tokenId); // 托管猫咪给合约
        Auction memory auction = Auction(
            _seller,
            uint128(_startingPrice),
            uint128(_endingPrice),
            uint64(_duration),
            uint64(now)
        );
        _addAuction(_tokenId, auction); // 保存拍卖信息
    }

    /// 购买一个拍卖 完成拍卖和转移所有权 外部函数 可支付 仅限非停止状态
    function bid(uint256 _tokenId) external payable whenNotPaused {
        _bid(_tokenId, msg.value); // 入股购买资金转移失败，会报异常
        _transfer(msg.sender, _tokenId);
    }

    /// 取消没有胜者的拍卖 外部函数
    /// 注意这个方法可以再合约被停止的情况下调用
    function cancelAuction(uint256 _tokenId) external {
        Auction storage auction = tokenIdToAuction[_tokenId]; // 找到拍卖信息
        require(_isOnAuction(auction)); // 检查拍卖是否激活状态 讲真的，从某种设计的角度来说，我觉得这种检查放到拍卖合约里面检查比较好，额，当前合约就是拍卖合约。。。
        address seller = auction.seller; // 卖家地址
        require(msg.sender == seller); // 检查调用者是不是卖家地址
        _cancelAuction(_tokenId, seller); // 取消拍卖
    }

    /// 取消拍卖 外部函数 仅限停止状态 仅限合约拥有者调用
    /// 紧急情况下使用的方法
    function cancelAuctionWhenPaused(uint256 _tokenId)
        external
        whenPaused
        onlyOwner
    {
        Auction storage auction = tokenIdToAuction[_tokenId]; // 找到拍卖信息
        require(_isOnAuction(auction)); // 检查是否激活状态
        _cancelAuction(_tokenId, auction.seller); // 取消拍卖
    }

    /// 返回拍卖信息 外部函数 只读
    function getAuction(uint256 _tokenId)
        external
        view
        returns (
            address seller,
            uint256 startingPrice,
            uint256 endingPrice,
            uint256 duration,
            uint256 startedAt
        )
    {
        Auction storage auction = tokenIdToAuction[_tokenId]; // 找到拍卖信息
        require(_isOnAuction(auction)); // 检查拍卖是激活状态
        return (
            auction.seller,
            auction.startingPrice,
            auction.endingPrice,
            auction.duration,
            auction.startedAt
        );
    }

    /// 获取拍卖当前价格 外部函数 只读
    function getCurrentPrice(uint256 _tokenId) external view returns (uint256) {
        Auction storage auction = tokenIdToAuction[_tokenId]; // 找到拍卖信息
        require(_isOnAuction(auction)); // 检查拍卖是激活状态
        return _currentPrice(auction); // 计算当前价格
    }
}

/// 繁育拍卖合约
contract SiringClockAuction is ClockAuction {
    // 在setSiringAuctionAddress方法调用中，合约检查确保我们在操作正确的拍卖
    bool public isSiringClockAuction = true;

    // 委托父合约构造函数
    function SiringClockAuction(address _nftAddr, uint256 _cut)
        public
        ClockAuction(_nftAddr, _cut)
    {}

    /// 创建一个拍卖 外部函数
    /// 包装函数 要求调用方必须是 KittyCore 核心
    function createAuction(
        uint256 _tokenId,
        uint256 _startingPrice,
        uint256 _endingPrice,
        uint256 _duration,
        address _seller
    ) external {
        require(_startingPrice == uint256(uint128(_startingPrice))); // 检查开始价格
        require(_endingPrice == uint256(uint128(_endingPrice))); // 检查结束价格
        require(_duration == uint256(uint64(_duration))); // 检查拍卖持续时间

        require(msg.sender == address(nonFungibleContract)); // 要求调用者是 nft 合约地址
        _escrow(_seller, _tokenId); // 授权拍卖
        Auction memory auction = Auction(
            _seller,
            uint128(_startingPrice),
            uint128(_endingPrice),
            uint64(_duration),
            uint64(now)
        );
        _addAuction(_tokenId, auction); // 添加拍卖信息
    }

    /// 发起一个出价 外部函数 可支付
    /// 要求调用方是 KittyCore 合约 因为所有的出价方法都被包装
    /// 同样退回猫咪给卖家 看不懂说的啥 Also returns the kitty to the seller rather than the winner.
    function bid(uint256 _tokenId) external payable {
        require(msg.sender == address(nonFungibleContract));
        address seller = tokenIdToAuction[_tokenId].seller;
        _bid(_tokenId, msg.value);
        _transfer(seller, _tokenId);
    }
}

/// 销售拍卖合约
contract SaleClockAuction is ClockAuction {
    // 在setSaleAuctionAddress方法调用中，合约检查确保我们在操作正确的拍卖
    bool public isSaleClockAuction = true;

    uint256 public gen0SaleCount; // 第 0 代猫咪售出计数
    uint256[5] public lastGen0SalePrices; // 记录最近 5 只第 0 代卖出价格

    // 委托父合约构造函数
    function SaleClockAuction(address _nftAddr, uint256 _cut)
        public
        ClockAuction(_nftAddr, _cut)
    {}

    /// 创建新的拍卖
    function createAuction(
        uint256 _tokenId,
        uint256 _startingPrice,
        uint256 _endingPrice,
        uint256 _duration,
        address _seller
    ) external {
        require(_startingPrice == uint256(uint128(_startingPrice)));
        require(_endingPrice == uint256(uint128(_endingPrice)));
        require(_duration == uint256(uint64(_duration)));

        require(msg.sender == address(nonFungibleContract));
        _escrow(_seller, _tokenId);
        Auction memory auction = Auction(
            _seller,
            uint128(_startingPrice),
            uint128(_endingPrice),
            uint64(_duration),
            uint64(now)
        );
        _addAuction(_tokenId, auction);
    }

    /// 如果卖家是 NFT合约 更新价格
    function bid(uint256 _tokenId) external payable {
        // _bid verifies token ID size
        address seller = tokenIdToAuction[_tokenId].seller;
        uint256 price = _bid(_tokenId, msg.value);
        _transfer(msg.sender, _tokenId);

        // If not a gen0 auction, exit
        if (seller == address(nonFungibleContract)) {
            // Track gen0 sale prices
            lastGen0SalePrices[gen0SaleCount % 5] = price;
            gen0SaleCount++;
        }
    }

    /// 平均第 0 代售价 外部函数 只读
    function averageGen0SalePrice() external view returns (uint256) {
        uint256 sum = 0;
        for (uint256 i = 0; i < 5; i++) {
            sum += lastGen0SalePrices[i];
        }
        return sum / 5;
    }
}

/// 猫咪拍卖合约 创建销售和繁育的拍卖
///  This wrapper of ReverseAuction exists only so that users can create
///  auctions with only one transaction.
contract KittyAuction is KittyBreeding {
    // 当前拍卖合约变量定义在 KittyBase 中，KittyOwnership中有对变量的检查
    // 销售拍卖参考第 0 代拍卖和 p2p 销售
    // 繁育拍卖参考猫咪的繁育权拍卖

    /// 设置销售拍卖合约 外部函数 仅限 CEO 调用
    function setSaleAuctionAddress(address _address) external onlyCEO {
        SaleClockAuction candidateContract = SaleClockAuction(_address);

        require(candidateContract.isSaleClockAuction());

        saleAuction = candidateContract;
    }

    /// 设置繁育排满合约 外部函数 仅限 CEO 调用
    function setSiringAuctionAddress(address _address) external onlyCEO {
        SiringClockAuction candidateContract = SiringClockAuction(_address);

        // NOTE: verify that a contract is what we expect - https://github.com/Lunyr/crowdsale-contracts/blob/cfadd15986c30521d8ba7d5b6f57b4fefcc7ac38/contracts/LunyrToken.sol#L117
        require(candidateContract.isSiringClockAuction());

        // Set the new contract address
        siringAuction = candidateContract;
    }

    /// 将一只猫咪放入销售拍卖 外部函数 仅限非停止状态调用
    function createSaleAuction(
        uint256 _kittyId,
        uint256 _startingPrice,
        uint256 _endingPrice,
        uint256 _duration
    ) external whenNotPaused {
        // 拍卖合约检查输入参数大小

        // 如果猫咪已经在拍卖中了，会报异常，因为所有权在拍卖合约那里
        require(_owns(msg.sender, _kittyId));
        // 确保猫咪不在怀孕状态 防止买到猫咪的人收到小猫咪的所有权
        require(!isPregnant(_kittyId));
        _approve(_kittyId, saleAuction); // 授权猫咪所有权给拍卖合约

        // 如果参数有误拍卖合约会报异常。 调用成功会清除转移和繁育授权
        saleAuction.createAuction(
            _kittyId,
            _startingPrice,
            _endingPrice,
            _duration,
            msg.sender
        );
    }

    /// 将一只猫咪放入繁育拍卖 外部函数 仅限非停止状态调用
    function createSiringAuction(
        uint256 _kittyId,
        uint256 _startingPrice,
        uint256 _endingPrice,
        uint256 _duration
    ) external whenNotPaused {
        // 拍卖合约检查输入参数大小

        // 如果猫咪已经在拍卖中了，会报异常，因为所有权在拍卖合约那里
        require(_owns(msg.sender, _kittyId));
        require(isReadyToBreed(_kittyId)); // 检查猫咪是否在哺育状态
        _approve(_kittyId, siringAuction); // 授权猫咪所有权给拍卖合约

        // 如果参数有误拍卖合约会报异常。 调用成功会清除转移和繁育授权
        siringAuction.createAuction(
            _kittyId,
            _startingPrice,
            _endingPrice,
            _duration,
            msg.sender
        );
    }

    /// 出价完成一个繁育合约 猫咪会立即进入哺育状态 外部函数 可以支付 仅当非停止状态
    function bidOnSiringAuction(uint256 _sireId, uint256 _matronId)
        external
        payable
        whenNotPaused
    {
        // 拍卖合约检查输入大小

        require(_owns(msg.sender, _matronId));
        require(isReadyToBreed(_matronId));
        require(_canBreedWithViaAuction(_matronId, _sireId));

        // 计算当前价格
        uint256 currentPrice = siringAuction.getCurrentPrice(_sireId);
        require(msg.value >= currentPrice + autoBirthFee); // 出价要高于当前价格和自动出生费用

        // 如果出价失败，繁育合约会报异常
        siringAuction.bid.value(msg.value - autoBirthFee)(_sireId);
        _breedWith(uint32(_matronId), uint32(_sireId));
    }

    /// 转移拍卖合约的余额到 KittyCore 外部函数仅限管理层调用
    function withdrawAuctionBalances() external onlyCLevel {
        saleAuction.withdrawBalance();
        siringAuction.withdrawBalance();
    }
}

/// 所有关系到创建猫咪的函数
contract KittyMinting is KittyAuction {
    // 限制合约创建猫咪的数量
    uint256 public constant PROMO_CREATION_LIMIT = 5000;
    uint256 public constant GEN0_CREATION_LIMIT = 45000;

    // 第 0 代猫咪拍卖的常数
    uint256 public constant GEN0_STARTING_PRICE = 10 finney;
    uint256 public constant GEN0_AUCTION_DURATION = 1 days;

    // 合约创建猫咪计数
    uint256 public promoCreatedCount;
    uint256 public gen0CreatedCount;

    /// 创建推广猫咪 外部函数 仅限 COO 调用
    function createPromoKitty(uint256 _genes, address _owner) external onlyCOO {
        address kittyOwner = _owner;
        if (kittyOwner == address(0)) {
            kittyOwner = cooAddress;
        }
        require(promoCreatedCount < PROMO_CREATION_LIMIT);

        promoCreatedCount++;
        _createKitty(0, 0, 0, _genes, kittyOwner);
    }

    /// 创建第 0 代猫咪 外部函数 仅限 COO 调用
    /// 为猫咪创建一个拍卖
    function createGen0Auction(uint256 _genes) external onlyCOO {
        require(gen0CreatedCount < GEN0_CREATION_LIMIT);

        uint256 kittyId = _createKitty(0, 0, 0, _genes, address(this));
        _approve(kittyId, saleAuction);

        saleAuction.createAuction(
            kittyId,
            _computeNextGen0Price(),
            0,
            GEN0_AUCTION_DURATION,
            address(this)
        );

        gen0CreatedCount++;
    }

    /// 计算第 0 代拍卖的价格 最后 5 个价格平均值 + 50%  内部函数 只读
    function _computeNextGen0Price() internal view returns (uint256) {
        uint256 avePrice = saleAuction.averageGen0SalePrice();

        // Sanity check to ensure we don't overflow arithmetic
        require(avePrice == uint256(uint128(avePrice)));

        uint256 nextPrice = avePrice + (avePrice / 2);

        // We never auction for less than starting price
        if (nextPrice < GEN0_STARTING_PRICE) {
            nextPrice = GEN0_STARTING_PRICE;
        }

        return nextPrice;
    }
}

/// 加密猫核心 收集 哺育 领养？
contract KittyCore is KittyMinting {
    // 这是加密猫的主要合约。为了让代码和逻辑部分分开，我们采用了 2 种方式。
    // 第一，我们分开了部分兄弟合约管理拍卖和我们最高秘密的基因混合算法。
    // 拍卖分开因为逻辑在某些方面比较复杂，另外也总是存在小 bug 的风险。
    // 让这些风险在它们自己的合约里，我们可以升级它们，同时不用干扰记录着猫咪所有权的主合约。
    // 基因混合算法分离是因为我们可以开源其他部分的算法，同时防止别人很容易就分叉弄明白基因部分是如何工作的。不用担心，我确定很快就会有人对齐逆向工程。
    // 第二，我们分开核心合约产生多个文件是为了使用继承。这让我们保持关联的代码紧紧绑在一起，也避免了所有的东西都在一个巨型文件里。
    // 分解如下：
    //
    //      - KittyBase: 这是我们定义大多数基础代码的地方，这些代码贯穿了核心功能。包括主要数据存储，常量和数据类型，还有管理这些的内部函数。
    //
    //      - KittyAccessControl: 这个合约管理多种地址和限制特殊角色操作，像是 CEO CFO COO
    //
    //      - KittyOwnership:  这个合约提供了基本的 NFT token 交易 请看 ERC721
    //
    //      - KittyBreeding: 这个包含了必要的哺育猫咪相关的方法，包括保证对公猫提供者的记录和对外部基因混合合约的依赖
    //
    //      - KittyAuctions: 这里我们有许多拍卖、出价和繁育的方法，实际的拍卖功能存储在 2 个兄弟合约（一个管销售 一个管繁育），拍卖创建和出价都要通过这个合约操作。
    //
    //      - KittyMinting: 这是包含创建第 0 代猫咪的最终门面合约。我们会制作 5000 个推广猫咪，这样的猫咪可以被分出去，比如当社区建立时。
    //              所有的其他猫咪仅仅能够通过创建并立即进入拍卖，价格通过算法计算的方式分发出去。不要关心猫咪是如何被创建的，有一个 5 万的硬性限制。之后的猫咪都只能通过繁育生产。

    // 当核心合约被破坏并且有必要升级时，设置这个变量
    address public newContractAddress;

    /// 构造函数 创建主要的加密猫的合约实例
    function KittyCore() public {
        paused = true; // 开始是暂停状态

        ceoAddress = msg.sender; // 设置 ceo 地址

        cooAddress = msg.sender; // 设置 coo 地址

        // 创建神秘之猫，这个猫咪会产生第 0 代猫咪
        _createKitty(0, 0, 0, uint256(-1), address(0));
    }

    ///用于标记智能合约升级 防止出现严重 bug，这个方法只是记录新合约地址并触发合约升级事件。在这种情况下，客户端要采用新的合约地址。若升级发生，本合约会处于停止状态。
    function setNewAddress(address _v2Address) external onlyCEO whenPaused {
        // 看 README.md 了解升级计划
        newContractAddress = _v2Address;
        ContractUpgrade(_v2Address); // 触发合约升级事件
    }

    /// fallback 函数 退回所有发送到本合约的以太币 除非是销售拍卖合约和繁育拍卖合约发来的
    function() external payable {
        require(
            msg.sender == address(saleAuction) ||
                msg.sender == address(siringAuction)
        );
    }

    /// 获取猫咪信息
    function getKitty(uint256 _id)
        external
        view
        returns (
            bool isGestating,
            bool isReady,
            uint256 cooldownIndex,
            uint256 nextActionAt,
            uint256 siringWithId,
            uint256 birthTime,
            uint256 matronId,
            uint256 sireId,
            uint256 generation,
            uint256 genes
        )
    {
        Kitty storage kit = kitties[_id];

        isGestating = (kit.siringWithId != 0); // 如果 siringWithId 不是 0 表明处于妊娠状态
        isReady = (kit.cooldownEndBlock <= block.number);
        cooldownIndex = uint256(kit.cooldownIndex);
        nextActionAt = uint256(kit.cooldownEndBlock);
        siringWithId = uint256(kit.siringWithId);
        birthTime = uint256(kit.birthTime);
        matronId = uint256(kit.matronId);
        sireId = uint256(kit.sireId);
        generation = uint256(kit.generation);
        genes = kit.genes;
    }

    /// 启动合约 要求所有的外部合约地址都被设置，才能够启动合约。如果升级合约被设置了，那么无法启动合约  公开函数 要求 CEO 才能调用 仅限合约停止状态调用
    /// public 我们才能调用父合约的外部方法
    function unpause() public onlyCEO whenPaused {
        require(saleAuction != address(0));
        require(siringAuction != address(0));
        require(geneScience != address(0));
        require(newContractAddress == address(0));

        // Actually unpause the contract.
        super.unpause();
    }

    // 提现方法 外部 仅限 CFO
    function withdrawBalance() external onlyCFO {
        uint256 balance = this.balance;
        // 减去所有怀孕的猫咪数量+1作为余量
        uint256 subtractFees = (pregnantKitties + 1) * autoBirthFee;

        if (balance > subtractFees) {
            cfoAddress.send(balance - subtractFees);
        }
    }
}
