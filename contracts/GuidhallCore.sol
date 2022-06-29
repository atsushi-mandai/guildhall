// SPDX-License-Identifier: MIT
// ATSUSHI MANDAI Wisdom3 Contracts

pragma solidity ^0.8.0;

import "./token/ERC20/CRDIT.sol";
import "./access/Ownable.sol";
import "./utils/math/SafeMath.sol";

/// @title GuildhallCore
/// @author Atsushi Mandai
/// @notice Basic functions of the Guildhall will be written here.
contract GuildhallCore is CRDIT, Ownable {

    using SafeMath for uint256;

    /**********
    *
    * Events for the GuildhallCore
    *
    **********/


    /**********
    *
    * Variables for the GuildhallCore
    *
    **********/

    /**
    * @dev quests is an array which stores every Quest.
    * The content of the condition should be clearly written so that 
    * it is easy to determine whether it has been achieved or not.
    * For status, 0 is closed, 1 is open, 2 is finished.
    */
    struct Quest {
        address client;
        address assignedHero;
        string questTitle;
        string questBody;
        string condition;
        string langCode;
        uint reward;
        uint8 status;
    }
    Quest[] public quests;


}