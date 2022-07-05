// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the CRDIT
 */
interface ICRDIT {

    /**
    * @dev Returns the current tax rate.
    */
    function tax() external view returns(uint8);

    /**
    * @dev Returns the mintAddLimit.
    */
    function mintAddLimit() external view returns(uint8);

    /**
    * @dev Returns the mint limit of an address.
    */
    function mintLimitOf(address _address) external view returns(uint);

    /**
    * @dev Returns the amount after deducting tax.
    */
    function afterTax(uint _amount) external view returns(uint);

    /**
    * @dev Changes the tax rate of CRDIT.
    */
    function changeTax(uint8 _newTax) external returns(bool);

    /**
    * @dev Changes the mintAddLimit.
    */
    function changeMintAddLimit(uint8 _newLimit) external returns(bool);

    /**
    * @dev Changes the mint limit of an address.
    */
    function changeMintLimit(address _address, uint _amount) external returns(bool);

    /**
    * @dev Mints new CRDIT.
    */
    function publicMint(address _to, uint256 _amount) external returns(bool);
}