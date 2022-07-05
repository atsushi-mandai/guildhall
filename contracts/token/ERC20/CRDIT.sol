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
    * @dev Everytime the transaction is made, {tax / 1000} will be burned.
    */
    uint8 private _tax = 1;
    
    /**
    * @dev 
    */
    mapping(address => uint256) private _addressToMintLimit;

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
    *
    *
    * @dev
    * public functions associated with salesTax.
    *
    *
    */

    /**
    * @dev Returns the current salesTax.
    */
    function salesTax() public view returns (uint) {
        return _tax;
    }

    /**
    * @dev Sets new uint for the _tax.
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
    *
    *
    * @dev
    * public functions associated with publicMint.
    *
    *
    */

    function publicMint(
        address to, 
        uint256 amount
    ) public returns(bool) {
        require(amount <= _addressToMintLimit[_msgSender()], "This contract has reached its mint limit.");
        _mint(to, amount);
        return true;
    }


}