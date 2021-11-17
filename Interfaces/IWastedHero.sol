//SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;


interface IWastedWarrior {
    
    enum PackageRarity { NONE, PLASTIC, STEEL, GOLD, PLATINUM }
    
    event WarriorCreated(uint indexed warriorId, bool isBreed, bool isFusion, uint indexed packageType, address indexed buyer);
    event WarriorListed(uint indexed warriorId, uint price);
    event WarriorDelisted(uint indexed warriorId);
    event WarriorBought(uint indexed warriorId, address buyer, address seller, uint price);
    event WarriorOffered(uint indexed warriorId, address buyer, uint price);
    event WarriorOfferCanceled(uint indexed warriorId, address buyer);
    event NameChanged(uint indexed warriorId, string newName);
    event PetAdopted(uint indexed warriorId, uint indexed petId);
    event PetReleased(uint indexed warriorId, uint indexed petId);
    event AcquiredSkill(uint indexed warriorId, uint indexed skillId);
    event ItemsEquipped(uint indexed warriorId, uint[] itemIds);
    event ItemsRemoved(uint indexed warriorId, uint[] itemIds);
    event WarriorLeveledUp(uint indexed warriorId, uint level, uint amount);
    event StartingIndexFinalized(uint versionId, uint startingIndex);
    event NewPoolAdded(uint poolId);
    event BreedingWarrior(uint indexed fatherId, uint indexed motherId, uint newId);
    event FusionWarrior(uint indexed firstWarriorId, uint indexed secondWarriorId, uint newId);
    
    struct BoughtPackageTimes {
        uint plastic;
        uint steel;
        uint gold;
        uint platinum;
    }
    struct ParentWarrior {
        uint fatherId;
        uint motherId;
    }
    
    struct Warrior {
        string name;
        uint256 level;
        uint256 weapon;
        uint256 armor;
        uint256 accessory;
        bool isBreed;
        bool isFusion;
    }
    
    
    struct Pool {
        uint256 currentSupplyWarriors;
        uint256 maxSupply;
        uint256 startTime;
    }
    
    /**
     * @notice Gets warrior information.
     * 
     * @dev Prep function for staking.
     */
    function getWarrior(uint warriorId) external view returns (
        string memory name,
        bool isBreed,
        bool isFusion,
        uint level,
        uint pet,
        uint[] memory skills,
        uint[3] memory equipment
    );
    
     /**
     * @notice Function can level up a Warrior.
     * 
     * @dev Prep function for staking.
     */
    function levelUp(uint warriorId, uint amount) external;
    
    /**
     * @notice Get current level of given warrior.
     * 
     * @dev Prep function for staking.
     */
    function getWarriorLevel(uint warriorId) external view returns (uint);
    
    /**
     * @notice Claim wasted warriors when it's on claimable time.
     * 
     * @dev Function take 2 arguments are , new name of warrior.
     * 
     */
    function createWarrior(uint poolId, uint amount, uint rarityPackage) external payable;

    /**
     * @notice Function to change Warrior's name.
     *
     * @dev Function take 2 arguments are warriorId, new name of warrior.
     * 
     * Requirements:
     * - `replaceName` must be a valid string.
     * - `replaceName` is not duplicated.
     * - You have to pay `serviceFeeToken` to change warrior's name.
     */
    function rename(uint warriorId, string memory replaceName) external;

    /**
     * @notice Owner equips items to their warrior by burning ERC1155 Equipment NFTs.
     *
     * Requirements:
     * - caller must be owner of the warrior.
     */
    function equipItems(uint warriorId, uint[] memory itemIds) external;

    /**
     * @notice Owner removes items from their warrior. ERC1155 Equipment NFTs are minted back to the owner.
     *
     * Requirements:
     * - Caller must be owner of the warrior.
     */
    function removeItems(uint warriorId, uint[] memory itemIds) external;

    /**
     * @notice Lists a warrior on sale.
     *
     * Requirements:
     * - Caller must be the owner of the warrior.
     */
    function listing(uint warriorId, uint price) external;

    /**
     * @notice Remove from a list on sale.
     */
    function delist(uint warriorId) external;

    /**
     * @notice Instant buy a specific warrior on sale.
     *
     * Requirements:
     * - Caller must be the owner of the warrior.
     * - Target warrior must be currently on sale time.
     * - Sent value must be exact the same as current listing price.
     * - Owner cannot buy.
     */
    function buy(uint warriorId) external payable;

    /**
     * @notice Gives offer for a warrior.
     *
     * Requirements:
     * - Owner cannot offer.
     */
    function offer(uint warriorId, uint offerPrice) external payable;

    /**
     * @notice Owner accept an offer to sell their warrior.
     */
    function acceptOffer(uint warriorId, address buyer) external;

    /**
     * @notice Abort an offer for a specific warrior.
     */
    function abortOffer(uint warriorId) external;

    // /**
    //  * @notice Acquire skill for warrior by skillId.
    //  * 
    //  */
    // function acquireSkill(uint warriorId, uint skillId) external;

    /**
     * @notice Adopts a Pet.
     */
    function adoptPet(uint warriorId, uint petId) external;

    /**
     * @notice Abandons a Pet attached to a warrior.
     */
    function abandonPet(uint warriorId) external;
    
    /**
     * @notice Burn two warriors to create one new warrior.
     * 
     * @dev The id of the new warrior is the length of the warriors array
     * 
     * Requirements:
     * - caller must be owner of the warriors.
     */
    function fusionWarrior(uint firstWarriorId, uint secondWarriorId) external payable;
    
    /**
     * @notice Breed based on two warriors.
     * 
     * @dev The id of the new warrior is the length of the warriors array
     * 
     * Requirements:
     * - caller must be owner of the warriors.
     * - warriors's owner can only breeding 7 times at most.
     */
    function breedingWarrior (uint fatherId, uint motherId) external payable;
}