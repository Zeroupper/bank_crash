pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract BankCrashToken is ERC20, Ownable {
    using SafeMath for uint256;

    uint256 public constant INITIAL_SUPPLY = 420690000000 * (10 ** 18); // 420.69 billion tokens, assuming 18 decimal places

    // Allocation
    uint256 public constant STAKING_REWARD_ALLOCATION = 600;
    uint256 public constant LIQUIDITY_POOL_ALLOCATION = 200;
    uint256 public constant TEAM_MARKETING_ALLOCATION = 100;
    uint256 public constant CEX_LISTING_ALLOCATION = 69;
    uint256 public constant COMMUNITY_REWARDS_ALLOCATION = 31;

    // Addresses for allocation
    address public stakingRewardAddress;
    address public liquidityPoolAddress;
    address public teamMarketingAddress;
    address public cexListingAddress;
    address public communityRewardsAddress;

    constructor(
        address _stakingRewardAddress,
        address _liquidityPoolAddress,
        address _teamMarketingAddress,
        address _cexListingAddress,
        address _communityRewardsAddress
    ) ERC20("BankCrashToken", "BASH") {
        require(
            _stakingRewardAddress != address(0) &&
                _liquidityPoolAddress != address(0) &&
                _teamMarketingAddress != address(0) &&
                _cexListingAddress != address(0) &&
                _communityRewardsAddress != address(0),
            "Cannot set allocation address to zero address"
        );

        stakingRewardAddress = _stakingRewardAddress;
        liquidityPoolAddress = _liquidityPoolAddress;
        teamMarketingAddress = _teamMarketingAddress;
        cexListingAddress = _cexListingAddress;
        communityRewardsAddress = _communityRewardsAddress;

        _mint(
            stakingRewardAddress,
            INITIAL_SUPPLY.mul(STAKING_REWARD_ALLOCATION).div(1000)
        );
        _mint(
            liquidityPoolAddress,
            INITIAL_SUPPLY.mul(LIQUIDITY_POOL_ALLOCATION).div(1000)
        );
        _mint(
            teamMarketingAddress,
            INITIAL_SUPPLY.mul(TEAM_MARKETING_ALLOCATION).div(1000)
        );
        _mint(
            cexListingAddress,
            INITIAL_SUPPLY.mul(CEX_LISTING_ALLOCATION).div(1000)
        );
        _mint(
            communityRewardsAddress,
            INITIAL_SUPPLY.mul(COMMUNITY_REWARDS_ALLOCATION).div(1000)
        );
    }

    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }
}
