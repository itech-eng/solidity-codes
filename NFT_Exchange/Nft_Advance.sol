// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./IERC20.sol";


contract NFT is ERC721 {

    uint8 public tokenStartId = 1;
    mapping (address => bool) public admins;
    address[] private allAdmins;
    uint16 public adminCount;

    modifier onlyAdmin() {
        require(admins[msg.sender] == true, "Unauthorized request.");
        _;
    }

    using Counters for Counters.Counter;

    Counters.Counter private currentTokenId;

    string public baseTokenURI;
    mapping (uint256 => string) private _tokenURIs;

    function removeAddressArrayElement(address[] storage _arr, address _elem) internal {
        bool found;
        uint index;
        for(uint i = 0; i<_arr.length; i++) {
            if(_arr[i] == _elem) {
                found = true;
                index = i;
                break;
            }
        }
        if(found) {
            _arr[index] = _arr[_arr.length - 1];
            _arr.pop();
        }
    }

    constructor(string memory _name, string memory _symbol, address _admin) ERC721(_name, _symbol) {
        admins[_admin] = true;
        allAdmins.push(_admin);
        adminCount++;
    }

    function addAdmin(address _account) external onlyAdmin returns(bool) {
        admins[_account] = true;
        allAdmins.push(_account);
        adminCount++;
        return true;
    }

    function deleteAdmin(address _account) external onlyAdmin returns(bool) {
        require(_account != msg.sender, "You can't delete yourself from admin.");
        require(admins[_account] == true, "No admin found with this address.");
        delete admins[_account];
        removeAddressArrayElement(allAdmins, _account);
        adminCount--;
        return true;
    }

    function getAllAdmins() external view onlyAdmin returns(address[] memory) {
        return allAdmins;
    }

    function totalSupply() external view returns (uint256) {
        return currentTokenId.current();
    }

    function mint(address recipient, string memory uri) public onlyAdmin returns (uint256) {
        currentTokenId.increment();
        uint256 newItemId = currentTokenId.current();
        _tokenURIs[newItemId] = uri;
        _safeMint(recipient, newItemId);
        return newItemId;
    }

    // function _setTokenURI(uint256 _tokenId, string memory _tokenURI) public {
    //   require(_exists(_tokenId), "ERC721Metadata: setTokenURI request for nonexistent token");
    //   require(ownerOf(_tokenId) == msg.sender, "Invalid token owner");
    //   _tokenURIs[_tokenId] = _tokenURI;
    // }

    function tokenURI(uint256 tokenId) public view virtual override returns(string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        return _tokenURIs[tokenId];
    }

    function withdrawNative(address payable to, uint256 amountInWei) external onlyAdmin returns(bool) {
        require(amountInWei <= address(this).balance, "Not enough fund.");
        to.transfer(amountInWei);
        return true;
    }

    function withdrawToken(address _tokenContract, address to, uint256 amount)
     external onlyAdmin returns(bool) {
        IERC20 token = IERC20(_tokenContract);
        require(amount <= token.balanceOf(address(this)), "Not enough fund.");
        token.transfer(to, amount);
        return true;
    }

}
