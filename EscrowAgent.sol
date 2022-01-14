// SPDX-License-Identifier: MIT

pragma solidity ^0.5.8;

import "./TRC20.sol";
import "./SafeMath.sol";

contract EscrowAgent {
    using SafeMath for uint256;
    address agent; 
    mapping (address => mapping (address => uint256)) deposits;

    modifier onlyAgent() {
        require(msg.sender == agent, "Unauthorized request");
        _;
    }

    constructor() public {
        agent = msg.sender;
    }

    function getTRC20Balance(address _contract, address _account) public onlyAgent view returns(uint256) {
        TRC20 token = TRC20(_contract);
        return token.balanceOf(_account);
    }

    function getLockedAmount(address _contract, address _account) public view returns(uint256) {
        require(msg.sender == agent || msg.sender == _account, "Unautorized request");
        return deposits[_contract][_account];
    }

    function lockAmount(address _contract, address _seller, uint256 _amount) public payable returns(bool) {
        TRC20 token = TRC20(_contract);
        // token.approve(address(this), _amount);
        //token.transferFrom(_seller, agent, _amount);
        deposits[_contract][_seller] = deposits[_contract][_seller].add(_amount);
        return true;
    }

    function releaseAmount(address _contract, address _payee, address _seller, int256 _amount) public onlyAgent returns(bool){
        uint256 amount;
        if (_amount == -1) {
            amount = deposits[_contract][_seller];
        } else {
            amount = uint256(_amount);
        }
        TRC20 token = TRC20(_contract);
        // token.approve(address(this), amount);
        //token.transferFrom(agent, _payee, amount);
        deposits[_contract][_seller] = deposits[_contract][_seller].sub(amount);
        return true;
    }

}
