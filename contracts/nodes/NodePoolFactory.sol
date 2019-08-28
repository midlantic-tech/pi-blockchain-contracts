pragma solidity 0.5.0;

import "../utils/Owned.sol";
import "./NodePool.sol";

contract NodePoolFactory is Owned {
    uint public price;
    address[] public pools;

    event NodePoolCreated(address indexed _address, string name, string symbol, address owner, string utf8Symbol);

    constructor (uint _price) public {
        price = _price;
    }

    function createNodePool(uint[] calldata prices, uint[] calldata percentages, uint _nodePricePercentage, address dex, string calldata name, string calldata symbol, string calldata utf8Symbol) external payable returns (address) {
        require(msg.value == price);
        NodePool nodePool = new NodePool(prices, percentages, _nodePricePercentage, dex, name, symbol);
        pools.push(address(nodePool));

        emit NodePoolCreated(address(nodePool), name, symbol, msg.sender, utf8Symbol);

        return address(nodePool);
    }

    function changePrice(uint newPrice) public onlyOwner {
        price = newPrice;
    }

    function withdrawFunds() public onlyOwner {
        msg.sender.transfer(address(this).balance);
    }
}
