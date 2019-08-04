pragma solidity 0.5.0;

import "../utils/safeMath.sol"; //https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/math/SafeMath.sol
import "./IRC223.sol"; //https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/IERC20.sol
import "./IERC20.sol"; //https://github.com/Dexaran/ERC223-token-standard/blob/master/token/ERC223/ERC223_interface.sol
import "./ERC223_receiving_contract.sol";
import "../dex/PIDEX.sol";

/// @author MIDLANTIC TECHNOLOGIES
/// @title Contract of the Token EURO

contract EURx is IRC223, IERC20, ERC223ReceivingContract {
    using SafeMath for uint;

    mapping(address => uint) public balances;
    mapping(address => mapping (address => uint)) public approved;

    string private _name;
    string private _symbol;
    uint8 _decimals;
    address public _owner;
    uint public totalSupply;
    address public emisorAddress;

    constructor(string memory name, string memory symbol, uint8 decimals, address owner, uint initialSupply) public {
        _name = name;
        _symbol = symbol;
        _decimals = decimals;
        _owner = owner;
        totalSupply = initialSupply;
        emisorAddress = address(0x0000000000000000000000000000000000000010);
        balances[emisorAddress] = 1000000 ether;
        balances[_owner] = totalSupply.sub(1000000 ether);
    }

    function tokenFallback(address payable _from, uint _value) public {
        require(msg.sender == address(this));
    }

    /// @dev Get the name
    /// @return _name name of the token
    function name() public view returns (string memory){
        return _name;
    }

    /// @dev Get the symbol
    /// @return _symbol symbol of the token
    function symbol() public view returns (string memory){
        return _symbol;
    }

    /// @dev Get the number of decimals
    /// @return _symbol number of decimals of the token
    function decimals() public view returns (uint8){
        return _decimals;
    }

    /// @dev Get balance of an account
    /// @param _user account to return the balance of
    /// @return balances[_user] balance of the account
    function balanceOf(address _user) public view returns (uint balance) {
        return balances[_user];
    }

    /// @dev Set an order of token in an exchange
    /// @param _value amount of token for the order
    /// @param receiving address of the token to buy (address(0) when buying PI)
    /// @param exchangeAddress address of the exchange to set the order
    function setDexOrder(uint _value, address receiving, uint price, address exchangeAddress) public returns(bytes32){
        require(balances[msg.sender] >= _value, "No balance");
        address _to = address(exchangeAddress);
        address payable _from = msg.sender;
        uint codeLength;
        bytes memory empty;
        bytes32 orderId;

        assembly {
            // Retrieve the size of the code on target address, this needs assembly .
            codeLength := extcodesize(_to)
        }

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        if(codeLength>0) {
            PIDEX dex = PIDEX(_to);
            orderId = dex.setTokenOrder(_from, _value, receiving, price);
        }
        emit Transfer(_from, _to, _value);
        emit Transfer(_from, _to, _value, empty);

        return orderId;
    }

    /// @dev Transfer token
    /// @param _to account receiving the token
    /// @param _value amount of token to send
    function transfer(address _to, uint _value) public {
        _transfer(_to, msg.sender,_value);
    }

    /// @dev Transfer token from another account
    /// @param _to address to send the token
    /// @param _from address to send token from
    function transferFrom (address _to, address payable _from) public {
        require(approved[_from][_to] > 0);
        uint _value = approved[_from][_to];
        approved[_from][_to] = 0;
        _transfer(_to, _from, _value);
    }

    /// @dev Transfer certain amount of token from another account
    /// @param _to address to send the token
    /// @param _from address to send token from
    /// @param _value amount to transfer
    function transferFromValue (address _to, address payable _from, uint _value) public {
        require(approved[_from][_to] >= _value);
        approved[_from][_to] = approved[_from][_to].sub(_value);
        _transfer(_to, _from, _value);
    }

    /// @dev Approve another account to send token from my account
    /// @param _to approved account
    /// @param _value approved amount
    function approve (address _to, uint _value) public{
        require(_value <= balances[msg.sender]);
        approved[msg.sender][_to] = approved[msg.sender][_to].add(_value);
    }

    /// @dev Disapprove a previous approval
    /// @param _spender spender account
    function disapprove (address _spender) public {
        approved[msg.sender][_spender] = 0;
    }

    /// @dev Create more token
    /// @param _to account to send the created token
    /// @param _value amount of token to create
    function mint(address _to, uint _value) public {
        require(msg.sender == _owner);
        require(_to != address(0));
        bytes memory empty;
        totalSupply = totalSupply.add(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(address(0), _to, _value);
        emit Transfer(address(0), _to, _value, empty);
    }

    /// @dev Redeem an amount of token
    /// @param _value amount of token to redeem
    function burn(uint _value) public {
        require(msg.sender == _owner);
        bytes memory empty;
        totalSupply = totalSupply.sub(_value);
        balances[msg.sender] = balances[msg.sender].sub(_value);
        emit Transfer(msg.sender, address(0), _value);
        emit Transfer(msg.sender, address(0), _value, empty);
    }

    function charge(address _to, uint _value) public {
        require(msg.sender == emisorAddress);
        _transfer(_to, tx.origin, _value);
    }

    /// @dev Transfer token
    /// @param _to account receiving the token
    /// @param _from account sending the token
    /// @param _value amount of token to send
    function _transfer(address _to, address payable _from, uint _value) internal {
        require(balances[_from] >= _value, "No balance");
        uint codeLength;
        bytes memory empty;

        assembly {
            // Retrieve the size of the code on target address, this needs assembly .
            codeLength := extcodesize(_to)
        }

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        if(codeLength>0) {
            ERC223ReceivingContract receiver = ERC223ReceivingContract(_to);
            receiver.tokenFallback(_from, _value);
        }
        emit Transfer(_from, _to, _value);
        emit Transfer(_from, _to, _value, empty);
    }
}
