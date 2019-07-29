pragma solidity 0.5.0;

 /* New ERC223 contract interface */

contract IRC223 {
    uint public totalSupply;
    function balanceOf(address who) public view returns (uint);

    function name() public view returns (string memory _name);
    function symbol() public view returns (string memory _symbol);
    function decimals() public view returns (uint8 _decimals);

    function transfer(address to, uint value) public;

    event Transfer(address indexed from, address indexed to, uint value, bytes indexed data);
}
