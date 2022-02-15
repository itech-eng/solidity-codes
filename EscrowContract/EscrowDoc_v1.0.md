# Intro
There are two types of role here, admin and owners.
admin itself is also an owner.
There can be only one admin but owner can be multiple.
Owners can do everything except
changing the admin and deleteing any owner.
<br>-----------------------------------------------------------------------------------------------------------------------------------------------------<br>

# Format
function(parameter): access<br>
Short description
<br>-----------------------------------------------------------------------------------------------------------------------------------------------------<br>

# Read Functions
<b>admin(): public</b><br>
This function will return the current admin address.

<b>ownerCount(): public</b><br>
will return the owner count

<b>owners(account_address): public</b><br>
it will take any account address and will return true or false if the account is an owner or not.

<b>paused(): public</b><br>
it will return true or false if the contract functionality (<b>lockAmount(), withdrawForUser()</b>) is paused or not.

<b>seeEscrowFund(_tokenContract_address, _account_address): public</b><br>
This function returns the total  locked/escrow amount of an account on a specific token.<br>
_tokenContract_address is e.g: USDT contract address,<br>
_account_address is any account address

<b>seeFeeFund(_tokenContract_address): owner</b><br>
This function returns the total fee amount stored in the contract on a specific token.<br>
_tokenContract_address is e.g: USDT contract address,<br>

<br>-----------------------------------------------------------------------------------------------------------------------------------------------------<br>

# Write Functions

<b>addOwner(_account_address): owner</b><br>
This function adds account as an owner.<br>
_account_address is any account address

<b>changeAdmin(_account_address): admin</b><br>
This function changes/replaces the admin of the contract. New admin must be an existing owner.<br>
_account_address is any account address

<b>deleteOwner(_account_address): admin</b><br>
This function deletes an owner from the contract.<br>
_account_address is any account address

<b>lockAmount(_tokenContract_address, _seller_address,_amountwithFee): owner</b><br>
This function keeps track/saves an amount in escrow fund of an account(_seller_address) on a specific token. This function will be used from our backend application actually.<br>
_tokenContract_address is e.g: USDT contract address,<br>
_seller_address is any account address<br>
_amountwithFee is just an amount of regarding token

<b>pauseContract(): owner</b><br>
This function makes the pause status true.<br>
This status checking applied on (<b>lockAmount(), withdrawForUser()</b>)

<b>releaseAmount(_tokenContract_address, _payee_address, _seller_address,_amountWithFee, _totalFee): owner</b><br>
This function checks the locked amount/escrow fund of the _seller account of a specific token and then sends the amount to the _payee account. This function will be used from our backend application actually.<br>
_tokenContract_address is e.g: USDT contract address,<br>
_payee_address is any account address (but not any owner address)<br>
_seller_address is any account address<br>
_amountWithFee is just an amount of regarding token<br>
_totalFee is just an amount of regarding token<br>

<b>unPauseContract(): owner</b><br>
This function makes the pause status false.<br>

<b>withdrawFeeFund(_tokenContract_address, _to_address, _amount): owner</b><br>
This function sends the _amount of a specific token to the _to_address account from fee fund of this contract.<br>
_tokenContract_address is e.g: USDT contract address<br>
_to_address is any account address<br>
_amoun is just an amount of regarding token<br>

<b>withdrawForUser(_tokenContract_address, _sender_address, _receiver_address,_amountWithoutFee, _totalFee, _note): owner</b><br>
This function sends the amount(_amountWithoutFee) from this contract balance on a specific token to the _receiver_address account. This function will be used from our backend application actually.<br>
_tokenContract_address is e.g: USDT contract address,<br>
_sender_address is any account address<br>
_receiver_address is any account address (but not any owner address)<br>
_amountWithoutFee is just an amount of regarding token<br>
_totalFee is just an amount of regarding token<br>
_note is just a text<br>

<b>withdrawTrx(_tokenContract_address, _to_address, _amount): owner</b><br>
This function sends (_amount)TRX from this contract balance if it holds TRX.<br>
_tokenContract_address is e.g: USDT contract address<br>
_to_address is any account address<br>
_amoun is just an amount of regarding token<br>