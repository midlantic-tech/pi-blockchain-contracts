// Copyright 2018 Parity Technologies (UK) Ltd.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

pragma solidity ^0.5.0;

import "../../utils/safeMath.sol";

interface Bridge {
    function relayMessage(bytes calldata data, address recipient)
    external;
}

interface BridgeRecipient {
    function acceptMessage(bytes calldata data, address sender)
    external;
}

interface ERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract IRC223 {
    uint public totalSupply;
    function balanceOf(address who) public view returns (uint);

    function transfer(address to, uint value) public;
    function transferFrom (address _to, address _from) public;

    event Transfer(address indexed from, address indexed to, uint value, bytes indexed data);
}

contract ERC223ReceivingContract {
    function tokenFallback(address payable _from, uint _value) public;
}


contract ERC20BridgeRecipient is BridgeRecipient, ERC223ReceivingContract {
    event Deposit(address indexed from, address indexed recipient, uint256 value);
    event Withdraw(address indexed recipient, uint256 value);

    address public bridgedRecipientAddress;
    Bridge public bridge;
    mapping(address => uint) deposited;

    IRC223 public erc223;

    constructor(address bridgeAddr, address bridgedRecipientAddr, address erc223Addr)
    public
    {
        bridgedRecipientAddress = bridgedRecipientAddr;
        bridge = Bridge(bridgeAddr);
        erc223 = IRC223(erc223Addr);
    }

    function deposit(address payable recipient, uint256 value)
    internal
    {
        bytes memory data = MessageSerialization.serializeMessage(recipient, value);
        bridge.relayMessage(data, bridgedRecipientAddress);

        emit Deposit(msg.sender, recipient, value);
    }

    function tokenFallback(address payable _from, uint _value) public {
        require(msg.sender == address(erc223));
        require(_from != address(0));
        require(_value > 0);
        deposit(_from, _value);
    }
}


contract NativeBridgeRecipient is BridgeRecipient {
    using SafeMath for uint256;

    struct Mint {
        address recipient;
        uint256 value;
    }

    event Minting(address indexed recipient, uint256 value);
    event Burned(uint256 value);

    address constant BURN_ADDRESS = address(0x0000000000000000000000000000000000000000);
    address constant SYSTEM_ADDRESS = address(0xffffFFFfFFffffffffffffffFfFFFfffFFFfFFfE);

    address public bridgedRecipientAddress;
    Bridge public bridge;
    mapping(address => uint) deposited;

    uint256 public totalSupply;

    Mint[] public minting;

    constructor(address bridgeAddr)
    public
    {
        bridge = Bridge(bridgeAddr);
    }

    function setBridgedRecipientAddress(address bridgedRecipientAddr)
    external
    {
        require(bridgedRecipientAddress == address(0));

        bridgedRecipientAddress = bridgedRecipientAddr;
    }

    function acceptMessage(bytes calldata data, address sender)
    external
    {
        require(bridgedRecipientAddress != address(0));

        require(msg.sender == address(bridge));
        require(sender == bridgedRecipientAddress);

        (address payable recipient, uint256 value) = MessageSerialization.deserializeMessage(data);
        mint(recipient, value);
    }

    function mint(address payable recipient, uint256 value)
    internal
    {
        recipient.transfer(value.mul(1 ether).div(100000)); //PENSAR SI HACER UN REQUIRE codelength 0
        totalSupply += value;
        emit Minting(recipient, value);
    }
}


library MessageSerialization {
    function serializeMessage(address payable recipient, uint256 value)
    external
    pure
    returns (bytes memory)
    {
        bytes memory buffer = new bytes(52);

        // solium-disable-next-line security/no-inline-assembly
        assembly {
            // buffer has a total of 84 bytes (32 bytes length + 52 bytes capacity)
            // we write the recipient address at offset 52 (84 - 32), and
            // afterwards we write the 32 bytes of the value at offset 32 (52 - 20)
            // overwriting the first 12 bytes of the previous write which will be set
            // to 0 (since address is only 20 bytes long).
            mstore(add(buffer, 52), recipient)
            mstore(add(buffer, 32), value)
        }

        return buffer;
    }

    function deserializeMessage(bytes memory buffer)
    public
    pure
    returns (address payable, uint256)
    {
        require(buffer.length == 52);

        address payable recipient;
        uint256 value;

        // solium-disable-next-line security/no-inline-assembly
        assembly {
            recipient := mload(add(buffer, 52))
            value := mload(add(buffer, 32))
        }

        return (recipient, value);
    }
}
