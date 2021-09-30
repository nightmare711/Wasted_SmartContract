//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IWastedEquipment {
    // Event required.
    event ItemCreated(uint indexed itemId, string name, uint16 maxSupply, ItemType itemType, Rarity rarity);
    event ItemUpgradable(uint indexed itemId, uint indexed nextTierItemId, uint8 upgradeAmount);
    event UpgradedItem()
    
    enum ItemType { WEAPON, ARMOR, ACCESSORY, SKILL } // 4 types of equipments.
    enum Rarity { COMMON, UNCOMMON, RARE, EPIC, LEGENDARY }
    
    
    struct WastedItem {
        ItemType itemType;
        Rarity rarity;
        string name;
        uint16 maxSupply; // max total supply of this item.
        uint16 minted; // total item minted.
        uint16 burnt; //total burnt to upgrade item
        uint8 star; // star of item
        uint8 requireAmount; //require amount item to upgrade to next star. 
    }
    
     /**
     * @notice Roll equipments.
     * 
     * Requirements:
     * -  Fee token is required.
     */
    function rollWastedEquipment(uint vendorId, uint amount) external;
    
    /**
     * @notice Check if item is out of stock.
     */
    function isOutOfStock(uint itemId, uint16 amount) external view returns (bool);
    
    /**
     * @notice Create an wasted item.
     */
    function createWastedItem(string memory name, uint16 maxSupply, ItemType itemType, Rarity rarity) external;

    /**
     * @notice Add next star of item to existing one.
     * 
     * Requirements:
     *  - Only operator of system.
     */
    function addNextStar(uint itemId, uint8 upgradeAmount) external;

    /**
     * @notice Burns the same items to upgrade its star.
     *
     * Requirements:
     * - `servicesFeeInToken` is required.
     * - Item must have its next tier.
     * - Caller's balance must have at least `upgradeAmount` to upgrade item.
     */
    function upgradeWastedItem(uint itemId) external;

    /**
    * @notice Get informations of item by itemId
    */
    
     function getWastedItem(uint itemId) external view returns (Item memory item);

    /**
     * @notice Gets wasted item type.
     */
    function getWastedItemType(uint itemId) external view returns (ItemType);

}