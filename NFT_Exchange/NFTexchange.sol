pragma solidity ^0.8.13;

import "./IERC20.sol";
import "./IERC721.sol";
import "./SafeMath.sol";

contract NFTExchange {

    using SafeMath for uint256;

    mapping (address => bool) private admins;
    address[] private allAdmins;
    uint16 public adminCount;

    bool public paused;

    struct SellOrder {
        string _sellId; 
        uint expiresAt; 
        address _nftContract; 
        uint256 _nftTokenId; 
        address _seller; 
        uint256 _sellerAmount; 
        uint256 _feeWithRoyalty; 
        uint256 _totalAmount;
    }

    event Exchange(string indexed exchangeId);

    event Paused();
    event Unpaused();

    modifier onlyAdmin() {
        require(admins[msg.sender] == true, "Unauthorized request.");
        _;
    }

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

    constructor(address _admin) {
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

    function pauseContract() external onlyAdmin returns(bool){
        paused = true;
        emit Paused();
        return true;
    }

    function unPauseContract() external onlyAdmin returns(bool){
        paused = false;
        emit Unpaused();
        return true;
    }

    function getAllAdmins() external view onlyAdmin returns(address[] memory) {
        return allAdmins;
    }

    function withdrawETH(address payable to, uint256 amountInWei) external onlyAdmin returns(bool) {
        require(amountInWei <= address(this).balance, "Not enough ETH.");
        to.transfer(amountInWei);
        return true;
    }

    function withdrawERC20Token(address _tokenContract, address to, uint256 amount)
     external onlyAdmin returns(bool) {
        IERC20 token = IERC20(_tokenContract);
        require(amount <= token.balanceOf(address(this)), "Not enough fund.");
        token.transfer(to, amount);
        return true;
    }

    function buyNFT(SellOrder memory sell, string memory exchangeId, bytes memory _signature)
    payable external returns(bool) {
        require(sell._nftContract != address(0), "NFT Contract address can't be zero address");
        require(sell._seller != address(0), "Seller address can't be zero address");

        IERC721 nft = IERC721(sell._nftContract);
        require(nft.isApprovedForAll(sell._seller, address(this)), "Don't have approval for NFT.");
        require(nft.ownerOf(sell._nftTokenId) == sell._seller, "Seller doesn't own the NFT.");

        require(block.timestamp < sell.expiresAt, "Sell offer expired.");
        require(msg.value > 0, "Zero amount sent.");
        require(sell._totalAmount == msg.value, "Total Amount and sent amount doesn't match.");

        bytes32 hash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32",
        keccak256(abi.encodePacked(sell._sellId, sell.expiresAt, sell._nftContract, sell._nftTokenId, 
        sell._seller, sell._sellerAmount, sell._feeWithRoyalty, sell._totalAmount))));
        (bytes32 r, bytes32 s, uint8 v) = splitSig(_signature);
        address signer = ecrecover(hash, v, r, s);
        require(signer == sell._seller, "Invalid seller signature.");
        
        emit Exchange(exchangeId);

        nft.transferFrom(sell._seller, msg.sender, sell._nftTokenId);

        payable(sell._seller).transfer(sell._sellerAmount);
        return true;
    }

    function exchangeNFT(string memory exchangeId, address _nftContract, uint256 _nftTokenId, address _paymentTokenContract, 
    address _seller, address _buyer, uint256 _sellerAmount, uint256 _feeWithRoyalty, uint256 _totalAmount) 
    external onlyAdmin returns(bool) {
        require(_nftContract != address(0), "NFT Contract address can't be zero address");
        require(_paymentTokenContract != address(0), "Payment Token Contract address can't be zero address");
        require(_seller != address(0), "Seller address can't be zero address");
        require(_buyer != address(0), "Buyer address can't be zero address");
        require(_buyer != msg.sender, "Admin can't be a Buyer.");

        IERC721 nft = IERC721(_nftContract);
        require(nft.isApprovedForAll(_seller, address(this)), "Don't have approval for NFT.");
        require(nft.ownerOf(_nftTokenId) == _seller, "Seller doesn't own the NFT.");

        IERC20 token = IERC20(_paymentTokenContract);
        require(token.allowance(_buyer, address(this)) > _totalAmount, "Don't have approval for Token.");
        require(token.balanceOf(_buyer) > _totalAmount, "Buyer doesn't have enough Token.");

        
        emit Exchange(exchangeId);
        
        nft.transferFrom(_seller, _buyer, _nftTokenId);

        token.transferFrom(_buyer, _seller, _sellerAmount);
        token.transferFrom(_buyer, address(this), _feeWithRoyalty);
        return true;
    }

    function splitSig(bytes memory sig) internal pure returns(bytes32 r, bytes32 s, uint8 v) {
        require(sig.length == 65, "invalid signature length");

        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        }
    }
    
}

