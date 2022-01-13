// SPDX-License-Identifier: MIT

pragma solidity ^0.5.8;

import "./TRC20.sol";
import "./SafeMath.sol";

contract EscrowAgent {
    using SafeMath for uint256;
    address agent; 
    mapping (address => mapping (address => uint256)) deposits;

    modifier onlyAgent() {
        require(msg.sender == agent);
        _;
    }

    constructor() public {
        agent = msg.sender;
    }

    function getBalance(address _contract, address _account) public onlyAgent view returns(uint256) {
        TRC20 token = TRC20(_contract);
        return token.balanceOf(_account);
    }

    function getDeposits(address _contract, address _account) public view returns(uint256) {
        if(msg.sender == agent || msg.sender == _account) {
            return deposits[_contract][_account];
        } else {
            require(false, "Unautorized request");
            _;
        }
    }

    function deposit(address _contract, address _seller, uint256 _amount) public payable {
        TRC20 token = TRC20(_contract);
        token.transfer(agent, _amount);
        deposits[_contract][_seller] = deposits[_contract][_seller].add(_amount);
    }

    function withdraw(address _contract, address payable _payee, int256 _amount) public onlyAgent {
        uint256 amount;
        if (_amount == -1) {
            amount = deposits[_contract][_payee];
        } else {
            amount = uint256(_amount);
        }
        TRC20 token = TRC20(_contract);
        token.transfer(_payee, amount);
        deposits[_contract][_payee] = deposits[_contract][_payee].sub(amount);
    }

}
