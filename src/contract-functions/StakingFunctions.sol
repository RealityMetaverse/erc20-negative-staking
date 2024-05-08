// SPDX-License-Identifier: Apache-2.0
// Copyright 2024 HB Craft.

pragma solidity 0.8.20;

import "./ReadFunctions.sol";
import "./WriteFunctions.sol";

abstract contract StakingFunctions is ReadFunctions, WriteFunctions {
    function stakeToken(uint256 poolID, uint256 tokenAmount)
        external
        nonReentrant
        ifPoolExists(poolID)
        ifAvailable(poolID, PoolDataType.IS_STAKING_OPEN)
        ifUserOwnsEnoughTokens(tokenAmount)
        enoughTokenSent(tokenAmount, stakingPoolList[poolID].minimumDeposit)
    {
        StakingPool storage targetPool = stakingPoolList[poolID];
        uint256 stakingFeeToBePaid;
        uint256 amountToBeStaked;

        // Calculate the fee
        if (targetPool.stakingFeePercentage != 0) {
            stakingFeeToBePaid = (tokenAmount * targetPool.stakingFeePercentage / 100) / FIXED_POINT_PRECISION;
            amountToBeStaked = tokenAmount - stakingFeeToBePaid;
        } else {
            stakingFeeToBePaid = 0;
            amountToBeStaked = tokenAmount;
        }

        _checkIfTargetReached(poolID, amountToBeStaked);

        // Update the total staking fee paid
        targetPool.totalList[DataType.FEE_PAID] += stakingFeeToBePaid;
        // Update the staking pool balances
        _updatePoolData(ActionType.STAKING, poolID, msg.sender, 0, amountToBeStaked);

        emit Stake(
            msg.sender,
            poolID,
            targetPool.poolType,
            targetPool.stakerDepositList[msg.sender].length - 1,
            amountToBeStaked,
            targetPool.stakingFeePercentage / FIXED_POINT_PRECISION,
            stakingFeeToBePaid
        );
        if (stakingFeeToBePaid != 0) _payTreasuaryStakingToken(stakingFeeToBePaid);
        _receiveStakingToken(amountToBeStaked);
    }
}
