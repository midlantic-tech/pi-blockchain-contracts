pragma solidity 0.5.0;

contract Faucet {

    function getPi(address payable account) public {
        account.transfer(1000000000000000000000);
    }
}
