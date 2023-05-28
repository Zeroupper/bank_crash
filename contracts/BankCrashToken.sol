// SPDX-License-Identifier: unlicensed

pragma solidity ^0.8.18;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

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

    constructor() ERC20("BankCrashToken", "BASH") {
        _mint(
            address(this),
            INITIAL_SUPPLY
        );
    }

    function stake(uint256 _amount, uint256 _months) external {
        require(_months > 0, "Staking period must be at least one month");
        require(_amount > 0, "Staking amount must be greater than zero");

        // Transfer the tokens to this contract
        transferFrom(msg.sender, address(this), _amount);

        // Staking_apy = 1.69 * month
        uint256 baseAPY = _months.mul(169).div(100);

        // Maximum_apy = 69 + 4.2 * month
        uint256 maxAPY =  _months.mul(42).div(10).add(69);

        uint256 start = block.timestamp;
        uint256 end = block.timestamp.add(_months.mul(30 days));

        // Create a new stake
        stakes[msg.sender][nextStakeId[msg.sender]] = Stake(_amount, start, end, baseAPY, maxAPY);

        // Increment the next stake ID for this user
        nextStakeId[msg.sender].add(1);
    }

    function unstake(uint256 _stakeId) external {
        require(stakes[msg.sender][_stakeId].createdAt > 0, "This stake does not exist");
        Stake storage userStake = stakes[msg.sender][_stakeId];

        uint256 bonusApy = calculateBonusAPY();
        uint256 finalApy = userStake.baseAPY.add(bonusApy);
        uint256 stakingDurationInYear = (block.timestamp - userStake.createdAt) / (365 days);

        // X = D(1 + r/n)n*y where:

        // X = Final amount
        // D = Initial Deposit
        // r = period rate 
        // n = number of compounding periods per year
        // y = number of years
        uint256 reward = (1 + finalApy / 100 / 12) * 12 * stakingDurationInYear;
    
        uint256 finalReward = getStakePenalty(userStake).mul(reward);

        _mint(
            address(this),
            finalReward
        );
        transfer(msg.sender, userStake.amount + finalReward);
        delete stakes[msg.sender][_stakeId];
    }

    function getStakePenalty(Stake memory userStake) internal view returns (uint256) {
        uint256 stakingDuration = userStake.endAt.sub(userStake.createdAt);
        uint256 completedStake = block.timestamp.sub(userStake.createdAt);

        if(completedStake > stakingDuration) {
            completedStake = stakingDuration;
        }

        return 100 * (1 - completedStake / stakingDuration);
    }

    // Make call to Oracle, get bonus apy between the start of the stake and the end of the stake
    function calculateBonusAPY() internal pure returns (uint256) {
        return 10;
    }
}
