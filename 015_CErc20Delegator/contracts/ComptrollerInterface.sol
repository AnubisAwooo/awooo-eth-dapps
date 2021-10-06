pragma solidity ^0.5.16;

// 审计接口
contract ComptrollerInterface {
    // 标识是一个审计接口
    /// @notice Indicator that this is a Comptroller contract (for inspection)
    bool public constant isComptroller = true;

    /*** Assets You Are In ***/

    // 进入市场 what？传入地址数组是什么意思？
    function enterMarkets(address[] calldata cTokens)
        external
        returns (uint256[] memory);

    // 退出市场 what？给个 token 地址就可以了？
    function exitMarket(address cToken) external returns (uint256);

    /*** Policy Hooks ***/

    // 铸币允许？
    function mintAllowed(
        address cToken,
        address minter,
        uint256 mintAmount
    ) external returns (uint256);

    // 铸币验证？
    function mintVerify(
        address cToken,
        address minter,
        uint256 mintAmount,
        uint256 mintTokens
    ) external;

    // 赎回允许？
    function redeemAllowed(
        address cToken,
        address redeemer,
        uint256 redeemTokens
    ) external returns (uint256);

    // 赎回验证？
    function redeemVerify(
        address cToken,
        address redeemer,
        uint256 redeemAmount,
        uint256 redeemTokens
    ) external;

    // 借币允许？
    function borrowAllowed(
        address cToken,
        address borrower,
        uint256 borrowAmount
    ) external returns (uint256);

    // 借币验证？
    function borrowVerify(
        address cToken,
        address borrower,
        uint256 borrowAmount
    ) external;

    // 偿还借币允许？
    function repayBorrowAllowed(
        address cToken,
        address payer,
        address borrower,
        uint256 repayAmount
    ) external returns (uint256);

    // 偿还借币验证？
    function repayBorrowVerify(
        address cToken,
        address payer,
        address borrower,
        uint256 repayAmount,
        uint256 borrowerIndex
    ) external;

    // 清算借币允许？
    function liquidateBorrowAllowed(
        address cTokenBorrowed,
        address cTokenCollateral,
        address liquidator,
        address borrower,
        uint256 repayAmount
    ) external returns (uint256);

    // 清算借币验证
    function liquidateBorrowVerify(
        address cTokenBorrowed,
        address cTokenCollateral,
        address liquidator,
        address borrower,
        uint256 repayAmount,
        uint256 seizeTokens
    ) external;

    // 扣押允许？
    function seizeAllowed(
        address cTokenCollateral,
        address cTokenBorrowed,
        address liquidator,
        address borrower,
        uint256 seizeTokens
    ) external returns (uint256);

    // 扣押验证？
    function seizeVerify(
        address cTokenCollateral,
        address cTokenBorrowed,
        address liquidator,
        address borrower,
        uint256 seizeTokens
    ) external;

    // 转账允许？
    function transferAllowed(
        address cToken,
        address src,
        address dst,
        uint256 transferTokens
    ) external returns (uint256);

    // 转账验证？
    function transferVerify(
        address cToken,
        address src,
        address dst,
        uint256 transferTokens
    ) external;

    /*** Liquidity/Liquidation Calculations ***/

    // 清算计算扣押代币
    function liquidateCalculateSeizeTokens(
        address cTokenBorrowed,
        address cTokenCollateral,
        uint256 repayAmount
    ) external view returns (uint256, uint256);
}
