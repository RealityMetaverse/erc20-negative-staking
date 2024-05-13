// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "../AuxiliaryFunctions.sol";

contract RewardClaimFunctions is AuxiliaryFunctions {
    function _trackRewardClaim(address userAddress, uint256 _poolID, uint256 _depositNo)
        internal
        view
        returns (uint256)
    {
        uint256 userBalanceBefore = _getRewardTokenBalance(userAddress);
        uint256 _claimableReward = stakingContract.checkClaimableRewardBy(userAddress, _poolID, _depositNo);
        uint256 userBalanceAfter = userBalanceBefore + _claimableReward;

        return userBalanceAfter;
    }

    function _testRewardClaim(address userAddress, uint256 _poolID, uint256 _depositNo, uint256 userBalanceAfter)
        internal
    {
        assertEq(stakingContract.checkClaimableRewardBy(userAddress, _poolID, _depositNo), 0);
        assertEq(_getRewardTokenBalance(userAddress), userBalanceAfter);
    }

    function _claimRewardWithTest(address userAddress, uint256 _poolID, uint256 _depositNo, bool ifRevertExpected)
        internal
    {
        if (userAddress != address(this)) vm.startPrank(userAddress);

        if (ifRevertExpected) {
            vm.expectRevert();
            stakingContract.claimReward(_poolID, _depositNo);
        } else {
            uint256 userBalanceAfter = _trackRewardClaim(userAddress, _poolID, _depositNo);

            stakingContract.claimReward(_poolID, _depositNo);

            _testRewardClaim(userAddress, _poolID, _depositNo, userBalanceAfter);
        }

        if (userAddress != address(this)) vm.stopPrank();
    }

    function _claimAllRewardWithTest(address userAddress, uint256 _poolID, bool ifRevertExpected) internal {
        if (userAddress != address(this)) vm.startPrank(userAddress);

        if (ifRevertExpected) {
            vm.expectRevert();
            stakingContract.claimAllReward(_poolID);
        } else {
            uint256 userBalanceBefore = _getRewardTokenBalance(userAddress);

            uint256 _claimableReward;
            uint256 depositCount = stakingContract.checkDepositCountOfAddress(userAddress, _poolID);
            for (uint256 _depositNo = 0; _depositNo < depositCount; _depositNo++) {
                _claimableReward += stakingContract.checkClaimableRewardBy(userAddress, _poolID, _depositNo);
            }

            uint256 userBalanceAfter = userBalanceBefore + _claimableReward;

            stakingContract.claimAllReward(_poolID);

            uint256 newclaimableReward;
            depositCount = stakingContract.checkDepositCountOfAddress(userAddress, _poolID);
            for (uint256 _depositNo = 0; _depositNo < depositCount; _depositNo++) {
                newclaimableReward += stakingContract.checkClaimableRewardBy(userAddress, _poolID, _depositNo);
            }

            assertEq(newclaimableReward, 0);
            assertEq(_getRewardTokenBalance(userAddress), userBalanceAfter);
        }

        if (userAddress != address(this)) vm.stopPrank();
    }
}
