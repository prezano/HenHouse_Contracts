// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.7;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./HenHouseRouter.sol";

contract HenHouseERC20 is Ownable, ERC20 {
    using SafeMath for uint256;

  
    uint256 internal amountFarm = 20 * 10**6 * 10**18;
    uint256 private farmReward;
    uint256 private gameRewardsPercentage = 35;
    uint256 private day_alive = 1;
    uint256 private time_created = block.timestamp;
    
    HenHouseRouter public router;

    uint256 public tokenForBosses = 2 * 10**6 * 10**18;

    address public addressForBosses;
    uint256 public sellFeeRate = 5;
    uint256 public buyFeeRate = 2;

    uint64 private halvingPerDay_45 = 200000;
    uint64 private halvingPerDay_91 = 100000;
    uint64 private halvingPerDay_137 = 50000;
    uint64 private halvingPerDay_3501 = 25000;

    constructor(string memory name, string memory symbol, address _henHouseRouter) ERC20(name, symbol) {
        router = HenHouseRouter(_henHouseRouter);
        addressForBosses = _msgSender();
    }

    modifier onlyFarmOwners() {
        require(router.farmOwners(_msgSender()), "caller is not the farmer");
        _;
    }

    function setTransferFeeRate(uint256 _sellFeeRate, uint256 _buyFeeRate)
        public
        onlyOwner
    {
        sellFeeRate = _sellFeeRate;
        buyFeeRate = _buyFeeRate;
    }

    function setMinTokensBeforeSwap(uint256 _tokenForBosses)
        public
        onlyOwner
    {
        require(_tokenForBosses < 20 * 10**6 * 10**18);
        tokenForBosses = _tokenForBosses;
    }

    function farm(address recipient, uint256 amount) external onlyFarmOwners {
        require(amountFarm != farmReward, "Over cap farm");
        require(recipient != address(0), "0x is not accepted here");
        require(amount > 0, "not accept 0 value");

        farmReward = farmReward.add(amount);
        if (farmReward <= amountFarm) _mint(recipient, amount);
        else {
            uint256 availableReward = farmReward.sub(amountFarm);
            _mint(recipient, availableReward);
            farmReward = amountFarm;
        }
    }

    function playToEarnRewards() external view onlyFarmOwners returns(uint256) {
        if (day_alive <= 45){
            return (uint256(halvingPerDay_45).mul(gameRewardsPercentage).div(100)).div(4);
        }
        if (day_alive > 45 && day_alive <= 91){
            return (uint256(halvingPerDay_91).mul(gameRewardsPercentage).div(100)).div(4);
        }
        if (day_alive > 91 && day_alive <= 137){
            return (uint256(halvingPerDay_137).mul(gameRewardsPercentage).div(100)).div(4);
        }
        if (day_alive > 137 && day_alive <= 3501){
            return (uint256(halvingPerDay_3501).mul(gameRewardsPercentage).div(100)).div(4);
        }              
    }
}