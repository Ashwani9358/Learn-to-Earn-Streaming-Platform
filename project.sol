// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract LearnToEarn {
    // Define the admin of the platform
    address public admin;

    // Stablecoin token address
    address public stablecoinAddress;

    // Structure to track student progress
    struct CourseProgress {
        uint256 totalLessons;
        uint256 completedLessons;
        bool rewarded;
    }

    // Mapping to track enrolled courses for each student
    mapping(address => mapping(uint256 => CourseProgress)) public studentProgress;

    // Events
    event CourseEnrolled(address indexed student, uint256 courseId);
    event LessonCompleted(address indexed student, uint256 courseId, uint256 completedLessons);
    event RewardClaimed(address indexed student, uint256 courseId, uint256 rewardAmount);

    constructor(address _stablecoinAddress) {
        admin = msg.sender;
        stablecoinAddress = _stablecoinAddress;
    }

    // Modifier to restrict access to the admin
    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can perform this action");
        _;
    }

    // Enroll a student into a course
    function enrollCourse(address student, uint256 courseId, uint256 totalLessons) external onlyAdmin {
        require(totalLessons > 0, "Total lessons must be greater than 0");
        require(studentProgress[student][courseId].totalLessons == 0, "Student already enrolled in this course");

        studentProgress[student][courseId] = CourseProgress({
            totalLessons: totalLessons,
            completedLessons: 0,
            rewarded: false
        });

        emit CourseEnrolled(student, courseId);
    }

    // Record a completed lesson
    function completeLesson(address student, uint256 courseId) external onlyAdmin {
        CourseProgress storage progress = studentProgress[student][courseId];
        require(progress.totalLessons > 0, "Student not enrolled in this course");
        require(progress.completedLessons < progress.totalLessons, "All lessons already completed");

        progress.completedLessons++;
        emit LessonCompleted(student, courseId, progress.completedLessons);
    }

    // Claim reward after completing the course
    function claimReward(uint256 courseId) external {
        CourseProgress storage progress = studentProgress[msg.sender][courseId];
        require(progress.totalLessons > 0, "Student not enrolled in this course");
        require(progress.completedLessons == progress.totalLessons, "Course not fully completed");
        require(!progress.rewarded, "Reward already claimed");

        uint256 rewardAmount = calculateReward(progress.totalLessons);
        progress.rewarded = true;

        // Transfer stablecoins as reward
        require(IERC20(stablecoinAddress).transfer(msg.sender, rewardAmount), "Reward transfer failed");

        emit RewardClaimed(msg.sender, courseId, rewardAmount);
    }

    // Calculate reward amount based on course length (e.g., 10 stablecoins per lesson)
    function calculateReward(uint256 totalLessons) internal pure returns (uint256) {
        return totalLessons * 10 * 1e18; // Assuming stablecoin has 18 decimals
    }
}

// Interface for ERC20 token
interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
}
