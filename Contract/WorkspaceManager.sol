// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

// 1. WORKSPACE MANAGEMENT CONTRACT

contract WorkspaceManager is UUPSUpgradeable, AccessControlUpgradeable, ReentrancyGuardUpgradeable {
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant MEMBER_ROLE = keccak256("MEMBER_ROLE");
    bytes32 public constant EDITOR_ROLE = keccak256("EDITOR_ROLE");
    bytes32 public constant VIEWER_ROLE = keccak256("VIEWER_ROLE");

    struct Workspace {
        string name;
        address owner;
        string metadataCID; // IPFS CID for workspace settings/branding
        uint256 createdAt;
        bool isActive;
        uint256 storageLimit; // in bytes
        uint256 storageUsed;
    }

    struct Member {
        address memberAddress;
        bytes32 role;
        uint256 joinedAt;
        bool isActive;
    }

    // workspaceId => Workspace
    mapping(uint256 => Workspace) public workspaces;
    // workspaceId => member address => Member
    mapping(uint256 => mapping(address => Member)) public workspaceMembers;
    // workspaceId => array of member addresses
    mapping(uint256 => address[]) public workspaceMemberList;
    
    uint256 public workspaceCounter;
    
    // Events
    event WorkspaceCreated(uint256 indexed workspaceId, address indexed owner, string name);
    event MemberAdded(uint256 indexed workspaceId, address indexed member, bytes32 role);
    event MemberRemoved(uint256 indexed workspaceId, address indexed member);
    event MemberRoleUpdated(uint256 indexed workspaceId, address indexed member, bytes32 newRole);
    event WorkspaceUpdated(uint256 indexed workspaceId, string metadataCID);
    event StorageUpdated(uint256 indexed workspaceId, uint256 storageUsed);

    function initialize() public initializer {
        __UUPSUpgradeable_init();
        __AccessControl_init();
        __ReentrancyGuard_init();
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function createWorkspace(string memory _name, string memory _metadataCID) external returns (uint256) {
        workspaceCounter++;
        uint256 workspaceId = workspaceCounter;

        workspaces[workspaceId] = Workspace({
            name: _name,
            owner: msg.sender,
            metadataCID: _metadataCID,
            createdAt: block.timestamp,
            isActive: true,
            storageLimit: 10 * 1024 * 1024 * 1024, // 10 GB default
            storageUsed: 0
        });

        // Owner gets all roles
        _addMember(workspaceId, msg.sender, ADMIN_ROLE);

        emit WorkspaceCreated(workspaceId, msg.sender, _name);
        return workspaceId;
    }

    function addMember(uint256 _workspaceId, address _member, bytes32 _role) external {
        require(workspaces[_workspaceId].isActive, "Workspace not active");
        require(
            hasRole(_workspaceId, msg.sender, ADMIN_ROLE),
            "Only admins can add members"
        );
        _addMember(_workspaceId, _member, _role);
    }

    function _addMember(uint256 _workspaceId, address _member, bytes32 _role) internal {
        require(!workspaceMembers[_workspaceId][_member].isActive, "Member already exists");

        workspaceMembers[_workspaceId][_member] = Member({
            memberAddress: _member,
            role: _role,
            joinedAt: block.timestamp,
            isActive: true
        });

        workspaceMemberList[_workspaceId].push(_member);
        emit MemberAdded(_workspaceId, _member, _role);
    }

    function removeMember(uint256 _workspaceId, address _member) external {
        require(
            hasRole(_workspaceId, msg.sender, ADMIN_ROLE),
            "Only admins can remove members"
        );
        require(_member != workspaces[_workspaceId].owner, "Cannot remove owner");
        
        workspaceMembers[_workspaceId][_member].isActive = false;
        emit MemberRemoved(_workspaceId, _member);
    }

    function updateMemberRole(uint256 _workspaceId, address _member, bytes32 _newRole) external {
        require(
            hasRole(_workspaceId, msg.sender, ADMIN_ROLE),
            "Only admins can update roles"
        );
        
        workspaceMembers[_workspaceId][_member].role = _newRole;
        emit MemberRoleUpdated(_workspaceId, _member, _newRole);
    }

    function updateStorage(uint256 _workspaceId, uint256 _storageUsed) external {
        require(
            hasRole(_workspaceId, msg.sender, ADMIN_ROLE) || 
            hasRole(_workspaceId, msg.sender, EDITOR_ROLE),
            "Insufficient permissions"
        );
        
        workspaces[_workspaceId].storageUsed = _storageUsed;
        emit StorageUpdated(_workspaceId, _storageUsed);
    }

    function hasRole(uint256 _workspaceId, address _member, bytes32 _role) public view returns (bool) {
        Member memory member = workspaceMembers[_workspaceId][_member];
        return member.isActive && member.role == _role;
    }

    function isMember(uint256 _workspaceId, address _member) public view returns (bool) {
        return workspaceMembers[_workspaceId][_member].isActive;
    }

    function getWorkspaceMembers(uint256 _workspaceId) external view returns (address[] memory) {
        return workspaceMemberList[_workspaceId];
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyRole(DEFAULT_ADMIN_ROLE) {}
}