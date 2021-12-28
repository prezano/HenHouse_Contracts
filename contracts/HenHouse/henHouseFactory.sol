// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.7;
pragma abicoder v2;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../Tokens/HenHouseRouter.sol";
import "../Tokens/henHouse.sol";
import "../Interfaces/IHenHouseLand.sol";

contract HenHouseLandNFT is ERC721, Ownable, IHenHouseLand{
    using SafeMath for uint256;
    using EnumerableSet for EnumerableSet.UintSet;
    HenHouse public henHouseToken;
    HenHouseRouter public henHouseRouter;
    uint256 timeToHatch = 0 days;

    event EXP(uint256 indexed tokenId, address owner, uint256 exp);

    mapping(uint256 => HenHouseLand) public henhouses;
    mapping(address => bool) claimedFree; // check if user already claimed free henhouse
    mapping(address => bool) henHouseFarmer; // check if user already claimed free henhouse
    mapping(Capacity => uint256) henHousePrices;
    mapping(Capacity => uint256) public henHouseCapacity;
    mapping(uint256 => uint256) chickenInHenHouseTime;
    mapping(uint256 => uint256) public chickensInHenHouse;

    constructor(
        string memory _name,
        string memory _symbol,
        address _manager,
        address payable _henHouseToken
    ) ERC721(_name, _symbol) {
        henHouseRouter = HenHouseRouter(_manager);
        henHouseToken = HenHouse(_henHouseToken);
        henHousePrices[Capacity.SMALL] = 1;
        henHousePrices[Capacity.MEDIUM] = 2;
        henHousePrices[Capacity.LARGE] = 3;
        henHouseCapacity[Capacity.SMALL] = 3;
        henHouseCapacity[Capacity.MEDIUM] = 6;
        henHouseCapacity[Capacity.LARGE] = 9;
    }

    function setHenHouseFarmer(address _farmer) external onlyOwner {
        henHouseFarmer[_farmer] = true;
    }

    modifier onlyHenHouseFarmer() {
        require(henHouseFarmer[msg.sender], "not henhouse farmer");
        _;
    }

    function update(uint256 _tokenId, HenHouseLand memory _asset ) public  {
        henhouses[_tokenId] = _asset;
    }

    function updateChickenInHenHouseTime(uint256 _chickenId) public {
        chickenInHenHouseTime[_chickenId] = block.timestamp;
    }

    function removeChickenInHenHouse(uint256 _chickenId) public onlyHenHouseFarmer{
        chickenInHenHouseTime[_chickenId] = 0;
    }

    function increaseChickensInHenHouse(uint256 _henHouseId) public onlyHenHouseFarmer{
        chickensInHenHouse[_henHouseId]++;
    }

    function getChickenInHenHouseTime(uint256 _chickenId) public view onlyHenHouseFarmer returns (uint256){
        return chickenInHenHouseTime[_chickenId];
    }

    function _mint(address to, uint256 tokenId) internal override(ERC721) {
        super._mint(to, tokenId);
        henHouseRouter.incrementTokenId(1);
    }

    function setHenHousePrice(Capacity _tier,uint256 _newPrice) external onlyOwner {
        henHousePrices[_tier] = _newPrice;
    }

    function setHenHouseCapacity(Capacity _tier,uint256 _newCapacity) external onlyOwner {
        henHouseCapacity[_tier] = _newCapacity;
    }

    function claimFree() public {
        require(claimedFree[msg.sender] == false, "User already claimed free henhouse");
        uint256 nextTokenId = henHouseRouter.getNextTokenId(1);
        _mint(msg.sender, nextTokenId);
        HenHouseLand memory henhouse;
        henhouse.capacity = Capacity.SMALL;
        henhouse.isForSale = false;
        henhouses[nextTokenId] = henhouse;
        henHouseFarmer[msg.sender] = true;
    }

   function buyHenHouse(Capacity _tier) public {
        uint256 feeMarket = henHousePrices[_tier].mul(henHouseRouter.feeMarket()).div(
            henHouseRouter.divPercent()
        );
        henHouseToken.transferFrom(msg.sender, henHouseRouter.feeAddress(), feeMarket);
        henHouseToken.transferFrom(
            msg.sender,
            henHouseRouter.feeAddress(),
            henHousePrices[_tier].sub(feeMarket)
        );        
        uint256 nextTokenId = henHouseRouter.getNextTokenId(1);
        _mint(msg.sender, nextTokenId);
        HenHouseLand memory henhouse;
        henhouse.capacity = _tier;
        henhouse.isForSale = false;
        henhouses[nextTokenId] = henhouse;
        henHouseFarmer[msg.sender] = true;
    }

    function troggleHenHouseSale(uint256 _tokenId, uint256 _price) external {
        require(
            ownerOf(_tokenId) == msg.sender,
            "must be owner of asset"
        );
        HenHouseLand memory henhouse = henhouses[_tokenId];
        if (henhouse.isForSale ) {
            henhouse.isForSale = false;
            henhouse.price = 0;
        } else {
            henhouse.isForSale = true;
            henhouse.price = _price;
        }
        henhouses[_tokenId] = henhouse;

    }

    function buyHenHouseMarketplace(uint256 _tokenId) public {
        require(msg.sender != address(0), "not sender 0");
        require(_exists(_tokenId), "token not exists");
        address tokenOwner = ownerOf(_tokenId);
        require(tokenOwner != address(0),"not to be owner of 0");
        require(tokenOwner != msg.sender, "not to be owner of token");
        HenHouseLand memory asset = henhouses[_tokenId];
        require(asset.isForSale, "not for sale");

        uint256 feeMarket = asset.price.mul(henHouseRouter.feeMarket()).div(
            henHouseRouter.divPercent()
        );
        henHouseToken.transferFrom(msg.sender, henHouseRouter.feeAddress(), feeMarket);
        henHouseToken.transferFrom(
            msg.sender,
            tokenOwner,
            asset.price.sub(feeMarket)
        );   
        
        _transfer(tokenOwner, msg.sender, _tokenId);

        asset.isForSale = false;
        henhouses[_tokenId] = asset;
        henHouseFarmer[msg.sender] = true;
    }    

    function changeHenHousePrice(uint256 _tokenId, uint256 _newPrice) public {
        require(msg.sender != address(0), "not sender 0");
        require(_exists(_tokenId), "token not exists");
        address tokenOwner = ownerOf(_tokenId);
        require(tokenOwner == msg.sender, "must be owner");
        HenHouseLand memory asset = henhouses[_tokenId];
        asset.price = _newPrice;
        henhouses[_tokenId] = asset;
    }

   function getHenHouse(uint256 _tokenId) public view returns (HenHouseLand memory) {
        return henhouses[_tokenId];
    }
  
}