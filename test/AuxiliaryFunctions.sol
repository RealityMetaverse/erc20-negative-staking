// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "./ReadFunctions.sol";
import "../src/ProgramManager.sol";

contract AuxiliaryFunctions is ReadFunctions {
    // ======================================
    // =  Contract Intereaction Functions   =
    // ======================================
    function _performPMActions(address userAddress, PMActions actionType) internal {
        if (userAddress != address(this)) vm.startPrank(userAddress);

        if (actionType == PMActions.PAUSE) {
            stakingContract.pauseProgram();
        } else if (actionType == PMActions.RESUME) {
            stakingContract.resumeProgram();
        }

        if (userAddress != address(this)) vm.stopPrank();
    }

    function _addPool(address userAddress, bool ifLocked) internal {
        if (userAddress != address(this)) vm.startPrank(userAddress);

        if (ifLocked) {
            stakingContract.addStakingPoolDefault(ProgramManager.PoolType.LOCKED, _lockedAPY, _stakingFee);
        } else {
            stakingContract.addStakingPoolDefault(ProgramManager.PoolType.FLEXIBLE, _flexibleAPY, _stakingFee);
        }

        if (userAddress != address(this)) vm.stopPrank();
    }

    function _addCustomPool(address userAddress, bool ifLocked) internal {
        if (userAddress != address(this)) vm.startPrank(userAddress);

        if (ifLocked) {
            stakingContract.addStakingPoolCustom(
                ProgramManager.PoolType.LOCKED,
                _defaultStakingTarget,
                _defaultMinimumDeposit,
                true,
                _lockedAPY,
                _stakingFee
            );
        } else {
            stakingContract.addStakingPoolCustom(
                ProgramManager.PoolType.FLEXIBLE,
                _defaultStakingTarget,
                _defaultMinimumDeposit,
                false,
                _flexibleAPY,
                _stakingFee
            );
        }

        if (userAddress != address(this)) vm.stopPrank();
    }

    function _endPool(address userAddress, uint256 poolID) internal {
        if (userAddress != address(this)) vm.startPrank(userAddress);

        stakingContract.endStakingPool(poolID, _confirmationCode);

        if (userAddress != address(this)) vm.stopPrank();
    }

    function _increaseSTAllowance(address userAddress, uint256 tokenAmount) internal {
        if (userAddress != address(this)) vm.startPrank(userAddress);

        myToken.increaseAllowance(address(stakingContract), tokenAmount);

        if (userAddress != address(this)) vm.stopPrank();
    }

    function _increaseINTAllowance(address userAddress, uint256 tokenAmount) internal {
        if (userAddress != address(this)) vm.startPrank(userAddress);

        myInterestToken.increaseAllowance(address(stakingContract), tokenAmount);

        if (userAddress != address(this)) vm.stopPrank();
    }

    function _stakeTokenWithTest(address userAddress, uint256 _poolID, uint256 tokenAmount, bool ifRevertExpected)
        internal
    {
        if (userAddress != address(this)) vm.startPrank(userAddress);

        if (ifRevertExpected) {
            vm.expectRevert();
            stakingContract.stakeToken(_poolID, tokenAmount);
        } else {
            uint256[] memory currentData = _getCurrentData(userAddress, _poolID);
            uint256 userDepositCountBefore = _getUserDepositCount(userAddress, _poolID);

            uint256 _netStaked = _calculateNETStakedAmount(_poolID, tokenAmount);

            uint256[] memory expectedData = new uint256[](7);
            expectedData[0] = currentData[0] + _netStaked;
            expectedData[1] = currentData[1] - tokenAmount;
            expectedData[2] = currentData[2] + _netStaked;
            expectedData[3] = currentData[3] + _netStaked;
            expectedData[4] = currentData[4] + (tokenAmount - _netStaked);

            stakingContract.stakeToken(_poolID, tokenAmount);

            currentData = _getCurrentData(userAddress, _poolID);

            assertEq(currentData[0], expectedData[0]);
            assertEq(currentData[1], expectedData[1]);
            assertEq(currentData[2], expectedData[2]);
            assertEq(currentData[3], expectedData[3]);
            assertEq(currentData[4], expectedData[4]);
            assertEq(_getUserDepositCount(userAddress, _poolID), userDepositCountBefore + 1);
        }

        if (userAddress != address(this)) vm.stopPrank();
    }

    function _stakeTokenWithAllowance(address userAddress, uint256 _poolID, uint256 tokenAmount) internal {
        _increaseSTAllowance(userAddress, tokenAmount);
        _stakeTokenWithTest(userAddress, _poolID, tokenAmount, false);
    }

    function _tryMultiUserMultiStake(uint256 howManyTimes, bool ifCreatePool) internal {
        if (ifCreatePool) {
            for (uint256 No = 0; No < howManyTimes; No++) {
                _addPool(address(this), false);
            }
        }

        for (uint256 No = 0; No < howManyTimes; No++) {
            for (uint256 userNo = 0; userNo < addressList.length; userNo++) {
                _increaseSTAllowance(addressList[userNo], amountToStake);
                _stakeTokenWithTest(addressList[userNo], No, amountToStake, false);
            }
        }
    }

    function _calculateNETStakedAmount(uint256 poolID, uint256 tokenAmount) internal view returns (uint256) {
        uint256 amountToBeStaked;
        uint256 _stakingFee = stakingContract.checkStakingFee(poolID);

        if (_stakingFee != 0) {
            uint256 stakingFeeToBePaid = (tokenAmount * _stakingFee * myTokenDecimals / 100) / myTokenDecimals;
            amountToBeStaked = tokenAmount - stakingFeeToBePaid;
        } else {
            amountToBeStaked = tokenAmount;
        }

        return amountToBeStaked;
    }
}
