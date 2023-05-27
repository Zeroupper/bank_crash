pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./BankCrashToken.sol";

contract StakingContract is Ownable {
    using SafeMath for uint256;

    BankCrashToken public token;

    struct Stake {
        uint256 amount;
        uint256 start;
        uint256 end;
        uint256 baseAPY;
        uint256 maximumAPY;
    }

    // The first key is the user's address, and the second key is the stake ID
    mapping(address => mapping(uint256 => Stake)) public stakes;
    // This keeps track of the next stake ID for each user
    mapping(address => uint256) public nextStakeId;

    constructor(BankCrashToken _token) {
        require(address(_token) != address(0), "Invalid token address");
        token = _token;
    }

    function stake(uint256 _amount, uint256 _months) external {
        require(_months > 0, "Staking period must be at least one month");
        require(_amount > 0, "Staking amount must be greater than zero");

        // Transfer the tokens to this contract
        token.transferFrom(msg.sender, address(this), _amount);

        // Calculate the APYs
        uint256 baseAPY = 15 * _months.div(10);
        uint256 maxAPY = 69 + (7 * _months);

        uint256 monthInSeconds = _months * 30 * 24* 60 * 60;
        uint256 start = block.timestamp;
        uint256 end = block.timestamp + monthInSeconds;

        // Create a new stake
        stakes[msg.sender][nextStakeId[msg.sender]] = Stake(_amount, start, end, baseAPY, maxAPY);

        // Increment the next stake ID for this user
        nextStakeId[msg.sender]++;
    }

    function unstake(uint256 _stakeId) external {
        Stake storage userStake = stakes[msg.sender][_stakeId];
    
        uint256 bonusApy = calculateBonusAPY(userStake);
        uint256 reward = userStake
            .amount
            .mul(userStake.baseAPY.add(bonusApy))
            .div(100);
    
        uint256 finalReward = getUnstakePenalty(userStake) * reward;

        // TODO CASE: if (token.stakingRewardAddress < finalReward) 
        // require(token.transferFrom(token.stakingRewardAddress(), msg.sender, finalReward), "Token transfer failed");
        // TODO transfer finalReward to the staker
        token.transferFromStakingRewards(msg.sender, finalReward);
    }

    function getUnstakePenalty( Stake memory userStake) public view returns (uint256) {
        uint256 stakingDuration = userStake.end - userStake.start;
        uint256 completedStake = block.timestamp - userStake.start;

        if(completedStake > stakingDuration) {
            completedStake = stakingDuration;
        }

        return 100 * (1 - completedStake / stakingDuration);
    }

    // Make call to Oracle, get bonus apy between the start of the stake and the end of the stake
    function calculateBonusAPY(Stake memory userStake) private returns (uint256){
        return 0;
    }
}
