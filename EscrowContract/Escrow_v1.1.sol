pragma solidity ^0.8.6;

import "./ITRC20.sol";
import "./SafeMath.sol";

contract Escrow {

    using SafeMath for uint256;

    mapping (address => bool) public owners;
    address[] private allOwners;
    uint16 public ownerCount;

    mapping (address => bool) public admins;
    address[] private allAdmins;
    uint16 public adminCount;

    struct Trade {
        address token;
        address seller;
        address buyer;
        uint256 amountWithFee;
        uint256 totalFee;
    } 

    mapping (address => mapping (address => uint256)) private escrowFund;
    mapping (string => Trade) public pendingTrades;
    // string[] private pendingTradeIds;

    mapping (address => uint256) private feesFund;
    bool public paused;

    event EscrowRecord(string tradeId);
    event ReleaseBalance(string tradeId, bool success);
    event Withdraw(address indexed _tokenContract, address indexed sender, address indexed receiver,
    uint256 amountWithoutFee, uint256 totalFee, string note);
    event Paused();
    event Unpaused();

    modifier onlyAdmin() {
        require(admins[msg.sender] == true, "Unauthorized request.");
        _;
    }

    modifier adminOrOwner() {
        require(admins[msg.sender] == true || owners[msg.sender] == true, "Unauthorized request.");
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

    /* function removeStringArrayElement(string[] storage _arr, string memory _elem) internal {
        bool found;
        uint index;
        for(uint i = 0; i<_arr.length; i++) {
            if(compareString(_arr[i], _elem)) {
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

    function compareString(string memory _a, string memory _b) internal returns(bool) {
        return keccak256(abi.encode(_a)) == keccak256(abi.encode(_b));
    } */

    constructor(address _admin) {
        admins[_admin] = true;
        allAdmins.push(_admin);
        adminCount++;

        owners[_admin] = true;
        allOwners.push(_admin);
        ownerCount++;
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
    
    function addOwner(address _account) external onlyAdmin returns(bool) {
        owners[_account] = true;
        allOwners.push(_account);
        ownerCount++;
        return true;
    }

    function deleteOwner(address _account) external onlyAdmin returns(bool) {
        require(owners[_account] == true, "No owner found with this address.");
        delete owners[_account];
        removeAddressArrayElement(allOwners, _account);
        ownerCount--;
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

    function getAllOwners() external view onlyAdmin returns(address[] memory) {
        return allOwners;
    }
    
    /* function getAllPendingTradeIds() external view onlyAdmin returns(string[] memory) {
        return pendingTradeIds;
    } */

    function seeFeeFund(address _tokenContract) external view adminOrOwner returns(uint256) {
        return feesFund[_tokenContract];
    }

    function seeEscrowFund(address _tokenContract, address _account) external view returns(uint256) {
        return escrowFund[_tokenContract][_account];
    }

    function withdrawTrx(address payable to, uint256 amount) external onlyAdmin returns(bool) {
        require(amount <= address(this).balance, "Not enough TRX.");
        to.transfer(amount);
        return true;
    }

    function withdrawFeeFund(address _tokenContract, address to, uint256 amount)
     external onlyAdmin returns(bool) {
        require(amount <= feesFund[_tokenContract], "Not enough fund.");
        feesFund[_tokenContract] = feesFund[_tokenContract].sub(amount);
        ITRC20 token = ITRC20(_tokenContract);
        token.transfer(to, amount);
        return true;
    }

    function withdrawForUser(address _tokenContract, address _sender, address _receiver, uint256 _amountWithoutFee, 
    uint256 _totalFee, string memory _note) external onlyAdmin returns(bool) {
        require(_tokenContract != address(0), "Token Contract address can't be zero address");
        require(_receiver != address(0), "Receiver address can't be zero address");
        require(_receiver != msg.sender, "Owner can't be a receiver.");
        
        feesFund[_tokenContract] = feesFund[_tokenContract].add(_totalFee);
        
        ITRC20 token = ITRC20(_tokenContract);
        token.transfer(_receiver, _amountWithoutFee);

        emit Withdraw(_tokenContract, _sender, _receiver, _amountWithoutFee, _totalFee, _note);
        return true;
    }

    function addEscrowRecord(address _tokenContract, string memory _tradeId, address _seller, address _buyer, uint256 _amountWithFee, uint256 _totalFee)
    external onlyAdmin returns(bool) {
        require(_tokenContract != address(0), "Contract address can't be zero address");
        require(_seller != address(0), "Seller address can't be zero address");
        require(_buyer != address(0), "Buyer address can't be zero address");

        pendingTrades[_tradeId] = Trade(_tokenContract, _seller, _buyer, _amountWithFee, _totalFee);
        //pendingTradeIds.push(_tradeId);
        escrowFund[_tokenContract][_seller] = escrowFund[_tokenContract][_seller].add(_amountWithFee);

        emit EscrowRecord(_tradeId);
        return true;
    }

    function releaseAmount(string memory _tradeId, bool _success) external adminOrOwner returns(bool) {
        require(pendingTrades[_tradeId].token != address(0), "Trade Id not found.");
        Trade memory trade = pendingTrades[_tradeId];
        address _payee = trade.seller;

        require(uint256(trade.amountWithFee) <= escrowFund[trade.token][trade.seller], 
        "Invalid trade id, Not enough balance in Escrow fund of this seller.");
        
        uint256 amountToSend = uint256(trade.amountWithFee);
        if(_success) {
            _payee = trade.buyer;
            amountToSend = amountToSend.sub(trade.totalFee);
            feesFund[trade.token] = feesFund[trade.token].add(trade.totalFee);
        }
        
        escrowFund[trade.token][trade.seller] = escrowFund[trade.token][trade.seller].sub(uint256(trade.amountWithFee));
        delete pendingTrades[_tradeId];
        //removeStringArrayElement(pendingTradeIds, _tradeId);
        ITRC20 token = ITRC20(trade.token);
        token.transfer(_payee, amountToSend);

        emit ReleaseBalance(_tradeId, _success);
        return true;
    }
    
}
