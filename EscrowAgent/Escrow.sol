pragma solidity ^0.8.6;

import "./ITRC20.sol";
import "./SafeMath.sol";

contract Escrow {

    using SafeMath for uint256;

    mapping (address => bool) public owners;
    uint16 public ownerCount;
    address public admin; 
    mapping (address => mapping (address => uint256)) public escrowFund;
    mapping (address => uint256) private feesFund;
    bool public paused;

    event LockBalance(address indexed _tokenContract, address indexed seller, uint256 amountWithFee);
    event ReleaseBalance(address indexed _tokenContract, address indexed seller, address indexed payee,
    uint256 amountWithFee, uint256 totalFee);
    event Withdraw(address indexed _tokenContract, address indexed sender, address indexed receiver,
    uint256 amountWithoutFee, uint256 totalFee, string note);
    event Paused();
    event Unpaused();

    modifier onlyAdmin() {
        require(msg.sender == admin, "Unauthorized request.");
        _;
    }

    modifier onlyOwner() {
        require(owners[msg.sender] == true, "Unauthorized request.");
        _;
    }
    
    modifier ifUnpaused() {
        require(paused == false, "The Contract is paused.");
        _;
    }

    constructor() {
        admin = msg.sender;
        owners[msg.sender] = true;
        ownerCount++;
    }

    function seeFeeFund(address _tokenContract) external view onlyOwner returns(uint256) {
        return feesFund[_tokenContract];
    }

    function addOwner(address _account) external onlyOwner returns(bool) {
        owners[_account] = true;
        ownerCount++;
        return true;
    }

    function deleteOwner(address _account) external onlyAdmin returns(bool) {
        require(_account != msg.sender, "You can't delete yourself form owner.");
        require(owners[_account] == true, "No owner found with this address.");
        delete owners[_account];
        ownerCount--;
        return true;
    }

    function changeAdmin(address _account) external onlyAdmin returns(bool) {
        require(owners[_account] == true, "Admin should be an existing owner.");
        admin = _account;
        return true;
    }

    function pauseContract() external onlyOwner returns(bool){
        paused = true;
        emit Paused();
        return true;
    }

    function unPauseContract() external onlyOwner returns(bool){
        paused = false;
        emit Unpaused();
        return true;
    }

    function withdrawTrx(address payable account, uint256 amount) external onlyOwner returns(bool) {
        require(amount <= address(this).balance, "Not enough TRX.");
        account.transfer(amount);
        return true;
    }

    function withdrawFeeFund(address _tokenContract, address account, uint256 amount)
     external onlyOwner returns(bool) {
        require(amount <= feesFund[_tokenContract], "Not enough fund.");
        feesFund[_tokenContract] = feesFund[_tokenContract].sub(amount);
        ITRC20 token = ITRC20(_tokenContract);
        token.transfer(account, amount);
        return true;
    }

    function withdrawForUser(address _tokenContract, address _sender, address _receiver, uint256 _amountWithoutFee, 
    uint256 _totalFee, string memory _note) external onlyOwner ifUnpaused returns(bool) {
        require(_receiver != msg.sender, "Owner can't be a receiver.");
        require(_tokenContract != address(0), "Token Contract address can't be zero address");
        require(_receiver != address(0), "Payee address can't be zero address");
        
        feesFund[_tokenContract] = feesFund[_tokenContract].add(_totalFee);
        
        ITRC20 token = ITRC20(_tokenContract);
        token.transfer(_receiver, _amountWithoutFee);

        emit Withdraw(_tokenContract, _sender, _receiver, _amountWithoutFee, _totalFee, _note);
        return true;
    }

    function lockAmount(address _tokenContract, address _seller, uint256 _amountWithFee)
    external onlyOwner ifUnpaused returns(bool) {
        require(_tokenContract != address(0), "Contract address can't be zero address");
        require(_seller != address(0), "Seller address can't be zero address");

        escrowFund[_tokenContract][_seller] = escrowFund[_tokenContract][_seller].add(_amountWithFee);
        emit LockBalance(_tokenContract, _seller, _amountWithFee);
        return true;
    }

    function releaseAmount(address _tokenContract, address _payee, address _seller, int256 _amountWithFee, uint256 _totalFee) 
    external onlyOwner returns(bool) {
        require(_tokenContract != address(0), "Token Contract address can't be zero address");
        require(_seller != address(0), "Seller address can't be zero address");
        require(_payee != address(0), "Payee address can't be zero address");

        uint256 amountToSend;
        if (_amountWithFee == -1) {
            amountToSend = escrowFund[_tokenContract][_seller];
        } else {
            amountToSend = uint256(_amountWithFee);
        }
        
        if(_seller != _payee) {
            amountToSend = amountToSend.sub(_totalFee);
            feesFund[_tokenContract] = feesFund[_tokenContract].add(_totalFee);
        }
        
        escrowFund[_tokenContract][_seller] = escrowFund[_tokenContract][_seller].sub(uint256(_amountWithFee));
        ITRC20 token = ITRC20(_tokenContract);
        token.transfer(_payee, amountToSend);

        emit ReleaseBalance(_tokenContract, _seller, _payee, uint256(_amountWithFee), _totalFee);
        return true;
    }
    
}

