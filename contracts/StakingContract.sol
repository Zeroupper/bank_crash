pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract StakingContract is Ownable {
    using SafeMath for uint256;

    ERC20 public token;

    struct Stake {
        uint256 amount;
        uint256 start;
        uint256 end;
        uint256 baseAPY;
        uint256 bonusAPY;
        uint256 maximumAPY;
    }

    mapping(address => Stake[]) public stakes;

    constructor(ERC20 _token) {
        require(address(_token) != address(0), "Invalid token address");
        token = _token;
    }

    function stake(
        uint256 _amount,
        uint256 _months,
        uint256 _baseAPY,
        uint256 _maximumAPY
    ) external {
        require(_amount > 0, "Stake amount must be greater than 0");
        require(_months > 0, "Stake period must be greater than 0");
        require(token.balanceOf(msg.sender) >= _amount, "Insufficient token balance");
        token.transferFrom(msg.sender, address(this), _amount);
        stakes[msg.sender].push(
            Stake(
                _amount,
                block.timestamp,
                block.timestamp.add(_months.mul(30 days)),
                _baseAPY,
                0,
                _maximumAPY
            )
        );
    }

    function withdraw(uint256 _stakeIndex) external {
        Stake storage stake = stakes[msg.sender][_stakeIndex];
        require(stake.end < block.timestamp, "Stake period has not ended yet");
        uint256 reward = stake
            .amount
            .mul(stake.baseAPY.add(stake.bonusAPY))
            .div(100);
        if (block.timestamp < stake.end) {
            uint256 penalty = reward.mul(100).mul(
                1 - (block.timestamp - stake.start) / (stake.end - stake.start)
            );
            reward = reward.sub(penalty);
        }
        require(token.balanceOf(address(this)) >= stake.amount.add(reward), "Insufficient token balance");
        token.transfer(msg.sender, stake.amount.add(reward));
        delete stakes[msg.sender][_stakeIndex];
    }

    function applyBonusAPY(uint256 _bonusAPY) external onlyOwner {
        for (uint256 i = 0; i < stakes[msg.sender].length; i++) {
            Stake storage stake = stakes[msg.sender][i];
            if (
                stake.baseAPY.add(stake.bonusAPY).add(_bonusAPY) <=
                stake.maximumAPY
            ) {
                stake.bonusAPY = stake.bonusAPY.add(_bonusAPY);
            }
        }
    }
}
