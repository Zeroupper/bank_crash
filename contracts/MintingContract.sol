// pragma solidity ^0.8.0;

// import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
// import "@openzeppelin/contracts/access/Ownable.sol";
// import "@openzeppelin/contracts/utils/math/SafeMath.sol";
// import "./BankCrashToken.sol";

// contract MintingContract is Ownable {
//     using SafeMath for uint256;

//     BankCrashToken public token;

//     struct Mint {
//         uint256 amount;
//         uint256 start;
//         uint256 end;
//         uint256 baseAPY;
//         uint256 bonusAPY;
//         uint256 maximumAPY;
//     }

//     mapping(address => Mint[]) public mints;

//     constructor(BankCrashToken _token) {
//         require(address(_token) != address(0), "Invalid token address");
//         token = _token;
//     }

//     function mint(
//         uint256 _amount,
//         uint256 _months,
//         uint256 _baseAPY,
//         uint256 _maximumAPY
//     ) external onlyOwner {
//         require(_amount > 0, "Mint amount must be greater than 0");
//         require(_months > 0, "Mint period must be greater than 0");
//         token.mint(address(this), _amount);
//         mints[msg.sender].push(
//             Mint(
//                 _amount,
//                 block.timestamp,
//                 block.timestamp.add(_months.mul(30 days)),
//                 _baseAPY,
//                 0,
//                 _maximumAPY
//             )
//         );
//     }

//     function stopMinting(uint256 _mintIndex) external {
//         Mint storage mint = mints[msg.sender][_mintIndex];
//         require(mint.end > block.timestamp, "Mint period has already ended");
//         uint256 reward = mint.amount.mul(mint.baseAPY.add(mint.bonusAPY)).div(
//             100
//         );
//         if (block.timestamp < mint.end) {
//             uint256 penalty = reward.mul(100).mul(
//                 1 - (block.timestamp - mint.start) / (mint.end - mint.start)
//             );
//             reward = reward.sub(penalty);
//         }
//         require(token.balanceOf(address(this)) >= mint.amount.add(reward), "Insufficient token balance");
//         token.transfer(msg.sender, mint.amount.add(reward));
//         delete mints[msg.sender][_mintIndex];
//     }

//     function applyBonusAPY(uint256 _bonusAPY) external onlyOwner {
//         for (uint256 i = 0; i < mints[msg.sender].length; i++) {
//             Mint storage mint = mints[msg.sender][i];
//             if (
//                 mint.baseAPY.add(mint.bonusAPY).add(_bonusAPY) <=
//                 mint.maximumAPY
//             ) {
//                 mint.bonusAPY = mint.bonusAPY.add(_bonusAPY);
//             }
//         }
//     }
// }
