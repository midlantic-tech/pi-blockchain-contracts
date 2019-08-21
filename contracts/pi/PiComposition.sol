pragma solidity 0.5.0;

import "../utils/safeMath.sol";

/// @author MIDLANTIC TECHNOLOGIES
/// @title A contract designed to handle the composition of PI

contract PiComposition {
    using SafeMath for uint;

    struct Composition {
        address[] compositionTokenAddress;
        uint[] compositionTokenAmount;
    }

    mapping(address => uint) public emisorTokenBalance; //emisor's address indicate circulating amount of PI

    address[] tokens;
    uint[] balances;
    address public emisorAddress;
    Composition currentComposition;

    constructor() public {
        currentComposition.compositionTokenAddress.push(address(0x0000000000000000000000000000000000000014));
        currentComposition.compositionTokenAmount.push(1094980000000000000);
        emisorAddress = address(0x0000000000000000000000000000000000000010);
        emisorTokenBalance[emisorAddress] = 53000 ether;
        emisorTokenBalance[address(0x0000000000000000000000000000000000000014)] = 58033940000000000000000;
    }

    /// @dev Returns the current composition
    /// @return currentComposition.compositionTokenAddress array with addresses of the tokens in PI's composition
    /// @return currentComposition.compositionTokenAmount array with the change of the tokens in PI's composition
    function getComposition() public view returns(address[] memory, uint[] memory) {
        return (currentComposition.compositionTokenAddress, currentComposition.compositionTokenAmount);
    }

    function getEmisorBalances() public returns(address[] memory, uint[] memory) {
        tokens.length = 0;
        balances.length = 0;

        tokens.push(emisorAddress);
        balances.push(emisorTokenBalance[emisorAddress]);

        for (uint i = 0; i < currentComposition.compositionTokenAddress.length; i++) {
            tokens.push(currentComposition.compositionTokenAddress[i]);
            balances.push(emisorTokenBalance[currentComposition.compositionTokenAddress[i]]);
        }

        return (tokens, balances);
    }

    /// @dev Handle the balance of Emisor Contract
    /// @param modifiedToken address of the token to modify the balance
    /// @param tokenAmount amount of PI/token to modify
    /// @param sign True when adding and False when substracting
    function modifyBalance(address modifiedToken, uint tokenAmount, bool sign) public {
        require(msg.sender == emisorAddress);
        if (sign) {
            emisorTokenBalance[modifiedToken] = emisorTokenBalance[modifiedToken].add(tokenAmount);
        } else {
            emisorTokenBalance[modifiedToken] = emisorTokenBalance[modifiedToken].sub(tokenAmount);
        }
    }

    /// @dev Add a token to the composition of PI
    /// @param newTokenAddress address of the token to add
    function addToken(address newTokenAddress) public {
        require(msg.sender == emisorAddress);
        currentComposition.compositionTokenAddress.push(newTokenAddress);
        currentComposition.compositionTokenAmount.push(0);
    }

    function removeFromComposition(address tokenAddress) public {
        require(msg.sender == emisorAddress);
        emisorTokenBalance[tokenAddress] = 0;
        recalculate();
    }

    /// @dev Recalculate changes of the composition of PI based on Emisor's balances and circulating PI
    function recalculate() public {
        require(msg.sender == emisorAddress);
        for (uint i = 0; i < currentComposition.compositionTokenAddress.length; i++) {
            currentComposition.compositionTokenAmount[i] = emisorTokenBalance[currentComposition.compositionTokenAddress[i]]
                .mul(1 ether)
                .div(emisorTokenBalance[emisorAddress]);
        }
    }
}
