//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


interface IWastedHero {
    
    event HeroCreated(uint indexed heroId);
    event HeroListed(uint indexed heroId, uint price);
    event HeroDelisted(uint indexed heroId);
    event HeroBought(uint indexed heroId, address buyer, address seller, uint price);
    event HeroOffered(uint indexed heroId, address buyer, uint price);
    event HeroOfferCanceled(uint indexed heroId, address buyer);
    event NameChanged(uint indexed heroId, string newName);
    event PetAdopted(uint indexed heroId, uint indexed petId);
    event PetReleased(uint indexed heroId, uint indexed petId);
    event AcquiredSkill(uint indexed heroId, uint indexed skillId);
    event ItemsEquipped(uint indexed heroId, uint[] itemIds);
    event ItemsRemoved(uint indexed heroId, uint[] itemIds);
    event HeroLeveledUp(uint indexed heroId, uint level, uint amount);
    event StartingIndexFinalized(uint versionId, uint startingIndex);
    event NewVersionAdded(uint versionId);
    
    struct Hero {
        string name;
        uint256 level;
        uint256 weapon;
        uint256 armor;
        uint256 accessory;
    }
    
    
    struct Pool {
        uint256 indexOfHero;
        uint256 currentSupplyHeros;
        uint256 maxSupply;
        uint256 startTime;
    }
    
    /**
     * @notice Gets hero information.
     * 
     * @dev Prep function for staking.
     */
    function getHero(uint heroId) external view returns (
        string memory name,
        uint level,
        uint pet,
        uint[] memory skills,
        uint[9] memory equipment
    );
    
     /**
     * @notice Function can level up a Hero.
     * 
     * @dev Prep function for staking.
     */
    function levelUp(uint heroId, uint amount) external;
    
    /**
     * @notice Get current level of given hero.
     * 
     * @dev Prep function for staking.
     */
    function getHeroLevel(uint heroId) external view returns (uint);
    
    /**
     * @notice Claim wasted heros when it's on claimable time.
     * 
     * @dev Function take 2 arguments are , new name of hero.
     * 
     */
    function createHero(uint versionId, uint amount) external payable;

    /**
     * @notice Function to change Hero's name.
     *
     * @dev Function take 2 arguments are heroId, new name of hero.
     * 
     * Requirements:
     * - `replaceName` must be a valid string.
     * - `replaceName` is not duplicated.
     * - You have to pay `serviceFeeToken` to change hero's name.
     */
    function rename(uint heroId, string memory replaceName) external;

    /**
     * @notice Owner equips items to their hero by burning ERC1155 Equipment NFTs.
     *
     * Requirements:
     * - caller must be owner of the hero.
     */
    function equipItems(uint heroId, uint[] memory itemIds) external;

    /**
     * @notice Owner removes items from their hero. ERC1155 Equipment NFTs are minted back to the owner.
     *
     * Requirements:
     * - Caller must be owner of the hero.
     */
    function removeItems(uint heroId, uint[] memory itemIds) external;

    /**
     * @notice Lists a hero on sale.
     *
     * Requirements:
     * - Caller must be the owner of the hero.
     */
    function listing(uint heroId, uint price) external;

    /**
     * @notice Remove from a list on sale.
     */
    function delist(uint heroId) external;

    /**
     * @notice Instant buy a specific hero on sale.
     *
     * Requirements:
     * - Caller must be the owner of the hero.
     * - Target hero must be currently on sale time.
     * - Sent value must be exact the same as current listing price.
     * - Owner cannot buy.
     */
    function buy(uint heroId) external payable;

    /**
     * @notice Gives offer for a hero.
     *
     * Requirements:
     * - Owner cannot offer.
     */
    function offer(uint heroId, uint offerPrice) external payable;

    /**
     * @notice Owner accept an offer to sell their hero.
     */
    function acceptOffer(uint heroId, address buyer) external;

    /**
     * @notice Abort an offer for a specific hero.
     */
    function abortOffer(uint heroId) external;

    /**
     * @notice Acquire skill for hero by skillId.
     * 
     */
    function acquireSkill(uint heroId, uint skillId) external;

    /**
     * @notice Adopts a Pet.
     */
    function adoptPet(uint heroId, uint petId) external;

    /**
     * @notice Abandons a Pet attached to a hero.
     */
    function abandonPet(uint heroId) external;
    
    /**
     * @notice Burn two heros to create one new hero.
     * 
     * @dev The id of the new hero is the length of the heros array
     * 
     * Requirements:
     * - caller must be owner of the heros.
     */
    function fushionHero(uint[2] memory heroIds) external;
    
    /**
     * @notice Breed based on two heros.
     * 
     * @dev The id of the new hero is the length of the heros array
     * 
     * Requirements:
     * - caller must be owner of the heros.
     * - Heros's owner can only breeding 7 times at most.
     */
    function breedingHero (uint[2] memory heroIds) external payable;
}