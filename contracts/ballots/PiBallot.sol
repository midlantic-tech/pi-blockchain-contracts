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
        bool close;
        bool isFederal;
        bool isAssociation;
        bool addPending;
        bool addAssociation;
        address who;
        address oldLeader;
        address newLeader;
        uint voteCount;
    }

    struct Proposal {
        bool open;
        uint voteCount;
    }

    mapping(address => bool) isAssociation;
    mapping(bytes32 => Ballot) public ballots;
    mapping(bytes32 => Proposal) public proposals;
    mapping(address => bool) associationVoter;
    mapping(bytes32 => mapping(address => bool)) voted;

    uint associationVoterCounter;
    uint salt;
    uint globalIndex;

    ManageNodes manageNodes;
    PiEmisor emisor;

    event BallotCreated(bytes32);

    constructor () public {
        manageNodes = ManageNodes(address(0x0000000000000000000000000000000000000012));
        emisor = PiEmisor(address(0x0000000000000000000000000000000000000010));
    }

    function addAssociationMember(address newAssociationMember) public {
        require(isAssociation[msg.sender]);
        associationVoter[newAssociationMember] = true;
        associationVoterCounter++;
    }

    function removeAssociationMember(address oldAssociationMember) public {
        require(isAssociation[msg.sender]);
        associationVoter[oldAssociationMember] = false;
        associationVoterCounter--;
    }

    /// @dev Association opens a proposal identified by a hash
    /// @param proposalId identifier of the proposal
    function openProposal(bytes32 proposalId) public {
        require(isAssociation[msg.sender]);
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

    function openBallotAddPending(address tokenAddress) public returns(bytes32) {
        require(manageNodes.isValidator(msg.sender));
        salt++;
        bytes32 ballotId = bytes32(keccak256(abi.encodePacked(block.timestamp, tokenAddress, salt, msg.sender)));
        ballots[ballotId].open = true;
        ballots[ballotId].who = tokenAddress;
        ballots[ballotId].isFederal = true;
        ballots[ballotId].addPending = true;
        emit BallotCreated(ballotId);
        return ballotId;
    }

    function openBallotAddAssociation(address newAssociation) public returns(bytes32) {
        require(manageNodes.isValidator(msg.sender));
        salt++;
        bytes32 ballotId = bytes32(keccak256(abi.encodePacked(block.timestamp, newAssociation, salt, msg.sender)));
        ballots[ballotId].open = true;
        ballots[ballotId].who = newAssociation;
        ballots[ballotId].isFederal = true;
        ballots[ballotId].addAssociation = true;
        emit BallotCreated(ballotId);
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
        ballots[ballotId].oldLeader = _oldLeader;
        ballots[ballotId].newLeader = _newLeader;
        emit BallotCreated(ballotId);
        return ballotId;
    }

    /// @dev Members of any Association vote for a certain Ballot
    /// @param _ballotId identifier of the ballot
    /// @param userVote vote: True for YES
    function voteAssociation (bytes32 _ballotId, bool userVote) public {
        require(ballots[_ballotId].open && !ballots[_ballotId].close);
        require(associationVoter[msg.sender] && !voted[_ballotId][msg.sender]);
        if (userVote) {
            ballots[_ballotId].voteCount ++;
        }
        voted[_ballotId][msg.sender] = true;
        bool success = checkBallot(_ballotId);
        if (success) {
            manageNodes.changeValidatorsPending(ballots[_ballotId].oldLeader, ballots[_ballotId].newLeader);
        }
    }

    function voteFederal(bytes32 _ballotId, bool userVote) public {
        require(manageNodes.isValidator(msg.sender));
        require(ballots[_ballotId].open && !ballots[_ballotId].close);
        require(ballots[_ballotId].isFederal);
        require(!voted[_ballotId][msg.sender]);
        if (userVote) {
            ballots[_ballotId].voteCount ++;
        }
        voted[_ballotId][msg.sender] = true;
        uint success = checkBallot(_ballotId);
        if(success) {
            if(ballots[_ballotId].addPending) {
                emisor.addPending(ballots[_ballotId].who);
            } else if(ballots[_ballotId].addAssociation) {
                addAssociation(ballots[_ballotId].who);
            }
        }
    }

    /// @dev Checks success of the ballot
    /// @param _ballotId identifier of the ballot
    function checkBallot (bytes32 _ballotId) internal returns(bool) {
        if (ballots[_ballotId].voteCount >= associationVoterCounter.div(2)) {
            ballots[_ballotId].close = true;
            return true;
        }

        return false;
    }

    /// @dev Add a Association with its members
    /// @param newAssociation wallet of the Association
    /// @param members array with wallets of Association's members
    function addAssociation (address newAssociation) internal {
        require(msg.sender == _owner);
        isAssociation[newAssociation] = true;
    }
}
