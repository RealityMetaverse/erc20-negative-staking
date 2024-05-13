// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "../main-test-functions/RewardClaimFunctions.sol";

contract RewardClaimScenarios is RewardClaimFunctions {
    function test_RewardClaim() external {
        _addPool(address(this), true);

        vm.warp(1706809873);
        _stakeTokenWithAllowance(userOne, 0, amountToStake);

        _increaseINTAllowance(address(this), amountToProvide);
        stakingContract.provideReward(amountToProvide);

        vm.warp(1738401000);
        _claimRewardWithTest(userOne, 0, 0, false);
    }

    function test_RewardClaim_ClaimAll() external {
        _addPool(address(this), true);

        vm.warp(1706809873);
        for (uint256 times = 0; times < 3; times++) {
            _stakeTokenWithAllowance(userOne, 0, amountToStake);
        }

        _increaseINTAllowance(address(this), amountToProvide);
        stakingContract.provideReward(amountToProvide);

        vm.warp(1738401000);
        _claimAllRewardWithTest(userOne, 0, false);
    }

    function test_RewardClaim_NotEnoughFundsInTheRewardPool() external {
        _addPool(address(this), true);

        _stakeTokenWithAllowance(userOne, 0, amountToStake);

        vm.warp(1738401000);
        _claimRewardWithTest(userOne, 0, 0, true);
    }

    function test_RewardClaim_NothingToClaim() external {
        _addPool(address(this), true);

        _stakeTokenWithAllowance(userOne, 0, amountToStake);

        _increaseINTAllowance(address(this), amountToProvide);
        stakingContract.provideReward(amountToProvide);

        _claimRewardWithTest(userOne, 0, 0, true);
    }

    function test_RewardClaim_NotOpen() external {
        _addPool(address(this), true);
        stakingContract.changePoolAvailabilityStatus(0, 2, false);

        vm.warp(1706809873);
        _stakeTokenWithAllowance(userOne, 0, amountToStake);

        _increaseINTAllowance(address(this), amountToProvide);
        stakingContract.provideReward(amountToProvide);

        vm.warp(1738401000);
        _claimRewardWithTest(userOne, 0, 0, true);
    }

    function test_RewardClaim_DoubleDeposit() external {
        _addPool(address(this), false);

        _stakeTokenWithAllowance(userOne, 0, amountToStake);
        _stakeTokenWithAllowance(userOne, 0, amountToStake);

        skip(2 days);
        uint256 expectedRewards = stakingContract.checkTotalClaimableRewardBy(userOne, 0);
        assertEq(stakingContract.checkTotalClaimableReward(0), expectedRewards, "wrong reward 1");
        assertEq(stakingContract.checkGeneratedRewardDailyTotal(0, true), expectedRewards / 2, "wrong reward 2");
        assertEq(stakingContract.checkGeneratedRewardDailyTotal(0, false), expectedRewards / 2, "wrong reward 3");
    }
}
