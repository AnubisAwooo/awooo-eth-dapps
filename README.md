# awooo-eth-dapps

## truffle 学习

### 编译命令

```sh
truffle init # 初始化新的项目，在当前项目目录
truffle compile # 编译
```

引入依赖文件

```sol
import "./AnotherContract.sol";

import "some_package/SomeContract.sol"; # 从外部导入合约
```

### 部署命令

```sh
truffle migrate
```

脚本含义

```js
// artifacts.require() 告诉 Truffle 要与哪些合约进行交互 返回了一个合约抽象 contract abstraction 参数是合约名，不是文件名
var MyContract = artifacts.require("XlbContract");

// 部署脚本必须通过 module.exports 导出函数
// 参数为 deployer 此对象为部署智能合约提供清晰的语法以及执行部署职责
module.exports = function (deployer) {
    // 部署步骤
    deployer.deploy(MyContract);

    // 按顺序部署
    deployer.deploy(A);
    deployer.deploy(B);

    // Deploy A, then deploy B, passing in A's newly deployed address
    deployer.deploy(A).then(function () {
        return deployer.deploy(B, A.address);
    });
};

// 网络参数区分环境
module.exports = function (deployer, network) {
    if (network == "live") {
        // Do something specific to the network named "live".
    } else {
        // Perform a different step otherwise.
    }
};

// 传入账户参数
module.exports = function (deployer, network, accounts) {
    // Use the accounts within your migrations.
};
```

deploy 方法

```js
// 部署方法
deployer.deploy(contract, args…, options)

// 部署没有构造函数的合约
deployer.deploy(A);

// 部署合约 并使用一些参数传递给合约的构造函数。
deployer.deploy(A, arg1, arg2, ...);

// 如果合约部署过，不会覆盖
deployer.deploy(A, {overwrite: false});

// 设置 gasLimit 和部署合约的账号
deployer.deploy(A, {gas: 4612388, from: "0x...."});

// 部署多个合约，一些包含参数，另一些没有。
// 这比编写三个`deployer.deploy()`语句更快，因为部署者可以作为单个批处理请求执行部署。
deployer.deploy([
  [A, arg1, arg2, ...],
  B,
  [C, arg1]
]);

// 外部依赖示例:
// 对于此示例，我们的依赖在部署到线上网络时提供了一个地址，但是没有为测试和开发等任何其他网络提供地址。
// 当我们部署到线上网络时，我们希望它使用该地址，但在测试和开发中，我们需要部署自己的版本。 我们可以简单地使用`overwrite`键来代替编写一堆条件。
deployer.deploy(SomeDependency, {overwrite: false});
```

link 方法

```js
// 部署库LibA，然后将LibA链接到合约B，然后部署B.
deployer.deploy(LibA);
deployer.link(LibA, B);
deployer.deploy(B);

// 链接 LibA 到多个合约
deployer.link(LibA, [B, C, D]);
```

then 方法

```js
var a, b;
deployer
    .then(function () {
        // 创建一个新版本的 A
        return A.new();
    })
    .then(function (instance) {
        a = instance;
        // 获取部署的 B 实例
        return B.deployed();
    })
    .then(function (instance) {
        b = instance;
        // 通过B的setA（）函数在B上设置A的新实例地址
        return b.setA(a.address);
    });
```

### 与合约进行交互

写入数据称为交易 **transaction**，而读取数据称为 调用 **call**

#### 交易 Transactions

-   消耗 Gas 费用（以太）
-   会更改网络状态
-   不会立即执行（需要等待网络矿工打包）
-   没有执行返回值（只是一个交易 ID）

#### 调用 Calls

-   免费（不消耗 Gas）
-   不改变网络状态
-   立即执行
-   有返回值

#### 合约抽象

artifacts.require() 返回的对象，封装很多功能

-   有合约的部署地址
-   包括合约的方法
-   使用时自动判断是发送交易还是调用
-   可以附带参数，比如指定账户发送交易

```js
// 合约部署完成后可以执行下面的交易
// truffle console 进入交互界面

// 取得合约抽象实例
let instance = await MetaCoin.deployed();

let accounts = await web3.eth.getAccounts();
// 调用合约方法发起交易
instance.sendCoin(accounts[1], 10, { from: accounts[0] });

// 调用合约
let balance = await instance.getBalance(accounts[0]);
balance.toNumber();

// 取出交易结果
let result = await contract.sendCoin(accounts[1], 10, { from: accounts[0] });
result.tx; // 交易hash
result.logs; // 解码后的日志
result.receipt; // 交易收据 包括使用的 gas

// 同一个合约部署新的
let newInstance = await MetaCoin.new();
newInstance.address;

// 根据合约地址取得合约抽象
let specificInstance = await MetaCoin.at("0x1234...");

// 给合约转账
instance.sendTransaction({...}).then(function(result) {
  // Same transaction result object as above.
});
instance.send(web3.toWei(1, "ether")).then(function(result) {
  // Same result object as above.
});
```

### 调试合约

```js
# 调试交易
truffle debug <transaction hash>
```

## 计划要学习的合约

-   Compound 看了一半看不下去了
-   AAVE 也是借贷的
-   Balancer 去中性化交易
-   Uniswap 去中性化交易
-   Yearn DeFi 聚合器项目
