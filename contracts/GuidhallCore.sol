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
    * events for the GuildhallCore
    *
    **********/


    /**********
    *
    * variables for the GuildhallCore
    *
    **********/

    /**
    * @dev quests is an array which stores every Quest.
    * The content of the condition should be clearly written so that 
    * it is easy to determine whether it has been achieved or not.
    * For languageCode, ISO 639-1 should be used. 
    * For status, 0 is closed, 1 is open, 2 is finished.
    */
    struct Quest {
        address client;
        string title;
        string body;
        string conditions;
        string languageCode;
        uint reward;
        uint8 status;
    }
    Quest[] public quests;
    mapping(uint => mapping(address => bool)) public questToHeroToAssigned;


    /**********
    *
    * public functions for the GuildhallCore
    *
    **********/

    function createQuest(
        string memory _title,
        string memory _body,
        string memory _conditions,
        string memory _languageCode,
        uint _reward,
        uint8 _status
    ) public {
        require(balanceOf(_msgSender()) >= _reward);
        _transfer(_msgSender(), address(this), _reward);
        quests.push(Quest(_msgSender(), _title, _body, _conditions, _languageCode, _reward, _status));
        //some mint functions here maybe
    }

}