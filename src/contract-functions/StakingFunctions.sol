// SPDX-License-Identifier: BUSL-1.1
// Copyright 2024 Reality Metaverse
pragma solidity 0.8.20;

import "./ReadFunctions.sol";
import "./WriteFunctions.sol";

abstract contract StakingFunctions is ReadFunctions, WriteFunctions {
    function safeStake(uint256 poolID, uint256 tokenAmount, uint256 forMaxFeePercentage)
        external
        nonReentrant
        ifPoolExists(poolID)
        ifAvailable(poolID, PoolDataType.IS_STAKING_OPEN)
        ifUserOwnsEnoughTokens(tokenAmount)
        enoughTokenSent(tokenAmount, stakingPoolList[poolID].minimumDeposit)
    {
        StakingPool storage targetPool = stakingPoolList[poolID];

        require(forMaxFeePercentage <= (targetPool.stakingFeePercentage / FIXED_POINT_PRECISION), "Staking Fee Increased");

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

        // Update the total staking fee paid and the total staking fee paid by the user
        targetPool.feePayerList[msg.sender] += stakingFeeToBePaid;
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
        if (stakingFeeToBePaid != 0) _payTreasuryStakingToken(stakingFeeToBePaid);
        _receiveStakingToken(amountToBeStaked);
    }
}
