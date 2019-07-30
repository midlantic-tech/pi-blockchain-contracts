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
    mapping(uint => uint) public requiredBalance;
    address payable[] public nodesArray;
    uint public currentValidatorPrice;
    uint public sellValidatorPrice;
    uint public purchaseValidatorPrice;
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
        currentValidatorPrice = 6600000000000000000; // Value of the 11th node
        purchaseValidatorPrice = 6666000000000000000; // Purchase price of the 11th value
        purchaseCommission[purchaseValidatorPrice] = currentValidatorPrice;
        currentValidatorPrice = 5500000000000000000; // Value of the N-1 node
        sellValidatorPrice = 5445000000000000000; // Sell price of the 11th value
        sellCommission[sellValidatorPrice] = currentValidatorPrice;
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
        require(msg.value == purchaseValidatorPrice);
        nodes[msg.sender].payedPrice = purchaseValidatorPrice;
        nodesValue += purchaseValidatorPrice;
        nodesArray.push(msg.sender);
        globalIndex++;
        nodes[msg.sender].index = globalIndex;
        nodes[msg.sender].isHolder = true;
        emisorAddress.transfer(purchaseValidatorPrice.sub(purchaseCommission[purchaseValidatorPrice]));
        updateValidatorPrice();
    }

    /// @dev Sell the node you own
    function sellNode() public isNode(msg.sender) {
        require(!nodes[msg.sender].isValidator);
        removeFromArray(msg.sender);
        globalIndex--;
        msg.sender.transfer(sellValidatorPrice);
        emisorAddress.transfer(sellCommission[sellValidatorPrice].sub(sellValidatorPrice));
        nodes[msg.sender].isHolder = false;
        updateValidatorPrice();
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

    /// @dev Called by BlockReward contract to remove circulating the non required amount in this contract
    function withdrawRest() public {
        require(msg.sender == address(0x0000000000000000000000000000000000000009));
        emisorAddress.transfer(address(this).balance.sub(requiredBalance[globalIndex]));
    }

    /// @dev Update node's price when somebody buy/sell a node
    function updateValidatorPrice() internal {
        uint nodos = globalIndex;
        uint a = 100000;
        uint b = 200000;
        uint c = a.div(10);
        uint d = b.div(10);
        uint e = nodos.mul(c);
        uint f = e.add(c);
        currentValidatorPrice = e.mul(f).div(d);
        currentValidatorPrice = currentValidatorPrice.mul(1 ether).div(100000);
        purchaseValidatorPrice = currentValidatorPrice.mul(101).div(100);
        purchaseCommission[purchaseValidatorPrice] = currentValidatorPrice;
        nodos--;
        e = nodos.mul(c);
        f = e.add(c);
        currentValidatorPrice = e.mul(f).div(d);
        currentValidatorPrice = currentValidatorPrice.mul(1 ether).div(100000);
        sellValidatorPrice = currentValidatorPrice.mul(99).div(100);
        sellCommission[sellValidatorPrice] = currentValidatorPrice;
        requiredBalance[globalIndex] += currentValidatorPrice;
    }

    /// @dev Remove an element of an array
    /// @param who element to remove
    function removeFromArray (address who) internal {
        uint index = nodes[who].index;
        if (index == 0) return;
        if (nodesArray.length != 0){
            index--;
            if (nodesArray.length > 1) {
                for (uint i = index; i < nodesArray.length.sub(1); i++) {
                    nodesArray[i] = nodesArray[i.add(1)];
                    nodes[nodesArray[i]].index--;
                }
            }
            nodesArray.length --;
        }
    }
}
