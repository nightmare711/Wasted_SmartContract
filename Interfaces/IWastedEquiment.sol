//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IWastedEquipment {
    // Event required.
    enum ItemType { WEAPON, ARMOR, ACCESSORY, SKILL } // 4 types of equipments.
    enum Rarity { COMMON, UNCOMMON, RARE, EPIC, LEGENDARY }
    event ItemCreated(uint indexed itemId, string name, uint16 maxSupply, ItemType itemType, Rarity rarity);
    event ItemUpgradable(uint indexed itemId, uint indexed nextTierItemId, uint8 upgradeAmount);
    event ItemUpdated(uint itemId);
    
    
    struct WastedItem {
        ItemType itemType;
        Rarity rarity;
        string name;
        uint16 maxSupply;
        uint16 minted;
        uint16 burnt;
        uint8 star;
        uint8 requireAmountToUpgrade;
    }
    
     /**
     * @notice Roll equipments.
     * 
     * Requirements:
     * -  Fee token is required.
     */
    
    /**
     * @notice Burns ERC1155 equipment since it is equipped to the knight.
     */
    function putItemsIntoStorage(address account, uint[] memory itemIds) external;
    
    /**
     * @notice Check if item is out of stock.
     */
    function isOutOfStock(uint itemId, uint16 amount) external view returns (bool);
    
    /**
     * @notice Create an wasted item.
     */
    function createWastedItem(string memory name, uint16 maxSupply, ItemType itemType, Rarity rarity) external;
    
    /**
     * @notice Returns ERC1155 equipment back to the owner.
     */
    function returnItems(address account, uint[] memory itemIds) external;

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
    
     function getWastedItem(uint itemId) external view returns (WastedItem memory item);

    /**
     * @notice Gets wasted item type.
     */
    function getWastedItemType(uint itemId) external view returns (ItemType);

}