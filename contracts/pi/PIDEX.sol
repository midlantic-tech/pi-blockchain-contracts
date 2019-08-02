pragma solidity 0.5.0;

import "../utils/safeMath.sol";
import "./ERC223_receiving_contract.sol";
import "./IRC223.sol";
import "./PiFiatToken.sol";

/// @author MIDLANTIC TECHNOLOGIES
/// @title Contract designed to handle orders in the Exchange

contract PIDEX is ERC223ReceivingContract {
    using SafeMath for uint;

    struct Order {
        uint nonce;
        address payable owner;
        address sending;
        address receiving;
        uint amount;
        uint price;
        bool open;
        bool close;
        bool cancelled;
        bool dealed;
        bytes32[] deals;
        bytes32[] dealsOrders;
        uint[] dealsAmounts;
    }

    mapping(bytes32 => Order) public orders;
    mapping(address => bool) public listedTokens;
    mapping(address => mapping(address => uint)) public receivedTokens;

    address private _dex;

    constructor (address dex) public {
        _dex = dex;
    }

    event SetOrder(address, address, address, uint, uint, bytes32);
    event CancelOrder(address, address, address, uint, uint, bytes32);
    event Deal(bytes32);

    function getDeals(bytes32 _orderId) public view returns (bytes32[] memory, bytes32[] memory, uint[] memory) {
        require(orders[_orderId].dealed);
        return (orders[_orderId].deals, orders[_orderId].dealsOrders, orders[_orderId].dealsAmounts);
    }

    /// @dev set an order selling PI
    /// @param receiving address of the token to buy
    /// @param price the price of the order
    function setPiOrder(address receiving, uint price) external payable returns (bytes32) {
        bytes32 orderId = setOrder(msg.sender, address(0), msg.value, receiving, price);
        return orderId;
    }

    /// @dev set an order selling a token
    /// @param owner the owner of the order
    /// @param amount amount of token to sell
    /// @param receiving address of the token to buy (address(0) when buying PI)
    /// @param price the price of the order
    function setTokenOrder(address payable owner, uint amount, address receiving, uint price) public returns (bytes32) {
        require(acceptedSender(msg.sender));
        bytes32 orderId = setOrder(owner, msg.sender, amount, receiving, price);
        return orderId;
    }

    /// @dev Cancel an order
    /// @param orderId identifier of the order to cancel
    function cancelOrder(bytes32 orderId) public {
        require(msg.sender == orders[orderId].owner);
        require(orders[orderId].open && !orders[orderId].cancelled);
        orders[orderId].open = false;
        orders[orderId].cancelled = true;
        if(orders[orderId].sending == address(0)) {
            msg.sender.transfer(orders[orderId].amount);
        } else {
            IRC223 token = IRC223(address(orders[orderId].sending));
            token.transfer(msg.sender, orders[orderId].amount);
        }
        emit CancelOrder(
            orders[orderId].owner,
            orders[orderId].sending,
            orders[orderId].receiving,
            orders[orderId].amount,
            orders[orderId].price,
            orderId
        );
    }

    /// @dev The exchange orders a deal between two orders
    /// @param orderA the older order
    /// @param orderB the more recent order
    /// @param side direction of the deal
    /// @return newOrderId identifier of the new order (bytes32(0) when none)
    function dealOrder(bytes32 orderA, bytes32 orderB, uint side) public returns (bytes32) {
        require(msg.sender == _dex);
        require(orders[orderA].open && orders[orderB].open);
        require(!orders[orderA].close && !orders[orderB].close);
        require(orders[orderA].sending == orders[orderB].receiving);
        require(orders[orderA].receiving == orders[orderB].sending);
        if (side == 1) {
            require(orders[orderA].price <= orders[orderB].price);
        } else if (side == 2) {
            require(orders[orderA].price >= orders[orderB].price);
        }
        uint amount;

        if (orders[orderA].amount < orders[orderB].amount) {
            amount = orders[orderA].amount;
        } else if (orders[orderA].amount > orders[orderB].amount) {
            amount = orders[orderB].amount;
        } else {
            amount = orders[orderA].amount;
        }

        //colision????;
        bytes32 dealId = bytes32(keccak256(abi.encodePacked(block.timestamp, orderA, orderB, orders[orderA].nonce, orders[orderB].nonce, amount)));

        checkDeal(orderA, orderB, amount, dealId);
        checkDeal(orderB, orderA, amount, dealId);

        if (orders[orderA].receiving == address(0)) {
            orders[orderA].owner.transfer(amount);
        } else {
            IRC223 token = IRC223(address(orders[orderA].receiving));
            token.transfer(orders[orderA].owner, amount);
        }

        if (orders[orderB].receiving == address(0)) {
            orders[orderB].owner.transfer(amount);
        } else {
            IRC223 token = IRC223(address(orders[orderB].receiving));
            token.transfer(orders[orderB].owner, amount);
        }

        emit Deal(dealId);
        return dealId;
    }

    /// @dev Add a new token to the exchange
    /// @param token address of the token to list
    function listToken(address token) public {
        require(msg.sender == _dex);
        listedTokens[token] = true;
    }

    /// @dev Function to receive token ERC223ReceivingContract
    /// @param _from account sending token
    /// @param _value amount of token
    function tokenFallback(address payable _from, uint _value) public {
        require(acceptedSender(msg.sender));
        receivedTokens[_from][msg.sender] = _value;
    }

    /// @dev Set a new order in the exchange
    /// @param owner the owner of the order
    /// @param sending address of the token to sell (address(0) when selling PI)
    /// @param amount amount of PI/token to sell
    /// @param receiving address of the token to buy (address(0) when buying PI)
    /// @param price the price of the order
    /// @return orderId identifier of the order
    function setOrder(address payable owner, address sending, uint amount, address receiving, uint price) internal returns (bytes32) {
        require(acceptedSender(sending));
        bytes32 orderId = bytes32(keccak256(abi.encodePacked(block.timestamp, owner, sending, receiving, amount, price)));
        require(!orders[orderId].open && !orders[orderId].cancelled && !orders[orderId].dealed);
        orders[orderId].owner = owner;
        orders[orderId].sending = sending;
        orders[orderId].receiving = receiving;
        orders[orderId].amount = amount;
        orders[orderId].price = price;
        orders[orderId].open = true;
        emit SetOrder(orders[orderId].owner, orders[orderId].sending, orders[orderId].receiving, orders[orderId].amount, orders[orderId].price, orderId);
        return orderId;
    }

    function checkDeal (bytes32 _orderId, bytes32 _matchingOrder, uint _amount, bytes32 _dealId) internal {
        if (orders[_orderId].amount > _amount) {
            orders[_orderId].amount = orders[_orderId].amount.sub(_amount);
        } else {
            orders[_orderId].amount = 0;
            orders[_orderId].open = false;
            orders[_orderId].close = true;
        }
        orders[_orderId].nonce ++;
        orders[_orderId].dealed = true;
        orders[_orderId].deals.push(_dealId);
        orders[_orderId].dealsOrders.push(_matchingOrder);
        orders[_orderId].dealsAmounts.push(_amount);
    }

    /// @dev Check if the sender is accepted
    /// @param sender address of the account calling the contract
    function acceptedSender(address sender) internal view returns (bool) {
        uint codeLength;

        assembly {
            // Retrieve the size of the code on target address, this needs assembly .
            codeLength := extcodesize(sender)
        }
        if(codeLength>0) {
            return listedTokens[sender];
        } else {
            return true;
        }
    }
}
