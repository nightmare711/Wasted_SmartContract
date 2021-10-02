//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IWastedHero.sol";
import "./AcceptedToken.sol";
import "./IWastedEquipment.sol";
import "./IPet.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


contract WastedHero is  IWastedHero, ERC721, ReentrancyGuard, AcceptedToken {
    using SafeERC20 for IERC20;
    using EnumerableSet for EnumerableSet.UintSet;
    
    modifier onlyHeroOwner(uint heroId) {
        require(ownerOf(heroId) == msg.sender, "WastedHero: Caller isn't owner of hero");
        _;
    }
    
    IWastedEquipment public wastedEquipment;
    IPet public wastedPet;
    Hero[] private _heroes;
    Pool[] public pools;
    
    uint private constant PERCENT = 100;
    uint public marketFeeInPercent = 20;
    uint public serviceFeeInToken = 1e20;
    uint public breedingFee = 0.15 * 1e18;
    uint public fushionFee = 0.15 * 1e18;
    uint public rarePackageFee = 0.15 * 1e18;
    uint public epicPackageFee = 0.2 * 1e18;
    uint public legendaryPackageFee = 0.3 * 1e18;
    uint public maxLevel = 100;
    string private _uri;
    
    mapping(uint => uint) public heroBreedingTime;
    mapping(uint => uint) public heroesOnSale;
    mapping(uint => mapping(address => uint)) public heroesOffers;
    mapping(string => bool) public usedNames;

    mapping(uint => uint) private _heroesWithPet;
    mapping(uint => EnumerableSet.UintSet) private _heroeskills;
    constructor(
        IWastedEquipment equipmentAddress,
        IERC20 tokenAccept,
        uint maxSupply,
        uint startTime,
        string memory baseURI
    ) ERC721("WastedHero", "WAH") AcceptedToken(tokenAccept) {
        wastedEquipment = equipmentAddress;
        _uri = baseURI;
        pools.push(Pool(0, 0, maxSupply, startTime));
    }
    
    function setWastedEquipment(IWastedEquipment wastedEquipmentAddress) external onlyOwner {
        require(address(wastedEquipmentAddress) != address(0), "WastedHero: invalid address");
        wastedEquipment = wastedEquipmentAddress;
    }

    function setWastedPet(IPet wastedPetAddress) external onlyOwner {
        require(address(wastedPetAddress) != address(0));
        wastedPet = wastedPetAddress;
    }
    
    /**
    * @notice function to set market fee.
    * 
    * Requirements: 
    * - onlyOwner.
    */
    function setMarketFeeInPercent(uint marketFee) external onlyOwner {
        require(marketFee < PERCENT, "WastedHero: invalid marketFeeInPercent");
        marketFeeInPercent = marketFee;
    }
    
    /**
    * @notice function to set service fee.
    * 
    * Requirements: 
    * - onlyOwner.
    */
    function setServiceFee(uint value) external onlyOwner {
        serviceFeeInToken = value;
    }
    
    /**
    * @notice function to set breedingFee fee.
    * 
    * Requirements: 
    * - onlyOwner.
    */
    function setBreedingFee(uint newBreedingFee) external onlyOwner {
        breedingFee = newBreedingFee;
    }
    
    /**
    * @notice function to set fushion fee.
    * 
    * Requirements: 
    * - onlyOwner.
    */
    function setFusionFee(uint newFusionFee) external onlyOwner {
        fushionFee = newFusionFee;
    }
    
     /**
    * @notice function to set rare package fee.
    * 
    * Requirements: 
    * - onlyOwner.
    */
    function setRarePackageFee(uint newRarePackageFee) external onlyOwner {
        rarePackageFee = newRarePackageFee;
    }
    
    /**
    * @notice function to set epic fee.
    * 
    * Requirements: 
    * - onlyOwner.
    */
    function setEpicPackageFee(uint newEpicPackageFee) external onlyOwner {
        epicPackageFee = newEpicPackageFee;
    }
    
     /**
    * @notice function to set legendary fee.
    * 
    * Requirements: 
    * - onlyOwner.
    */
    function setLegendaryPackageFee(uint newLegendaryPackageFee) external onlyOwner {
        legendaryPackageFee = newLegendaryPackageFee;
    }

    function setMaxLevel(uint newMaxLevel) external onlyOwner {
        require(newMaxLevel > 0, "WastedHero: invalid max level");
        maxLevel = newMaxLevel;
    }

    function setBaseURI(string memory baseURI) external onlyOwner {
        _uri = baseURI;
    }
    
    function getHero(uint heroId) external view override returns (
        string memory name,
        uint level,
        uint pet,
        uint[] memory skills,
        uint[3] memory equipment
    ) {
        Hero memory hero = _heroes[heroId];

        uint skillCount = _heroeskills[heroId].length();
        uint[] memory skillIds = new uint[](skillCount);
        for (uint i = 0; i < skillCount; i++) {
            skillIds[i] = _heroeskills[heroId].at(i);
        }

        name = hero.name;
        level = hero.level;
        pet = _heroesWithPet[heroId];
        skills = skillIds;
        equipment = [
            hero.weapon,
            hero.armor,
            hero.accessory
        ];
    }
    
    function getHeroLevel(uint heroId) external view override returns (uint) {
        return _heroes[heroId].level;
    }

    function getLatestPool() public view returns (uint) {
        return pools.length - 1;
    }

    function totalSupply() external view returns (uint) {
        return _heroes.length;
    }

    function _baseURI() internal view override returns (string memory) {
        return _uri;
    }
    
    function listing(uint heroId, uint price) external override onlyHeroOwner(heroId) {
        require(price > 0, "WastedHero: invalid price");
        heroesOnSale[heroId] = price;

        emit HeroListed(heroId, price);
    }
    
    function _makeTransaction(uint heroId, address buyer, address seller, uint price) private {
        Hero storage hero = _heroes[heroId];
        
        uint marketFee = price * marketFeeInPercent / PERCENT;

        heroesOnSale[heroId] = 0;

        (bool isTransferToSeller,) = seller.call{value: price - marketFee}("");
        require(isTransferToSeller);

        (bool isTransferToTreasury,) = owner().call{value: marketFee}("");
        require(isTransferToTreasury);

        _transfer(seller, buyer, heroId);
    }
    
    
    function _createHero() private returns (uint heroId) {
        _heroes.push(Hero("", 1, 0, 0, 0));
        heroId = _heroes.length - 1;
        
        emit HeroCreated(heroId);
    }
    
    function _removeWastedEquipment(uint heroId, uint[] memory itemIds) private {
        require(heroesOnSale[heroId] == 0, "WastedHero: cannot change items while on sale");
        require(itemIds.length > 0, "WastedHero: no item supply");
        
        Hero storage hero = _heroes[heroId];
        bool[] memory itemSet = new bool[](3);
        
        for (uint i = 0; i < itemIds.length; i++) {
            uint itemId = itemIds[i];
            IWastedEquipment.ItemType itemType = wastedEquipment.getWastedItemType(itemId);
            require(itemId != 0, "WastedHero: invalid itemId");
            require(!itemSet[uint(itemType)], "WastedHero: duplicate itemType");

            if (itemType == IWastedEquipment.ItemType.WEAPON) {
                require(hero.weapon == itemId, "WastedHero: invalid weapon");
                hero.weapon = 0;
                itemSet[uint(IWastedEquipment.ItemType.WEAPON)] = true;
            } else if (itemType == IWastedEquipment.ItemType.ARMOR) {
                require(hero.armor == itemId, "WastedHero: invalid armor");
                hero.armor = 0;
                itemSet[uint(IWastedEquipment.ItemType.ARMOR)] = true;
            } else if (itemType == IWastedEquipment.ItemType.ACCESSORY) {
                require(hero.accessory == itemId, "WastedHero: invalid accessory");
                hero.accessory = 0;
                itemSet[uint(IWastedEquipment.ItemType.ACCESSORY)] = true;
            } else {
                require(false, "WastedHero: invalid item type");
            }
        }
        
        
    }
    
    
    function _setWastedEquipment(uint heroId, uint[] memory itemIds) private {
        
        require(heroesOnSale[heroId] == 0, "WastedHero: cannot change items while on sale");
        require(itemIds.length > 0, "WastedHero: no item supply");

        Hero storage hero = _heroes[heroId];
        bool[] memory itemSet = new bool[](3);
        

        for (uint i = 0; i < itemIds.length; i++) {
            uint itemId = itemIds[i];
            IWastedEquipment.ItemType itemType = wastedEquipment.getWastedItemType(itemId);
            require(itemId != 0, "WastedHero: invalid itemId");
            require(itemType != IWastedEquipment.ItemType.SKILL, "WastedHero: cannot equip skill book");
            require(!itemSet[uint(itemType)], "WastedHero: duplicate itemType");

            if (itemType == IWastedEquipment.ItemType.WEAPON) {
                require(hero.weapon == 0, "WastedHero: Hero's weapon is equipped");
                hero.weapon = itemId;
                itemSet[uint(IWastedEquipment.ItemType.WEAPON)] = true;
            } else if (itemType == IWastedEquipment.ItemType.ARMOR) {
                require(hero.armor == 0, "WastedHero: Hero's armor is equipped");
                hero.armor = itemId;
                itemSet[uint(IWastedEquipment.ItemType.ARMOR)] = true;
            } else if (itemType == IWastedEquipment.ItemType.ACCESSORY) {
                require(hero.accessory == 0, "WastedHero: Hero's accessory is equipped");
                hero.accessory = itemId;
                itemSet[uint(IWastedEquipment.ItemType.ACCESSORY)] = true;
            } else {
                require(false, "WastedHero: invalid item type");
            }
        }
    }
    
    function _validateStr(string memory str) internal pure returns (bool) {
        bytes memory b = bytes(str);
        if (b.length < 1) return false;
        if (b.length > 20) return false;

        // Leading space
        if (b[0] == 0x20) return false;

        // Trailing space
        if (b[b.length - 1] == 0x20) return false;

        bytes1 lastChar = b[0];

        for (uint i; i < b.length; i++) {
            bytes1 char = b[i];

            // Cannot contain continuous spaces
            if (char == 0x20 && lastChar == 0x20) return false;

            if (
                !(char >= 0x30 && char <= 0x39) && //9-0
                !(char >= 0x41 && char <= 0x5A) && //A-Z
                !(char >= 0x61 && char <= 0x7A) && //a-z
                !(char == 0x20) //space
            ) {
                return false;
            }

            lastChar = char;
        }

        return true;
    }

    function delist(uint heroId) external override onlyHeroOwner(heroId) {
        require(heroesOnSale[heroId] > 0, "WastedHero: Hero isn't on sale");
        heroesOnSale[heroId] = 0;

        emit HeroDelisted(heroId);
    }
    
    function buy(uint heroId) external override payable nonReentrant {
        uint price = heroesOnSale[heroId];
        address seller = ownerOf(heroId);
        address buyer = msg.sender;
        
        require(buyer != seller, "WastedHero: invalid buyer");
        require(price > 0, "WastedHero: Hero is not on sale");
        require(msg.value == price, "WastedHero: must pay equal price");

        _makeTransaction(heroId, buyer, seller, price);

        emit HeroBought(heroId, buyer, seller, price);
    }
    
    function offer(uint heroId, uint offerPrice) external override nonReentrant payable {
        address buyer = msg.sender;
        uint currentOffer = heroesOffers[heroId][buyer];
        bool needRefund = offerPrice < currentOffer;
        uint requiredValue = needRefund ? 0 : offerPrice - currentOffer;

        require(buyer != ownerOf(heroId), "WastedHero: owner cannot offer");
        require(offerPrice != currentOffer, "WastedHero: same offer");
        require(msg.value == requiredValue, "WastedHero: sent value invalid");

        heroesOffers[heroId][buyer] = offerPrice;

        if (needRefund) {
            uint returnedValue = currentOffer - offerPrice;

            (bool success,) = buyer.call{value: returnedValue}("");
            require(success);
        }

        emit HeroOffered(heroId, buyer, offerPrice);
    }
    
    function acceptOffer(uint heroId, address buyer) external override nonReentrant onlyHeroOwner(heroId) {
        uint offeredPrice = heroesOffers[heroId][buyer];
        address seller = msg.sender;

        require(buyer != seller, "Wasted: invalid buyer");

        heroesOffers[heroId][buyer] = 0;

        _makeTransaction(heroId, buyer, seller, offeredPrice);

        emit HeroBought(heroId, buyer, seller, offeredPrice);
    }
    
    function abortOffer(uint heroId) external override nonReentrant {
        address caller = msg.sender;
        uint offerPrice = heroesOffers[heroId][caller];

        require(offerPrice > 0, "WastedHero: offer not found");

        heroesOffers[heroId][caller] = 0;

        (bool success,) = caller.call{value: offerPrice}("");
        require(success);

        emit HeroOfferCanceled(heroId, caller);
    }
    
    function levelUp(uint heroId, uint amount) external override onlyOperator {
        Hero storage hero = _heroes[heroId];
        uint newLevel = hero.level + amount;

        require(amount > 0);
        require(newLevel <= maxLevel, "WastedHero: max level reached");

        hero.level = newLevel;

        emit HeroLeveledUp(heroId, newLevel, amount);
    }
    
    function adoptPet(uint heroId, uint petId) external override onlyHeroOwner(heroId) {
        require(wastedPet.ownerOf(petId) == msg.sender, "WastedHero: not pet owner");

        _heroesWithPet[heroId] = petId;
        wastedPet.bindPet(petId);

        emit PetAdopted(heroId, petId);
    }

    function abandonPet(uint heroId) external override onlyHeroOwner(heroId) {
        uint petId = _heroesWithPet[heroId];

        require(petId != 0, "WastedHero: couldn't found pet");

        _heroesWithPet[heroId] = 0;
        wastedPet.releasePet(petId);

        emit PetReleased(heroId, petId);
    }
    
    
    function addNewPool( uint indexOfHero, uint maxSupply, uint startTime ) external onlyOwner {
        uint latestPoolId = getLatestPool();
        
        pools.push(Pool(indexOfHero, 0, maxSupply, startTime));
        
        emit NewPoolAdded(latestPoolId + 1);
    }
    
    function rename( uint heroId, string memory replaceName ) external override onlyHeroOwner(heroId) collectTokenAsFee(serviceFeeInToken, owner()) {
        require(_validateStr(replaceName), "WastedHero: invalid name");
        require(usedNames[replaceName] == false, "WastedHero: name already exist");

        Hero storage hero = _heroes[heroId];
        
        if (bytes(hero.name).length > 0) {
            usedNames[hero.name] = false;
        }

        hero.name = replaceName;
        usedNames[replaceName] = true;

        emit NameChanged(heroId, replaceName);
    }
    
    function equipItems(uint heroId, uint[] memory itemIds) external override onlyHeroOwner(heroId) {
        _setWastedEquipment(heroId, itemIds);

        wastedEquipment.putItemsIntoStorage(msg.sender, itemIds);

        emit ItemsEquipped(heroId, itemIds);
    }

    function removeItems(uint heroId, uint[] memory itemIds) external override onlyHeroOwner(heroId) {
        _removeWastedEquipment(heroId, itemIds);

        wastedEquipment.returnItems(msg.sender, itemIds);

        emit ItemsRemoved(heroId, itemIds);
    }
    
    function createHero(uint poolId, uint amount, uint rarityPackage) external override payable {
        Pool storage pool = pools[poolId];

        require(amount > 0 && amount <= 5, "WastedHero: amount out of range");
        require(block.timestamp >= pool.startTime, "WastedHero: Pool has not started");
        require(pool.currentSupplyHeroes + amount <= pool.maxSupply, "WastedHero: sold out");
        
        if(rarityPackage == uint(IWastedHero.PackageRarity.RARE)) {
            require(msg.value == rarePackageFee * amount, "WastedHero: not enough fee");
        } else if (rarityPackage == uint(IWastedHero.PackageRarity.EPIC)) {
            require(msg.value == epicPackageFee * amount, "WastedHero: not enough fee");
        } else if (rarityPackage == uint(IWastedHero.PackageRarity.LEGENDARY)) {
            require(msg.value == legendaryPackageFee * amount, "WastedHero: not enough fee");
        }
        
        for (uint i = 0; i < amount; i++) {
            uint heroId = _createHero();
            _safeMint(msg.sender, heroId);
        }

        pool.currentSupplyHeroes += amount;
       

        (bool isSuccess,) = owner().call{value: msg.value}("");
        require(isSuccess);

    }
    
    function breedingHero (uint fatherId, uint motherId) external override payable {
        
        require(ownerOf(fatherId) == msg.sender && ownerOf(motherId) == msg.sender, "WastedHero: Caller isn't owner of hero");
        require(heroBreedingTime[fatherId] <= 7 && heroBreedingTime[motherId] <= 7, "WastedHero: Hero can only breeding 7 times");
        require(msg.value == breedingFee, "WastedHero: not enough fee");
        
        uint heroId = _createHero();
        _safeMint(msg.sender, heroId);
        heroBreedingTime[fatherId] += 1;
        heroBreedingTime[motherId] += 1;
        
        (bool isSuccess,) = owner().call{value: msg.value}("");
        require(isSuccess);
        
    }
    
    function fushionHero(uint fatherId, uint motherId) external override payable {
        require(ownerOf(fatherId) == msg.sender && ownerOf(motherId) == msg.sender, "WastedHero: Caller isn't owner of hero");
        require(msg.value == fushionFee, "WastedHero: not enough fee");
        
        uint heroId = _createHero();
        _safeMint(msg.sender, heroId);
        
        _burn(fatherId);
        _burn(motherId);
        
        (bool isSuccess,) = owner().call{value: msg.value}("");
        require(isSuccess);
    }
    
}