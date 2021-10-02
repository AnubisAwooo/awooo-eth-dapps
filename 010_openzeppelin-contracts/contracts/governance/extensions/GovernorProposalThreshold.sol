// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../Governor.sol";

/**
 * 拓展合约 Governor 支持提案限制持有者最小余额
 * @dev Extension of {Governor} for proposal restriction to token holders with a minimum balance.
 *
 * _Available since v4.3._
 */
abstract contract GovernorProposalThreshold is Governor {
    /**
     * @dev See {IGovernor-propose}.
     */
    function propose(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        string memory description
    ) public virtual override returns (uint256) {
        require(
            getVotes(msg.sender, block.number - 1) >= proposalThreshold(),
            "GovernorCompatibilityBravo: proposer votes below proposal threshold"
        );

        return super.propose(targets, values, calldatas, description);
    }

    /**
     * 有一定支持人数的人才能发起提案
     * @dev Part of the Governor Bravo's interface: _"The number of votes required in order for a voter to become a proposer"_.
     */
    function proposalThreshold() public view virtual returns (uint256);
}
