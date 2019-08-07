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

    mapping(address => bool) public acceptedTokens;
    mapping(address => Pending) public pendingTokens;

    uint public circulating;
    address payable rewards;

    PiComposition composition;

    event TokenTransfer(address, uint);

    constructor () public {
        composition = PiComposition(address(0x0000000000000000000000000000000000000011));
        acceptedTokens[address(0x0000000000000000000000000000000000000014)] = true;
        rewards = address(0x0000000000000000000000000000000000000009);
    }

    /// @dev Fallback function to remove circulating
    function () external payable {

    }

    /// @dev Receive PI and send tokens in composition
    function managePiReceived() external payable {
        address[] memory compositionTokenAddress;
        uint[] memory compositionTokenAmount;
        (compositionTokenAddress, compositionTokenAmount) = composition.getComposition();
        for (uint i = 0; i < compositionTokenAddress.length; i++) {
            IRC223 token = IRC223(compositionTokenAddress[i]);
            uint amount = msg.value.mul(compositionTokenAmount[i]).div(1 ether).mul(99).div(100);
            token.transfer(msg.sender, amount);
            composition.modifyBalance(compositionTokenAddress[i], amount, false);
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
            require(acceptedTokens[compositionTokenAddress[i]]);
            PiFiatToken token = PiFiatToken(compositionTokenAddress[i]);
            uint _tokenValue = _value.mul(compositionTokenAmount[i]).div(1 ether);
            token.charge(address(this), _tokenValue);
            composition.modifyBalance(compositionTokenAddress[i], _tokenValue, true);
        }
        uint piAmount = _value.mul(99).div(100); //comprobar comision
        uint commission = _value.sub(piAmount);
        uint rewardsCommission = commission.mul(50).div(100);
        msg.sender.transfer(piAmount);
        rewards.transfer(rewardsCommission);
        composition.modifyBalance(address(this), piAmount.add(rewardsCommission), true);
        composition.recalculate();
    }

    /// @dev Function to receive token ERC223ReceivingContract
    /// @param _from account sending token
    /// @param _value amount of token
    function tokenFallback(address payable _from, uint _value) public {
        require(isAcceptedToken(msg.sender));
        if (!acceptedTokens[msg.sender]) {
            managePendingToken(_from, _value);
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

    /// @dev Token added to the composition of PI
    /// @param newAcceptedToken address of the token
    function addToken (address newAcceptedToken) internal {
        pendingTokens[newAcceptedToken].isPending = false;
        acceptedTokens[newAcceptedToken] = true;
    }
}
