pragma solidity 0.5.0;

import "../utils/safeMath.sol";
import "../tokens/ERC223_receiving_contract.sol";
import "../tokens/IRC223.sol";

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
        uint side;
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
    mapping(address => uint) public salt;
    mapping(address => mapping(bytes32 => uint)) public setInBlock;

    address private _dex;
    uint public cancelBlocks;

    constructor (address dex) public {
        _dex = dex;
        cancelBlocks = 12;
    }

    event SetOrder(address indexed owner, address indexed buying, address indexed selling, uint amount, uint price, bytes32 id);
    event CancelOrder(address indexed owner, address indexed buying, address indexed selling, uint amount, uint price, bytes32 id);
    event Deal(bytes32 indexed id, bytes32 orderA, bytes32 orderB);

    function getDeals(bytes32 _orderId) public view returns (bytes32[] memory, bytes32[] memory, uint[] memory) {
        require(orders[_orderId].dealed);
        return (orders[_orderId].deals, orders[_orderId].dealsOrders, orders[_orderId].dealsAmounts);
    }

    function changeDex(address newDex) public {
        require(msg.sender == _dex);
        _dex = newDex;
    }

    function changeCancelBlocks(uint nBlocks) public {
        require(msg.sender == _dex);
        cancelBlocks = nBlocks;
    }

    /// @dev set an order selling PI
    /// @param receiving address of the token to buy
    /// @param price the price of the order
    function setPiOrder(address receiving, uint price, uint side) external payable returns (bytes32) {
        bytes32 orderId = setOrder(msg.sender, address(0), msg.value, receiving, price, side);
        return orderId;
    }

    /// @dev set an order selling a token
    /// @param owner the owner of the order
    /// @param amount amount of token to sell
    /// @param receiving address of the token to buy (address(0) when buying PI)
    /// @param price the price of the order
    function setTokenOrder(address payable owner, uint amount, address receiving, uint price, uint side) public returns (bytes32) {
        require(listedTokens[msg.sender]);
        bytes32 orderId = setOrder(owner, msg.sender, amount, receiving, price, side);
        return orderId;
    }

    /// @dev Cancel an order
    /// @param orderId identifier of the order to cancel
    function cancelOrder(bytes32 orderId) public {
        require(msg.sender == orders[orderId].owner);
        require(orders[orderId].open && !orders[orderId].cancelled);
        require(setInBlock[msg.sender][orderId].add(cancelBlocks) < block.number);
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
        uint finalAmountA;
        uint finalAmountB;

        if (orders[orderA].side == 1) {
            finalAmountA = orders[orderA].amount;
            finalAmountB = orders[orderB].amount.mul(1 ether).div(orders[orderB].price);
        } else {
            finalAmountA = orders[orderA].amount.mul(1 ether).div(orders[orderA].price);
            finalAmountB = orders[orderB].amount;
        }

        uint finalAmount;

        // Partial orders
        if(finalAmountA > finalAmountB) {
            finalAmount = finalAmountB;
        } else {
            finalAmount = finalAmountA;
        }

        uint auxA = finalAmountA.sub(finalAmount);
        uint auxB = finalAmountB.sub(finalAmount);

        //Desnormalizamos
        //uint finalAmountAc;
        //uint finalAmountBc;
        uint rest;

        if (orders[orderA].side == 1) {
            finalAmountA = finalAmount;
            finalAmountB = finalAmount.mul(orders[orderB].price).div(1 ether);
        } else {
            finalAmountA = finalAmount.mul(orders[orderB].price).div(1 ether);
            rest = finalAmount.mul(orders[orderA].price).div(1 ether);
            rest = rest.sub(finalAmountA);
            finalAmountB = finalAmount;
        }

        bytes32 dealId = bytes32(keccak256(abi.encodePacked(block.timestamp, orderA, orderB, orders[orderA].nonce, orders[orderB].nonce, finalAmountA, finalAmountB)));



        checkDeal(orderA, orderB, finalAmountA, dealId, auxA);
        checkDeal(orderB, orderA, finalAmountB, dealId, auxB);

        //Transferir fondos

        //Transferir a A
        if (orders[orderA].receiving == address(0)) {
            orders[orderA].owner.transfer(finalAmountB);
        } else {
            IRC223 token = IRC223(address(orders[orderA].receiving));
            token.transfer(orders[orderA].owner, finalAmountB);
        }

        if (orders[orderA].sending == address(0)) {
            if ((auxA <= 0) && (rest > 0)) {
                orders[orderA].owner.transfer(rest);
            }
        } else {
            if ((auxA <= 0) && (rest > 0)) {
                IRC223 token = IRC223(address(orders[orderA].sending));
                token.transfer(orders[orderA].owner, rest);
            }
        }

        //Transferir a B
        if (orders[orderB].receiving == address(0)) {
            orders[orderB].owner.transfer(finalAmountA);
        } else {
            IRC223 token = IRC223(address(orders[orderB].receiving));
            token.transfer(orders[orderB].owner, finalAmountA);
        }

        emit Deal(dealId, orderA, orderB);
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
        require(listedTokens[msg.sender]);
    }

    /// @dev Set a new order in the exchange
    /// @param owner the owner of the order
    /// @param sending address of the token to sell (address(0) when selling PI)
    /// @param amount amount of PI/token to sell
    /// @param receiving address of the token to buy (address(0) when buying PI)
    /// @param price the price of the order
    /// @return orderId identifier of the order
    function setOrder(address payable owner, address sending, uint amount, address receiving, uint price, uint side) internal returns (bytes32) {
        bytes32 orderId = bytes32(keccak256(abi.encodePacked(block.timestamp, sending, receiving, amount, price, side, salt[owner])));
        require(!orders[orderId].open && !orders[orderId].cancelled && !orders[orderId].dealed);
        salt[owner]++;
        setInBlock[msg.sender][orderId] = block.number;
        orders[orderId].owner = owner;
        orders[orderId].sending = sending;
        orders[orderId].receiving = receiving;
        orders[orderId].amount = amount;
        orders[orderId].price = price;
        orders[orderId].side = side;
        orders[orderId].open = true;
        emit SetOrder(orders[orderId].owner, orders[orderId].sending, orders[orderId].receiving, orders[orderId].amount, orders[orderId].price, orderId);
        return orderId;
    }

    function checkDeal (bytes32 _orderId, bytes32 _matchingOrder, uint _amount, bytes32 _dealId, uint _aux) internal {
        if (orders[_orderId].amount > _amount) {
            orders[_orderId].amount = orders[_orderId].amount.sub(_amount);
        }

        if (_aux <= 0) {
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
}
