pragma solidity 0.5.0;

import "../utils/Owned.sol";
import "./PiFiatToken.sol";

contract TokenFactory is Owned {

    mapping(bytes32 => bool) public reservedSymbol;

    uint public price;
    address[] public tokens;

    event TokenCreated(address indexed _address, string name, string indexed symbol, address owner, uint initialSupply, string utf8Symbol);

    constructor (uint _price) public {
        price = _price;
    }

    function createToken(string calldata name, string calldata symbol, uint initialSupply, string calldata utf8Symbol) external payable returns (address) {
        require(msg.value == price);
        require(!reservedSymbol[keccak256(bytes(symbol))]);
        reservedSymbol[keccak256(bytes(symbol))] = true;
        PiFiatToken token = new PiFiatToken(name, symbol, msg.sender, initialSupply);
        tokens.push(address(token));

        emit TokenCreated(address(token), name, symbol, msg.sender, initialSupply, utf8Symbol);

        return address(token);
    }

    function changePrice(uint newPrice) public onlyOwner {
        price = newPrice;
    }

    function withdrawFunds() public onlyOwner {
        msg.sender.transfer(address(this).balance);
    }
}
