// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Test, console} from "forge-std/Test.sol";
import "forge-std/console.sol";

import {MockToken} from "./MockToken.sol";

import {ERC20Staking} from "../src/ERC20Staking.sol";
import "../src/ProgramManager.sol";

contract TestSetUp is Test {
    MockToken myToken;
    MockToken myInterestToken;

    uint256 myTokenDecimal = 18;
    uint256 myTokenDecimals = 10 ** myTokenDecimal;

    uint256 _defaultStakingTarget = 10000 * myTokenDecimals;
    uint256 _defaultMinimumDeposit = 10 * myTokenDecimals;

    uint256 _lockedAPY = 200;
    uint256 _flexibleAPY = 10;

    uint256 _stakingFee = 30;

    ERC20Staking stakingContract;
    uint256 _confirmationCode = 0;

    address contractAdmin = address(1);
    address userOne = address(2);
    address userTwo = address(3);
    address userThree = address(4);
    address treasuaryAddress = address(10);

    address[] addressList = [userOne, userTwo, userThree];
    uint256 amountToProvide = 1000 * myTokenDecimals;
    uint256 amountToStake = 10 * myTokenDecimals;

    uint256 tokenToDistribute = 2000 * myTokenDecimals;

    enum PMActions {
        PAUSE,
        RESUME
    }

    function setUp() external {
        myToken = new MockToken(myTokenDecimal);
        myInterestToken = new MockToken(myTokenDecimal);

        stakingContract = new ERC20Staking(
            address(myToken), address(myInterestToken), _defaultStakingTarget, _defaultMinimumDeposit, _confirmationCode
        );
        stakingContract.addContractAdmin(contractAdmin);
        stakingContract.changeTreasuryAddress(treasuaryAddress);

        for (uint256 userNo = 0; userNo < addressList.length; userNo++) {
            myToken.transfer(addressList[userNo], tokenToDistribute);
        }

        myToken.transfer(userThree, _defaultStakingTarget * 2);
        myToken.transfer(contractAdmin, tokenToDistribute);
        myInterestToken.transfer(contractAdmin, tokenToDistribute);
    }
}
