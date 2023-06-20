// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

import "./Interest.sol";

// Authtor: @CryptoMikest
contract TestCrashTokenV1 is Initializable, ERC20Upgradeable, OwnableUpgradeable, Interest {
    using SafeMath for uint256;
    
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize() initializer public {
        __ERC20_init("TestCrashToken", "TESH");
        __Ownable_init();
        _mint(msg.sender, INITIAL_SUPPLY);
    }

    // Define the initial token supply (420.69 billion tokens)
    uint256 public constant INITIAL_SUPPLY = 420690000000 * (10 ** 18);

    struct TestCrashEvents{
        uint256 bigCrash;
        uint256 mediumCrash;
        uint256 smallCrash;
    }

    struct Stake {
        uint256 amount;
        uint256 createdAt;
        uint256 endAt;
        uint256 baseAPY;
        uint256 maximumAPY;
        TestCrashEvents memento;
    }

    TestCrashEvents public testCrashEvents;

    mapping(address => mapping(uint256 => Stake)) public stakes;

    mapping(address => uint256) public nextStakeId;

    /**
    * @dev Emitted when a new stake is created
    */
    event StakeCreated(address indexed user, uint256 stakeId, uint256 amount, uint256 endAt, uint256 baseAPY, uint256 maximumAPY);
    
    /**
    * @dev Emitted when a stake is removed
    */
    event StakeRemoved(address indexed user, uint256 stakeId, uint256 amount, uint256 reward);

    /**
    * @dev Emitted when test crash events are added
    */
    event TestCrashEventAdded(address indexed user, bool, bool, bool);

    /**
    * @notice Enables users to stake tokens
    * @param _amount The amount of tokens to stake
    * @param _months The length of the stake in months
    * @dev Transfers tokens from the user to the contract and creates a new Stake
    */
    function stake(uint256 _amount, uint256 _months) external {
        require(_months > 2, "Staking period must be at least 3 months");
        require(_months <= 120, "Staking period can only be maximum 120 months (10 years)");
        require(_amount > 0, "Staking amount must be greater than zero");

        // Transfer the tokens to this contract
        this.transferFrom(msg.sender, address(this), _amount);

        uint256 baseAPY = 10 + _months / 3;

        // Maximum_apy = 69 + 3 * month
        uint256 maxAPY = 69 + _months * 3;

        uint256 start = block.timestamp;
        uint256 end = block.timestamp.add(_months.mul(30 days));

        // Create a new stake
        stakes[msg.sender][nextStakeId[msg.sender]] = Stake(_amount, start, end, baseAPY, maxAPY, TestCrashEvents(testCrashEvents.bigCrash, testCrashEvents.mediumCrash, testCrashEvents.smallCrash));

        emit StakeCreated(msg.sender, nextStakeId[msg.sender], _amount, end, baseAPY, maxAPY);
        
        // Increment the next stake ID for this user
        nextStakeId[msg.sender] = nextStakeId[msg.sender].add(1);
    }

    /**
    * @notice Allows users to remove a stake
    * @param _stakeId The ID of the stake to remove
    * @dev Checks that the stake exists, calculates the reward, applies a penalty for early unstaking, mints and transfers reward, and deletes the stake
    */
    function unstake(uint256 _stakeId) external {
        require(stakes[msg.sender][_stakeId].createdAt > 0, "This stake does not exist");
        Stake storage userStake = stakes[msg.sender][_stakeId];
        uint256 bonusApy = getBonusAPY(userStake);
        uint256 finalApy = userStake.baseAPY.add(bonusApy);
        uint256 reward = calculateReward(finalApy, userStake);
        uint256 rewardWithPenalty = userStake.amount.add(reward).mul(getStakePenalty(_stakeId)).div(100);

        _mint(
            address(this),
            rewardWithPenalty
        );
        this.transfer(msg.sender, rewardWithPenalty);
        delete stakes[msg.sender][_stakeId];
        emit StakeRemoved(msg.sender, _stakeId, userStake.amount, rewardWithPenalty);
    }

    /**
    * @notice Calculates the penalty for early unstaking
    * @param _stakeId The ID of the stake to get penalty
    * @return The penalty as a percentage of the reward
    * @dev Penalizes early unstaking. No penalty if stake is completed. 67% penalty if unstaked within first 60 days. Linear penalty based on completed stake afterwards.
    */
    function getStakePenalty(uint256 _stakeId) public view returns (uint256) {
        require(stakes[msg.sender][_stakeId].createdAt > 0, "This stake does not exist");
        Stake storage userStake = stakes[msg.sender][_stakeId];

        uint256 totalStakingDuration = userStake.endAt.sub(userStake.createdAt);
        uint256 completedStake = block.timestamp.sub(userStake.createdAt);
        
        if(block.timestamp > userStake.endAt) {
            return 100;
        }
        if(block.timestamp < userStake.createdAt + 60 days) {
            return 33;
        } else {
            return 33 + 67 * completedStake / totalStakingDuration;
        }
    }

    /**
    * @notice Updates the number of 'Test Crash' events
    * @param bigTestCrashEvent Indicates a 'Big Test Crash' event
    * @param mediumTestCrashEvent Indicates a 'Medium Test Crash' event
    * @param smallTestCrashEvent Indicates a 'Small Test Crash' event
    * @dev Only callable by the owner. Increments the crash counters.
    */
    function updateTestCrashEvents(bool bigTestCrashEvent, bool mediumTestCrashEvent, bool smallTestCrashEvent) public onlyOwner {
        if(bigTestCrashEvent) {
            testCrashEvents.bigCrash++;
        }
        if(mediumTestCrashEvent) {
            testCrashEvents.mediumCrash++;
        }
        if(smallTestCrashEvent) {
            testCrashEvents.smallCrash++;
        }
        emit TestCrashEventAdded(msg.sender, bigTestCrashEvent, mediumTestCrashEvent, smallTestCrashEvent);
    }

    /**
    * @notice Calculates the bonus APY based on 'Test Crash' events
    * @param userStake The stake for which the bonus APY is calculated
    * @return The bonus APY amount
    * @dev Checks the number of each type of 'Test Crash' events that have occurred since the user's stake was created, and calculates the bonus APY
    */
    function getBonusAPY(Stake memory userStake) public view returns (uint256) {
        uint256 bigTestCollapses = testCrashEvents.bigCrash - userStake.memento.bigCrash;
        uint256 mediumTestCollapses = testCrashEvents.mediumCrash - userStake.memento.mediumCrash;
        uint256 smallTestCollapses = testCrashEvents.smallCrash - userStake.memento.smallCrash;

        return bigTestCollapses * 42 + mediumTestCollapses * 14 + smallTestCollapses * 2;
    }

    /**
    * @notice Calculates the reward for a stake
    * @param finalApy The APY for the stake (baseAPY + bonusAPY)
    * @param userStake The stake for which the reward is calculated
    * @return The reward amount in wei
    * @dev Calculates the completed duration of the stake, calculates the final amount using the accrueInterest function, and calculates the reward
    */
    function calculateReward(uint256 finalApy, Stake memory userStake) internal view returns (uint256) {
        uint256 completedStake = block.timestamp.sub(userStake.createdAt);
        uint256 stakingDuration = userStake.endAt.sub(userStake.createdAt);

        if(block.timestamp > userStake.endAt) {
            completedStake = stakingDuration;
        }
        uint256 interestRate = yearlyRateToRay(finalApy.mul(1 ether).div(100));
        uint256 principalInRay = userStake.amount.mul(10 ** 27);
        uint256 finalAmount = accrueInterest(principalInRay, interestRate, completedStake);
        uint256 reward = finalAmount.sub(principalInRay).div(10 ** 27);
        return reward;
    }
}
