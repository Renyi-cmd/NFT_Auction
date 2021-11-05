// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
abstract contract myNFT is ERC721URIStorage
{
    string public myName;
    string public mySymbol;
    uint public count;
    uint public minPrice;
    uint public maxPrice;
    uint public endTime;
    address payable maxPerson;
    bool hasEnded;
    struct NFT
    {
        uint ID;
        uint price;
        uint num;
        string name;
        string URI;
        address payable minter;
        address payable currOwner;
        address payable prevOwner;
        bool state;
    }
    mapping(uint=>NFT) NFTs;
    mapping(string=>bool) nameExist;
    mapping(uint=>bool) claimState;
    constructor() ERC721("NFTManage", "NFT")
    {
        myName = name();
        mySymbol = symbol();
    }
    function createNFT(string memory newName, string memory URI, uint price) public
    {
        count += 1;
        require(msg.sender != address(0));
        require(_exists(count) == false);
        require(nameExist[newName] == false);
        _safeMint(msg.sender, count);
        _setTokenURI(count, URI);
        nameExist[newName] = true;
        NFT memory newNFT = NFT(
            count,
            price,
            0,
            newName,
            URI,
            payable(msg.sender),
            payable(msg.sender),
            payable(address(0)),
            false
        );
        NFTs[count] = newNFT;
    }
    function startAuction(uint ID, uint min, uint time) public
    {
        require(_exists(ID));
        require(msg.sender == ownerOf(ID));
        uint newEndTime = block.timestamp + time;
        NFTs[ID].state = true;
        minPrice = maxPrice = min;
        endTime = newEndTime;
        maxPerson = payable(msg.sender);
        hasEnded = claimState[ID] = false;
    }
    function endAuction(uint ID) public
    {
        require(_exists(ID));
        require(block.timestamp >= endTime);
        hasEnded = true;
    }
    function increaseBid(uint ID, uint newBid) public
    {
        require(_exists(ID));
        require(msg.sender != ownerOf(ID));
        require(block.timestamp <= endTime);
        if(newBid <= maxPrice) revert();
        NFTs[ID].price = newBid;
        maxPerson = payable(msg.sender);
    }
    function transferNFT(uint ID) public payable
    {
        require(_exists(ID));
        require(msg.sender != address(0));
        require(hasEnded == true);
        require(claimState[ID] == false);
        require(msg.sender == maxPerson);
        address owner = ownerOf(ID);
        require(owner != address(0));
        _transfer(owner, msg.sender, ID);
        payable(owner).transfer(msg.value);
        NFTs[ID].prevOwner = NFTs[ID].currOwner;
        NFTs[ID].currOwner = payable(msg.sender);
        NFTs[ID].price = maxPrice;
        NFTs[ID].num += 1;
        NFTs[ID].state = false;
    }
}