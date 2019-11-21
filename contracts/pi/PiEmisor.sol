pragma solidity 0.5.0;

import "./PiComposition.sol";
import "../utils/safeMath.sol";
import "../tokens/ERC223_receiving_contract.sol";
import "../tokens/PiFiatToken.sol";

/// @author MIDLANTIC TECHNOLOGIES
/// @title A contract designed to handle the emission of PI

contract PiEmisor is ERC223ReceivingContract {
    using SafeMath for uint;

    struct Pending {
        bool isPending;
        uint change;
    }

    struct Increase {
        bool isIncrease;
        uint change;
    }
    
    struct Decrease {
        bool isDecrease;
        uint change;
        address sender;
    }

    mapping(address => bool) public acceptedTokens;
    mapping(address => Pending) public pendingTokens;
    mapping(address => Increase) public expectingIncrease;
    mapping(address => Decrease) public expectingDecrease;

    address payable rewards;

    PiComposition composition;

    event ReceivePi(address indexed user, uint piAmount);
    event RedeemPi(address indexed user, uint piAmount);
    event TokenAdded(address indexed token, uint change);

    constructor () public {
        composition = PiComposition(address(0x0000000000000000000000000000000000000011));
        acceptedTokens[address(0x0000000000000000000000000000000000000014)] = true;
        rewards = address(0x0000000000000000000000000000000000000009);
    }

    /// @dev Function to remove circulating
    function removeCirculating() external payable {
      composition.modifyBalance(address(this), msg.value, false);
      composition.recalculate();
    }

    /// @dev Receive PI and send tokens in composition
    function sellPi() external payable {
        address[] memory compositionTokenAddress;
        uint[] memory compositionTokenAmount;
        (compositionTokenAddress, compositionTokenAmount) = composition.getComposition();
        for (uint i = 0; i < compositionTokenAddress.length; i++) {
            if (compositionTokenAmount[i] != 0) {
                IRC223 token = IRC223(compositionTokenAddress[i]);
                uint amount = msg.value.mul(compositionTokenAmount[i]).div(1 ether).mul(99).div(100);
                token.transfer(msg.sender, amount);
                composition.modifyBalance(compositionTokenAddress[i], amount, false);
            }
        }
        rewards.transfer(msg.value.mul(5).div(1000));
        composition.modifyBalance(address(this), msg.value.mul(995).div(1000), false);
        circulating -= msg.value.mul(995).div(1000);
        composition.recalculate();
    }

    /// @dev Add a pending token to receive the first transaction of the token
    /// @param newPendingToken address of the token
    /// @param _change change of the token
    function addPending (address newPendingToken, uint _change) public {
        require(msg.sender == address(0x0000000000000000000000000000000000000013));
        pendingTokens[newPendingToken].isPending = true;
        pendingTokens[newPendingToken].change = _change;
    }

    function increaseAmount (address tokenAddress, uint _change) public {
        require(msg.sender == address(0x0000000000000000000000000000000000000013));
        expectingIncrease[tokenAddress].isIncrease = true;
        expectingIncrease[tokenAddress].change = _change;
    }

    function decreaseAmount (address tokenAddress, uint _change, address _sender) public {
        require(msg.sender == address(0x0000000000000000000000000000000000000013));
        expectingDecrease[tokenAddress].isDecrease = true;
        expectingDecrease[tokenAddress].change = _change;
        expectingDecrease[tokenAddress].sender = _sender;
    }
    
    function executeDecrease (address tokenAddress) external payable {
        require(msg.sender == expectingDecrease[tokenAddress].sender);
        require(expectingDecrease[tokenAddress].isDecrease);
        expectingDecrease[tokenAddress].isDecrease = false;
        uint tokenAmount = msg.value.mul(expectingDecrease[tokenAddress].change).div(1 ether);
        PiFiatToken token = PiFiatToken(tokenAddress);
        require(tokenAmount <= token.balanceOf(address(this)));
        token.transfer(msg.sender, tokenAmount);
        composition.modifyBalance(address(this), msg.value, false);
        composition.modifyBalance(tokenAddress, tokenAmount, false);
        composition.recalculate();
    }

    function removeFromComposition(address tokenAddress) public {
        require(msg.sender == address(0x0000000000000000000000000000000000000013));
        composition.removeFromComposition(tokenAddress);
    }

    /// @dev Check if the token is accepted
    /// @param tokenAddress address of the token
    /// return bool True when accepted False when not accepted
    function isAcceptedToken(address tokenAddress) public view returns (bool) {
        return (pendingTokens[tokenAddress].isPending || acceptedTokens[tokenAddress]);
    }

    /// @dev Purchase certain amount of PI
    /// @param _value amount of PI to purchase
    function purchasePi(uint _value) public {
        address[] memory compositionTokenAddress;
        uint[] memory compositionTokenAmount;
        (compositionTokenAddress, compositionTokenAmount) = composition.getComposition();
        for (uint i = 0; i < compositionTokenAddress.length; i++) {
            if (compositionTokenAmount[i] != 0) {
                PiFiatToken token = PiFiatToken(compositionTokenAddress[i]);
                uint _tokenValue = _value.mul(compositionTokenAmount[i]).div(1 ether);
                token.charge(address(this), _tokenValue);
                composition.modifyBalance(compositionTokenAddress[i], _tokenValue, true);
            }
        }
        uint piAmount = _value.mul(99).div(100); //comprobar comision
        uint commission = _value.sub(piAmount);
        uint rewardsCommission = commission.mul(50).div(100);
        msg.sender.transfer(piAmount);
        rewards.transfer(rewardsCommission);
        composition.modifyBalance(address(this), piAmount.add(rewardsCommission), true);
        composition.recalculate();
        emit ReceivePi(msg.sender, piAmount);
    }

    /// @dev Function to receive token ERC223ReceivingContract
    /// @param _from account sending token
    /// @param _value amount of token
    function tokenFallback(address payable _from, uint _value) public {
        require(isAcceptedToken(msg.sender));
        if (!acceptedTokens[msg.sender]) {
            managePendingToken(_from, _value);
        } else if (expectingIncrease[msg.sender].isIncrease) {
            manageIncreasingToken(_from, _value);
        }
    }

    /// @dev Handle the reception of a pending token
    /// @param _from account sending the token
    /// @param _value amount of received tokens
    function managePendingToken(address payable _from, uint _value) internal {
        composition.addToken(msg.sender);
        composition.modifyBalance(msg.sender, _value, true);
        uint piAmount = _value.mul(pendingTokens[msg.sender].change).div(1 ether);
        composition.modifyBalance(address(this), piAmount, true);
        circulating += piAmount;
        _from.transfer(piAmount);
        composition.recalculate();
        addToken(msg.sender);
    }

    function manageIncreasingToken(address payable _from, uint _value) internal {
        composition.modifyBalance(msg.sender, _value, true);
        uint piAmount = _value.mul(expectingIncrease[msg.sender].change).div(1 ether);
        composition.modifyBalance(address(this), piAmount, true);
        _from.transfer(piAmount);
        composition.recalculate();
        expectingIncrease[msg.sender].isIncrease = false;
    }

    /// @dev Token added to the composition of PI
    /// @param newAcceptedToken address of the token
    function addToken (address newAcceptedToken) internal {
        pendingTokens[newAcceptedToken].isPending = false;
        acceptedTokens[newAcceptedToken] = true;
        emit TokenAdded(newAcceptedToken, pendingTokens[newAcceptedToken].change);
    }
}
