// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "./WorkspaceManager.sol"; 

// ============================================================================
//  STORAGE & PAYMENT CONTRACT
// ============================================================================

contract StoragePayment is UUPSUpgradeable, AccessControlUpgradeable, ReentrancyGuardUpgradeable {
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    struct StoragePlan {
        string name;
        uint256 storageLimitGB;
        uint256 pricePerMonth; // in wei
        uint256 pricePerGB; // in wei per GB per month
        bool isActive;
    }

    struct Subscription {
        uint256 planId;
        uint256 workspaceId;
        address subscriber;
        uint256 startDate;
        uint256 expiryDate;
        uint256 storageUsed; // in bytes
        bool isActive;
    }

    // planId => StoragePlan
    mapping(uint256 => StoragePlan) public plans;
    // workspaceId => Subscription
    mapping(uint256 => Subscription) public subscriptions;
    
    uint256 public planCounter;
    address public workspaceManager;
    address public treasury;

    // Events
    event PlanCreated(uint256 indexed planId, string name, uint256 storageLimitGB);
    event SubscriptionCreated(uint256 indexed workspaceId, uint256 indexed planId, address indexed subscriber);
    event SubscriptionRenewed(uint256 indexed workspaceId, uint256 newExpiryDate);
    event PaymentReceived(uint256 indexed workspaceId, uint256 amount);

    function initialize(address _workspaceManager, address _treasury) public initializer {
        __UUPSUpgradeable_init();
        __AccessControl_init();
        __ReentrancyGuard_init();
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        workspaceManager = _workspaceManager;
        treasury = _treasury;
    }

    function createPlan(
        string memory _name,
        uint256 _storageLimitGB,
        uint256 _pricePerMonth,
        uint256 _pricePerGB
    ) external onlyRole(ADMIN_ROLE) returns (uint256) {
        planCounter++;
        uint256 planId = planCounter;

        plans[planId] = StoragePlan({
            name: _name,
            storageLimitGB: _storageLimitGB,
            pricePerMonth: _pricePerMonth,
            pricePerGB: _pricePerGB,
            isActive: true
        });

        emit PlanCreated(planId, _name, _storageLimitGB);
        return planId;
    }

    function subscribe(uint256 _workspaceId, uint256 _planId) external payable nonReentrant {
        StoragePlan memory plan = plans[_planId];
        require(plan.isActive, "Plan not active");
        require(msg.value >= plan.pricePerMonth, "Insufficient payment");

        uint256 expiryDate = block.timestamp + 30 days;

        subscriptions[_workspaceId] = Subscription({
            planId: _planId,
            workspaceId: _workspaceId,
            subscriber: msg.sender,
            startDate: block.timestamp,
            expiryDate: expiryDate,
            storageUsed: 0,
            isActive: true
        });

        // Transfer to treasury
        (bool success, ) = treasury.call{value: msg.value}("");
        require(success, "Transfer failed");

        emit SubscriptionCreated(_workspaceId, _planId, msg.sender);
        emit PaymentReceived(_workspaceId, msg.value);
    }

    function renewSubscription(uint256 _workspaceId) external payable nonReentrant {
        Subscription storage sub = subscriptions[_workspaceId];
        require(sub.isActive, "No active subscription");
        
        StoragePlan memory plan = plans[sub.planId];
        require(msg.value >= plan.pricePerMonth, "Insufficient payment");

        sub.expiryDate += 30 days;

        (bool success, ) = treasury.call{value: msg.value}("");
        require(success, "Transfer failed");

        emit SubscriptionRenewed(_workspaceId, sub.expiryDate);
        emit PaymentReceived(_workspaceId, msg.value);
    }

    function isSubscriptionActive(uint256 _workspaceId) external view returns (bool) {
        Subscription memory sub = subscriptions[_workspaceId];
        return sub.isActive && sub.expiryDate > block.timestamp;
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyRole(DEFAULT_ADMIN_ROLE) {}
}