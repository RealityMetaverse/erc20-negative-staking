// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "../AuxiliaryFunctions.sol";

contract MainManagementScenarios is AuxiliaryFunctions {
    // ======================================
    // =      Program Management Test       =
    // ======================================
    function test_ProgramManagement_TransferOwnership() external {
        vm.startPrank(contractAdmin);
        vm.expectRevert();
        stakingContract.transferOwnership(userOne);
        vm.stopPrank();

        vm.startPrank(userOne);
        vm.expectRevert();
        stakingContract.transferOwnership(userTwo);
        vm.stopPrank();

        assertEq(stakingContract.contractOwner(), address(this));

        stakingContract.transferOwnership(userOne);
        assertEq(stakingContract.contractOwner(), userOne);
    }

    function test_ProgramManagement_AddRemoveAdmin() external {
        assertEq(stakingContract.contractAdmins(contractAdmin), true);

        stakingContract.removeContractAdmin(contractAdmin);
        assertEq(stakingContract.contractAdmins(contractAdmin), false);
    }

    function test_ProgramManagement_PoolCount(uint8 x) external {
        for (uint8 No; No < x; No++) {
            _addPool(address(this), true);
        }

        assertEq(x, stakingContract.checkPoolCount());
    }

    function test_ProgramManagement_AddEndPool() external {
        vm.warp(1706809873);
        for (uint8 No = 0; No < 10; No++) {
            _addPool(address(this), true);
        }

        vm.warp(1738401000);
        for (uint8 No = 0; No < 10; No++) {
            if (No <= 4 || No >= 7) _endPool(address(this), No);
        }

        vm.warp(1738402000);
        for (uint8 No; No < 10; No++) {
            if (No <= 4 || No >= 7) {
                assertTrue(stakingContract.checkIfPoolEnded(No));
                assertFalse(stakingContract.checkIfStakingOpen(No));
                assertTrue(stakingContract.checkIfWithdrawalOpen(No));
                assertTrue(stakingContract.checkIfRewardClaimOpen(No));
            } else {
                assertFalse(stakingContract.checkIfPoolEnded(No));
                assertTrue(stakingContract.checkIfStakingOpen(No));
                assertFalse(stakingContract.checkIfWithdrawalOpen(No));
                assertTrue(stakingContract.checkIfRewardClaimOpen(No));
            }
        }
    }

    function test_ProgramManagement_IncorrectConfirmationCode() external {
        _addPool(address(this), true);
        vm.expectRevert();
        stakingContract.endStakingPool(0, 255);
    }

    // ======================================
    // =      Reward Management Test      =
    // ======================================
    function test_RewardManagement_ProvideReward() external {
        _increaseINTAllowance(contractAdmin, amountToProvide);

        vm.startPrank(contractAdmin);
        stakingContract.provideReward(amountToProvide);
        vm.stopPrank();
    }

    function test_RewardManagement_CollectRewardPoolFunds() external {
        _increaseINTAllowance(contractAdmin, amountToProvide);

        vm.startPrank(contractAdmin);
        stakingContract.provideReward(amountToProvide);
        assertEq(stakingContract.checkRewardProvidedBy(contractAdmin), amountToProvide);
        vm.expectRevert();
        stakingContract.collectRewardPoolFunds(amountToProvide);
        vm.stopPrank();
        stakingContract.collectRewardPoolFunds(amountToProvide);
    }

    function test_RewardManagement_NotEnoughFundsInTheRewardPool() external {
        _increaseINTAllowance(address(this), amountToProvide);

        stakingContract.provideReward(amountToProvide);
        stakingContract.collectRewardPoolFunds(amountToProvide);

        vm.expectRevert();
        stakingContract.collectRewardPoolFunds(amountToProvide);
    }
}
