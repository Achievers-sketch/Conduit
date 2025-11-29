// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "./WorkspaceManager.sol"; 
//DOCUMENT REGISTRY CONTRACT


contract DocumentRegistry is UUPSUpgradeable, AccessControlUpgradeable, ReentrancyGuardUpgradeable {
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    struct Document {
        uint256 id;
        string cid; // IPFS content identifier
        address owner;
        uint256 workspaceId;
        string title;
        uint256 version;
        uint256 createdAt;
        uint256 updatedAt;
        bool isDeleted;
        string[] versionHistory; // Array of CIDs
    }

    struct Permission {
        address user;
        PermissionLevel level;
        uint256 grantedAt;
        uint256 expiresAt; // 0 = never expires
    }

    enum PermissionLevel { NONE, VIEWER, EDITOR, ADMIN }

    // documentId => Document
    mapping(uint256 => Document) public documents;
    // documentId => user => Permission
    mapping(uint256 => mapping(address => Permission)) public permissions;
    // workspaceId => array of document IDs
    mapping(uint256 => uint256[]) public workspaceDocuments;
    
    uint256 public documentCounter;
    address public workspaceManager;

    // Events
    event DocumentCreated(uint256 indexed documentId, uint256 indexed workspaceId, address indexed owner, string cid);
    event DocumentUpdated(uint256 indexed documentId, string newCID, uint256 version);
    event DocumentDeleted(uint256 indexed documentId);
    event PermissionGranted(uint256 indexed documentId, address indexed user, PermissionLevel level);
    event PermissionRevoked(uint256 indexed documentId, address indexed user);

    function initialize(address _workspaceManager) public initializer {
        __UUPSUpgradeable_init();
        __AccessControl_init();
        __ReentrancyGuard_init();
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        workspaceManager = _workspaceManager;
    }

    function createDocument(
        uint256 _workspaceId,
        string memory _cid,
        string memory _title
    ) external returns (uint256) {
        require(
            WorkspaceManager(workspaceManager).isMember(_workspaceId, msg.sender),
            "Not a workspace member"
        );

        documentCounter++;
        uint256 documentId = documentCounter;

        documents[documentId] = Document({
            id: documentId,
            cid: _cid,
            owner: msg.sender,
            workspaceId: _workspaceId,
            title: _title,
            version: 1,
            createdAt: block.timestamp,
            updatedAt: block.timestamp,
            isDeleted: false,
            versionHistory: new string[](0)
        });

        documents[documentId].versionHistory.push(_cid);
        workspaceDocuments[_workspaceId].push(documentId);

        // Owner gets admin permission
        permissions[documentId][msg.sender] = Permission({
            user: msg.sender,
            level: PermissionLevel.ADMIN,
            grantedAt: block.timestamp,
            expiresAt: 0
        });

        emit DocumentCreated(documentId, _workspaceId, msg.sender, _cid);
        return documentId;
    }

    function updateDocument(uint256 _documentId, string memory _newCID) external {
        Document storage doc = documents[_documentId];
        require(!doc.isDeleted, "Document deleted");
        require(
            hasPermission(_documentId, msg.sender, PermissionLevel.EDITOR),
            "Insufficient permissions"
        );

        doc.cid = _newCID;
        doc.version++;
        doc.updatedAt = block.timestamp;
        doc.versionHistory.push(_newCID);

        emit DocumentUpdated(_documentId, _newCID, doc.version);
    }

    function deleteDocument(uint256 _documentId) external {
        Document storage doc = documents[_documentId];
        require(
            doc.owner == msg.sender || 
            hasPermission(_documentId, msg.sender, PermissionLevel.ADMIN),
            "Only owner or admin can delete"
        );

        doc.isDeleted = true;
        emit DocumentDeleted(_documentId);
    }

    function grantPermission(
        uint256 _documentId,
        address _user,
        PermissionLevel _level,
        uint256 _expiresAt
    ) external {
        require(
            hasPermission(_documentId, msg.sender, PermissionLevel.ADMIN),
            "Only admins can grant permissions"
        );

        permissions[_documentId][_user] = Permission({
            user: _user,
            level: _level,
            grantedAt: block.timestamp,
            expiresAt: _expiresAt
        });

        emit PermissionGranted(_documentId, _user, _level);
    }

    function revokePermission(uint256 _documentId, address _user) external {
        require(
            hasPermission(_documentId, msg.sender, PermissionLevel.ADMIN),
            "Only admins can revoke permissions"
        );
        require(_user != documents[_documentId].owner, "Cannot revoke owner permissions");

        delete permissions[_documentId][_user];
        emit PermissionRevoked(_documentId, _user);
    }

    function hasPermission(
        uint256 _documentId,
        address _user,
        PermissionLevel _requiredLevel
    ) public view returns (bool) {
        Permission memory perm = permissions[_documentId][_user];
        
        // Check if permission expired
        if (perm.expiresAt != 0 && perm.expiresAt < block.timestamp) {
            return false;
        }

        return uint(perm.level) >= uint(_requiredLevel);
    }

    function getDocument(uint256 _documentId) external view returns (Document memory) {
        return documents[_documentId];
    }

    function getVersionHistory(uint256 _documentId) external view returns (string[] memory) {
        return documents[_documentId].versionHistory;
    }

    function getWorkspaceDocuments(uint256 _workspaceId) external view returns (uint256[] memory) {
        return workspaceDocuments[_workspaceId];
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyRole(DEFAULT_ADMIN_ROLE) {}
}