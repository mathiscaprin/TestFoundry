pragma solidity 0.8.26;

import "forge-std/Test.sol";
import {NFT} from "../src/NFT.sol";
import {SimpleVotingSystem} from "../src/SimplevotingSystem.sol";

contract SimpleVotingSystemTest is Test {
    SimpleVotingSystem voting;
    NFT Nft;

    address admin;
    address founder;
    address withdrawer;

    address voter1;
    address voter2;

    address payable candidate1;
    address payable candidate2;

    function setUp() public {
        admin = makeAddr("admin");
        founder = makeAddr("founder");
        withdrawer = makeAddr("withdrawer");

        voter1 = makeAddr("voter1");
        voter2 = makeAddr("voter2");
        candidate1 = payable(makeAddr("candidate1"));
        candidate2 = payable(makeAddr("candidate2"));

        vm.deal(admin, 10 ether);
        vm.deal(founder, 10 ether);
        vm.deal(withdrawer, 10 ether);
        vm.deal(voter1, 10 ether);
        vm.deal(voter2, 10 ether);

        Nft = new NFT(admin);
        voting = new SimpleVotingSystem(admin);

        Nft.grantRole(Nft.MINTER_ROLE(), address(voting));

        vm.prank(admin);
        voting.addFounder(founder);
        vm.prank(admin);
        voting.addWithdrawer(withdrawer);
    }

    function _setStatus(uint8 status) internal {
        vm.prank(admin);
        voting.setWorkflowStatus(SimpleVotingSystem.Workflow(status));
    }

    function _addCandidate(string memory name, address wallet) internal {
        vm.prank(admin);
        voting.addCandidate(name, wallet);
    }

    function _openVoteAndWait1h() internal {
        _setStatus(2);
        vm.warp(block.timestamp + 1 hours);
    }

    function test_AddCandidate_OnlyAdmin_AndOnlyInRegisterPhase() public {
        vm.prank(voter1);
        vm.expectRevert();
        voting.addCandidate("ALICE", candidate1);

        _addCandidate("ALICE", candidate1);

        _setStatus(1);
        assertEq(voting.getCandidatesCount(), 1);

        vm.prank(admin);
        vm.expectRevert(bytes("Le workflow n'est pas bon"));
        voting.addCandidate("BOB", candidate2);
    }

    function test_FundCandidate_OnlyFounder_AndOnlyInFoundCandidates() public {
        _addCandidate("ALICE", candidate1);
        _setStatus(1);

        vm.prank(voter1);
        vm.expectRevert();
        voting.fundCandidate{value: 1 ether}(1);

        uint256 beforeBal = candidate1.balance;
        vm.prank(founder);
        voting.fundCandidate{value: 1 ether}(1);
        assertEq(candidate1.balance, beforeBal + 1 ether);
    }

    function test_Vote_RevertsBefore1hAfterVoteStatus() public {
        _addCandidate("ALICE", candidate1);
        _setStatus(2); 

        vm.prank(voter1);
        vm.expectRevert(bytes("Les votes ne sont pas lances"));
        voting.vote(1);
    }

    function test_Vote_MintsNFT_AndBlocksSecondVoteByNFT() public {
        _addCandidate("ALICE", candidate1);
        _openVoteAndWait1h();

        vm.prank(voter1);
        voting.vote(1);
        assertEq(Nft.balanceOf(voter1), 1);

        vm.prank(voter1);
        vm.expectRevert(bytes("You have already voted"));
        voting.vote(1);
    }

    function test_Vote_OnlyInVotePhase() public {
        _addCandidate("ALICE", candidate1);

        vm.prank(voter1);
        vm.expectRevert(bytes("Le workflow n'est pas bon"));
        voting.vote(1);
    }

    function test_DefineWinner_OnlyInCompleted_AndOnlyAdmin() public {
        _addCandidate("ALICE", candidate1);
        _addCandidate("BOB", candidate2);

        _openVoteAndWait1h();

        vm.prank(voter1);
        voting.vote(1);

        vm.prank(voter2);
        voting.vote(2);

        vm.prank(admin);
        vm.expectRevert(bytes("Le workflow n'est pas bon"));
        voting.DefineWinner();

        _setStatus(3);

        vm.prank(voter1);
        vm.expectRevert();
        voting.DefineWinner();

        vm.prank(admin);
        uint winnerId = voting.DefineWinner();
        SimpleVotingSystem.Candidate memory w = voting.getCandidate(winnerId);
        assertTrue(w.id == 1 || w.id == 2);
    }

    function test_Withdraw_OnlyWithdrawer_AndOnlyWhenCompleted() public {
        vm.deal(admin, 1 ether);
        vm.prank(admin);
        (bool ok, ) = address(voting).call{value: 1 ether}("");
        assertTrue(ok);
        assertEq(address(voting).balance, 1 ether);

        vm.prank(withdrawer);
        vm.expectRevert(bytes("Le workflow n'est pas bon"));
        voting.withdraw(payable(withdrawer), 0.5 ether);

        _setStatus(3); 

        vm.prank(voter1);
        vm.expectRevert();
        voting.withdraw(payable(voter1), 0.5 ether);

        uint256 before = withdrawer.balance;
        vm.prank(withdrawer);
        voting.withdraw(payable(withdrawer), 0.5 ether);
        assertEq(withdrawer.balance, before + 0.5 ether);
        assertEq(address(voting).balance, 0.5 ether);
    }
}
