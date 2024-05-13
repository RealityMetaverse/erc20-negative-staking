// SPDX-License-Identifier: Apache-2.0
// Copyright 2024 HB Craft.

pragma solidity 0.8.20;

import "./ReadFunctions.sol";
import "./WriteFunctions.sol";

abstract contract WithdrawFunctions is ReadFunctions, WriteFunctions {
    // ======================================
    // =     Reward Claim Functions       =
    // ======================================
    function _calculateDaysPassed(uint256 poolID, uint256 startDate, uint256 withdrawalDate)
        private
        view
        returns (uint256)
    {
        uint256 timePassed;
        uint256 poolEndDate = stakingPoolList[poolID].endDate;

        if (withdrawalDate != 0) {
            if (poolEndDate == 0 || withdrawalDate <= poolEndDate) {
                timePassed = withdrawalDate - startDate;
            } else if (withdrawalDate > poolEndDate) {
                timePassed = poolEndDate - startDate;
            }
        } else if (poolEndDate != 0) {
            timePassed = poolEndDate - startDate;
        } else {
            timePassed = block.timestamp - startDate;
        }

        // Convert the time elapsed to days
        uint256 daysPassed = timePassed / (1 days);
        return daysPassed;
    }

    function _calculateReward(uint256 poolID, address userAddress, uint256 depositNumber)
        private
        view
        returns (uint256)
    {
        uint256 daysPassed;
        uint256 depositAPY;
        uint256 depositAmount;
        uint256 rewardAlreadyClaimed;

        uint256 claimableReward;

        // A local variable to refer to the appropriate TokenDeposit
        TokenDeposit storage deposit = stakingPoolList[poolID].stakerDepositList[userAddress][depositNumber];

        daysPassed = _calculateDaysPassed(poolID, deposit.stakingDate, deposit.withdrawalDate);
        depositAPY = deposit.APY;
        depositAmount = deposit.amount;
        rewardAlreadyClaimed = deposit.claimedReward;

        claimableReward = (((depositAmount * ((depositAPY / 365) * daysPassed) / 100)) / FIXED_POINT_PRECISION)
            - rewardAlreadyClaimed;
        return claimableReward;
    }

    function _checkClaimableRewardBy(address userAddress, uint256 poolID, uint256 depositNumber)
        private
        view
        returns (uint256)
    {
        return _calculateReward(poolID, userAddress, depositNumber);
    }

    function checkClaimableRewardBy(address userAddress, uint256 poolID, uint256 depositNumber)
        external
        view
        ifPoolExists(poolID)
        returns (uint256)
    {
        return _calculateReward(poolID, userAddress, depositNumber);
    }

    function checkTotalClaimableRewardBy(address userAddress, uint256 poolID) public view returns (uint256) {
        uint256 userDepositCount = checkDepositCountOfAddress(userAddress, poolID);
        uint256 totalClaimableReward = 0;

        for (uint256 depositNumber = 0; depositNumber < userDepositCount; depositNumber++) {
            totalClaimableReward += _checkClaimableRewardBy(userAddress, poolID, depositNumber);
        }

        return totalClaimableReward;
    }

    function checkTotalClaimableReward(uint256 poolID) external view ifPoolExists(poolID) returns (uint256) {
        uint256 totalClaimableReward = 0;

        for (uint256 stakerNo = 0; stakerNo < stakingPoolList[poolID].stakerAddressList.length; stakerNo++) {
            totalClaimableReward +=
                checkTotalClaimableRewardBy(stakingPoolList[poolID].stakerAddressList[stakerNo], poolID);
        }

        return totalClaimableReward;
    }

    function checkGeneratedRewardLastDayFor(address userAddress, uint256 poolID)
        external
        view
        ifPoolExists(poolID)
        returns (uint256)
    {
        uint256 userDepositCount = checkDepositCountOfAddress(userAddress, poolID);
        uint256 totalLastDayGenerated = 0;

        StakingPool storage targetStakingPool = stakingPoolList[poolID];
        for (uint256 depositNumber = 0; depositNumber < userDepositCount; depositNumber++) {
            TokenDeposit storage targetDeposit = targetStakingPool.stakerDepositList[userAddress][depositNumber];
            if (targetDeposit.withdrawalDate == 0 && (((block.timestamp - targetDeposit.stakingDate) / (1 days)) >= 1))
            {
                totalLastDayGenerated +=
                    (targetDeposit.amount * (targetDeposit.APY / 365) / 100) / FIXED_POINT_PRECISION;
            }
        }

        return totalLastDayGenerated;
    }

    function checkGeneratedRewardDailyTotal(uint256 poolID, bool ifPrecise)
        external
        view
        ifPoolExists(poolID)
        returns (uint256)
    {
        uint256 dailyTotalRewardGenerated = 0;

        if (ifPrecise) {
            address userAddress;
            uint256 userDepositCount;

            for (uint256 stakerNo = 0; stakerNo < stakingPoolList[poolID].stakerAddressList.length; stakerNo++) {
                userAddress = stakingPoolList[poolID].stakerAddressList[stakerNo];
                userDepositCount = checkDepositCountOfAddress(userAddress, poolID);

                for (uint256 depositNumber = 0; depositNumber < userDepositCount; depositNumber++) {
                    TokenDeposit storage targetDeposit =
                        stakingPoolList[poolID].stakerDepositList[userAddress][depositNumber];
                    if (targetDeposit.withdrawalDate == 0) {
                        dailyTotalRewardGenerated +=
                            (targetDeposit.amount * (targetDeposit.APY / 365) / 100) / FIXED_POINT_PRECISION;
                    }
                }
            }
        } else {
            StakingPool storage targetStakingPool = stakingPoolList[poolID];
            dailyTotalRewardGenerated = (
                targetStakingPool.totalList[DataType.STAKED] * (targetStakingPool.APY / 365) / 100
            ) / FIXED_POINT_PRECISION;
        }

        return dailyTotalRewardGenerated;
    }

    function _processRewardClaim(uint256 poolID, address userAddress, uint256 depositNumber, bool isBatchClaim)
        private
    {
        uint256 rewardToClaim = _calculateReward(poolID, userAddress, depositNumber);

        if (!isBatchClaim) {
            if (rewardPool < rewardToClaim) {
                revert NotEnoughFundsInTheRewardPool(rewardToClaim, rewardPool);
            }

            if (rewardToClaim == 0) {
                revert("Nothing to Claim");
            }
        }

        if (isBatchClaim && (rewardPool < rewardToClaim || rewardToClaim == 0)) {
            // Skip claiming for this case
            return;
        }

        // Proceed with claiming process
        _updatePoolData(ActionType.REWARD_CLAIM, poolID, msg.sender, depositNumber, rewardToClaim);
        rewardPool -= rewardToClaim;

        emit ClaimReward(msg.sender, poolID, depositNumber, rewardToClaim);
        _sendRewardToken(msg.sender, rewardToClaim);
    }

    /// @dev isBatchClaim = true because the function is called by withdraw function and we don't want to raise an exception when nothing to claim
    function _claimReward(uint256 poolID, address userAddress, uint256 depositNumber) private {
        bool _isRewardClaimOpen = stakingPoolList[poolID].isRewardClaimOpen;
        if (_isRewardClaimOpen) _processRewardClaim(poolID, userAddress, depositNumber, true);
    }

    function claimReward(uint256 poolID, uint256 depositNumber)
        external
        nonReentrant
        ifPoolExists(poolID)
        ifAvailable(poolID, PoolDataType.IS_REWARD_CLAIM_OPEN)
    {
        _processRewardClaim(poolID, msg.sender, depositNumber, false);
    }

    function claimAllReward(uint256 poolID)
        external
        nonReentrant
        ifPoolExists(poolID)
        ifAvailable(poolID, PoolDataType.IS_REWARD_CLAIM_OPEN)
    {
        for (
            uint256 depositNumber = 0;
            depositNumber < stakingPoolList[poolID].stakerDepositList[msg.sender].length;
            depositNumber++
        ) {
            _processRewardClaim(poolID, msg.sender, depositNumber, true);
        }
    }

    // ======================================
    // =    Withdraw Related Functions      =
    // ======================================
    function _withdrawDeposit(uint256 poolID, uint256 depositNumber, bool isBatchWithdrawal) private {
        TokenDeposit storage targetDeposit = stakingPoolList[poolID].stakerDepositList[msg.sender][depositNumber];
        uint256 depositWithdrawalDate = targetDeposit.withdrawalDate;

        if (depositWithdrawalDate != 0) {
            if (!isBatchWithdrawal) {
                revert("Deposit already withdrawn");
            }
        } else {
            _claimReward(poolID, msg.sender, depositNumber);

            // Update the staking pool balances
            uint256 amountToWithdraw = targetDeposit.amount;
            _updatePoolData(ActionType.WITHDRAWAL, poolID, msg.sender, depositNumber, amountToWithdraw);

            emit Withdraw(msg.sender, poolID, stakingPoolList[poolID].poolType, depositNumber, amountToWithdraw);
            _sendStakingToken(msg.sender, amountToWithdraw);
        }
    }

    function withdrawDeposit(uint256 poolID, uint256 depositNumber)
        external
        nonReentrant
        ifPoolExists(poolID)
        ifDepositExists(poolID, depositNumber)
        ifAvailable(poolID, PoolDataType.IS_WITHDRAWAL_OPEN)
        enoughFundsAvailable(poolID, stakingPoolList[poolID].stakerDepositList[msg.sender][depositNumber].amount)
    {
        _withdrawDeposit(poolID, depositNumber, false);
    }

    function withdrawAll(uint256 poolID)
        external
        nonReentrant
        ifPoolExists(poolID)
        sufficientBalance(poolID)
        ifAvailable(poolID, PoolDataType.IS_WITHDRAWAL_OPEN)
        enoughFundsAvailable(poolID, stakingPoolList[poolID].stakerList[msg.sender])
    {
        StakingPool storage targetPool = stakingPoolList[poolID];
        TokenDeposit[] storage targetDepositList = targetPool.stakerDepositList[msg.sender];

        for (uint128 depositNumber = 0; depositNumber < targetDepositList.length; depositNumber++) {
            _withdrawDeposit(poolID, depositNumber, true);
        }
    }
}
