// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.7;

import './henHouseERC20.sol';
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

contract HenHouse is HenHouseERC20, ReentrancyGuard {
    using SafeMath for uint256;

    mapping(address => bool) bots;
    uint256 public maxSupply = 100 * 10**6 * 10**18;//;
    uint256 public amountPlayToEarn = 35 * 10**6 * 10**18;
    uint256 public amountTeam = 15 * 10**6 * 10**18;
    uint256 public amountReserve = 15 * 10**6 * 10**18;
    uint256 public amountSponsors = 5 * 10**6 * 10**18;
    uint256 public amountSales = 10 * 10**6 * 10**18;
    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;

    bool public antiBotEnabled;
    uint256 public antiBotDuration = 10 minutes;
    uint256 public antiBotTime;
    uint256 public antiBotAmount;

    constructor(string memory name, string memory symbol, address _router)
        HenHouseERC20(name, symbol, _router)
    {
        _mint(_msgSender(), maxSupply.sub(amountFarm).sub(amountPlayToEarn).sub(amountSponsors).sub(amountReserve).sub(amountTeam));
    
        //_mint(_msgSender(), maxSupply);
        // IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(
        //     0x10ED43C718714eb63d5aA57B78B54704E256024E
        // );

        // uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
        // .createPair(address(this), _uniswapV2Router.WETH());

        // uniswapV2Router = _uniswapV2Router;
        //_approve(address(this), address(uniswapV2Router), ~uint256(0));
    }

    function burn(uint256 amount) public {
        _burn(_msgSender(), amount);
    }

    function setBots(address _bots) external onlyOwner {
        require(!bots[_bots]);

        bots[_bots] = true;
    }

    // function _transfer(
    //     address sender,
    //     address recipient,
    //     uint256 amount
    // ) internal virtual override {
    //     if (
    //         antiBotTime > block.timestamp &&
    //         amount > antiBotAmount &&
    //         bots[sender]
    //     ) {
    //         revert("Anti Bot");
    //     }

    //     uint256 transferFeeRate = recipient == uniswapV2Pair
    //         ? sellFeeRate
    //         : (sender == uniswapV2Pair ? buyFeeRate : 0);

    //     if (
    //         transferFeeRate > 0 &&
    //         sender != address(this) &&
    //         recipient != address(this)
    //     ) {
    //         uint256 _fee = amount.mul(transferFeeRate).div(100);
    //         super._transfer(sender, address(this), _fee); // TransferFee
    //         amount = amount.sub(_fee);
    //     }

    //     super._transfer(sender, recipient, amount);
    // }

    // function sweepTokenForBosses() public nonReentrant {
    //     uint256 contractTokenBalance = balanceOf(address(this));
    //     if (contractTokenBalance >= tokenForBosses) {
    //         swapTokensForEth(tokenForBosses);
    //     }
    // }

    // receive eth from uniswap swap
    receive() external payable {}

    // function swapTokensForEth(uint256 tokenAmount) private {
    //     // generate the uniswap pair path of token -> weth
    //     address[] memory path = new address[](2);
    //     path[0] = address(this);
    //     path[1] = uniswapV2Router.WETH();

    //     // make the swap
    //     uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
    //         tokenAmount,
    //         0, // accept any amount of ETH
    //         path,
    //         addressForBosses, // The contract
    //         block.timestamp
    //     );
    // }

    function setAddressForBosses(address _addressForBosses) external onlyOwner {
        require(_addressForBosses != address(0), "0x is not accepted here");

        addressForBosses = _addressForBosses;
    }

    function antiBot(uint256 amount) external onlyOwner {
        require(amount > 0, "not accept 0 value");
        require(!antiBotEnabled);

        antiBotAmount = amount;
        antiBotTime = block.timestamp.add(antiBotDuration);
        antiBotEnabled = true;
    }
}