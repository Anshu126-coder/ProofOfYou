// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title ProofOfYou
 * @dev A decentralized identity verification system that allows users to create and manage digital identity proofs
 * @author ProofOfYou Team
 */
contract ProofOfYou {
    
    struct Identity {
        string name;
        string email;
        uint256 timestamp;
        bool isVerified;
        address verifier;
        string ipfsHash; // For storing additional documents
    }
    
    struct Endorsement {
        address endorser;
        string message;
        uint256 timestamp;
        bool isActive;
    }
    
    mapping(address => Identity) public identities;
    mapping(address => Endorsement[]) public endorsements;
    mapping(address => bool) public authorizedVerifiers;
    mapping(address => uint256) public reputationScore;
    
    address public owner;
    uint256 public totalIdentities;
    
    event IdentityCreated(address indexed user, string name, uint256 timestamp);
    event IdentityVerified(address indexed user, address indexed verifier, uint256 timestamp);
    event EndorsementAdded(address indexed user, address indexed endorser, string message, uint256 timestamp);
    event VerifierAuthorized(address indexed verifier, address indexed authorizer);
    event ReputationUpdated(address indexed user, uint256 newScore);
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can perform this action");
        _;
    }
    
    modifier onlyVerifier() {
        require(authorizedVerifiers[msg.sender] || msg.sender == owner, "Only authorized verifiers can perform this action");
        _;
    }
    
    modifier identityExists(address user) {
        require(bytes(identities[user].name).length > 0, "Identity does not exist");
        _;
    }
    
    constructor() {
        owner = msg.sender;
        authorizedVerifiers[msg.sender] = true;
    }
    
    /**
     * @dev Creates a new digital identity for the caller
     * @param _name Full name of the user
     * @param _email Email address of the user
     * @param _ipfsHash IPFS hash for additional identity documents
     */
    function createIdentity(string memory _name, string memory _email, string memory _ipfsHash) external {
        require(bytes(identities[msg.sender].name).length == 0, "Identity already exists");
        require(bytes(_name).length > 0, "Name cannot be empty");
        require(bytes(_email).length > 0, "Email cannot be empty");
        
        identities[msg.sender] = Identity({
            name: _name,
            email: _email,
            timestamp: block.timestamp,
            isVerified: false,
            verifier: address(0),
            ipfsHash: _ipfsHash
        });
        
        totalIdentities++;
        reputationScore[msg.sender] = 1; // Base reputation score
        
        emit IdentityCreated(msg.sender, _name, block.timestamp);
    }
    
    /**
     * @dev Verifies an identity (only authorized verifiers can call this)
     * @param _user Address of the user whose identity needs to be verified
     */
    function verifyIdentity(address _user) external onlyVerifier identityExists(_user) {
        require(!identities[_user].isVerified, "Identity already verified");
        require(_user != msg.sender, "Cannot verify own identity");
        
        identities[_user].isVerified = true;
        identities[_user].verifier = msg.sender;
        reputationScore[_user] += 10; // Boost reputation for verified users
        
        emit IdentityVerified(_user, msg.sender, block.timestamp);
        emit ReputationUpdated(_user, reputationScore[_user]);
    }
    
    /**
     * @dev Adds an endorsement for a user's identity
     * @param _user Address of the user to endorse
     * @param _message Endorsement message
     */
    function addEndorsement(address _user, string memory _message) external identityExists(_user) {
        require(_user != msg.sender, "Cannot endorse yourself");
        require(bytes(_message).length > 0, "Endorsement message cannot be empty");
        require(bytes(identities[msg.sender].name).length > 0, "Endorser must have an identity");
        
        endorsements[_user].push(Endorsement({
            endorser: msg.sender,
            message: _message,
            timestamp: block.timestamp,
            isActive: true
        }));
        
        reputationScore[_user] += 2; // Small reputation boost for endorsements
        
        emit EndorsementAdded(_user, msg.sender, _message, block.timestamp);
        emit ReputationUpdated(_user, reputationScore[_user]);
    }
    
    /**
     * @dev Authorizes a new verifier (only owner can call this)
     * @param _verifier Address of the new verifier
     */
    function authorizeVerifier(address _verifier) external onlyOwner {
        require(_verifier != address(0), "Invalid verifier address");
        require(!authorizedVerifiers[_verifier], "Verifier already authorized");
        
        authorizedVerifiers[_verifier] = true;
        
        emit VerifierAuthorized(_verifier, msg.sender);
    }
    
    /**
     * @dev Gets the complete identity information for a user
     * @param _user Address of the user
     * @return Identity struct containing all user information
     */
    function getIdentity(address _user) external view identityExists(_user) returns (Identity memory) {
        return identities[_user];
    }
    
    /**
     * @dev Gets all endorsements for a user
     * @param _user Address of the user
     * @return Array of endorsements
     */
    function getEndorsements(address _user) external view returns (Endorsement[] memory) {
        return endorsements[_user];
    }
    
    /**
     * @dev Gets the reputation score of a user
     * @param _user Address of the user
     * @return Current reputation score
     */
    function getReputationScore(address _user) external view returns (uint256) {
        return reputationScore[_user];
    }
    
    /**
     * @dev Checks if an address is an authorized verifier
     * @param _verifier Address to check
     * @return Boolean indicating if the address is an authorized verifier 
     */
    function isAuthorizedVerifier(address _verifier) external view returns (bool) {
        return authorizedVerifiers[_verifier];
    }
}
