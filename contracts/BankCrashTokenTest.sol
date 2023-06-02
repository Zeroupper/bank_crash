// SPDX-License-Identifier: unlicensed

pragma solidity ^0.8.18;

import "./BankCrashToken.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract BankCrashTokenTest is BankCrashToken {
    using SafeMath for uint256;

    constructor() BankCrashToken() {
        _mint(address(this), INITIAL_SUPPLY);
    }

    // Add additional test methods as needed
    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }

    
    function stake(uint256 _amount, uint256 _months) override external {
        require(_months > 0, "Staking period must be at least one month");
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
}
