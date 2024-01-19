// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Presale is Ownable {
    // Presale parameters
    uint256 public presaleStartTime;
    uint256 public presaleEndTime;
    uint256 public tokenPrice; // Token price in wei
    uint256 public hardCap; // Maximum amount of ether to be raised
    uint256 public softCap; // Minimum amount of ether to consider the presale successful
    uint256 public minPurchase; // Minimum purchase amount in wei
    uint256 public maxPurchase; // Maximum purchase amount in wei
    uint256 public presaleTokens; // Total number of tokens available for presale
    uint256 public refundType; // 0 = refund, 1 = burn
    address public router; // Router address for the presale
    uint256 public liquidityPercent; // Percentage of tokens to add to the liquidity pool
    uint256 public listingPrice; // Listing price in wei
    uint256 public listingTime; // Time to list the token on Uniswap
    string public logoURL; // URL to the token logo
    string public websiteURL; // URL to the token website
    string public telegramURL; // URL to the token Telegram group
    string public twitterURL; // URL to the token Twitter profile
    string public githubURL; // URL to the token Github profile
    string public instagramURL; // URL to the token Instagram profile
    string public facebookURL; // URL to the token Facebook profile
    string public redditURL; // URL to the token Reddit profile
    string public discordURL; // URL to the token Discord server
    string public youtubeURL; // URL to the token Youtube channel
    

    // Track participant contributions
    mapping(address => uint256) public contributions;

    // Presale state
    enum State {Inactive, Active, Successful, Failed}
    State public state;

    // Token contract
    IERC20 public token;

    // Events
    event TokensPurchased(address indexed buyer, uint256 amount, uint256 contribution);

    // Modifier to ensure the presale is active
    modifier onlyWhileActive() {
        require(block.timestamp >= presaleStartTime && block.timestamp <= presaleEndTime, "Presale: Not active");
        _;
    }

    // Modifier to check if the presale is successful
    modifier onlyIfSuccessful() {
        require(state == State.Successful, "Presale: Not successful");
        _;
    }

    // Modifier to check if the presale has failed
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
        string _logoURL,
        string _websiteURL,
        string _telegramURL,
        string _twitterURL,
        string _githubURL,
        string _instagramURL,
        string _facebookURL,
        string _redditURL,
        string _discordURL,
        string _youtubeURL,
        string _description
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
        logoURL = _logoURL;
        websiteURL = _websiteURL;
        telegramURL = _telegramURL;
        twitterURL = _twitterURL;
        githubURL = _githubURL;
        instagramURL = _instagramURL;
        facebookURL = _facebookURL;
        redditURL = _redditURL;
        discordURL = _discordURL;
        youtubeURL = _youtubeURL;
        description = _description;
    }

    // Start the presale
    function startPresale() external onlyOwner {
        require(state == State.Inactive, "Presale: Already started");
        state = State.Active;
    }

    // Purchase tokens during the presale
    function purchaseTokens() external payable onlyWhileActive {
        require(msg.value >= minPurchase && msg.value <= maxPurchase, "Invalid purchase amount");
        require(address(this).balance + msg.value <= hardCap, "Presale: Hard cap reached");

        uint256 tokensToPurchase = (msg.value * 1e18) / tokenPrice; // Calculate tokens based on the token price

        require(tokensToPurchase > 0, "Invalid token amount");

        // Transfer tokens to the buyer
        token.transfer(msg.sender, tokensToPurchase);

        // Update participant contributions
        contributions[msg.sender] += msg.value;

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