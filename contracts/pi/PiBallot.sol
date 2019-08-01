pragma solidity 0.5.0;

import "../utils/safeMath.sol";
import "../validators/interfaces/ManageNodes.sol";

/// @author MIDLANTIC TECHNOLOGIES
/// @title A contract designed to handle ballots

contract PiBallot {
    using SafeMath for uint;

    struct Ballot {
        bool open;
        bool close;
        address oldLeader;
        address newLeader;
        uint voteCount;
    }

    struct Proposal {
        bool open;
        uint voteCount;
    }

    ManageNodes manageNodes;

    mapping(address => bool) isSociety;
    mapping(bytes32 => Ballot) public ballots;
    mapping(bytes32 => Proposal) public proposals;
    mapping(address => bool) societyVoter;
    mapping(bytes32 => mapping(address => bool)) voted;
    mapping(bytes32 => mapping(address => bool)) votedProposal;

    address private _owner;
    uint societyVoterCounter;

    event BallotCreated(bytes32);

    constructor (address owner) public {
        _owner = owner;
        manageNodes = ManageNodes(address(0x0000000000000000000000000000000000000012));
    }

    /// @dev Add a Society with its members
    /// @param newSociety wallet of the Society
    /// @param members array with wallets of Society's members
    function addSociety (address newSociety, address[] memory members) public {
        require(msg.sender == _owner);
        isSociety[newSociety] = true;
        for (uint i = 0; i < members.length; i++) {
            societyVoter[members[i]] = true;
            societyVoterCounter++;
        }
    }

    /// @dev Society opens a proposal identified by a hash
    /// @param proposalId identifier of the proposal
    function openProposal(bytes32 proposalId) public {
        require(isSociety[msg.sender]);
        proposals[proposalId].open = true;
    }

    /// @dev Members of any society vote for a certain proposal
    /// @param proposalId identifier of the proposal
    function voteProposal(bytes32 proposalId) public {
        require(proposals[proposalId].open);
        require(societyVoter[msg.sender] && !votedProposal[proposalId][msg.sender]);
        proposals[proposalId].voteCount++;
        votedProposal[proposalId][msg.sender] = true;
    }

    /// @dev Society opens a ballot to change a Validator
    /// @param _oldLeader wallet of the current validator
    /// @param _newLeader wallet of the new validator
    /// @return ballotId identifier of the Ballot
    function openBallot (address _oldLeader, address _newLeader) public returns(bytes32) {
        require(isSociety[msg.sender]);
        uint nodeIndex = manageNodes.getNodeIndex(_oldLeader);
        require(nodeIndex > 5);
        bytes32 ballotId = bytes32(keccak256(abi.encodePacked(block.timestamp, _oldLeader, _newLeader, msg.sender)));
        ballots[ballotId].open = true;
        ballots[ballotId].oldLeader = _oldLeader;
        ballots[ballotId].newLeader = _newLeader;
        emit BallotCreated(ballotId);
        return ballotId;
    }

    /// @dev Members of any Society vote for a certain Ballot
    /// @param _ballotId identifier of the ballot
    /// @param userVote vote: True for YES
    function vote (bytes32 _ballotId, bool userVote) public {
        require(ballots[_ballotId].open && !ballots[_ballotId].close);
        require(societyVoter[msg.sender] && !voted[_ballotId][msg.sender]);
        if (userVote) {
            ballots[_ballotId].voteCount ++;
        }
        voted[_ballotId][msg.sender] = true;
        checkBallot(_ballotId);
    }

    /// @dev Checks success of the ballot
    /// @param _ballotId identifier of the ballot
    function checkBallot (bytes32 _ballotId) internal {
        if (ballots[_ballotId].voteCount >= societyVoterCounter.mul(80).div(100)) {
            manageNodes.changeValidatorsPending(ballots[_ballotId].oldLeader, ballots[_ballotId].newLeader);
            ballots[_ballotId].close = true;
        }
    }
}
