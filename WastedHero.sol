//SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "./IWastedWarrior.sol";
import "./AcceptedToken.sol";
import "./IWastedEquipment.sol";
import "./IPet.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


contract WastedWarrior is  IWastedWarrior, ERC721, ReentrancyGuard, AcceptedToken {
    using SafeERC20 for IERC20;
    using EnumerableSet for EnumerableSet.UintSet;
    
    modifier onlyWarriorOwner(uint warriorId) {
        require(ownerOf(warriorId) == msg.sender, "WastedWarrior: Caller isn't owner of warrior");
        _;
    }
    modifier onlyDifferentFamily(uint fatherId, uint motherId) {
        if(_warriors[fatherId].isBreed && _warriors[motherId].isBreed) {
            require(parentWarriors[fatherId].fatherId != parentWarriors[motherId].fatherId && parentWarriors[fatherId].motherId != parentWarriors[motherId].motherId, "WastedWarrior: Invalid parent");
            require(parentWarriors[fatherId].fatherId != parentWarriors[motherId].motherId && parentWarriors[fatherId].motherId != parentWarriors[motherId].fatherId, "WastedWarrior: Invalid parent");
        } else if(_warriors[fatherId].isBreed) {
            require(parentWarriors[fatherId].fatherId != motherId && parentWarriors[fatherId].motherId != motherId, "WastedWarrior: Invalid parent");
        } else if(_warriors[motherId].isBreed) {
            require(parentWarriors[motherId].fatherId != fatherId && parentWarriors[motherId].motherId != fatherId, "WastedWarrior: Invalid parent" );
        }
        _;
    }
    
    IWastedEquipment public wastedEquipment;
    IPet public wastedPet;
    Warrior[] private _warriors;
    Pool[] public pools;
    
    
    uint private constant PERCENT = 100;
    uint public marketFeeInPercent = 20;
    uint public serviceFeeInToken = 1e20;
    uint public breedingFee = 0.15 * 1e18;
    uint public fusionFee = 0.15 * 1e18;
    uint public plasticPackageFee = 0.1 * 1e18;
    uint public steelPackageFee = 0.15 * 1e18;
    uint public goldPackageFee = 0.2 * 1e18;
    uint public platinumPackageFee = 0.3 * 1e18;
    uint8 public maxBoughtPlasticPackageTimes = 8;
    uint8 public maxBoughtSteelPackageTimes = 4;
    uint8 public maxBoughtGoldPackageTimes = 2;
    uint8 public maxBoughtPlatinumPackageTimes = 1;
    uint public totalSupplyPlasticPackage = 60;
    uint public totalSupplySteelPackage = 60;
    uint public totalSupplyGoldPackage = 20;
    uint public totalSupplyPlatinumPackage = 10;
    uint public maxLevel = 100;
    string private _uri;
    
    bytes32 internal keyHash;
    uint256 internal fee;
    
    uint256 public randomResult;
    
    mapping(address => BoughtPackageTimes) boughtPackageTimes;
    mapping(uint => uint) mintedPackages;
    mapping(uint => ParentWarrior) parentWarriors; 
    mapping(uint => uint) public warriorBreedingTime;
    mapping(uint => uint) public warriorsOnSale;
    mapping(uint => mapping(address => uint)) public warriorsOffers;
    mapping(string => bool) public usedNames;
    mapping(uint => uint) public rarityPackagesOfWarrior;

    mapping(uint => uint) private _warriorsWithPet;
    mapping(uint => EnumerableSet.UintSet) private _warriorsSkills;
    constructor(
        IWastedEquipment equipmentAddress,
        IERC20 tokenAccept,
        uint maxSupply,
        uint startTime,
        string memory baseURI
    ) ERC721("WastedWarrior", "WAH") AcceptedToken(tokenAccept) {
        wastedEquipment = equipmentAddress;
        _uri = baseURI;
        pools.push(Pool(0, maxSupply, startTime));
    }
    
    
    function setWastedEquipment(IWastedEquipment wastedEquipmentAddress) external onlyOwner {
        require(address(wastedEquipmentAddress) != address(0), "WastedWarrior: invalid address");
        wastedEquipment = wastedEquipmentAddress;
    }

    function setWastedPet(IPet wastedPetAddress) external onlyOwner {
        require(address(wastedPetAddress) != address(0));
        wastedPet = wastedPetAddress;
    }
    
    function setMaxBoughtPlasticPackage(uint8 times) external onlyOwner {
        maxBoughtPlasticPackageTimes = times;
    }
    
    function setMaxBoughtSteelPackage(uint8 times) external onlyOwner {
        maxBoughtSteelPackageTimes = times;
    }
    
    function setMaxBoughtGoldPackage(uint8 times) external onlyOwner {
        maxBoughtGoldPackageTimes = times;
    }
    
    function setMaxBoughtPlatinumPackage(uint8 times) external onlyOwner {
        maxBoughtPlatinumPackageTimes = times;
    }
    
    /**
    * @notice function to set market fee.
    * 
    * Requirements: 
    * - onlyOwner.
    */
    function setMarketFeeInPercent(uint marketFee) external onlyOwner {
        require(marketFee < PERCENT, "WastedWarrior: invalid marketFeeInPercent");
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
    * @notice function to set  fusion fee.
    * 
    * Requirements: 
    * - onlyOwner.
    */
    function setFusionFee(uint newFusionFee) external onlyOwner {
        fusionFee = newFusionFee;
    }
     
    /**
    * @notice function to set normal package fee.
    * 
    * Requirements: 
    * - onlyOwner.
    */
    function setPlasticPackageFee(uint newPlasticPackageFee) external onlyOwner {
        plasticPackageFee = newPlasticPackageFee;
    }
    
     /**
    * @notice function to set rare package fee.
    * 
    * Requirements: 
    * - onlyOwner.
    */
    function setSteelPackageFee(uint newSteelPackageFee) external onlyOwner {
        steelPackageFee = newSteelPackageFee;
    }
    
    /**
    * @notice function to set epic package fee.
    * 
    * Requirements: 
    * - onlyOwner.
    */
    function setGoldPackageFee(uint newGoldPackageFee) external onlyOwner {
        goldPackageFee = newGoldPackageFee;
    }
    
     /**
    * @notice function to set mystic package fee.
    * 
    * Requirements: 
    * - onlyOwner.
    */
    function setPlatinumPackageFee(uint newPlatinumPackageFee) external onlyOwner {
        platinumPackageFee = newPlatinumPackageFee;
    }
    
    /**
    * @notice function to set total supply packages.
    * 
    * Requirements: 
    * - onlyOwner.
    */
    function setPlasticPackageSupply(uint newSupplyPackage) external onlyOwner {
        totalSupplyPlasticPackage = newSupplyPackage;
    }
    
    /**
    * @notice function to set total supply packages.
    * 
    * Requirements: 
    * - onlyOwner.
    */
    function setSteelPackageSupply(uint newSupplyPackage) external onlyOwner {
        totalSupplySteelPackage = newSupplyPackage;
    }
    
    /**
    * @notice function to set total supply packages.
    * 
    * Requirements: 
    * - onlyOwner.
    */
    function setGoldPackageSupply(uint newSupplyPackage) external onlyOwner {
        totalSupplyGoldPackage = newSupplyPackage;
    }
    
    /**
    * @notice function to set total supply packages.
    * 
    * Requirements: 
    * - onlyOwner.
    */
    function setPlatinumPackageSupply(uint newSupplyPackage) external onlyOwner {
        totalSupplyPlatinumPackage = newSupplyPackage;
    }
    
    function setMaxLevel(uint newMaxLevel) external onlyOwner {
        require(newMaxLevel > 0, "WastedWarrior: invalid max level");
        maxLevel = newMaxLevel;
    }

    function setBaseURI(string memory baseURI) external onlyOwner {
        _uri = baseURI;
    }
        
    function getPool(uint poolId) external view returns (
        uint currentSupplyWarriors,
        uint maxSupply, 
        uint startTime
    ) {
        Pool memory pool = pools[poolId];
        currentSupplyWarriors = pool.currentSupplyWarriors;
        maxSupply = pool.maxSupply;
        startTime = pool.startTime;
    }
    
    function getWarrior(uint warriorId) external view override returns (
        string memory name,
        bool isBreed,
        bool isFusion,
        uint level,
        uint pet,
        uint[] memory skills,
        uint[3] memory equipment
    ) {
        Warrior memory warrior = _warriors[warriorId];

        uint skillCount = _warriorsSkills[warriorId].length();
        uint[] memory skillIds = new uint[](skillCount);
        for (uint i = 0; i < skillCount; i++) {
            skillIds[i] = _warriorsSkills[warriorId].at(i);
        }

        name = warrior.name;
        level = warrior.level;
        isBreed = warrior.isBreed;
        isFusion = warrior.isFusion;
        pet = _warriorsWithPet[warriorId];
        skills = skillIds;
        equipment = [
            warrior.weapon,
            warrior.armor,
            warrior.accessory
        ];
    }
    
    function getWarriorLevel(uint warriorId) external view override returns (uint) {
        return _warriors[warriorId].level;
    }

    function getLatestPool() public view returns (uint) {
        return pools.length - 1;
    }

    function totalSupply() external view returns (uint) {
        return _warriors.length;
    }

    function _baseURI() internal view override returns (string memory) {
        return _uri;
    }
    
    function listing(uint warriorId, uint price) external override onlyWarriorOwner(warriorId) {
        require(price > 0, "WastedWarrior: invalid price");
        warriorsOnSale[warriorId] = price;

        emit WarriorListed(warriorId, price);
    }
    
    function _makeTransaction(uint warriorId, address buyer, address seller, uint price) private {
        uint marketFee = price * marketFeeInPercent / PERCENT;

        warriorsOnSale[warriorId] = 0;

        (bool isTransferToSeller,) = seller.call{value: price - marketFee}("");
        require(isTransferToSeller);

        (bool isTransferToTreasury,) = owner().call{value: marketFee}("");
        require(isTransferToTreasury);

        _transfer(seller, buyer, warriorId);
    }
    
    
    function _createWarrior(bool isBreed, bool isFusion, uint packageType) private returns (uint warriorId) {
        _warriors.push(Warrior("", 1, 0, 0, 0, isBreed, isFusion));
        warriorId = _warriors.length - 1;
        
        emit WarriorCreated(warriorId, isBreed, isFusion, packageType, msg.sender);
    }
    
    function _removeWastedEquipment(uint warriorId, uint[] memory itemIds) private {
        require(warriorsOnSale[warriorId] == 0, "WastedWarrior: cannot change items while on sale");
        require(itemIds.length > 0, "WastedWarrior: no item supply");
        
        Warrior storage warrior = _warriors[warriorId];
        bool[] memory itemSet = new bool[](3);
        
        for (uint i = 0; i < itemIds.length; i++) {
            uint itemId = itemIds[i];
            IWastedEquipment.ItemType itemType = wastedEquipment.getWastedItemType(itemId);
            require(itemId != 0, "WastedWarrior: invalid itemId");
            require(!itemSet[uint(itemType)], "WastedWarrior: duplicate itemType");

            if (itemType == IWastedEquipment.ItemType.WEAPON) {
                require(warrior.weapon == itemId, "WastedWarrior: invalid weapon");
                warrior.weapon = 0;
                itemSet[uint(IWastedEquipment.ItemType.WEAPON)] = true;
            } else if (itemType == IWastedEquipment.ItemType.ARMOR) {
                require(warrior.armor == itemId, "WastedWarrior: invalid armor");
                warrior.armor = 0;
                itemSet[uint(IWastedEquipment.ItemType.ARMOR)] = true;
            } else if (itemType == IWastedEquipment.ItemType.ACCESSORY) {
                require(warrior.accessory == itemId, "WastedWarrior: invalid accessory");
                warrior.accessory = 0;
                itemSet[uint(IWastedEquipment.ItemType.ACCESSORY)] = true;
            } else {
                require(false, "WastedWarrior: invalid item type");
            }
        }
        
        
    }
    
    
    function _setWastedEquipment(uint warriorId, uint[] memory itemIds) private {
        
        require(warriorsOnSale[warriorId] == 0, "WastedWarrior: cannot change items while on sale");
        require(itemIds.length > 0, "WastedWarrior: no item supply");

        Warrior storage warrior = _warriors[warriorId];
        bool[] memory itemSet = new bool[](3);
        

        for (uint i = 0; i < itemIds.length; i++) {
            uint itemId = itemIds[i];
            IWastedEquipment.ItemType itemType = wastedEquipment.getWastedItemType(itemId);
            require(itemId != 0, "WastedWarrior: invalid itemId");
            require(itemType != IWastedEquipment.ItemType.SKILL, "WastedWarrior: cannot equip skill book");
            require(!itemSet[uint(itemType)], "WastedWarrior: duplicate itemType");

            if (itemType == IWastedEquipment.ItemType.WEAPON) {
                require(warrior.weapon == 0, "WastedWarrior: Warrior's weapon is equipped");
                warrior.weapon = itemId;
                itemSet[uint(IWastedEquipment.ItemType.WEAPON)] = true;
            } else if (itemType == IWastedEquipment.ItemType.ARMOR) {
                require(warrior.armor == 0, "WastedWarrior: Warrior's armor is equipped");
                warrior.armor = itemId;
                itemSet[uint(IWastedEquipment.ItemType.ARMOR)] = true;
            } else if (itemType == IWastedEquipment.ItemType.ACCESSORY) {
                require(warrior.accessory == 0, "WastedWarrior: Warrior's accessory is equipped");
                warrior.accessory = itemId;
                itemSet[uint(IWastedEquipment.ItemType.ACCESSORY)] = true;
            } else {
                require(false, "WastedWarrior: invalid item type");
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

    function delist(uint warriorId) external override onlyWarriorOwner(warriorId) {
        require(warriorsOnSale[warriorId] > 0, "WastedWarrior: warrior isn't on sale");
        warriorsOnSale[warriorId] = 0;

        emit WarriorDelisted(warriorId);
    }
    
    function buy(uint warriorId) external override payable nonReentrant {
        uint price = warriorsOnSale[warriorId];
        address seller = ownerOf(warriorId);
        address buyer = msg.sender;
        
        require(buyer != seller, "WastedWarrior: invalid buyer");
        require(price > 0, "WastedWarrior: Warrior is not on sale");
        require(msg.value == price, "WastedWarrior: must pay equal price");

        _makeTransaction(warriorId, buyer, seller, price);

        emit WarriorBought(warriorId, buyer, seller, price);
    }
    
    function offer(uint warriorId, uint offerPrice) external override nonReentrant payable {
        address buyer = msg.sender;
        uint currentOffer = warriorsOffers[warriorId][buyer];
        bool needRefund = offerPrice < currentOffer;
        uint requiredValue = needRefund ? 0 : offerPrice - currentOffer;

        require(buyer != ownerOf(warriorId), "WastedWarrior: owner cannot offer");
        require(offerPrice != currentOffer, "WastedWarrior: same offer");
        require(msg.value == requiredValue, "WastedWarrior: sent value invalid");

        warriorsOffers[warriorId][buyer] = offerPrice;

        if (needRefund) {
            uint returnedValue = currentOffer - offerPrice;

            (bool success,) = buyer.call{value: returnedValue}("");
            require(success);
        }

        emit WarriorOffered(warriorId, buyer, offerPrice);
    }
    
    function acceptOffer(uint warriorId, address buyer) external override nonReentrant onlyWarriorOwner(warriorId) {
        uint offeredPrice = warriorsOffers[warriorId][buyer];
        address seller = msg.sender;

        require(buyer != seller, "Wasted: invalid buyer");

        warriorsOffers[warriorId][buyer] = 0;

        _makeTransaction(warriorId, buyer, seller, offeredPrice);

        emit WarriorBought(warriorId, buyer, seller, offeredPrice);
    }
    
    function abortOffer(uint warriorId) external override nonReentrant {
        address caller = msg.sender;
        uint offerPrice = warriorsOffers[warriorId][caller];

        require(offerPrice > 0, "WastedWarrior: offer not found");

        warriorsOffers[warriorId][caller] = 0;

        (bool success,) = caller.call{value: offerPrice}("");
        require(success);

        emit WarriorOfferCanceled(warriorId, caller);
    }
    
    function levelUp(uint warriorId, uint amount) external override onlyOperator {
        Warrior storage warrior = _warriors[warriorId];
        uint newLevel = warrior.level + amount;

        require(amount > 0);
        require(newLevel <= maxLevel, "WastedWarrior: max level reached");

        warrior.level = newLevel;

        emit WarriorLeveledUp(warriorId, newLevel, amount);
    }
    
    function adoptPet(uint warriorId, uint petId) external override onlyWarriorOwner(warriorId) {
        require(wastedPet.ownerOf(petId) == msg.sender, "WastedWarrior: not pet owner");

        _warriorsWithPet[warriorId] = petId;
        wastedPet.bindPet(petId);

        emit PetAdopted(warriorId, petId);
    }

    function abandonPet(uint warriorId) external override onlyWarriorOwner(warriorId) {
        uint petId = _warriorsWithPet[warriorId];

        require(petId != 0, "WastedWarrior: couldn't found pet");

        _warriorsWithPet[warriorId] = 0;
        wastedPet.releasePet(petId);

        emit PetReleased(warriorId, petId);
    }
    
    
    function addNewPool( uint maxSupply, uint startTime ) external onlyOwner {
        uint latestPoolId = getLatestPool();
        
        pools.push(Pool( 0, maxSupply, startTime));
        
        emit NewPoolAdded(latestPoolId + 1);
    }
    
    function rename( uint warriorId, string memory replaceName ) external override onlyWarriorOwner(warriorId) collectTokenAsFee(serviceFeeInToken, owner()) {
        require(_validateStr(replaceName), "WastedWarrior: invalid name");
        require(usedNames[replaceName] == false, "WastedWarrior: name already exist");

        Warrior storage warrior = _warriors[warriorId];
        
        if (bytes(warrior.name).length > 0) {
            usedNames[warrior.name] = false;
        }

        warrior.name = replaceName;
        usedNames[replaceName] = true;

        emit NameChanged(warriorId, replaceName);
    }
    
    function equipItems(uint warriorId, uint[] memory itemIds) external override onlyWarriorOwner(warriorId) {
        _setWastedEquipment(warriorId, itemIds);

        wastedEquipment.putItemsIntoStorage(msg.sender, itemIds);

        emit ItemsEquipped(warriorId, itemIds);
    }

    function removeItems(uint warriorId, uint[] memory itemIds) external override onlyWarriorOwner(warriorId) {
        _removeWastedEquipment(warriorId, itemIds);

        wastedEquipment.returnItems(msg.sender, itemIds);

        emit ItemsRemoved(warriorId, itemIds);
    }
    
    function createWarrior(uint poolId, uint amount, uint rarityPackage) external override payable {
        Pool storage pool = pools[poolId];
        BoughtPackageTimes storage boughtTimes = boughtPackageTimes[msg.sender];

        require(amount > 0, "WastedWarrior: amount out of range");
        require(block.timestamp >= pool.startTime, "WastedWarrior: Pool has not started");
        require(pool.currentSupplyWarriors + amount <= pool.maxSupply, "WastedWarrior: sold out");
        require(rarityPackage >= 1 && rarityPackage <= 4, "WastedWarrior: invalid Package");
        
        if(rarityPackage == uint(IWastedWarrior.PackageRarity.PLASTIC)) {
            require(boughtTimes.plastic < maxBoughtPlasticPackageTimes, "WastedWarrior: not eligible");
            require(mintedPackages[1] + amount <= totalSupplyPlasticPackage, "WastedWarrior: sold out");
            require(msg.value == plasticPackageFee * amount, "WastedWarrior: not enough fee");
            mintedPackages[1] += amount;
            boughtTimes.plastic += amount;
        } else if(rarityPackage == uint(IWastedWarrior.PackageRarity.STEEL)) {
            require(boughtTimes.steel < maxBoughtSteelPackageTimes, "WastedWarrior: not eligible");
            require(mintedPackages[2] + amount <= totalSupplySteelPackage, "WastedWarrior: sold out");
            require(msg.value == steelPackageFee * amount, "WastedWarrior: not enough fee");
            mintedPackages[2] += amount;
            boughtTimes.steel += amount;
        } else if (rarityPackage == uint(IWastedWarrior.PackageRarity.GOLD)) {
            require(boughtTimes.gold < maxBoughtGoldPackageTimes, "WastedWarrior: not eligible");
            require(mintedPackages[3] + amount <= totalSupplyGoldPackage, "WastedWarrior: sold out");
            require(msg.value == goldPackageFee * amount, "WastedWarrior: not enough fee");
            mintedPackages[3] += amount; 
            boughtTimes.gold += amount;
        } else if (rarityPackage == uint(IWastedWarrior.PackageRarity.PLATINUM)) {
            require(boughtTimes.platinum < maxBoughtPlatinumPackageTimes, "WastedWarrior: not eligible");
            require(mintedPackages[4] + amount <= totalSupplyPlatinumPackage, "WastedWarrior: sold out");
            require(msg.value == platinumPackageFee * amount, "WastedWarrior: not enough fee");
            mintedPackages[4] += amount;
            boughtTimes.platinum += amount;
        }
        
        for (uint i = 0; i < amount; i++) {
            uint warriorId = _createWarrior(false, false, rarityPackage);
            rarityPackagesOfWarrior[warriorId] = rarityPackage;
            _safeMint(msg.sender, warriorId);
        }

        pool.currentSupplyWarriors += amount;
       

        (bool isSuccess,) = owner().call{value: msg.value}("");
        require(isSuccess);

    }
    
    function breedingWarrior(uint fatherId, uint motherId) external override onlyDifferentFamily(fatherId, motherId) payable {
        require(fatherId != motherId, "WastedWarrior: invalid id");
        require(ownerOf(fatherId) == msg.sender && ownerOf(motherId) == msg.sender, "WastedWarrior: Caller isn't owner of Warrior");
        require(warriorBreedingTime[fatherId] <= 7 && warriorBreedingTime[motherId] <= 7, "WastedWarrior: Warrior can only breeding 7 times");
        require(msg.value == breedingFee, "WastedWarrior: not enough fee");
        
        uint warriorId = _createWarrior(true, false, 0);
        _safeMint(msg.sender, warriorId);
        warriorBreedingTime[fatherId] += 1;
        warriorBreedingTime[motherId] += 1;
        parentWarriors[warriorId] = ParentWarrior(fatherId, motherId);
        (bool isSuccess,) = owner().call{value: msg.value}("");
        require(isSuccess);
        
        emit BreedingWarrior(fatherId, motherId, warriorId);
    }
    
    function fusionWarrior(uint firstWarriorId, uint secondWarriorId) external override payable {
        require(firstWarriorId != secondWarriorId, "WastedWarrior: invalid id");
        require(ownerOf(firstWarriorId) == msg.sender && ownerOf(secondWarriorId) == msg.sender, "WastedWarrior: Caller isn't owner of Warrior");
        require(msg.value ==  fusionFee, "WastedWarrior: not enough fee");
        
        uint warriorId = _createWarrior(false, true, 0);
        _safeMint(msg.sender, warriorId);
        
        _burn(firstWarriorId);
        _burn(secondWarriorId);
        
        (bool isSuccess,) = owner().call{value: msg.value}("");
        require(isSuccess);
        emit FusionWarrior(firstWarriorId, secondWarriorId, warriorId);
    }
    
}