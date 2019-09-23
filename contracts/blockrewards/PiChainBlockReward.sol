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

    struct DayCommission {
        uint commission;
        uint nodesValue;
    }

    address systemAddress;
    uint blockSecond;
    uint dayCommission;
    uint nodesComission;
    uint projectComission;
    address payable emisorAddress;
    uint nodesValue;
    uint assigned;
    uint day;

    ValidatorSet validatorSet;
    ManageNodes manageNodes;

    mapping(uint => DayCommission) public commissionByDay;

    modifier onlySystem {
        require(msg.sender == systemAddress);
        _;
    }

    event WithdrawRewards(address indexed who, uint since, uint until, uint amount);

    constructor()
    	public
    {
        systemAddress = 0xffffFFFfFFffffffffffffffFfFFFfffFFFfFFfE;
        manageNodes = ManageNodes(address(0x0000000000000000000000000000000000000012));
        emisorAddress = address(0x0000000000000000000000000000000000000010);
        blockSecond = 17280;
        dayCommission = 0;
        nodesComission = 0;
        projectComission = 0;
        nodesValue = 0;
        assigned = 0;
        day = 0;
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

        if ((block.number % blockSecond) == 0) {
            if(address(this).balance > assigned) {
                dayCommission = address(this).balance.sub(assigned);
            } else {
                dayCommission = 0;
            }

            assigned = assigned.add(dayCommission);
            commissionByDay[day].commission = nodesComission;
            commissionByDay[day].nodesValue = manageNodes.getNodesValue();
            day++;
        }

        return (benefactors, rewards);
    }

    /// @dev Function used by node's owners to withdrawl rewards
    /// @param userDay Withdrawl rewards since day with number userDay (emergency)
    function withdrawRewards(uint userDay) public {
        require(manageNodes.isRewarded(msg.sender, day));
        uint fromDay = manageNodes.getFromDay(msg.sender);
        if (userDay > fromDay) {
            fromDay = userDay;
        }
        uint payedPrice = manageNodes.getPayedPrice(msg.sender);
        uint toPay = 0;
        for(uint i = fromDay; i < day; i++) {
            toPay = toPay.add(commissionByDay[i].commission.mul(payedPrice).div(commissionByDay[i].nodesValue));
        }

        manageNodes.modifyFromDay(msg.sender, day);
        assigned = assigned.sub(toPay);
        msg.sender.transfer(toPay);
        emit WithdrawRewards(msg.sender, fromDay, day, toPay);
    }

    /// @dev Function used by node's owners to see pending rewards
    /// @param userDay Rewards since day with number userDay (emergency)
    /// @return toPay Total pending rewards
    function seeRewards(uint userDay) public view returns (uint) {
        uint toPay = 0;

        if (manageNodes.isRewarded(msg.sender, day)) {
            uint fromDay = manageNodes.getFromDay(msg.sender);
            if (userDay > fromDay) {
                fromDay = userDay;
            }
            uint payedPrice = manageNodes.getPayedPrice(msg.sender);

            for(uint i = fromDay; i < day; i++) {
                toPay = toPay.add(commissionByDay[i].commission.mul(payedPrice).div(commissionByDay[i].nodesValue));
            }
        }

        return toPay;
    }

    function () external payable {

    }
}
