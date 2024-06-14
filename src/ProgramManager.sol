// SPDX-License-Identifier: Apache-2.0
// Copyright 2024 HB Craft.

pragma solidity 0.8.20;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

contract ProgramManager {
    // ======================================
    // =          State Variables           =
    // ======================================
    IERC20Metadata public immutable STAKING_TOKEN;
    IERC20Metadata public immutable REWARD_TOKEN;
    uint256 internal constant FIXED_POINT_PRECISION = 10 ** 18;

    // Default value to set the stakingTarget property for the new StakingPool if not specified
    uint256 internal defaultStakingTarget;
    // Default value to set the minimumDeposit property for the new StakingPool if not specified
    uint256 internal defaultMinimumDeposit;

    /**
     *     - For preventing accidentally ending a stakingPool
     *     - Set when the contract is deployed
     *     - Asked when endPool() function is called
     */
    uint256 internal immutable CONFIRMATION_CODE;

    /// Program reward token balance for paying rewards
    uint256 internal rewardPool;
    /**
     *   - The list of users who donated/provided reward tokens to the rewardPool
     *   - Direct token transactions (via receive function) ends up in the rewardPool
     */
    mapping(address => uint256) internal rewardProviderList;

    /**
     *   - Each user can make infinite amount of deposits
     *   - A user's data for each deposit is kept seperately in stakingPoolList[poolID].stakerDepositList[userAddress]
     */
    struct TokenDeposit {
        uint256 stakingDate;
        uint256 withdrawalDate;
        uint256 amount;
        uint256 APY;
        uint256 claimedReward;
    }

    /**
     *     - The contract has ability to create 2 types of staking pools: LOCKED, FLEXIBLE
     *     - LOCKED staking pools' isWithdrawalOpen parameter is false by default
     *     - FLEXIBLE staking pools' isWithdrawalOpen parameter is true by default
     */
    enum PoolType {
        LOCKED,
        FLEXIBLE
    }

    // DataType and PoolDataType are used for cleaner communication among the contract functions
    enum DataType {
        STAKED,
        WITHDREW,
        REWARD_CLAIMED,
        FUNDS_COLLECTED,
        FUNDS_RESTORED,
        FEE_PAID
    }
    enum PoolDataType {
        IS_STAKING_OPEN,
        IS_WITHDRAWAL_OPEN,
        IS_REWARD_CLAIM_OPEN
    }

    enum ActionType {
        STAKING,
        WITHDRAWAL,
        REWARD_CLAIM
    }

    /**
     *     - Contract owners create as many pools as they want for different purposes
     *     - StakingPool's totalList[DataType.STAKED] parameter value can not be higher than stakingTarget
     */
    /**
     *     - The endDate is set via endPool function when no more reward is intended to be paid after certain period of time
     *     - If the current time has passed the endDate, endDate is used when calculating the rewards
     */
    struct StakingPool {
        uint256 stakingTarget;
        uint256 minimumDeposit;
        uint256 APY;
        uint256 stakingFeePercentage;
        uint256 endDate;
        bool isStakingOpen;
        bool isWithdrawalOpen;
        bool isRewardClaimOpen;
        PoolType poolType;
        address[] stakerAddressList;
        mapping(address => uint256) stakerList;
        mapping(address => TokenDeposit[]) stakerDepositList;
        mapping(address => uint256) withdrawerList;
        mapping(address => uint256) rewardClaimerList;
        mapping(address => uint256) feePayerList;
        mapping(address => uint256) fundRestorerList;
        mapping(DataType => uint256) totalList;
    }

    // The list holding all the created pools
    StakingPool[] internal stakingPoolList;

    constructor(IERC20Metadata _stakingToken, IERC20Metadata _rewardToken, uint256 _confirmationCode) {
        STAKING_TOKEN = _stakingToken;
        REWARD_TOKEN = _rewardToken;
        CONFIRMATION_CODE = _confirmationCode;
    }
}
