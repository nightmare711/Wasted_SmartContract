//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


interface IWastedKnight {
     struct Knight {
        string name;
        uint level;
        uint mainWeapon;
        uint subWeapon;
        uint headgear;
        uint armor;
        uint footwear;
        uint pants;
        uint gloves;
        uint mount;
        uint troop;
    }
    struct Version {
        uint startingIndex;
        uint currentSupply;
        uint maxSupply;
        uint salePrice;
        uint startTime;
        uint revealTime;
    }
    
    event KnightCreated(uint indexed knightId);
    event KnightListed(uint indexed knightId, uint price);
    event KnightDelisted(uint indexed knightId);
    event KnightBought(uint indexed knightId, address buyer, address seller, uint price);
    event KnightOffered(uint indexed knightId, address buyer, uint price);
    event KnightOfferCanceled(uint indexed knightId, address buyer);
    event NameChanged(uint indexed knightId, string newName);
    event PetAdopted(uint indexed knightId, uint indexed petId);
    event PetReleased(uint indexed knightId, uint indexed petId);
    event SkillLearned(uint indexed knightId, uint indexed skillId);
    event ItemsEquipped(uint indexed knightId, uint[] itemIds);
    event ItemsUnequipped(uint indexed knightId, uint[] itemIds);
    event KnightLeveledUp(uint indexed knightId, uint level, uint amount);
    event StartingIndexFinalized(uint versionId, uint startingIndex);
    event NewVersionAdded(uint versionId);
    
    /**
     * @notice Claims wasted knights when it's on presale phase.
     */
    function claimWastedKnight(uint versionId, uint amount) external payable;

    /**
     * @notice Function to change knight's name.
     *
     * @dev Function take 2 arguments are knightId, new name of knight
     * 
     * Requirements:
     * - `newName` must be a valid string.
     * - `newName` is not duplicated to other.
     * - Token required: `serviceFeeInToken`.
     */
    function changeKnightName(uint knightId, string memory newName) external;

    /**
     * @notice Owner equips items to their knight by burning ERC1155 Equipment NFTs.
     *
     * Requirements:
     * - caller must be owner of the knight.
     */
    function equipItems(uint knightId, uint[] memory itemIds) external;

    /**
     * @notice Owner removes items from their knight. ERC1155 Equipment NFTs are minted back to the owner.
     *
     * Requirements:
     * - caller must be owner of the knight.
     */
    function removeItems(uint knightId, uint[] memory itemIds) external;

    /**
     * @notice Lists a knight on sale.
     *
     * Requirements:
     * - Caller must be the owner of the knight.
     */
    function list(uint knightId, uint price) external;

    /**
     * @notice Delist a knight on sale.
     */
    function delist(uint knightId) external;

    /**
     * @notice Instant buy a specific knight on sale.
     *
     * Requirements:
     * - Target knight must be currently on sale.
     * - Sent value must be exact the same as current listing price.
     */
    function buy(uint knightId) external payable;

    /**
     * @notice Gives offer for a knight.
     *
     * Requirements:
     * - Owner cannot offer.
     */
    function offer(uint knightId, uint offerValue) external payable;

    /**
     * @notice Owner take an offer to sell their knight.
     *
     * Requirements:
     * - Offer value must be at least equal to `minPrice`.
     */
    function takeOffer(uint knightId, address offerAddr, uint minPrice) external;

    /**
     * @notice Cancels an offer for a specific knight.
     */
    function cancelOffer(uint knightId) external;

    /**
     * @notice Learns a skill for given Knight.
     */
    function learnSkill(uint knightId, uint skillId) external;

    /**
     * @notice Adopts a Pet.
     */
    function adoptPet(uint knightId, uint petId) external;

    /**
     * @notice Abandons a Pet attached to a Knight.
     */
    function abandonPet(uint knightId) external;
    
    /**
     * @notice Burn two knights to create one new knight.
     * 
     * Requirements:
     * - caller must be owner of the knights.
     */
     
    function breedingKnight (uint[2] memory knightIds) external;

    /**
     * @notice Operators can level up a Knight.
     */
    function levelUp(uint knightId, uint amount) external;

    /**
     * @notice Gets knight information.
     */
    function getKnight(uint knightId) external view returns (
        string memory name,
        uint level,
        uint pet,
        uint[] memory skills,
        uint[9] memory equipment
    );

    /**
     * @notice Gets current level of given knight.
     */
    function getKnightLevel(uint knightId) external view returns (uint);
    
}