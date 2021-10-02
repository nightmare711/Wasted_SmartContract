//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IPet {
    /**
     * @notice Temporarily burn a pet.
     */
    function bindPet(uint petId) external;

    /**
     * @notice Release given pet back into user inventory.
     */
    function releasePet(uint petId) external;

    /**
     * @notice Gets owner of given pet.
     */
    function ownerOf(uint petId) external view returns (address);
}