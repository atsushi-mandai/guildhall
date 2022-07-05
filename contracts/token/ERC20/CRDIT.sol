// SPDX-License-Identifier: MIT
// ATSUSHI MANDAI Wisdom3 Contracts

pragma solidity ^0.8.0;

import "./extensions/ERC20Capped.sol";
import "../../access/Ownable.sol";

/// @title CRDIT
/// @author Atsushi Mandai
/// @notice Basic functions of the ERC20 Token CRDIT for Guildhall will be written here.
contract CRDIT is ERC20Capped, Ownable {


    /**
    *
    *
    * @dev
    * variables
    *
    *
    */

    /** 
    * @dev ERC20 Token "Credit" (ticker "CRDIT") has max supply of 100,000,000.
    * Founder takes 10% of the max supply as an incentive for him and early collaborators.
    * All the remaining tokens will be minted through a non-arbitrary algorithm.
    */
    constructor () ERC20 ("Credit", "CRDIT") ERC20Capped(100000000 * (10**uint256(18)))
    {
        ERC20._mint(_msgSender(),10000000 * (10**uint256(18)));
    }

    /**
    * @dev Amount of CRDIT balance required for anyone to create a proposal
    * is {totalSupply * _requiredBalance / 100}
    */
    uint8 private _requiredBalance;

    /**
    * @dev Everytime a transaction is made, {tax / 1000} will be burned from reciever's balance.
    */
    uint8 private _tax = 1;
    
    /**
    * @dev Keeps the mint limit approved for each address.
    */
    mapping(address => uint256) private _addressToMintLimit;

    /**
    * @dev A proposal to set a new value for _tax
    */
    struct TaxProposal {
        uint8 newTax;
        uint votes;
        uint deadline;
    }
    TaxProposal[] private _taxProposals;
    uint private _lastTaxProposal;


    /**
    *
    *
    * @dev
    * public functions
    *
    *
    */

    /**
    * @dev Returns the current _requiredBalance.
    */
    function requiredBalance() public view returns(uint8) {
        return _requiredBalance;
    }

    /**
    * @dev Returns the current _salesTax.
    */
    function tax() public view returns (uint) {
        return _tax;
    }

    function createTaxProposal(uint8 newTax) public {
        _checkRequiredBalance();
        require(block.timestamp >= _lastTaxProposal + 30 days);
        _taxProposals.push(TaxProposal(newTax, 0, block.timestamp + 7 days));
        _lastTaxProposal = block.timestamp;
    }

    function voteForProposal(uint256 proposalId, uint256 amount) public {
        require(block.timestamp <= _taxProposals[proposalId].deadline);
        _transfer(_msgSender(), address(this), amount);
        _taxProposals[proposalId].votes = _taxProposals[proposalId].votes + amount;
    }

    //function unvoteForProposal

    /**
    * @dev Sets new value for _tax.
    */
    function changeTax(uint8 _newTax) public onlyOwner returns(bool) {
        _tax = _newTax;
        return true;
    }
    

    /**
    * @dev tax is added to the transfer.
    */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        _burn(to, amount * _tax / 1000);
        return true;
    }

    /**
    * @dev tax is added to the transferFrom.
    */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        _burn(to, amount * _tax / 1000);
        return true;
    }

    /**
    * @dev Sets mint limit for an address.
    */
    function setMintLimit(
        address allowedAddress,
        uint256 limit
    ) public onlyOwner returns(bool) {
        require(limit <= cap() - totalSupply());
        _addressToMintLimit[allowedAddress] = limit;
        return true;
    }

    /**
    * @dev Lets an address mint CRDIT within its limit.
    */
    function publicMint(
        address to, 
        uint256 amount
    ) public returns(bool) {
        require(amount <= _addressToMintLimit[_msgSender()], "This contract has reached its mint limit.");
        _addressToMintLimit[_msgSender()] = _addressToMintLimit[_msgSender()] - amount;
        _mint(to, amount);
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
        require(balanceOf(_msgSender()) >= totalSupply() * _requiredBalance / 100, "Not enough CRDIT balance to create a proposal.");
    }

}