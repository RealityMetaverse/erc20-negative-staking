# ERC20 Staking with Reward Token and Staking Fee

![version](https://img.shields.io/badge/version-1.1.1-blue)

---

### Contract Introduction

The contract based on and is modified version of https://github.com/RealityMetaverse/ERC1155-Marketplace-with-Dynamic-Pricing
The contract allows to launch a staking program and to create an unlimited number of staking pools inside the program, which can be either locked or flexible. All pools use the designated ERC20 token assigned during program deployment inside the `constructor` function. Thanks to this contract user can stake in one ERC20 token (`STAKE_TOKEN`) while claiming the reward in a different ERC20 token (`REWARD_TOKEN`). The contract also allows to cut certain percent of the token sent as a staking fee.

---

### Key Features

**Multiple Staking Pools:**

- Ability to create numerous locked or flexible staking pools.

- **Enum `PoolType`:** Defines the type of a `StakingPool`.
  ```solidity
  enum PoolType { LOCKED, FLEXIBLE }
  ```

**Customizable Pool Properties:**
Each pool can have:

- `stakingTarget`
- `minimumDeposit`
- `APY`
- `stakingFeePercentage`
- Statuses (open or close) for staking, withdrawal, and reward claims controlled independently.

---

### Supported Tokens

The contract was initially written for RMV token staking. However, it supports all ERC20 tokens. Non-ERC20 tokens are not supported. Users earn reward in the token they staked in.

---

### User Experience

**Staking:**

- Users can stake their tokens in various pools, each with distinct rules and rewards.
- Users have the flexibility to stake their tokens as many times as and in any amount they wish in any created staking pool.
- If the staking pool has a stakingFeePercentage over 0, then the certain amount of the token sent is cut as a staking fee.
- Each time a user stakes in a pool, a unique deposit is created and added to the deposit list of the user within that specific staking pool with the staking date and the APY that the staking pool had at the time of staking. This means that the returns on each deposit are calculated based on the APY the pool had at the moment of staking.

##### :warning: Warning

- When a user interacts with the **program contract** for **staking**, **providing reward**, or **restoring funds**, please be aware that although the user initiates the transaction, the **program contract** technically carries out the expenditure. So, the user can get an **allowance too low** error, and the transaction can fail if the user doesn't interact with the **token contract** and approves the **program contract address** as a **spender** before interacting with the program contract.
- For this reason, before the user interacts with the program contract for these purposes, your application must take a crucial step to ensure that the user interacts with the **token contract** by calling the `increaseAllowance(spender, addedValue)` function of the **token contract**. This will allow the program contract to carry out the expenditure and ensure the smooth and proper functionality.

**Reward Claim:**

- Reward is calculated on a daily basis.
- Reward is paid in the `REWARD_TOKEN`
- Stakers have the option to claim their accrued reward daily. This provides flexibility and frequent access to earned rewards.
- When reward is claimed, it is automatically calculated, collected from the common reward pool and sent to the staker if there are enough tokens in the reward pool.

  **Withdrawal:**

- When a staker decides to withdraw a deposit, the reward accrued on that deposit is also claimed simultaneously if the reward claim is open for that pool.

---

### Access Control

The contract implements an access control system with distinct roles. Functionalities are restricted based on access levels. The system ensures that access to the execution of functions are strictly regulated.

- **Enum `AccessTier`:** Defines the different access levels within the contract.
  ```solidity
  enum AccessTier { ADMIN, OWNER }
  ```

| Name                   | Value / Tier | Description                                                                              |
| :--------------------- | :----------- | :--------------------------------------------------------------------------------------- |
| `AccessTier.ADMIN`     | **0**        | Administrators with extended privileges for specific functions.                          |
| `AccessTier.OWNER`     | **1**        | The contract owner with full control over all functions, except `changeTreasuryAddress`. |
| `AccessTier.TREASUARY` | **2**        | Can only call the `changeTreasuryAddress`.                                               |

---

### Administrative Controls

The `contractOwner` can manage the program's overall functioning or configure staking pool properties individually. The `contractOwner` has the ability to assign `contractAdmin`s, and they are also authorized to partially participate in the program management. Most functions are available only to the contract owner.

| Function                       | Parameters                                                                                                                                                   | Access Tier         | Description                                                                |
| ------------------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------ | ------------------- | -------------------------------------------------------------------------- |
| `addContractAdmin`             | `address userAddress`                                                                                                                                        | `onlyContractOwner` | Adds a new contract admin.                                                 |
| `addStakingPoolDefault`        | `uint256 typeToSet` `uint256 APYToSet` `uint256 stakingFeeToSet`                                                                                             | `onlyContractOwner` | Adds a new staking pool with default settings.                             |
| `addStakingPoolCustom`         | `uint256 typeToSet` `uint256 stakingTargetToSet` `uint256 minimumDepositToSet` `uint256 stakingFeeToSet` `bool stakingAvailabilityStatus` `uint256 APYToSet` | `onlyContractOwner` | Adds a new staking pool with custom properties.                            |
| `changePoolAvailabilityStatus` | `uint256 poolID` `uint256 parameterToChange` `bool valueToAssign`                                                                                            | `onlyContractOwner` | Modifies availability status of a staking pool.                            |
| `collectFunds`                 | `uint256 poolID` `uint256 tokenAmount`                                                                                                                       | `onlyContractOwner` | Collects staked funds from a staking pool.                                 |
| `collectRewardPoolFunds`       | `uint256 tokenAmount`                                                                                                                                        | `onlyContractOwner` | Collects funds from the reward pool.                                       |
| `endStakingPool`               | `uint256 poolID `uint256 \_confirmationCode`                                                                                                                 | `onlyContractOwner` | Ends a specified staking pool.                                             |
| `pauseProgram`                 | None                                                                                                                                                         | `onlyContractOwner` | Closes staking, withdrawal and reward claim for all the pools.             |
| `provideReward`                | `uint256 tokenAmount`                                                                                                                                        | `onlyAdmins`        | Adds funds to the reward pool.                                             |
| `removeContractAdmin`          | `address userAddress`                                                                                                                                        | `onlyContractOwner` | Removes a contract admin.                                                  |
| `resumeProgram`                | None                                                                                                                                                         | `onlyContractOwner` | Sets availability status of the staking pools back to predefined settings. |
| `restoreFunds`                 | `uint256 poolID` `uint256 tokenAmount`                                                                                                                       | `onlyAdmins`        | Restores collected funds back to a staking pool.                           |
| `setDefaultMinimumDeposit`     | `uint256 newDefaultMinimumDeposit`                                                                                                                           | `onlyContractOwner` | Sets the program default minimum deposit.                                  |
| `setDefaultStakingTarget`      | `uint256 newStakingTarget`                                                                                                                                   | `onlyContractOwner` | Sets the program default staking target.                                   |
| `setPoolAPY`                   | `uint256 poolID` `uint256 newAPY`                                                                                                                            | `onlyContractOwner` | Sets a new APY for a specified staking pool.                               |
| `setPoolMiniumumDeposit`       | `uint256 poolID` `uint256 newMinimumDeposit`                                                                                                                 | `onlyAdmins`        | Sets a new minimum deposit for a staking pool.                             |
| `setPoolStakingTarget`         | `uint256 poolID` `uint256 newStakingTarget`                                                                                                                  | `onlyContractOwner` | Sets a new staking target for a staking pool.                              |
| `setPoolStakingFee`            | `uint256 poolID` `uint256 newStakingFee`                                                                                                                     | `onlyContractOwner` | Sets a new staking fee for a staking pool.                                 |

> The predefined settings for the staking program are:
>
> 1.  Both staking and reward claiming is open for locked and flexible pools.
> 2.  Withdrawal is open for flexible pools, but closed for locked pools.

> _Note:_ When a new staking pool is created, it is added to the array of staking pools. Each pool has a unique identifier, called poolID. This ID is essentially the index of the pool within the array. The numbering for poolID starts from zero and increments sequentially with each new pool addition. This means the first pool created will have a poolID of 0, the second pool will have a poolID of 1, and so on.

---

### Data Collection and Retrieval

The program keeps detailed data of stakers, withdrawers, reward claimers, fund collectors, fund restorers, reward providers, and reward collectors in each pool and provides a set of read functions for easy data retrieval.

| Function                         | Parameters                                                                         |
| -------------------------------- | ---------------------------------------------------------------------------------- |
| `checkAPY`                       | `uint256 poolID`                                                                   |
| `checkClaimableRewardBy`         | `address userAddress` `uint256 poolID` `uint256 depositNumber` `bool withDecimals` |
| `checkConfirmationCode`          | None                                                                               |
| `checkDailyGeneratedReward`      | `uint256 poolID`                                                                   |
| `checkDefaultMinimumDeposit`     | None                                                                               |
| `checkDefaultStakingTarget`      | None                                                                               |
| `checkDepositCountOfAddress`     | `address userAddress` `uint256 poolID`                                             |
| `checkDepositStakedAmount`       | `address userAddress` `uint256 poolID` `uint256 depositNumber`                     |
| `checkEndDate`                   | `uint256 poolID`                                                                   |
| `checkGeneratedRewardDailyTotal` | `uint256 poolID` `ifPrecise`                                                       |
| `checkGeneratedRewardLastDayFor` | `address userAddress` `uint256 poolID`                                             |
| `checkIfRewardClaimOpen`         | `uint256 poolID`                                                                   |
| `checkIfPoolEnded`               | `uint256 poolID`                                                                   |
| `checkIfStakingOpen`             | `uint256 poolID`                                                                   |
| `checkIfWithdrawalOpen`          | `uint256 poolID`                                                                   |
| `checkRewardClaimedBy`           | `address userAddress` `uint256 poolID`                                             |
| `checkRewardPool`                | None                                                                               |
| `checkRewardProvidedBy`          | `address userAddress`                                                              |
| `checkMinimumDeposit`            | `uint256 poolID`                                                                   |
| `checkPoolCount`                 | None                                                                               |
| `checkPoolType`                  | `uint256 poolID`                                                                   |
| `checkRestoredFundsBy`           | `address userAddress` `uint256 poolID`                                             |
| `checkStakedAmountBy`            | `address userAddress` `uint256 poolID`                                             |
| `checkStakingTarget`             | `uint256 poolID`                                                                   |
| `checkTotalClaimableReward`      | `uint256 poolID`                                                                   |
| `checkTotalClaimableRewardBy`    | `address userAddress` `uint256 poolID`                                             |
| `checkTotalFeePaid`              | `uint256 poolID`                                                                   |
| `checkTotalFundCollected`        | `uint256 poolID`                                                                   |
| `checkTotalFundRestored`         | `uint256 poolID`                                                                   |
| `checkTotalRewardClaimed`        | `uint256 poolID`                                                                   |
| `checkTotalStaked`               | `uint256 poolID`                                                                   |
| `checkTotalWithdrawn`            | `uint256 poolID`                                                                   |
| `checkWithdrawnAmountBy`         | `address userAddress` `uint256 poolID`                                             |

---

### Dependencies

This project uses the Foundry framework with the OpenZeppelin contracts (v5.0.1) for enhanced security and standardized features. You need to install necessary dependencies.

You can install the OpenZeppelin contracts by running:

```bash
$ forge install --no-commit OpenZeppelin/openzeppelin-contracts@v5.0.1
```
