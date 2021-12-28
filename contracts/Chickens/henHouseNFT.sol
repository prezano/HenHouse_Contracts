// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.7;
pragma abicoder v2;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../Tokens/henHouse.sol";
import "../Tokens/HenHouseRouter.sol";


contract HenHouseNFT is ERC721, Ownable {
    using SafeMath for uint256;
    using EnumerableSet for EnumerableSet.UintSet;
    HenHouse public henHouseToken;
    HenHouseRouter public henHouseRouter;

    uint256 timeToHatch = 0 days;

    enum Tribe {
        ZOMBIE,
        WARRIOR,
        ROBOT,
        ANIME
    }

    enum Rarity {
        EGG,
        BRONZE,
        SILVER,
        GOLD,
        DIAMOND
    }

    enum Egg {
        BRONZE,
        SILVER,
        GOLD,
        HATCHED
    }    

    enum Gender {
        EGG,
        MALE,
        FEMALE
    }    

    struct HenHouseChicken {
        Tribe tribe;
        Rarity rarity;
        Egg egg;
        Gender gender;
        bool isForSale;
        uint256 price;
        uint256 exp;
        uint256 bornAt;
        uint256 readyTime;
        uint256 dna;
    }

    event EXP(uint256 indexed tokenId, address owner, uint256 exp);
    event NewEgg(uint256 indexed tokenId, address to);
    event HatchEgg(uint256 indexed tokenId, Rarity rarity);

    mapping(uint256 => HenHouseChicken) public chickens;
    mapping(Egg => uint256) public eggPrices;
    mapping(Rarity => uint256) public chickenEggProduction;

    constructor(
        string memory _name,
        string memory _symbol,
        address _manager,
        address payable _henHouseToken
    ) ERC721(_name, _symbol) {
        henHouseToken = HenHouse(_henHouseToken);
        henHouseRouter = HenHouseRouter(_manager);
        eggPrices[Egg.BRONZE] = 5 * 10**3 * 10**18;
        eggPrices[Egg.SILVER] = 75 * 10**2 * 10**18;
        eggPrices[Egg.GOLD] = 15 * 10**3 * 10**18;
        chickenEggProduction[Rarity.BRONZE] = 1;
        chickenEggProduction[Rarity.SILVER] = 2;
        chickenEggProduction[Rarity.GOLD] = 4;
        chickenEggProduction[Rarity.DIAMOND] = 9;
    }

    modifier notEgg(uint256 _tokenId) {
        require(chickens[_tokenId].egg == Egg.HATCHED, "not hatched");
        _;
    }

    modifier onlyHatcher(address _who) {
        require(henHouseRouter.hatchers(_who), "not hatcher");
        _;
    }

    function setPrices (Egg _egg, uint256 _price) external onlyOwner{
        eggPrices[_egg] = _price;
    }

    function setProduction (Rarity _rarity, uint256 _production) external onlyOwner{
        chickenEggProduction[_rarity] = _production;
    }

    function _mint(address to, uint256 tokenId) internal override(ERC721) {
        super._mint(to, tokenId);
        henHouseRouter.incrementTokenId(0);
    }

    function upExp(
        uint256 _tokenId,
        address _owner,
        uint256 _exp
    ) public onlyHatcher(msg.sender) {
        require(_exp > 0, "require: non zero exp");
        HenHouseChicken storage chicken = chickens[_tokenId];
        chicken.exp = chicken.exp.add(_exp);
        emit EXP(_tokenId, _owner, _exp);
    }

    function hatchEgg(
        uint256 _tokenId,
        address _owner,
        uint8 _rarity,
        uint256 _dna,
        uint8 _gender
    ) public onlyHatcher(msg.sender) {
        require(ownerOf(_tokenId) == _owner, "require: owner KEY");
         HenHouseChicken storage chicken = chickens[_tokenId];
        require(chicken.egg != Egg.HATCHED, "require to be an EGG");
        require(block.timestamp >= chicken.readyTime, "cant hatch yet" );
        chicken.bornAt = block.timestamp;
        chicken.egg = Egg.HATCHED;
        chicken.rarity = Rarity(_rarity);
        chicken.dna = _dna;
        chicken.gender = Gender(_gender);
        emit HatchEgg(_tokenId, chicken.rarity);
    }

    function getChicken(uint256 _tokenId) public view returns (HenHouseChicken memory) {
        return chickens[_tokenId];
    }

    function getEgg(uint256 _tokenId) public view returns (Egg) {
        return chickens[_tokenId].egg;
    }

    function getRarity(uint256 _tokenId) public view returns (Rarity) {
        return chickens[_tokenId].rarity;
    }

    function buyEgg(Egg _egg, Tribe _tribe) public {
        uint256 feeMarket = eggPrices[_egg].mul(henHouseRouter.feeMarket()).div(
            henHouseRouter.divPercent()
        );
        henHouseToken.transferFrom(
            msg.sender,
            henHouseRouter.feeAddress(),
            feeMarket
        );
        henHouseToken.transferFrom(
            msg.sender,
            henHouseRouter.feeAddress(),
            eggPrices[_egg].sub(feeMarket)
        );

        uint256 nextTokenId = henHouseRouter.getNextTokenId(0);
        _mint(msg.sender, nextTokenId);
        uint256 creationTime = block.timestamp;
        chickens[nextTokenId] = HenHouseChicken({
            egg: _egg,
            tribe: _tribe,
            exp: 0,
            bornAt: creationTime,
            readyTime: creationTime + timeToHatch,
            rarity: Rarity.EGG,
            isForSale: false,
            price: 0,
            dna: 0,
            gender : Gender.EGG
        });
    }

    function troggleSale(uint256 _tokenId, uint256 _price) external {
        require(ownerOf(_tokenId) == msg.sender, "must be owner of asset");
        HenHouseChicken storage chicken = chickens[_tokenId];
        if (chicken.isForSale) {
            chicken.isForSale = false;
            chicken.price = 0;
        } else {
            chicken.isForSale = true;
        }

        chicken.price = _price;
        chickens[_tokenId] = chicken;
    }

    function buyEggMarketplace(uint256 _tokenId) public {
        require(msg.sender != address(0), "not sender 0");
        require(_exists(_tokenId), "token not exists");

        address tokenOwner = ownerOf(_tokenId);
        require(tokenOwner != address(0), "not to be owner of 0");
        require(tokenOwner != msg.sender, "not to be owner of token");
        HenHouseChicken memory asset = chickens[_tokenId];
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

        chickens[_tokenId] = asset;
    }

    function changeAssetPrice(uint256 _tokenId, uint256 _newPrice) public {
        require(msg.sender != address(0), "not sender 0");
        require(_exists(_tokenId), "token not exists");
        address tokenOwner = ownerOf(_tokenId);
        require(tokenOwner == msg.sender, "must be owner");
        HenHouseChicken memory asset = chickens[_tokenId];
        asset.price = _newPrice;
        chickens[_tokenId] = asset;
    }
}