// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Ownable} from "openzeppelin-contracts/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract SimpleVotingSystem  is Ownable, AccessControl {
    struct Candidate {
        uint id;
        string name;
        uint voteCount;
        address wallet;
    }

    enum Workflow {
        REGISTER_CANDIDATES,
        FOUND_CANDIDATES,
        VOTE,
        COMPLETED
    }

    mapping(uint => Candidate) public candidates;
    mapping(address => bool) public voters;
    uint[] private candidateIds;
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant FOUNDER_ROLE = keccak256("FOUNDER_ROLE");
    bytes32 public constant WITHDRAWER_ROLE = keccak256("WITHDRAWER_ROLE");

    Workflow public state = Workflow.REGISTER_CANDIDATES;
    uint256 public StartVote;

    constructor(address _admin) Ownable(_admin) {
        _grantRole(DEFAULT_ADMIN_ROLE, _admin);
        _grantRole(ADMIN_ROLE, _admin);

        state = Workflow.REGISTER_CANDIDATES;
    }
    modifier workflowState(Workflow requiredState) {
        require(state == requiredState, "Le workflow n'est pas bon");
        _;
    }

    function addCandidate(string memory _name, address _wallet) public onlyRole(ADMIN_ROLE) workflowState(Workflow.REGISTER_CANDIDATES) {
        require(bytes(_name).length > 0, "Candidate name cannot be empty");
        uint candidateId = candidateIds.length + 1;
        candidates[candidateId] = Candidate(candidateId, _name, 0, _wallet);
        candidateIds.push(candidateId);
    }

    function addFounder(address _founder) public workflowState(Workflow.REGISTER_CANDIDATES) {
        _grantRole(FOUNDER_ROLE, _founder);
    }

    function addWithdrawer(address _withdrawer) public workflowState(Workflow.REGISTER_CANDIDATES) {
        _grantRole(WITHDRAWER_ROLE, _withdrawer);
    }

    function vote(uint _candidateId) public workflowState(Workflow.VOTE) {
        require(!voters[msg.sender], "You have already voted");
        require(_candidateId > 0 && _candidateId <= candidateIds.length, "Invalid candidate ID");
        require(StartVote + 3600 < block.timestamp, "Les votes ne sont pas lances");
        voters[msg.sender] = true;
        candidates[_candidateId].voteCount += 1;
    }

    function getTotalVotes(uint _candidateId) public view workflowState(Workflow.FOUND_CANDIDATES)  returns (uint) {
        require(_candidateId > 0 && _candidateId <= candidateIds.length, "Invalid candidate ID");
        return candidates[_candidateId].voteCount;
    }

    function getCandidatesCount() public view workflowState(Workflow.FOUND_CANDIDATES) returns (uint) {
        return candidateIds.length;
    }

    // Optional: Function to get candidate details by ID
    function getCandidate(uint _candidateId) public view workflowState(Workflow.FOUND_CANDIDATES)  returns (Candidate memory) {
        require(_candidateId > 0 && _candidateId <= candidateIds.length, "Invalid candidate ID");
        return candidates[_candidateId];
    }

    function setWorkflowStatus(Workflow newState) public onlyRole(ADMIN_ROLE) {
        state = newState;
        if (newState == Workflow.VOTE) {
            StartVote = block.timestamp;
        }
    }

    function fundCandidate(uint _candidateId) public payable onlyRole(FOUNDER_ROLE) workflowState(Workflow.FOUND_CANDIDATES) {
        require(_candidateId > 0 && _candidateId <= candidateIds.length, "Invalid candidate ID");
        require(msg.value > 0, "On ne peut pas envoyer 0 ether");
        address payable candidateWallet = payable(candidates[_candidateId].wallet);
        candidateWallet.transfer(msg.value);
    }

    function DefineWinner() public view workflowState(Workflow.COMPLETED) returns (uint winnerId) {
        uint maxVotes = 0;
        for (uint i = 0; i < candidateIds.length; i++) {
            uint candidateId = candidateIds[i];
            if (candidates[candidateId].voteCount > maxVotes) {
                maxVotes = candidates[candidateId].voteCount;
                winnerId = candidateId;
            }
        }
    }

    function withdraw (address payable _withdrawer, uint256 _amount) public onlyRole(WITHDRAWER_ROLE) {

        payable(_withdrawer).transfer(_amount);
    }
}