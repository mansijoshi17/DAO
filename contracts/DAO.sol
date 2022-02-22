pragma solidity 0.7.3;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract DAO {
    enum Side {
        Yes,
        No
    }
    enum Status {
        Undecided,
        Approved,
        Rejected
    }
    struct Proposal {
        address author;
        bytes32 hash;
        uint256 createdAt;
        uint256 votesYes;
        uint256 votesNo;
        Status status;
    }

    mapping(bytes32 => Proposal) public proposals;
    mapping(address => mapping(bytes32 => bool)) public votes;
    mapping(address => uint256) public shares;
    uint256 public totalShares;
    IERC20 public token;
    uint256 constant CREATE_PROPOSAL_MIN_SHARE = 1000 * 10**18;
    uint256 constant VOTING_PERIOD = 7 days;

    constructor(address _token) {
        token = IERC20(_token);
    }

    function deposit(uint256 amount) external {
        shares[msg.sender] += amount;
        totalShares += amount;
        token.transferFrom(msg.sender, address(this), amount);
    }

    function withdraw(uint256 amount) external {
        require(shares[msg.sender] >= amount, "Not enough shares");
        shares[msg.sender] -= amount;
        totalShares -= amount;
        token.transfer(msg.sender, amount);
    }

    function createProposal(bytes32 proposalhash) external {
        require(
            shares[msg.sender] >= CREATE_PROPOSAL_MIN_SHARE,
            "Not enough shares to create proposal!"
        );
        require(
            proposals[proposalhash].hash == bytes32(0),
            "Proposal already exist!"
        );
        proposals[proposalhash] = Proposal(
            msg.sender,
            proposalhash,
            block.timestamp,
            0,
            0,
            Status.Undecided
        );
    }

    function vote(bytes32 proposalHash, Side side) external {
        Proposal storage proposal = proposals[proposalHash];
        require(votes[msg.sender][proposalHash] == false, "Already votes!");
        require(proposal.hash != bytes32(0), "Proposal already exist");
        require(
            block.timestamp <= proposal.createdAt + VOTING_PERIOD,
            "Voting period is over!"
        );
        votes[msg.sender][proposalHash] = true;
        if (side == Side.Yes) {
            proposal.votesYes += shares[msg.sender];
            if ((proposal.votesYes * 100) / totalShares > 50) {
                proposal.status = Status.Approved;
            }
        } else {
            proposal.votesNo += shares[msg.sender];
            if ((proposal.votesNo * 100) / totalShares > 50) {
                proposal.status = Status.Rejected;
            }
        }
    }
}
