pragma solidity 0.5.0;

import "../../utils/safeMath.sol";
import "./BaseOwnedSet.sol";

/// @author MIDLANTIC TECHNOLOGIES
/// @title Contract to handle node's market

contract ManageNodes {
    using SafeMath for uint;

    struct MasterNode {
        uint index;
        uint payedPrice;
        bool isValidator;
        bool isHolder;
    }

    mapping(address => MasterNode) public nodes;
    mapping(address => mapping(address => uint)) exchange;
    mapping(address => mapping(address => bool)) pendingValidatorChange;
    mapping(uint => uint) public purchaseCommission;
    mapping(uint => uint) public sellCommission;
    address payable[] public nodesArray;
    uint public currentNodePrice;
    uint public sellNodePrice;
    uint public purchaseNodePrice;
    uint public nodesValue;
    uint public maxValidators;
    uint public globalIndex;
    address payable emisorAddress;
    BaseOwnedSet validatorSet;

    modifier isNode(address _someone) {
        require(nodes[_someone].isValidator || nodes[_someone].isHolder);
        _;
    }

    modifier isNotNode(address _someone) {
        require(!nodes[_someone].isValidator && !nodes[_someone].isHolder);
        _;
    }

    constructor (address payable[] memory initialValidators) public {
        globalIndex = 1;
        for (uint i = 0; i < initialValidators.length; i++) {
            nodesArray.push(initialValidators[i]);
            globalIndex++;
            nodes[initialValidators[i]].index = globalIndex;
            nodes[initialValidators[i]].isValidator = true;
            nodes[initialValidators[i]].payedPrice = 1 ether;
            nodesValue += 1 ether;
        }
        emisorAddress = (address(0x0000000000000000000000000000000000000010));
        currentNodePrice = 6600000000000000000; // Value of the 11th node
        purchaseNodePrice = 6666000000000000000; // Purchase price of the 11th value
        purchaseCommission[purchaseNodePrice] = currentNodePrice;
        currentNodePrice = 5500000000000000000; // Value of the N-1 node
        sellNodePrice = 5445000000000000000; // Sell price of the 11th value
        sellCommission[sellNodePrice] = currentNodePrice;
    }

    /// @dev Set RelaySet contract's address when deployed
    /// @param newValidatorSetAddress Address of RelaySet
    function setValidatorSetAddress (address newValidatorSetAddress) public {
        require(msg.sender == address(0));
        validatorSet = BaseOwnedSet(newValidatorSetAddress);
    }

    /// @dev Getter for the array of nodes
    /// @return nodesArray array of nodes
    function getNodes() public view returns(address payable[] memory) {
        return nodesArray;
    }

    function getNodeIndex(address _node) public view returns(uint) {
        return nodes[_node].index;
    }

    /// DONDE???????????????????
    function getNodesValue() public view returns(uint) {
        return nodesValue;
    }

    /// @dev Getter for the payed price of the node
    /// @param _node account of the node to get the payed price
    /// @return payedPrice price
    function getPayedPrice(address _node) public view returns (uint){
        return nodes[_node].payedPrice;
    }

    /// @dev Purchase the next node
    function purchaseNode() external payable isNotNode(msg.sender) {
        require(msg.value == purchaseNodePrice);
        nodes[msg.sender].payedPrice = purchaseNodePrice;
        nodesValue += purchaseNodePrice;
        nodesArray.push(msg.sender);
        nodes[msg.sender].index = globalIndex;
        nodes[msg.sender].isHolder = true;
        globalIndex++;
        emisorAddress.transfer(purchaseNodePrice.sub(purchaseCommission[purchaseNodePrice]));
        updateNodePrice();
    }

    /// @dev Sell the node you own
    function sellNode() public isNode(msg.sender) {
        require(!nodes[msg.sender].isValidator);
        removeFromArray(msg.sender);
        globalIndex--;
        msg.sender.transfer(sellNodePrice);
        emisorAddress.transfer(sellCommission[sellNodePrice].sub(sellNodePrice));
        nodes[msg.sender].isHolder = false;
        updateNodePrice();
    }

    /// @dev Ballot contract call this function when there is successful ballot to allow the change of validator
    /// @param _oldValidator the current validator
    /// @param _newValidator the pending validator who can call changeValidatorsExecute function to execute the change
    function changeValidatorsPending(address _oldValidator, address _newValidator) public isNode(_oldValidator) isNotNode(_newValidator) {
        require(msg.sender == address(0x0000000000000000000000000000000000000013));
        pendingValidatorChange[_oldValidator][_newValidator] = true;
    }

    /// @dev Execute a pending validators change
    /// @param _oldValidator the current validator to pay it's payed node price
    function changeValidatorsExecute (address payable _oldValidator)
        external
        payable
        isNode(_oldValidator)
        isNotNode(msg.sender)
    {
        require(pendingValidatorChange[_oldValidator][msg.sender]);
        require(msg.value == nodes[_oldValidator].payedPrice);
        nodes[_oldValidator].isValidator = false;
        nodes[_oldValidator].isHolder = true;
        nodes[msg.sender].isValidator = true;
        nodes[msg.sender].isHolder = false;
        validatorSet.removeValidator(_oldValidator);
        validatorSet.addValidator(msg.sender);
        pendingValidatorChange[_oldValidator][msg.sender] = false;
        _oldValidator.transfer(nodes[_oldValidator].payedPrice);
    }

    /// @dev Update node's price when somebody buy/sell a node
    function updateNodePrice() internal {
        uint nodos = globalIndex;
        uint a = 100000;
        uint b = 200000;
        uint c = a.div(10);
        uint d = b.div(10);
        uint e = nodos.mul(c);
        uint f = e.add(c);
        currentNodePrice = e.mul(f).div(d);
        currentNodePrice = currentNodePrice.mul(1 ether).div(100000);
        purchaseNodePrice = currentNodePrice.mul(101).div(100);
        purchaseCommission[purchaseNodePrice] = currentNodePrice;
        nodos--;
        e = nodos.mul(c);
        f = e.add(c);
        currentNodePrice = e.mul(f).div(d);
        currentNodePrice = currentNodePrice.mul(1 ether).div(100000);
        sellNodePrice = currentNodePrice.mul(99).div(100);
        sellCommission[sellNodePrice] = currentNodePrice;
    }

    /// @dev Remove an element of an array
    /// @param who element to remove
    function removeFromArray (address who) internal {
        uint index = nodes[who].index;
        if (index == 0) return;
        if (nodesArray.length != 0){
            if (nodesArray.length > 1) {
                nodesArray[index.sub(1)] = nodesArray[nodesArray.length.sub(1)];
                nodes[nodesArray[index.sub(1)]].index = index;
            }
            nodesArray.length --;
        }
    }
}
