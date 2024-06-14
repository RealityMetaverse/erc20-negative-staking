// SPDX-License-Identifier: BUSL-1.1
// Copyright 2024 Reality Metaverse
pragma solidity 0.8.20;

import "./contract-functions/AdministrativeFunctions.sol";
import "./contract-functions/StakingFunctions.sol";
import "./contract-functions/WithdrawFunctions.sol";

/// @title ERC20 Negative Staking (v1.1.1)
/// @author Heydar Badirli
contract ERC20NegativeStaking is AdministrativeFunctions, StakingFunctions, WithdrawFunctions {
    constructor(
        address stakingTokenAddress,
        address rewardTokenAddress,
        uint256 _defaultStakingTarget,
        uint256 _defaultMinimumDeposit,
        uint256 _confirmationCode
    ) ProgramManager(IERC20Metadata(stakingTokenAddress), IERC20Metadata(rewardTokenAddress), _confirmationCode) {
        if (_defaultMinimumDeposit == 0) revert InvalidArgumentValue("Minimum Deposit", 1);

        contractOwner = msg.sender;
        treasury = msg.sender;

        defaultStakingTarget = _defaultStakingTarget;
        defaultMinimumDeposit = _defaultMinimumDeposit;

        emit CreateProgram(STAKING_TOKEN.symbol(), stakingTokenAddress, _defaultStakingTarget, _defaultMinimumDeposit);
    }
}
