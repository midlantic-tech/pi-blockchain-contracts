pragma solidity 0.5.0;

import "../utils/safeMath.sol";
import "../nodes/ManageNodes.sol";
import "../pi/PiEmisor.sol";

/// @author MIDLANTIC TECHNOLOGIES
/// @title A contract designed to handle ballots

contract PiBallot {
    using SafeMath for uint;

    struct Ballot {
        bool open;
        bool isFederal;
        bool isAssociation;
        bool addPending;
        bool removePending;
        bool removeAssociation;
        bool addAssociation;
        bool validatorChangeSpecial;
        bool isClosingBallot;
        address who;
        uint change;
        address[] validatorsChange;
        bytes32 closingBallot;
        uint voteCount;
    }

    struct Proposal {
        bool open;
        uint voteCount;
    }

    mapping(address => bool) public isAssociation;
    mapping(bytes32 => Ballot) public ballots;
    mapping(bytes32 => Proposal) public proposals;
    mapping(address => bool) public associationVoter;
    mapping(bytes32 => mapping(address => bool)) public voted;
    mapping(address => bool) public addedToken;

    uint public associationVoterCounter;
    uint public salt;

    ManageNodes manageNodes;
    PiEmisor emisor;

    event AddAssociationMember(address indexed member, address indexed association);
    event RemoveAssociationMember(address indexed member, address indexed association);
    event BallotCreated(bytes32 indexed id, address indexed creator);
    event SuccessfulBallot(bytes32 indexed id);
    event AddAssociation(address indexed newAssociation);
    event RemoveAssociation(address indexed newAssociation);

    constructor () public {
        manageNodes = ManageNodes(address(0x0000000000000000000000000000000000000012));
        emisor = PiEmisor(address(0x0000000000000000000000000000000000000010));
        addedToken[address(0x0000000000000000000000000000000000000014)] = true;
    }

    /// @dev Association adds a new member
    /// @param newAssociationMember address of the new member
    function addAssociationMember(address newAssociationMember) public {
        require(isAssociation[msg.sender]);
        associationVoter[newAssociationMember] = true;
        associationVoterCounter++;
        emit AddAssociationMember(newAssociationMember, msg.sender);
    }

    /// @dev Association removes a new member
    /// @param oldAssociationMember address of the member to remove
    function removeAssociationMember(address oldAssociationMember) public {
        require(isAssociation[msg.sender]);
        associationVoter[oldAssociationMember] = false;
        associationVoterCounter--;
        emit RemoveAssociationMember(oldAssociationMember, msg.sender);
    }

    /// @dev Association opens a proposal identified by a hash
    /// @param proposalId identifier of the proposal
    function openProposal(bytes32 proposalId) public {
        require(isAssociation[msg.sender]);
        require(!proposals[proposalId].open);
        proposals[proposalId].open = true;
    }

    /// @dev Members of any Association vote for a certain proposal
    /// @param proposalId identifier of the proposal
    function voteProposal(bytes32 proposalId) public {
        require(proposals[proposalId].open);
        require(associationVoter[msg.sender] && !voted[proposalId][msg.sender]);
        proposals[proposalId].voteCount++;
        voted[proposalId][msg.sender] = true;
    }

    /// @dev Federation opens a ballot to include a new token in Emisor's composition
    /// @param tokenAddress Address of the token to inlcuide
    /// @param change Initial conversion Token/Pi
    /// @return ballotId identifier of the Ballot
    function openBallotAddPending(address tokenAddress, uint change) public returns(bytes32) {
        require(manageNodes.isValidator(msg.sender));
        salt++;
        bytes32 ballotId = bytes32(keccak256(abi.encodePacked(block.timestamp, tokenAddress, salt, msg.sender)));
        ballots[ballotId].open = true;
        ballots[ballotId].who = tokenAddress;
        ballots[ballotId].change = change;
        ballots[ballotId].isFederal = true;
        ballots[ballotId].addPending = true;
        emit BallotCreated(ballotId, msg.sender);
        return ballotId;
    }

    /// @dev Federation opens a ballot to remove a token from Emisor's composition
    /// @param tokenAddress Address of the token to remove
    /// @return ballotId identifier of the Ballot
    function openBallotRemovePending(address tokenAddress) public returns(bytes32) {
        require(manageNodes.isValidator(msg.sender));
        salt++;
        bytes32 ballotId = bytes32(keccak256(abi.encodePacked(block.timestamp, tokenAddress, salt, msg.sender)));
        ballots[ballotId].open = true;
        ballots[ballotId].who = tokenAddress;
        ballots[ballotId].isFederal = true;
        ballots[ballotId].removePending = true;
        emit BallotCreated(ballotId, msg.sender);
        return ballotId;
    }

    function openBallotDecreaseAmount(address tokenAddress, uint _change) public returns(bytes32) {
        require(manageNodes.isValidator(msg.sender));
        salt++;
        bytes32 ballotId = bytes32(keccak256(abi.encodePacked(block.timestamp, tokenAddress, salt, msg.sender)));
        ballots[ballotId].open = true;
        ballots[ballotId].who = tokenAddress;
        ballots[ballotId].isFederal = true;
        ballots[ballotId].removePending = true;
        ballots[ballotId].change = _change;
        emit BallotCreated(ballotId, msg.sender);
        return ballotId;
    }

    /// @dev Federation opens a ballot to add a new Association
    /// @param newAssociation Address of the new association
    /// @return ballotId identifier of the Ballot
    function openBallotAddAssociation(address newAssociation) public returns(bytes32) {
        require(manageNodes.isValidator(msg.sender));
        salt++;
        bytes32 ballotId = bytes32(keccak256(abi.encodePacked(block.timestamp, newAssociation, salt, msg.sender)));
        ballots[ballotId].open = true;
        ballots[ballotId].who = newAssociation;
        ballots[ballotId].isFederal = true;
        ballots[ballotId].addAssociation = true;
        emit BallotCreated(ballotId, msg.sender);
        return ballotId;
    }

    /// @dev Federation opens a ballot to remove an Association
    /// @param oldAssociation Address of the association to remove
    /// @return ballotId identifier of the Ballot
    function openBallotRemoveAssociation(address oldAssociation) public returns(bytes32) {
        require(manageNodes.isValidator(msg.sender));
        salt++;
        bytes32 ballotId = bytes32(keccak256(abi.encodePacked(block.timestamp, oldAssociation, salt, msg.sender)));
        ballots[ballotId].open = true;
        ballots[ballotId].who = oldAssociation;
        ballots[ballotId].isFederal = true;
        ballots[ballotId].removeAssociation = true;
        emit BallotCreated(ballotId, msg.sender);
        return ballotId;
    }

    /// @dev Federation opens a ballot to change a Validator (emergency)
    /// @param _oldLeader wallet of the current validator
    /// @param _newLeader wallet of the new validator
    /// @return ballotId identifier of the Ballot
    function openBallotValidatorChangeSpecial (address _oldLeader, address _newLeader) public returns(bytes32) {
        require(manageNodes.isValidator(msg.sender));
        uint nodeIndex = manageNodes.getNodeIndex(_oldLeader);
        salt++;
        bytes32 ballotId = bytes32(keccak256(abi.encodePacked(block.timestamp, salt, _oldLeader, _newLeader, msg.sender)));
        ballots[ballotId].open = true;
        ballots[ballotId].isFederal = true;
        ballots[ballotId].validatorChangeSpecial = true;
        ballots[ballotId].validatorsChange.push(_oldLeader);
        ballots[ballotId].validatorsChange.push(_newLeader);
        emit BallotCreated(ballotId, msg.sender);
        return ballotId;
    }

    /// @dev Federation opens a ballot to close another ballot (emergency)
    /// @param closingBallot ID of the ballot to close
    /// @return ballotId identifier of the Ballot
    function openBallotCloseBallot (bytes32 closingBallot) public returns(bytes32) {
        require(manageNodes.isValidator(msg.sender));
        require(ballots[closingBallot].open);
        salt++;
        bytes32 ballotId = bytes32(keccak256(abi.encodePacked(block.timestamp, salt, closingBallot, msg.sender)));
        ballots[ballotId].open = true;
        ballots[ballotId].isFederal = true;
        ballots[ballotId].isClosingBallot = true;
        ballots[ballotId].closingBallot = closingBallot;
        emit BallotCreated(ballotId, msg.sender);
        return ballotId;
    }

    /// @dev Association opens a ballot to change a Validator
    /// @param _oldLeader wallet of the current validator
    /// @param _newLeader wallet of the new validator
    /// @return ballotId identifier of the Ballot
    function openBallotValidatorChange (address _oldLeader, address _newLeader) public returns(bytes32) {
        require(isAssociation[msg.sender]);
        uint nodeIndex = manageNodes.getNodeIndex(_oldLeader);
        require(nodeIndex > 5);
        salt++;
        bytes32 ballotId = bytes32(keccak256(abi.encodePacked(block.timestamp, salt, _oldLeader, _newLeader, msg.sender)));
        ballots[ballotId].open = true;
        ballots[ballotId].isAssociation = true;
        ballots[ballotId].validatorsChange.push(_oldLeader);
        ballots[ballotId].validatorsChange.push(_newLeader);
        emit BallotCreated(ballotId, msg.sender);
        return ballotId;
    }

    /// @dev Members of any Association vote for a certain Ballot
    /// @param _ballotId identifier of the ballot
    /// @param userVote vote: True for YES
    function voteAssociation (bytes32 _ballotId, bool userVote) public {
        require(ballots[_ballotId].open);
        require(associationVoter[msg.sender] && !voted[_ballotId][msg.sender]);
        if (userVote) {
            ballots[_ballotId].voteCount ++;
        }
        voted[_ballotId][msg.sender] = true;
        bool success = checkBallot(_ballotId);
        if (success) {
            manageNodes.changeValidatorsPending(ballots[_ballotId].validatorsChange[0], ballots[_ballotId].validatorsChange[1]);
        }
    }

    /// @dev Members of Federation vote for a certain Ballot
    /// @param _ballotId identifier of the ballot
    /// @param userVote vote: True for YES
    function voteFederal(bytes32 _ballotId, bool userVote) public {
        require(manageNodes.isValidator(msg.sender));
        require(ballots[_ballotId].open);
        require(ballots[_ballotId].isFederal);
        require(!voted[_ballotId][msg.sender]);
        if (userVote) {
            ballots[_ballotId].voteCount ++;
        }
        voted[_ballotId][msg.sender] = true;
        bool success = checkBallot(_ballotId);
        if(success) {
            if(ballots[_ballotId].addPending) {
                if (!addedToken[ballots[_ballotId].who]) {
                    emisor.addPending(ballots[_ballotId].who, ballots[_ballotId].change);
                    addedToken[ballots[_ballotId].who] = true;
                } else {
                    emisor.increaseAmount(ballots[_ballotId].who, ballots[_ballotId].change);
                }
            } else if (ballots[_ballotId].addAssociation) {
                addAssociation(ballots[_ballotId].who);
            } else if (ballots[_ballotId].removeAssociation) {
                removeAssociation(ballots[_ballotId].who);
            } else if (ballots[_ballotId].validatorChangeSpecial) {
                manageNodes.changeValidatorsPending(ballots[_ballotId].validatorsChange[0], ballots[_ballotId].validatorsChange[1]);
            } else if (ballots[_ballotId].isClosingBallot) {
                ballots[ballots[_ballotId].closingBallot].open = false;
            } else if (ballots[_ballotId].removePending) {
                if (ballots[_ballotId].change == 0) {
                    emisor.removeFromComposition(ballots[_ballotId].who);
                } else {
                    emisor.decreaseAmount(ballots[_ballotId].who, ballots[_ballotId].change, msg.sender);
                }
            }
        }
    }

    /// @dev Checks success of the ballot
    /// @param _ballotId identifier of the ballot
    function checkBallot (bytes32 _ballotId) internal returns(bool) {
        if (ballots[_ballotId].isAssociation) {
            if (ballots[_ballotId].voteCount > associationVoterCounter.div(2)) {
                ballots[_ballotId].open = false;
                emit SuccessfulBallot(_ballotId);
                return true;
            }  else {
                return false;
            }
        } else if (ballots[_ballotId].isFederal) {
            if (ballots[_ballotId].voteCount >= 7) {
                ballots[_ballotId].open = false;
                emit SuccessfulBallot(_ballotId);
                return true;
            }  else {
                return false;
            }
        }
    }

    /// @dev Add an Association
    /// @param newAssociation wallet of the Association
    function addAssociation (address newAssociation) internal {
        isAssociation[newAssociation] = true;
        emit AddAssociation(newAssociation);
    }

    /// @dev Remove an association 
    /// @param oldAssociation Association to remove
    function removeAssociation (address oldAssociation) internal {
        isAssociation[oldAssociation] = false;
        emit RemoveAssociation(oldAssociation);
    }
}
