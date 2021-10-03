// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../../interfaces/IERC3156.sol";
import "../ERC20.sol";

/**
 * 拓展实现 ERC3156 标准闪电贷功能
 * @dev Implementation of the ERC3156 Flash loans extension, as defined in
 * https://eips.ethereum.org/EIPS/eip-3156[ERC-3156].
 *
 * 增加闪电贷方法，该方法可以提供代币级别的闪电贷支持。默认没有费用，但是可以重写 flashFee 方法。
 * Adds the {flashLoan} method, which provides flash loan support at the token
 * level. By default there is no fee, but this can be changed by overriding {flashFee}.
 *
 * _Available since v4.1._
 */
abstract contract ERC20FlashMint is ERC20, IERC3156FlashLender {
    bytes32 private constant _RETURN_VALUE = keccak256("ERC3156FlashBorrower.onFlashLoan");

    /**
     * 返回可以借出的最大数量 公开函数 只读
     * @dev Returns the maximum amount of tokens available for loan.
     * @param token The address of the token that is requested.
     * @return The amont of token that can be loaned.
     */
    function maxFlashLoan(address token) public view override returns (uint256) {
        return token == address(this) ? type(uint256).max - ERC20.totalSupply() : 0;
    }

    /**
     * 计算闪电贷的费用。 公开函数 只读 可重写
     * @dev Returns the fee applied when doing flash loans. By default this
     * implementation has 0 fees. This function can be overloaded to make
     * the flash loan mechanism deflationary.
     * @param token The token to be flash loaned.
     * @param amount The amount of tokens to be loaned.
     * @return The fees applied to the corresponding flash loan.
     */
    function flashFee(address token, uint256 amount) public view virtual override returns (uint256) {
        require(token == address(this), "ERC20FlashMint: wrong token");
        // silence warning about unused variable without the addition of bytecode.
        amount;
        return 0;
    }

    /**
     * 进行闪电贷。新的代币将会被铸造并且发送给接收者，该接收者要求实现 IERC3156FlashBorrower 接口。
     * 当闪电贷结束后，接收者被期望还回借出的数量 和 费用 的代币，并且将他们授权给代币合约销毁。
     * @dev Performs a flash loan. New tokens are minted and sent to the
     * `receiver`, who is required to implement the {IERC3156FlashBorrower}
     * interface. By the end of the flash loan, the receiver is expected to own
     * amount + fee tokens and have them approved back to the token contract itself so
     * they can be burned.
     * @param receiver The receiver of the flash loan. Should implement the
     * {IERC3156FlashBorrower.onFlashLoan} interface.
     * @param token The token to be flash loaned. Only `address(this)` is
     * supported.
     * @param amount The amount of tokens to be loaned.
     * @param data An arbitrary datafield that is passed to the receiver.
     * @return `true` is the flash loan was successful.
     */
    function flashLoan(
        IERC3156FlashBorrower receiver,
        address token,
        uint256 amount,
        bytes calldata data
    ) public virtual override returns (bool) {
        uint256 fee = flashFee(token, amount); // 计算费用
        _mint(address(receiver), amount); // 挖矿相应的代币给指定接收者 接收者是实现了 IERC3156FlashBorrower 的合约
        // 执行回调，告诉接收者已经收到代币了
        // tips 所以借到代币后，所有的操作应当在回调方法 onFlashLoan 中完成， 当前函数流程仍然会继续走下去要收回代币
        require(
            receiver.onFlashLoan(msg.sender, token, amount, fee, data) == _RETURN_VALUE,
            "ERC20FlashMint: invalid return value"
        );
        uint256 currentAllowance = allowance(address(receiver), address(this)); // 获取授权给本合约额度
        require(currentAllowance >= amount + fee, "ERC20FlashMint: allowance does not allow refund"); // 要求额度大于或等于即将烧毁的代币
        _approve(address(receiver), address(this), currentAllowance - amount - fee); // 把额度为剩下的
        _burn(address(receiver), amount + fee); // 烧毁这些代币，如果 fee 是大于 0 的，那么这个代币能实现紧缩，每次都能够减少总量
        return true;
    }
}
