// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "./RewardClaimFunctions.sol";

contract WithdrawalFunctions is RewardClaimFunctions {
    function _trackRewardClaimWithWithdrawal(address userAddress, uint256 _poolID, uint256 _depositNo)
        internal
        view
        returns (uint256)
    {
        uint256 _rewardToClaim = 0;
        if (_depositNo != 9999) {
            _rewardToClaim = stakingContract.checkClaimableRewardBy(userAddress, _poolID, _depositNo);
        } else {
            uint256 poolCount = stakingContract.checkPoolCount();
            for (uint256 _poolNo = 0; _poolNo < poolCount; _poolNo++) {
                uint256 depositCount = stakingContract.checkDepositCountOfAddress(userAddress, _poolNo);
                for (uint256 _dNo = 0; _dNo < depositCount; _dNo++) {
                    _rewardToClaim += stakingContract.checkClaimableRewardBy(userAddress, _poolNo, _dNo);
                }
            }
        }

        return _rewardToClaim;
    }

    function _withdrawTokens(uint256 _poolID, uint256 _depositNo) internal {
        if (_depositNo == 9999) {
            stakingContract.withdrawAll(_poolID);
        } else {
            stakingContract.withdrawDeposit(_poolID, _depositNo);
        }
    }

    function _withdrawTokenWithTest(
        address userAddress,
        uint256 _poolID,
        uint256 _depositNo,
        bool ifRevertExpected,
        bool ifWithReward
    ) internal {
        uint256 totalWithdrawnBefore = _getTotalWithdrawn(_poolID);
        uint256 withdrawnByUser;

        if (userAddress != address(this)) vm.startPrank(userAddress);

        if (ifRevertExpected) {
            vm.expectRevert();
            _withdrawTokens(_poolID, _depositNo);
        } else {
            uint256[] memory currentData = _getCurrentData(userAddress, _poolID);

            uint256 _rewardToClaim;
            if (ifWithReward) _rewardToClaim = _trackRewardClaimWithWithdrawal(userAddress, _poolID, _depositNo);

            uint256 withdrawnbyUserBefore = _getTotalWithdrawnBy(userAddress, _poolID);
            _withdrawTokens(_poolID, _depositNo);

            withdrawnByUser = _getTotalWithdrawnBy(userAddress, _poolID) - withdrawnbyUserBefore;

            uint256[] memory expectedData = new uint256[](7);
            expectedData[0] = currentData[0] - withdrawnByUser;
            expectedData[1] = currentData[1] + withdrawnByUser;
            expectedData[2] = currentData[2] - withdrawnByUser;
            expectedData[3] = currentData[3] - withdrawnByUser;
            expectedData[5] = currentData[5] + _rewardToClaim;
            expectedData[6] = currentData[6] - _rewardToClaim;

            currentData = _getCurrentData(userAddress, _poolID);

            assertEq(currentData[0], expectedData[0]);
            assertEq(currentData[1], expectedData[1]);
            assertEq(currentData[2], expectedData[2]);
            assertEq(currentData[3], expectedData[3]);
            assertEq(currentData[5], expectedData[5]);
            assertEq(currentData[6], expectedData[6]);

            if (ifWithReward) assertEq(_trackRewardClaimWithWithdrawal(userAddress, _poolID, _depositNo), 0);
        }

        if (userAddress != address(this)) vm.stopPrank();

        uint256 totalWithdrawnAfter = totalWithdrawnBefore + withdrawnByUser;
        assertEq(_getTotalWithdrawn(_poolID), totalWithdrawnAfter);
    }
}
