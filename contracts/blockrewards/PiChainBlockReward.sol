// Copyright 2018 Parity Technologies (UK) Ltd.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//    http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

// Example block reward contract.

pragma solidity 0.5.0;

import "./BlockReward.sol";
import "../utils/safeMath.sol";
import "../validators/interfaces/ValidatorSet.sol";
import "../utils/Owned.sol";
import "../nodes/ManageNodes.sol";

contract PiChainBlockReward is BlockReward, Owned {
    using SafeMath for uint;

    address systemAddress;
    address validatorsAddress;
    uint blockSecond;
    uint dayCommission;
    uint nodesComission;
    uint projectComission;
    uint payPerBlock;
    address payable emisorAddress;
    uint lastPayed;
    uint nodesValue;

    ValidatorSet validatorSet;
    ManageNodes manageNodes;

    mapping(address => bool) public onlineValidators;
    mapping(address => bool) public offlineValidators;

    modifier onlySystem {
        require(msg.sender == systemAddress);
        _;
    }

    constructor()
    	public
    {
        systemAddress = 0xffffFFFfFFffffffffffffffFfFFFfffFFFfFFfE;
        validatorsAddress = address(0);
        manageNodes = ManageNodes(address(0x0000000000000000000000000000000000000012));
        emisorAddress = address(0x0000000000000000000000000000000000000010);
        blockSecond = 100;
        payPerBlock = 250;
        dayCommission = 0;
        nodesComission = 0;
        projectComission = 0;
        lastPayed = 0;
        nodesValue = 0;
    }

    // produce rewards for the given benefactors, with corresponding reward codes.
    // only callable by `SYSTEM_ADDRESS`
    function reward(address[] calldata benefactors, uint16[] calldata kind)
    	external
    	onlySystem
    	returns (address[] memory, uint256[] memory)
    {
        require(benefactors.length == kind.length);
        uint256[] memory rewards = new uint256[](benefactors.length);

        if(validatorsAddress != address(0)) {
            for (uint i = 0; i < benefactors.length; i++) {
                onlineValidators[benefactors[i]] = true;
            }

            address[] memory currentValidatorList = validatorSet.getValidators();

            if ((block.number % currentValidatorList.length) == 0) {
                for (uint j = 0; j < currentValidatorList.length; j++) {
                    if(!onlineValidators[currentValidatorList[j]]) {
                        offlineValidators[currentValidatorList[j]] = true;
        		        }
                    onlineValidators[currentValidatorList[j]] = false;
                }
        		}

            if ((block.number % blockSecond) == 0) {
                address payable[] memory validNodes = manageNodes.getNodes();
                if (blockSecond == 100) {
                    dayCommission = address(this).balance;
                    nodesComission = dayCommission.mul(5).div(10);
                    projectComission = nodesComission;
                    emisorAddress.transfer(projectComission);
                    lastPayed = 0;
                    if (validNodes.length < payPerBlock) {
                        payPerBlock = validNodes.length;
                    }
                    nodesValue = manageNodes.getNodesValue();
                }
                uint currentLastPayed = 0;
                if (lastPayed.add(payPerBlock) < validNodes.length) {
                    currentLastPayed = lastPayed.add(payPerBlock);
                    blockSecond++;
                } else {
                    currentLastPayed = validNodes.length;
                    blockSecond = 100;
                }

                for (uint i = lastPayed; i < currentLastPayed; i++) {
                    if (!offlineValidators[validNodes[i]]) {
                        uint payedPrice = manageNodes.getPayedPrice(validNodes[i]);
                        uint nodeCommission = nodesComission.mul(payedPrice).div(nodesValue);
                        validNodes[i].transfer(nodeCommission);
                    }
                    lastPayed = i;
                }
                if (currentLastPayed == validNodes.length) {
                    for (uint j = 0; j < currentValidatorList.length; j++) {
                        offlineValidators[currentValidatorList[j]] = false;
                    }

                    lastPayed = 0;
                }
        		}
      	}

        return (benefactors, rewards);
    }

    function setValidatorAddress(address _validatorsAddress) public onlyOwner {
        require(validatorsAddress == address(0));
        validatorsAddress = _validatorsAddress;
        validatorSet = ValidatorSet(validatorsAddress);
    }

    function () external payable {

    }
}
