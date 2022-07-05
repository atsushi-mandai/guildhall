// SPDX-License-Identifier: MIT
// ATSUSHI MANDAI Wisdom3 Contracts

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "../../utils/Context.sol";

/// @title CRDIT
/// @author Atsushi Mandai
/// @notice Basic functions of the governance of the ERC20 Token CRDIT.
contract CRDITGovernance is Context {

    IERC20 token;

    constructor() public {
        token = IERC20(0x01BE23585060835E02B77ef475b0Cc51aA1e0709);
        // this token address is LINK token deployed on Rinkeby testnet
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
    uint8 private _requiredBalance = 5;

    /**
    * @dev Amount of CRDIT balance required for anyone to create a proposal
    * is {totalSupply * _requiredVotes / 100}
    */
    uint8 private _requiredVotes = 30;

    /**
    * @dev A proposal to set a new value for _tax
    */
    struct TaxProposal {
        uint8 newTax;
        uint requiredVotes;
        uint votesFor;
        uint votesAgainst;
        uint deadline;
    }
    TaxProposal[] public _taxProposals;
    uint private _lastTaxProposal;
    mapping(uint => mapping(address => uint)) private _taxProposalToAddressToAmount;


    /**
    *
    *
    * @dev public view functions
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
    * @dev Returns _lastTaxProposal.
    */
    function lastTaxProposal() public view returns(uint256) {
        return _lastTaxProposal;
    }

    function createTaxProposal(uint8 _newTax) public {
        _checkRequiredBalance();
        require(block.timestamp >= _lastTaxProposal + 90 days);
        uint requiredVotes = token.totalSupply() * _requiredVotes / 100;
        _taxProposals.push(TaxProposal(_newTax, 0, 0, block.timestamp + 7 days));
        _lastTaxProposal = block.timestamp;
    }

    function voteForTaxProposal(uint256 _proposalId, uint256 _amount) public {
        require(block.timestamp <= _taxProposals[_proposalId].deadline);
        require(token.balanceOf(_msgSender()) >= _amount);
        token.transfer(address(this), _amount);
        _taxProposals[_proposalId].votesFor = _taxProposals[_proposalId].votesFor + _amount;
        _taxProposalToAddressToAmount[_proposalId][_msgSender()] = _amount;
    }

    function voteAgainstTaxProposal(uint256 proposalId, uint256 amount) public {
        require(block.timestamp <= _taxProposals[proposalId].deadline);
        token.transfer(address(this), amount);
        _taxProposals[proposalId].votesAgainst = _taxProposals[proposalId].votesAgainst + amount;
        _taxProposalToAddressToAmount[proposalId][_msgSender()] = amount;
    }

    //function unvoteTaxProposal(uint256 proposalId)

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
