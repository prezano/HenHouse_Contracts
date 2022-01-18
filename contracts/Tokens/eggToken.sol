// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.7;

import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import "@openzeppelin/contracts/access/Ownable.sol";

contract EggToken is ERC20, Ownable {

    address public addressForBosses;
    address public henHouseAddress;
    address public stakingAddress;

    constructor(string memory name, string memory symbol) ERC20(name, symbol) {
        addressForBosses = _msgSender();
    }

    modifier onlyHenHouse() {
        require(henHouseAddress == _msgSender(), "caller is not the farmer");
        _;
    }

    modifier onlyStaker() {
        require(stakingAddress == _msgSender(), "caller is not the staker");
        _;
    }

    function setHenHouseAddress(address _hh) public onlyOwner {
        henHouseAddress = _hh;
    }

    function setStakingAddress(address _ss) public onlyOwner {
        stakingAddress = _ss;
    }

    function mintTokens(address _depositAddress, uint256 _amount) public onlyHenHouse {
        _mint(_depositAddress, _amount);
    }

    function endStaking(address _to, uint256 _amount) public onlyStaker {
        transferFrom(msg.sender, _to, _amount);
        _burn(_to, _amount);
    }

    function burn(uint256 amount) public onlyHenHouse {
        _burn(_msgSender(), amount);
    }    
}