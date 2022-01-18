// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.7;

import './henHouseERC20.sol';
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract HenHouse is HenHouseERC20, ReentrancyGuard {
    using SafeMath for uint256;

    mapping(address => bool) bots;
    
    uint256 public maxSupply = 50 * 10**6 * 10**18;//;
    
    uint256 public amountSales = 5 * 10**6 * 10**18;
    uint256 public amountTeam = 75 * 10**5 * 10**18;
    uint256 public amountPlayToEarn = 175 * 10**5 * 10**18;
    uint256 public amountStaking = 10 * 10**6 * 10**18;
    uint256 public amountReserve = 65 * 10**5 * 10**18;
    uint256 public amountSponsors = 25 * 10**5 * 10**18;
    uint256 public amountAirDrop = 1 * 10**6 * 10**18;

    address public teamWallet;
    address public rewardsWallet;
    address public stakingWallet;
    address public reserveWallet;
    address public sponsorsWallet;
    address public airdropWallet;

    bool public antiBotEnabled;
    uint256 public antiBotDuration = 10 minutes;
    uint256 public antiBotTime;
    uint256 public antiBotAmount;

    constructor(string memory name, string memory symbol, address _router,address _team,address _rewards,address _staking,address _reserve,address _sponsor, address _airdrop)
        HenHouseERC20(name, symbol, _router)
    {
        teamWallet = _team;
        rewardsWallet = _rewards;
        stakingWallet = _staking;
        reserveWallet = _reserve;
        sponsorsWallet = _sponsor;
        airdropWallet = _airdrop;

        _mint(_team, amountTeam );
        _mint(_rewards, amountPlayToEarn );
        _mint(_staking, amountStaking );
        _mint(_reserve, amountReserve );
        _mint(_sponsor, amountSponsors );
        _mint(_airdrop, amountAirDrop );
        _mint(_msgSender(), amountSales);
    }
}