// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Presale is Ownable {
    using SafeMath for uint256;

    // Presale parameters
    uint256 public presaleStartTime;
    uint256 public presaleEndTime;
    uint256 public tokenPrice;
    uint256 public hardCap;
    uint256 public softCap;
    uint256 public minPurchase;
    uint256 public maxPurchase;
    uint256 public presaleTokens;
    uint256 public refundType;
    address public router;
    uint256 public liquidityPercent;
    uint256 public listingPrice;
    uint256 public listingTime;

    // URLs
    string[] public urls;

    //url[0] = logoURL;
    //url[1] = websiteURL;
    //url[2] = telegramURL;
    //url[3] = twitterURL;
    //url[4] = githubURL;
    //url[5] = instagramURL;
    //url[6] = facebookURL;
    //url[7] = redditURL;
    //url[8] = discordURL;
    //url[9] = youtubeURL;
    //url[10] = description;

    // Track participant contributions
    mapping(address => uint256) public contributions;

    // Presale state
    enum State {Inactive, Active, Successful, Failed}
    State public state;

    // Token contract
    IERC20 public token;

    // Events
    event TokensPurchased(address indexed buyer, uint256 amount, uint256 contribution);

    // Modifiers
    modifier onlyWhileActive() {
        require(block.timestamp >= presaleStartTime && block.timestamp <= presaleEndTime, "Presale: Not active");
        _;
    }

    modifier onlyIfSuccessful() {
        require(state == State.Successful, "Presale: Not successful");
        _;
    }

    modifier onlyIfFailed() {
        require(state == State.Failed, "Presale: Not failed");
        _;
    }

    // Constructor
    constructor(
        uint256 _presaleStartTime,
        uint256 _presaleEndTime,
        uint256 _tokenPrice,
        uint256 _hardCap,
        uint256 _softCap,
        uint256 _minPurchase,
        uint256 _maxPurchase,
        uint256 _presaleTokens,
        address _tokenAddress,
        uint256 _refundType,
        address _router,
        uint256 _liquidityPercent,
        uint256 _listingPrice,
        uint256 _listingTime,
        string[] memory _urls
    ) {
        require(_presaleEndTime > _presaleStartTime, "Invalid presale end time");
        require(_hardCap > 0 && _softCap > 0 && _softCap <= _hardCap, "Invalid hard or soft cap");
        require(_minPurchase > 0 && _maxPurchase > 0 && _maxPurchase >= _minPurchase, "Invalid min or max purchase");
        require(_presaleTokens > 0, "Invalid presale token amount");
        require(_tokenAddress != address(0), "Invalid token address");
        require(_refundType == 0 || _refundType == 1, "Invalid refund type");
        require(_router != address(0), "Invalid router address");
        require(_liquidityPercent > 0 && _liquidityPercent <= 100, "Invalid liquidity percent");
        require(_listingPrice > 0, "Invalid listing price");
        require(_listingTime > 0, "Invalid listing time");

        presaleStartTime = _presaleStartTime;
        presaleEndTime = _presaleEndTime;
        tokenPrice = _tokenPrice;
        hardCap = _hardCap;
        softCap = _softCap;
        minPurchase = _minPurchase;
        maxPurchase = _maxPurchase;
        presaleTokens = _presaleTokens;
        token = IERC20(_tokenAddress);
        state = State.Inactive;
        refundType = _refundType;
        router = _router;
        liquidityPercent = _liquidityPercent;
        listingPrice = _listingPrice;
        listingTime = _listingTime;
        urls = _urls;
    }

    // Start the presale
    function startPresale() external onlyOwner {
        require(state == State.Inactive, "Presale: Already started");
        state = State.Active;
    }

    // Purchase tokens during the presale
    function purchaseTokens() external payable onlyWhileActive {
        require(msg.value >= minPurchase && msg.value <= maxPurchase, "Invalid purchase amount");
        require(address(this).balance.add(msg.value) <= hardCap, "Presale: Hard cap reached");

        uint256 tokensToPurchase = msg.value.mul(1e18) / tokenPrice; // Calculate tokens based on the token price

        require(tokensToPurchase > 0, "Invalid token amount");

        // Transfer tokens to the buyer
        token.transfer(msg.sender, tokensToPurchase);

        // Update participant contributions
        contributions[msg.sender] = contributions[msg.sender].add(msg.value);

        emit TokensPurchased(msg.sender, tokensToPurchase, msg.value);

        // Check if the presale is successful or failed
        if (address(this).balance >= softCap && address(this).balance <= hardCap) {
            state = State.Successful;
        } else if (block.timestamp > presaleEndTime || address(this).balance > hardCap) {
            state = State.Failed;
        }
    }

    // Claim remaining funds if the presale failed
    function claimRemainingFunds() external onlyIfFailed onlyOwner {
        require(address(this).balance > 0, "No remaining funds");
        payable(owner()).transfer(address(this).balance);
    }

    // Withdraw tokens after the presale is successful
    function withdrawTokens() external onlyIfSuccessful onlyOwner {
        require(token.balanceOf(address(this)) >= presaleTokens, "Insufficient tokens");
        token.transfer(owner(), presaleTokens);
    }
}
