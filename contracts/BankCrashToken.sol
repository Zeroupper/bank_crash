// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "hardhat/console.sol";

contract BankCrashToken is ERC20, Ownable {
    using SafeMath for uint256;

    uint256 public constant INITIAL_SUPPLY = 420690000000 * (10 ** 18); // 420.69 billion tokens, 18 decimal places

    struct Stake {
        uint256 amount;
        uint256 createdAt;
        uint256 endAt;
        uint256 baseAPY;
        uint256 maximumAPY;
    }

    // The first key is the user's address, and the second key is the stake ID
    mapping(address => mapping(uint256 => Stake)) public stakes;
    // This keeps track of the next stake ID for each user
    mapping(address => uint256) public nextStakeId;

    event StakeCreated(address indexed user, uint256 stakeId, uint256 amount, uint256 endAt, uint256 baseAPY, uint256 maximumAPY);
    event StakeRemoved(address indexed user, uint256 stakeId, uint256 amount, uint256 reward);

    constructor() ERC20("BankCrashToken", "BASH") {
        _mint(msg.sender, INITIAL_SUPPLY);
    }

    function stake(uint256 _amount, uint256 _months) virtual external {
        require(_months > 2, "Staking period must be at least 3 months");
        require(_amount > 0, "Staking amount must be greater than zero");

        // Transfer the tokens to this contract
        this.transferFrom(msg.sender, address(this), _amount);

        // Staking_apy = 1.69 * month
        uint256 baseAPY = _months.mul(169).div(100);

        // Maximum_apy = 69 + 4.2 * month
        uint256 maxAPY =  _months.mul(42).div(10).add(69);

        uint256 start = block.timestamp;
        uint256 end = block.timestamp.add(_months.mul(30 days));

        // Create a new stake
        stakes[msg.sender][nextStakeId[msg.sender]] = Stake(_amount, start, end, baseAPY, maxAPY);

        emit StakeCreated(msg.sender, nextStakeId[msg.sender], _amount, end, baseAPY, maxAPY);
        
        // Increment the next stake ID for this user
        nextStakeId[msg.sender] = nextStakeId[msg.sender].add(1);
    }

    function unstake(uint256 _stakeId) virtual external {
        require(stakes[msg.sender][_stakeId].createdAt > 0, "This stake does not exist");
        Stake storage userStake = stakes[msg.sender][_stakeId];
        uint256 bonusApy = getBonusAPY();
        uint256 finalApy = userStake.baseAPY.add(bonusApy);
        uint256 reward = calculateReward(finalApy, userStake);
        uint256 rewardWithPenalty = userStake.amount.add(reward).mul(getStakePenalty(userStake)).div(100);

        _mint(
            address(this),
            rewardWithPenalty
        );
        this.transfer(msg.sender, rewardWithPenalty);
        delete stakes[msg.sender][_stakeId];
        emit StakeRemoved(msg.sender, _stakeId, userStake.amount, rewardWithPenalty);
    }

    function getStakePenalty(Stake memory userStake) internal view returns (uint256) {
        require(userStake.endAt.sub(userStake.createdAt) != 0, "Your staking duration cannot be 0.");
        uint256 totalStakingDuration = userStake.endAt.sub(userStake.createdAt);
        uint256 completedStake = block.timestamp.sub(userStake.createdAt);
        
        if(block.timestamp > userStake.endAt) {
            return 100;
        }
        if(block.timestamp < userStake.createdAt + 90 days) {
            return 75;
        }else {
            return 75 + 25 * completedStake / totalStakingDuration;
        }
    }

    // Make call to Oracle, get bonus apy between the start of the stake and the end of the stake
    function getBonusAPY() internal pure returns (uint256) {
        return 10;
    }

    function calculateReward(uint256 finalApy, Stake memory userStake) internal view returns (uint256) {
        uint256 completedStake = block.timestamp.sub(userStake.createdAt);
        uint256 stakingDuration = userStake.endAt.sub(userStake.createdAt);
        uint256 stakingDurationInYears = stakingDuration.mul(100).div(365 days);

        if(block.timestamp > userStake.endAt) {
            completedStake = stakingDuration;
        }

        uint256 reward = userStake.amount.mul(finalApy).mul(stakingDurationInYears).div(100);
        return reward.mul(completedStake).div(stakingDuration).div(100);
    }
}
