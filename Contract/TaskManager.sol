// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "./WorkspaceManager.sol";
// 3. TASK MANAGEMENT CONTRACT

contract TaskManager is UUPSUpgradeable, AccessControlUpgradeable, ReentrancyGuardUpgradeable {
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    enum TaskStatus { TODO, IN_PROGRESS, REVIEW, DONE, ARCHIVED }
    enum Priority { LOW, MEDIUM, HIGH, URGENT }

    struct Task {
        uint256 id;
        uint256 projectId;
        string title;
        string descriptionCID; // IPFS CID for rich description
        address assignee;
        TaskStatus status;
        Priority priority;
        uint256 dueDate;
        uint256[] dependencies; // Task IDs that must be completed first
        uint256[] subtasks;
        string[] attachments; // IPFS CIDs
        address createdBy;
        uint256 createdAt;
        uint256 completedAt;
    }

    struct Project {
        uint256 id;
        string name;
        uint256 workspaceId;
        address owner;
        uint256 createdAt;
        bool isActive;
    }

    // projectId => Project
    mapping(uint256 => Project) public projects;
    // taskId => Task
    mapping(uint256 => Task) public tasks;
    // projectId => array of task IDs
    mapping(uint256 => uint256[]) public projectTasks;
    
    uint256 public projectCounter;
    uint256 public taskCounter;
    address public workspaceManager;

    // Events
    event ProjectCreated(uint256 indexed projectId, uint256 indexed workspaceId, address indexed owner);
    event TaskCreated(uint256 indexed taskId, uint256 indexed projectId, address indexed assignee);
    event TaskAssigned(uint256 indexed taskId, address indexed assignee);
    event TaskStatusChanged(uint256 indexed taskId, TaskStatus newStatus);
    event TaskCompleted(uint256 indexed taskId, uint256 completedAt);
    event DependencyAdded(uint256 indexed taskId, uint256 dependencyTaskId);

    function initialize(address _workspaceManager) public initializer {
        __UUPSUpgradeable_init();
        __AccessControl_init();
        __ReentrancyGuard_init();
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        workspaceManager = _workspaceManager;
    }

    function createProject(uint256 _workspaceId, string memory _name) external returns (uint256) {
        require(
            WorkspaceManager(workspaceManager).isMember(_workspaceId, msg.sender),
            "Not a workspace member"
        );

        projectCounter++;
        uint256 projectId = projectCounter;

        projects[projectId] = Project({
            id: projectId,
            name: _name,
            workspaceId: _workspaceId,
            owner: msg.sender,
            createdAt: block.timestamp,
            isActive: true
        });

        emit ProjectCreated(projectId, _workspaceId, msg.sender);
        return projectId;
    }

    function createTask(
        uint256 _projectId,
        string memory _title,
        string memory _descriptionCID,
        address _assignee,
        Priority _priority,
        uint256 _dueDate
    ) external returns (uint256) {
        Project memory project = projects[_projectId];
        require(project.isActive, "Project not active");
        require(
            WorkspaceManager(workspaceManager).isMember(project.workspaceId, msg.sender),
            "Not a workspace member"
        );

        taskCounter++;
        uint256 taskId = taskCounter;

        tasks[taskId] = Task({
            id: taskId,
            projectId: _projectId,
            title: _title,
            descriptionCID: _descriptionCID,
            assignee: _assignee,
            status: TaskStatus.TODO,
            priority: _priority,
            dueDate: _dueDate,
            dependencies: new uint256[](0),
            subtasks: new uint256[](0),
            attachments: new string[](0),
            createdBy: msg.sender,
            createdAt: block.timestamp,
            completedAt: 0
        });

        projectTasks[_projectId].push(taskId);

        emit TaskCreated(taskId, _projectId, _assignee);
        return taskId;
    }

    function updateTaskStatus(uint256 _taskId, TaskStatus _newStatus) external {
        Task storage task = tasks[_taskId];
        Project memory project = projects[task.projectId];
        
        require(
            task.assignee == msg.sender ||
            WorkspaceManager(workspaceManager).hasRole(project.workspaceId, msg.sender, keccak256("ADMIN_ROLE")),
            "Not authorized"
        );

        // Check dependencies are completed
        if (_newStatus == TaskStatus.DONE) {
            for (uint i = 0; i < task.dependencies.length; i++) {
                require(
                    tasks[task.dependencies[i]].status == TaskStatus.DONE,
                    "Dependencies not completed"
                );
            }
            task.completedAt = block.timestamp;
            emit TaskCompleted(_taskId, block.timestamp);
        }

        task.status = _newStatus;
        emit TaskStatusChanged(_taskId, _newStatus);
    }

    function assignTask(uint256 _taskId, address _newAssignee) external {
        Task storage task = tasks[_taskId];
        Project memory project = projects[task.projectId];
        
        require(
            WorkspaceManager(workspaceManager).isMember(project.workspaceId, msg.sender),
            "Not a workspace member"
        );

        task.assignee = _newAssignee;
        emit TaskAssigned(_taskId, _newAssignee);
    }

    function addDependency(uint256 _taskId, uint256 _dependencyTaskId) external {
        Task storage task = tasks[_taskId];
        require(task.projectId == tasks[_dependencyTaskId].projectId, "Tasks must be in same project");
        
        task.dependencies.push(_dependencyTaskId);
        emit DependencyAdded(_taskId, _dependencyTaskId);
    }

    function getProjectTasks(uint256 _projectId) external view returns (uint256[] memory) {
        return projectTasks[_projectId];
    }

    function getTask(uint256 _taskId) external view returns (Task memory) {
        return tasks[_taskId];
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyRole(DEFAULT_ADMIN_ROLE) {}
}
