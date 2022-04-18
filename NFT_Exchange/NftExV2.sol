pragma solidity ^0.8.13;

import "./IERC20.sol";
import "./IERC721.sol";
import "./SafeMath.sol";

contract NFTexchange {

    using SafeMath for uint256;

    uint256 public chainId;

    string public contractName;
    string public contractVersion;
    
    string private constant EIP712_DOMAIN  = "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)";
    string private constant SELL_TYPE = "SellOrder(string _sellId,uint _expiresAt,address _nftContract,uint256 _nftTokenId,address _seller,uint256 _sellerAmount,uint256 _feeWithRoyalty,uint256 _totalAmount)";
    string private constant BUY_TYPE = "SellOrder(string _buyId,uint _expiresAt,address _nftContract,uint256 _nftTokenId,address _paymentTokenContract,address _buyer,uint256 _sellerAmount,uint256 _feeWithRoyalty,uint256 _totalAmount)";
    
    bytes32 private constant EIP712_DOMAIN_TYPEHASH = keccak256(abi.encodePacked(EIP712_DOMAIN));
    bytes32 private constant SELL_TYPEHASH = keccak256(abi.encodePacked(SELL_TYPE));
    bytes32 private constant BUY_TYPEHASH = keccak256(abi.encodePacked(BUY_TYPE));
    
    bytes32 private DOMAIN_SEPARATOR;

    mapping (address => bool) private admins;
    address[] private allAdmins;
    uint16 public adminCount;

    bool public paused;

    struct SellOrder {
        string _sellId; 
        uint _expiresAt; 
        address _nftContract; 
        uint256 _nftTokenId; 
        address _seller; 
        uint256 _sellerAmount; 
        uint256 _feeWithRoyalty; 
        uint256 _totalAmount;
    }

    struct BuyOrder {
        string _buyId; 
        uint _expiresAt; 
        address _nftContract;
        uint256 _nftTokenId;
        address _paymentTokenContract; 
        address _buyer;
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

    modifier ifUnpaused() {
        require(paused == false, "Contract is paused.");
        _;
    }

    function hashSellOrder(SellOrder memory sell) internal view returns (bytes32){
        return keccak256(abi.encodePacked(
            "\x19\x01",
            DOMAIN_SEPARATOR,
            keccak256(abi.encode(
                SELL_TYPEHASH,
                keccak256(bytes(sell._sellId)),
                sell._expiresAt,
                sell._nftContract,
                sell._nftTokenId,
                sell._seller,
                sell._sellerAmount,
                sell._feeWithRoyalty,
                sell._totalAmount
            ))
        ));
    }

    function verifySeller(SellOrder memory sell, bytes memory sig) public view returns (bool) {    
        (bytes32 r, bytes32 s, uint8 v) = splitSig(sig);
        return sell._seller == ecrecover(hashSellOrder(sell), v, r, s);
    }

    function hashBuyOrder(BuyOrder memory buy) internal view returns (bytes32){
        return keccak256(abi.encodePacked(
            "\x19\x01",
            DOMAIN_SEPARATOR,
            keccak256(abi.encode(
                BUY_TYPEHASH,
                keccak256(bytes(buy._buyId)),
                buy._expiresAt,
                buy._nftContract,
                buy._nftTokenId,
                buy._paymentTokenContract,
                buy._buyer,
                buy._sellerAmount,
                buy._feeWithRoyalty,
                buy._totalAmount
            ))
        ));
    }

    function verifyBuyer(BuyOrder memory buy, bytes memory sig) public view returns (bool) {    
        (bytes32 r, bytes32 s, uint8 v) = splitSig(sig);
        return buy._buyer == ecrecover(hashBuyOrder(buy), v, r, s);
    }

    function splitSig(bytes memory sig) internal pure returns(bytes32 r, bytes32 s, uint8 v) {
        require(sig.length == 65, "invalid signature length");

        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        }
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

    constructor(string memory _contractName, string memory _contractVersion, address _admin) {
        uint256 chain;
        assembly {
            chain := chainid()
        }
        chainId = chain;
        contractName = _contractName;
        contractVersion = _contractVersion;
        DOMAIN_SEPARATOR = keccak256(abi.encode(
            EIP712_DOMAIN_TYPEHASH,
            keccak256(bytes(contractName)),
            keccak256(bytes(contractVersion)),
            chainId,
            address(this)
        ));
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
    ifUnpaused payable external returns(bool) {
        require(sell._nftContract != address(0), "NFT Contract address can't be zero address");
        require(sell._seller != address(0), "Seller address can't be zero address");

        IERC721 nft = IERC721(sell._nftContract);
        require(nft.isApprovedForAll(sell._seller, address(this)), "Don't have approval for NFT.");
        require(nft.ownerOf(sell._nftTokenId) == sell._seller, "Seller doesn't own the NFT.");

        require(block.timestamp < sell._expiresAt, "Sell offer expired.");
        require(msg.value > 0, "Zero amount sent.");
        require(sell._totalAmount == msg.value, "Total Amount and sent amount doesn't match.");

        require(verifySeller(sell, _signature), "Invalid seller signature.");
        
        emit Exchange(exchangeId);

        nft.transferFrom(sell._seller, msg.sender, sell._nftTokenId);

        payable(sell._seller).transfer(sell._sellerAmount);
        return true;
    }

    function sellNFT(BuyOrder memory buy, string memory exchangeId, bytes memory _signature)
    ifUnpaused external returns(bool) {
        require(buy._nftContract != address(0), "NFT Contract address can't be zero address");
        require(buy._buyer != address(0), "Seller address can't be zero address");
        require(buy._paymentTokenContract != address(0), "Payment Token Contract address can't be zero address");

        IERC20 token = IERC20(buy._paymentTokenContract);
        require(token.allowance(buy._buyer, address(this)) > buy._totalAmount, "Don't have approval for Payment Token.");
        require(token.balanceOf(buy._buyer) > buy._totalAmount, "Buyer doesn't have enough Token.");

        IERC721 nft = IERC721(buy._nftContract);
        require(nft.isApprovedForAll(msg.sender, address(this)), "Don't have approval for NFT.");
        require(nft.ownerOf(buy._nftTokenId) == msg.sender, "Seller doesn't own the NFT.");

        require(block.timestamp < buy._expiresAt, "Buy offer expired.");

        require(verifyBuyer(buy, _signature), "Invalid buyer signature.");
        
        emit Exchange(exchangeId);

        nft.transferFrom(msg.sender, buy._buyer, buy._nftTokenId);

        token.transferFrom(buy._buyer, msg.sender, buy._sellerAmount);
        token.transferFrom(buy._buyer, address(this), buy._feeWithRoyalty);
        return true;
    }

    function exchangeNFTauction(string memory exchangeId, address _nftContract, uint256 _nftTokenId, address _paymentTokenContract, 
    address _seller, address _buyer, uint256 _sellerAmount, uint256 _feeWithRoyalty, uint256 _totalAmount) 
    external onlyAdmin ifUnpaused returns(bool) {
        require(_nftContract != address(0), "NFT Contract address can't be zero address");
        require(_paymentTokenContract != address(0), "Payment Token Contract address can't be zero address");
        require(_seller != address(0), "Seller address can't be zero address");
        require(_buyer != address(0), "Buyer address can't be zero address");
        require(_buyer != msg.sender, "Admin can't be a Buyer.");

        IERC721 nft = IERC721(_nftContract);
        require(nft.isApprovedForAll(_seller, address(this)), "Don't have approval for NFT.");
        require(nft.ownerOf(_nftTokenId) == _seller, "Seller doesn't own the NFT.");

        IERC20 token = IERC20(_paymentTokenContract);
        require(token.allowance(_buyer, address(this)) > _totalAmount, "Don't have approval for Payment Token.");
        require(token.balanceOf(_buyer) > _totalAmount, "Buyer doesn't have enough Token.");

        emit Exchange(exchangeId);
        
        nft.transferFrom(_seller, _buyer, _nftTokenId);

        token.transferFrom(_buyer, _seller, _sellerAmount);
        token.transferFrom(_buyer, address(this), _feeWithRoyalty);
        return true;
    }
    
}

