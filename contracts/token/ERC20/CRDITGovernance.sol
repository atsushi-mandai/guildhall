// SPDX-License-Identifier: MIT
// ATSUSHI MANDAI Wisdom3 Contracts

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./ICRDIT.sol";
import "../../utils/Context.sol";

/// @title CRDIT
/// @author Atsushi Mandai
/// @notice Basic functions of the governance of the ERC20 Token CRDIT.
contract CRDITGovernance is Context {

    IERC20 token;
    ICRDIT crdit;

    constructor() {
        //change here before depolying the contract.
        token = IERC20(0x06012c8cf97BEaD5deAe237070F9587f8E7A266d);
        crdit = ICRDIT(0x06012c8cf97BEaD5deAe237070F9587f8E7A266d);
    }

    /**
    *
    *
    * @dev variables
    *
    *
    */

    /**
    * @dev Amount of CRDIT balance required for anyone to create a proposal
    * is {totalSupply * _requiredBalance / 100}
    */
    uint8 private _requiredBalance = 3;

    /**
    * @dev Amount of CRDIT balance required for anyone to create a proposal
    * is {totalSupply * _requiredVotes / 100}
    */
    uint8 private _requiredVotes = 5;

    /**
    * @dev A proposal to set a new value for _tax of CRDIT.
    * For status,
    * 0: not implemented
    * 1: implemented
    */
    struct TaxProposal {
        uint8 newTax;
        uint8 status;
        uint votesRequired;
        uint votesFor;
        uint votesAgainst;
        uint deadline;
    }
    TaxProposal[] private _taxProposals;
    uint private _lastTaxProposalDate;
    mapping(uint => mapping(address => uint)) private _taxProposalToAddressToAmount;

    /**
    * @dev A proposal to set a new value for _mintAddLimit of CRDIT.
    * For status,
    * 0: not implemented
    * 1: implemented
    */
    struct MintAddLimitProposal {
        uint8 newLimit;
        uint8 status;
        uint votesRequired;
        uint votesFor;
        uint votesAgainst;
        uint deadline;
    }
    MintAddLimitProposal[] private _mintAddLimitProposals;
    uint private _lastMintAddLimitProposalDate;
    mapping(uint => mapping(address => uint)) private _mintAddLimitProposalToAddressToAmount;


    /**
    *
    *
    * @dev public view variables functions
    *
    *
    */

    /**
    * @dev Returns _requiredBalance.
    */
    function requiredBalance() public view returns(uint8) {
        return _requiredBalance;
    }

    /**
    * @dev Returns _requiredBalance.
    */
    function requiredVotes() public view returns(uint8) {
        return _requiredVotes;
    }

    /**
    * @dev Returns a TaxProposal.
    */
    function taxProposal(uint _proposalId) public view returns(TaxProposal memory) {
        return _taxProposals[_proposalId];
    }

    /**
    * @dev Returns the latest TaxProposal.
    */
    function latestTaxProposal() public view returns(TaxProposal memory) {
        return _taxProposals[_taxProposals.length - 1];
    }   

    /**
    * @dev Returns _lastTaxProposal.
    */
    function lastTaxProposalDate() public view returns(uint256) {
        return _lastTaxProposalDate;
    }

    /**
    * @dev Returns a MintAddLimitProposal.
    */
    function mintAddLimitProposal(uint _proposalId) public view returns(MintAddLimitProposal memory) {
        return _mintAddLimitProposals[_proposalId];
    }

    /**
    * @dev Returns the latest MintAddLimitProposal.
    */
    function latestMintAddLimitProposal() public view returns(MintAddLimitProposal memory) {
        return _mintAddLimitProposals[_mintAddLimitProposals.length - 1];
    }   

    /**
    * @dev Returns _lastMintAddLimitProposal.
    */
    function lastMintAddLimitProposalDate() public view returns(uint256) {
        return _lastMintAddLimitProposalDate;
    }


    /**
    *
    *
    * @dev public functions to change tax
    *
    *
    */

    /**
    * @dev Creates TaxProposal.
    */
    function createTaxProposal(uint8 _newTax) public {
        _checkRequiredBalance();
        require(block.timestamp >= _lastTaxProposalDate + 30 days, "New proposal could only be made after 90 days since last proposal.");
        uint votes = token.totalSupply() * _requiredVotes / 100;
        _taxProposals.push(TaxProposal(_newTax, 0, votes, 0, 0, block.timestamp + 7 days));
        _lastTaxProposalDate = block.timestamp;
    }

    /**
    * @dev Vote for an open tax proposal.
    */
    function voteForTaxProposal(uint256 _proposalId, uint256 _amount) public {
        require(block.timestamp <= _taxProposals[_proposalId].deadline, "This proposal has closed the vote.");
        require(token.balanceOf(_msgSender()) >= _amount, "Not enough balance.");
        token.transferFrom(_msgSender(), address(this), _amount);
        _taxProposals[_proposalId].votesFor = _taxProposals[_proposalId].votesFor + crdit.afterTax(_amount);
        _taxProposalToAddressToAmount[_proposalId][_msgSender()] = _taxProposalToAddressToAmount[_proposalId][_msgSender()] + crdit.afterTax(_amount);
    }

    /**
    * @dev Vote against an open tax proposal.
    */
    function voteAgainstTaxProposal(uint256 _proposalId, uint256 _amount) public {
        require(block.timestamp <= _taxProposals[_proposalId].deadline, "This proposal has closed the vote.");
        require(token.balanceOf(_msgSender()) >= _amount, "Not enough balance.");
        token.transferFrom(_msgSender(), address(this), _amount);
        _taxProposals[_proposalId].votesAgainst = _taxProposals[_proposalId].votesAgainst + crdit.afterTax(_amount);
        _taxProposalToAddressToAmount[_proposalId][_msgSender()] = _taxProposalToAddressToAmount[_proposalId][_msgSender()] + crdit.afterTax(_amount);
    }

    /**
    * @dev Implements the TaxProposal to change the tax of CRDIT.
    */
    function implementTaxProposal(uint256 _proposalId) public returns(bool) {
        TaxProposal memory proposal = _taxProposals[_proposalId];
        require(proposal.deadline < block.timestamp, "This proposal is still open for votes.");
        require(proposal.votesRequired >= proposal.votesFor + proposal.votesAgainst, "Not enough votes.");
        require(proposal.votesFor > proposal.votesAgainst, "This proposal was rejected.");
        require(proposal.status == 0, "This proposal has already been implemented.");
        _taxProposals[_proposalId].status = 1;
        crdit.changeTax(_taxProposals[_proposalId].newTax);
        return true;
    }

    /**
    * @dev Sends CRDIT back to its owner.
    */
    function unvoteTaxProposal(uint256 _proposalId) public returns(bool) {
        require(_taxProposals[_proposalId].deadline < block.timestamp, "Wait until the voting period is over."); 
        uint amount = _taxProposalToAddressToAmount[_proposalId][_msgSender()];
        _taxProposalToAddressToAmount[_proposalId][_msgSender()] = 0;
        token.transfer(_msgSender(), amount);
        return true;
    }


    /**
    *
    *
    * @dev public functions to change mintAddLimit
    *
    *
    */

    /**
    * @dev Creates MintAddLimitProposal.
    */
    function createMintAddLimitProposal(uint8 _newLimit) public {
        _checkRequiredBalance();
        require(block.timestamp >= _lastMintAddLimitProposalDate + 30 days, "New proposal could only be made after 90 days since last proposal.");
        uint votes = token.totalSupply() * _requiredVotes / 100;
        _mintAddLimitProposals.push(MintAddLimitProposal(_newLimit, 0, votes, 0, 0, block.timestamp + 7 days));
        _lastMintAddLimitProposalDate = block.timestamp;
    }

    /**
    * @dev Vote for an open MintAddLimitProposal.
    */
    function voteForMintAddLimitProposal(uint256 _proposalId, uint256 _amount) public {
        require(block.timestamp <= _mintAddLimitProposals[_proposalId].deadline, "This proposal has closed the vote.");
        require(token.balanceOf(_msgSender()) >= _amount, "Not enough balance.");
        token.transferFrom(_msgSender(), address(this), _amount);
        _mintAddLimitProposals[_proposalId].votesFor = _mintAddLimitProposals[_proposalId].votesFor + crdit.afterTax(_amount);
        _mintAddLimitProposalToAddressToAmount[_proposalId][_msgSender()] = _mintAddLimitProposalToAddressToAmount[_proposalId][_msgSender()] + crdit.afterTax(_amount);
    }

    /**
    * @dev Vote against an open MintAddLimitProposal.
    */
    function voteAgainstMintAddLimitProposal(uint256 _proposalId, uint256 _amount) public {
        require(block.timestamp <= _mintAddLimitProposals[_proposalId].deadline, "This proposal has closed the vote.");
        require(token.balanceOf(_msgSender()) >= _amount, "Not enough balance.");
        token.transferFrom(_msgSender(), address(this), _amount);
        _mintAddLimitProposals[_proposalId].votesAgainst = _mintAddLimitProposals[_proposalId].votesAgainst + crdit.afterTax(_amount);
        _mintAddLimitProposalToAddressToAmount[_proposalId][_msgSender()] = _mintAddLimitProposalToAddressToAmount[_proposalId][_msgSender()] + crdit.afterTax(_amount);
    }

    /**
    * @dev Implements the MintAddLimitProposal to change the mintAddLimit of CRDIT.
    */
    function implementMintAddLimitProposal(uint256 _proposalId) public returns(bool) {
        MintAddLimitProposal memory proposal = _mintAddLimitProposals[_proposalId];
        require(proposal.deadline < block.timestamp, "This proposal is still open for votes.");
        require(proposal.votesRequired >= proposal.votesFor + proposal.votesAgainst, "Not enough votes.");
        require(proposal.votesFor > proposal.votesAgainst, "This proposal was rejected.");
        require(proposal.status == 0, "This proposal has already been implemented.");
        _mintAddLimitProposals[_proposalId].status = 1;
        crdit.changeMintAddLimit(_mintAddLimitProposals[_proposalId].newLimit);
        return true;
    }

    /**
    * @dev Sends CRDIT back to its owner.
    */
    function unvoteMintAddLimitProposal(uint256 _proposalId) public returns(bool) {
        require(_taxProposals[_proposalId].deadline < block.timestamp, "Wait until the voting period is over."); 
        uint amount = _taxProposalToAddressToAmount[_proposalId][_msgSender()];
        _taxProposalToAddressToAmount[_proposalId][_msgSender()] = 0;
        token.transfer(_msgSender(), amount);
        return true;
    }






    /**
    *
    *
    * @dev
    * internal functions
    *
    *
    */

    function _checkRequiredBalance() private view {
        require(token.balanceOf(_msgSender()) >= token.totalSupply() * _requiredBalance / 100, "Not enough CRDIT balance to create a proposal.");
    }
}
