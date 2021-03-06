pragma solidity 0.5.0;

import "../utils/safeMath.sol";
import "../validators/RelayedOwnedSet.sol";
import "../pi/PiEmisor.sol";

/// @author MIDLANTIC TECHNOLOGIES
/// @title Contract designed to handle node's market

contract ManageNodes {
    using SafeMath for uint;

    struct MasterNode {
        uint index;
        uint payedPrice;
        bool isValidator;
        bool isHolder;
        uint fromDay;
    }

    mapping(address => MasterNode) public nodes;
    mapping(address => mapping(address => bool)) public pendingValidatorChange;
    mapping(uint => uint) public purchaseCommission;
    mapping(uint => uint) public sellCommission;

    address payable[] public nodesArray;
    uint public currentNodePrice;
    uint public sellNodePrice;
    uint public purchaseNodePrice;
    uint public nodesValue;
    uint public globalIndex;
    PiEmisor emisor;
    address rewardsAddress;
    RelayedOwnedSet validatorSet;
    uint public blockSecond;

    modifier isNode(address _someone) {
        require(nodes[_someone].isValidator || nodes[_someone].isHolder);
        _;
    }

    modifier isNotNode(address _someone) {
        require(!nodes[_someone].isValidator && !nodes[_someone].isHolder);
        _;
    }

    event PurchaseNode(address indexed buyer, uint price, uint fromDay);
    event SellNode(address indexed seller, uint price);
    event CurrentNodeValue(uint, uint);
    event PendingValidatorChange(address indexed, address indexed);
    event ExecutedValidatorChange(address indexed, address indexed);

    constructor (address payable[] memory initialValidators) public {
        globalIndex = 1;

        //Loop for the 10 validator nodes
        for (uint i = 0; i < initialValidators.length; i++) {
            nodesArray.push(initialValidators[i]);
            nodes[initialValidators[i]].index = globalIndex;
            nodes[initialValidators[i]].isValidator = true;
            nodes[initialValidators[i]].payedPrice = 1 ether;
            globalIndex++;
            nodesValue += 1 ether; //price not really payed but they cannot sell
        }

        emisor = PiEmisor(address(0x0000000000000000000000000000000000000010));
        rewardsAddress = (address(0x0000000000000000000000000000000000000009));
        currentNodePrice = 6600000000000000000; // Value of the 11th node
        purchaseNodePrice = 6666000000000000000; // Purchase price of the 11th value
        purchaseCommission[purchaseNodePrice] = currentNodePrice;
        currentNodePrice = 5500000000000000000; // Value of the N-1 node
        sellNodePrice = 5445000000000000000; // Sell price of the 11th value
        sellCommission[sellNodePrice] = currentNodePrice;
        blockSecond = 17280;
    }

    /// @dev Set RelaySet contract's address when deployed
    /// @param newValidatorSetAddress Address of RelaySet
    function setValidatorSetAddress (address newValidatorSetAddress) public {
        require(address(validatorSet) == address(0));
        validatorSet = RelayedOwnedSet(newValidatorSetAddress);
    }

    /// @dev Getter for the array of nodes
    /// @return nodesArray array of nodes
    function getNodes() public view returns(address payable[] memory) {
        return nodesArray;
    }

    /// @dev Check if an address is a validator or not
    /// @param _node Address to check
    /// @return isValidator Boolean True if is Validator, False if not
    function isValidator(address _node) public view returns(bool) {
        return nodes[_node].isValidator;
    }

    /// @dev Get the index in the array of a node
    /// @param _node Address to check
    /// @return Index in the array
    function getNodeIndex(address _node) public view returns(uint) {
        return nodes[_node].index;
    }

    /// @dev Cummulated value of the nodes
    /// @return nodesValue Value of the nodes
    function getNodesValue() public view returns(uint) {
        return nodesValue;
    }

    /// @dev Getter for the payed price of the node
    /// @param _node account of the node to get the payed price
    /// @return payedPrice price
    function getPayedPrice(address _node) public view returns (uint){
        return nodes[_node].payedPrice;
    }

    /// @dev Get day of the last withdraw of node's rewards
    /// @param _node Address of the node
    /// @return fromDay Day number
    function getFromDay(address _node) public view returns (uint) {
        return nodes[_node].fromDay;
    }

    /// @dev Modify day of the last withdraw
    /// @param _node Address of the node
    /// @param day New last day
    function modifyFromDay(address _node, uint day) public {
        require(msg.sender == rewardsAddress);
        nodes[_node].fromDay = day;
    }

    /// @dev Check if a node can withdrawl rewards of a certain day
    /// @param _node Address of the node
    /// @param day Day
    /// @return Boolean True/False if Can/Cannot withdrawl
    function isRewarded(address _node, uint day) public view returns (bool) {
        return (((nodes[_node].isValidator) || (nodes[_node].isHolder)) && (day > nodes[_node].fromDay));
    }

    /// @dev Purchase the next node
    function purchaseNode() external payable isNotNode(msg.sender) {
        require(msg.value == purchaseNodePrice);
        nodes[msg.sender].payedPrice = purchaseNodePrice;
        nodesValue = nodesValue.add(purchaseNodePrice);
        nodesArray.push(msg.sender);
        nodes[msg.sender].index = globalIndex;
        nodes[msg.sender].isHolder = true;
        nodes[msg.sender].fromDay = block.number.div(blockSecond);
        globalIndex++;
        emisor.removeCirculating.value(purchaseNodePrice.sub(purchaseCommission[purchaseNodePrice]))();
        updateNodePrice();
        emit PurchaseNode(msg.sender, msg.value, nodes[msg.sender].fromDay);
    }

    /// @dev Sell the node you own
    function sellNode() public isNode(msg.sender) {
        require(!nodes[msg.sender].isValidator);
        removeFromArray(msg.sender);
        globalIndex--;
        nodesValue = nodesValue.sub(nodes[msg.sender].payedPrice);
        msg.sender.transfer(sellNodePrice);
        emisor.removeCirculating.value(sellCommission[sellNodePrice].sub(sellNodePrice))();
        nodes[msg.sender].isHolder = false;
        updateNodePrice();
        emit SellNode(msg.sender, sellNodePrice);
    }

    /// @dev Ballot contract call this function when there is successful ballot to allow the change of validator
    /// @param _oldValidator the current validator
    /// @param _newValidator the pending validator who can call changeValidatorsExecute function to execute the change
    function changeValidatorsPending(address _oldValidator, address _newValidator) public {
        require(msg.sender == address(0x0000000000000000000000000000000000000013));
        require(nodes[_oldValidator].isValidator);
        require(!nodes[_newValidator].isValidator);
        pendingValidatorChange[_oldValidator][_newValidator] = true;
        emit PendingValidatorChange(_oldValidator, _newValidator);
    }

    /// @dev Execute a pending validators change
    /// @param _oldValidator the current validator to pay it's payed node price
    function changeValidatorsExecute (address payable _oldValidator)
        external
        payable
    {
        require(pendingValidatorChange[_oldValidator][msg.sender]);
        require(msg.value == nodes[_oldValidator].payedPrice);
        nodesArray.push(msg.sender);
        removeFromArray(_oldValidator);
        nodes[_oldValidator].isValidator = false;
        nodes[msg.sender].isValidator = true;
        nodes[msg.sender].payedPrice = 1 ether;
        nodes[msg.sender].fromDay = block.number.div(blockSecond);
        validatorSet.removeValidator(_oldValidator);
        validatorSet.addValidator(msg.sender);
        pendingValidatorChange[_oldValidator][msg.sender] = false;
        _oldValidator.transfer(nodes[_oldValidator].payedPrice);
        emit ExecutedValidatorChange(_oldValidator, msg.sender);
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
        emit CurrentNodeValue(currentNodePrice, globalIndex.sub(1));
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
