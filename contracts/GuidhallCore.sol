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

    uint8 taxRate = 1;
    uint8 trialTaxrate = 5;
    uint8 introducerReward = 4;
    uint confirmationPeriod = 7 days;
    uint trialPeriod = 90 days;
    uint reservePool = 0;

    /**
    * @dev quests is an array which stores every Quest.
    * The content of the condition should be clearly written so that 
    * it is easy to determine whether it has been achieved or not.
    * For languageCode, ISO 639-1 should be used. 
    * For status,
    *  0: the quest is closed,
    *  1: the quest is open for heroes to apply,
    *  2: hero is chosen and the quest is under execution,
    *  3: quest is finished and the reward is payed to the hero,
    *  4: quest is closed without being finished and the reward was returned to the client.
    *  5: quest is pended.
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

    /**
    * @dev Anyone can make an Application.
    */
    struct Application {
        uint questId;
        address hero;
        address introducer;
        string message;
        bool isAssigned;
    }
    Application[] public applications;

    /**
    * @dev Hero makes a Submit when they complete the quest.
    * For status,
    *  0: waiting for client confirmation,
    *  1: submit is accepted,
    *  2: submit is rejected.
    */
    struct Submit {
        uint applicationId;
        uint dueDate;
        uint8 status;
        string resultUrl;
        string resultMessage;
        string clientReply;
    }
    Submit[] public submits;

    /**
    * @dev Hero makes a Submit when they complete the quest.
    * For trial type,
    *  0: trial was brought to action by a client;
    *. 1: trial was brought to action by a hero;
    * For status,
    *  0: trial is open and is waiting for votes,
    *  1: trial is closed.
    */
    struct Trial {
        uint applicationId;
        uint voteDeadline;
        uint8 trialType;
        uint8 status;
        uint8 agreed;
        uint8 disagreed;
        address accuserAddress;
        address defandantAddress;
        string accuserMessage;
        string defendantMessage;
    }
    Trial[] public trials;


    /**********
    *
    * modifiers for the GuildhallCore
    *
    **********/

    modifier onlyClient(uint _questId) {
        require(quests[_questId].client == _msgSender());
        _;
    }

    modifier onlyHero(uint _applicationId) {
        require(applications[_applicationId].hero == _msgSender());
        require(applications[_applicationId].isAssigned == true);
        _;
    }


    /**********
    *
    * public governance functions for the GuildhallCore
    *
    **********/

    function changeTaxRate(uint8 _newRate) public onlyOwner {
        require(_newRate + introducerReward < 100);
        taxRate = _newRate;
    }

    function changeIntroducerReward(uint8 _newReward) public onlyOwner {
        require(_newReward + taxRate < 100);
        introducerReward = _newReward;
    }

    function changeConfirmationPeriod(uint _newPeriod) public onlyOwner {
        confirmationPeriod = _newPeriod;
    }

    function withdrawReservePool(uint _amount) public onlyOwner {
        require(_amount <= reservePool);
        reservePool = reservePool - _amount;
        _transfer(address(this), owner(), _amount);
    }


    /**********
    *
    * public functions for the GuildhallCore
    *
    **********/

    /**
    * @dev createQuest lets anyone to create a new quest and become a client.
    * Check the struct Quest for more information about each members of Quest.
    */
    function createQuest(
        string memory _title,
        string memory _body,
        string memory _conditions,
        string memory _languageCode,
        uint _reward
    ) public {
        require(balanceOf(_msgSender()) >= _reward);
        _transfer(_msgSender(), address(this), _reward);
        quests.push(Quest(_msgSender(), _title, _body, _conditions, _languageCode, _reward, 1));
        //some mint functions here maybe
    }

    /**
    * @dev closeQuest lets client close the quest he/she has created.
    * This function could only be called when the status of the quest is 1(=open).
    * The reward of the quest he/she has paid to the protocol will be returned.
    */
    function closeQuest(uint _questId) public onlyClient(_questId) {
        require(quests[_questId].status == 1);
        quests[_questId].status = 0;
        _transfer(address(this), _msgSender(), quests[_questId].reward);
    }

    /**
    * @dev applyToQuest lets any hero apply to a quest.
    */
    function applyToQuest(
        uint _questId,
        address _introducer,
        string memory _message
    ) public {
        require(quests[_questId].status == 1);
        applications.push(Application(_questId, _msgSender(), _introducer, _message, false));
    }

    /**
    * @dev assignHero lets client choose the hero to assign the quest.
    */
    function assignHero(
        uint _applicationId
    ) public onlyClient(applications[_applicationId].questId) {
        require(quests[applications[_applicationId].questId].status == 1, "Something is wrong");
        quests[applications[_applicationId].questId].status = 2;
        applications[_applicationId].isAssigned = true;
    }

    /**
    * @dev submitResult lets hero submit a result to his/her client.
    */
    function submitResult (
        uint _applicationId,
        string memory _url,
        string memory _message
    ) public onlyHero(_applicationId) {
        require(quests[applications[_applicationId].questId].status == 2, "This quest is currently not under execution.");
        submits.push(Submit(_applicationId, block.timestamp + confirmationPeriod , 0, _url, _message, "There is no reply yet."));
    }

    /**
    * @dev approveSubmit lets client approve the submit made by a hero he/she has assigned.
    * The reward of the quest is destributed to the hero and the introducer.
    */

    function approveSubmit(
        uint _submitId,
        string memory _reply
    ) public onlyClient(applications[submits[_submitId].applicationId].questId) {
        require(quests[applications[submits[_submitId].applicationId].questId].status == 2);
        require(submits[_submitId].status == 0);
        _approveSubmit(_submitId);
        submits[_submitId].clientReply = _reply;
    }

    /**
    * @dev rejectSubmit lets client reject the submit made by a hero he/she has assigned.
    */

    function rejectSubmit(
        uint _submitId,
        string memory _reply
    ) public onlyClient(applications[submits[_submitId].applicationId].questId) {
        require(quests[applications[submits[_submitId].applicationId].questId].status == 2);
        require(submits[_submitId].status == 0);
        submits[_submitId].status = 2;
        submits[_submitId].clientReply = _reply;
    }

    /**
    * @dev reportExpiration could be called by a hero who has made the submit,
    * when a client didn't approve nor reject the submit until the dueDate.
    */

    function reportExpiration(uint _submitId) public onlyHero(submits[_submitId].applicationId) {
        require(submits[_submitId].dueDate < block.timestamp);
        require(submits[_submitId].status == 0);
        _approveSubmit(_submitId);
        submits[_submitId].clientReply = "Expiration was reported by the hero. This reply is written by the protocol.";
    }

    /**
    * @dev pendQuest lets a client to pend the quest so that new submits won't be made.
    * This function should be used when the hero keeps on submitting results without completing the quest he/she was assigned.
    */
    function pendQuest(uint _questId) public onlyClient(_questId) {
        require(quests[_questId].status == 2);
        quests[_questId].status = 5;
    }

    function releasePend(uint _questId) public onlyClient(_questId) {
        require(quests[_questId].status == 5);
        quests[_questId].status = 2;
    }

    /**
    * @dev pendQuest lets a client to pend the quest so that new submits won't be made.
    * This function should be used when the hero keeps on submitting results without completing the quest he/she was assigned.
    */ 

    function sueHero(
        uint _applicationId,
        string memory _message
    ) public onlyClient(applications[_applicationId].questId) {
        require(applications[_applicationId].questId == 2);
        require(applications[_applicationId].isAssigned == true);
        trials.push(Trial(
            _applicationId,
            block.timestamp + trialPeriod,
            0, 0, 0, 0,
            _msgSender(), applications[_applicationId].hero,
            _message, "Waiting for defandant's message."
        ));
    }

    function sueClient(
        uint _applicationId,
        string memory _message
    ) public onlyHero(_applicationId) {
        require(applications[_applicationId].questId == 2);
        trials.push(Trial(
            _applicationId,
            block.timestamp + trialPeriod,
            1, 0, 0, 0,
            quests[applications[_applicationId].questId].client, _msgSender(),
            _message, "Waiting for defandant's message."
        ));
    }


    /**********
    *
    * internal functions for the GuildhallCore
    *
    **********/

    /**
    * @dev change the status of the submit and quest, then distribute the reward.
    */

    function _approveSubmit(uint _submitId) internal {
        submits[_submitId].status = 1;
        quests[applications[submits[_submitId].applicationId].questId].status = 3;
        reservePool = reservePool + (quests[applications[submits[_submitId].applicationId].questId].reward * taxRate);
        _transfer(
            address(this),
            applications[submits[_submitId].applicationId].hero,
            quests[applications[submits[_submitId].applicationId].questId].reward * (100 - introducerReward - taxRate) / 100
        );
        _transfer(
            address(this),
            applications[submits[_submitId].applicationId].introducer,
            quests[applications[submits[_submitId].applicationId].questId].reward * introducerReward / 100
        );
    }

}