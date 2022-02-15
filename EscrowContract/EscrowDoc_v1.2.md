# Intro
There are two types of role here, admins and owners.
first admin itself will be also an owner.
Admin and owner can be multiple.
Admins can do everything. Owners have very limited priviledge.
<br>-----------------------------------------------------------------------------------------------------------------------------------------------------<br>

# Format
function(parameter): accessType<br>
Short description
<br>-----------------------------------------------------------------------------------------------------------------------------------------------------<br>

# Read Functions
<b>adminCount(): public</b><br>
will return the admin count

<b>getAllAdmins(): onlyAdmin</b><br>
will return all the admin addresses

<b>getAllOwners(): onlyAdmin</b><br>
will return all the owner addresses

<b>getAllPendingTradeIds(): onlyAdmin</b><br>
will return all the pending tradeIds

<b>ownerCount(): public</b><br>
will return the owner count

<b>owners(account_address): public</b><br>
it will take any account address and will return true or false if the account is an owner or not.

<b>paused(): public</b><br>
it will return true or false if the contract functionality (<b>lockAmount(), withdrawForUser()</b>) is paused or not.

<b>pendingTrades(tradeId): public</b><br>
it will take any tradeId as string and will return a hash value if exists otherwise zero (0x000..00).

<b>seeEscrowFund(_tokenContract_address, _account_address): public</b><br>
This function returns the total  locked/escrow amount of an account on a specific token.<br>
_tokenContract_address is e.g: USDT contract address,<br>
_account_address is any account address

<b>seeFeeFund(_tokenContract_address): adminOrOwner</b><br>
This function returns the total fee amount stored in the contract on a specific token.<br>
_tokenContract_address is e.g: USDT contract address,<br>

<br>-----------------------------------------------------------------------------------------------------------------------------------------------------<br>

# Write Functions

<b>addAdmin(_account_address): onlyAdmin</b><br>
This function adds account as an admin.<br>
_account_address is any account address

<b>addEscrowRecord(_tokenContract_address, _tradeId _seller_address,_buyer_ddress, _amountwithFee, _totalFee): onlyAdmin</b><br>
This function adds a trade entity by <b>(key => value)</b> mapping <b>(_tradeId => hash(other parameters))</b> and also keeps track/saves an amount in escrow fund of an account(_seller_address) on a specific token. This function will be used from our backend application actually.<br>
_tokenContract_address is e.g: USDT contract address<br>
_tradeId is a unique random string<br>
_seller_address is any account address<br>
_buyer_address is any account address<br>
_amountWithFee is just an amount of the token<br>
_totalFee is just an amount of the token<br>

<b>addOwner(_account_address): onlyAdmin</b><br>
This function adds account as an owner.<br>
_account_address is any account address

<b>deleteAdmin(_account_address): onlyAdmin</b><br>
This function deletes an Admin from the contract.<br>
_account_address is any account address

<b>deleteOwner(_account_address): onlyAdmin</b><br>
This function deletes an owner from the contract.<br>
_account_address is any account address

<b>pauseContract(): onlyAdmin</b><br>
This function makes the pause status true.<br>
This status checking applied on (<b>lockAmount(), withdrawForUser()</b>)

<b>releaseAmount(_tokenContract_address, _tradeId, _seller_address, _buyer_address,_amountWithFee, _totalFee, _success): adminOrOwner</b><br>
This function first matches the _tradeId and the hash(other parameters) with the previously saved hash(while escrow record) mapping with this _tradeId. Then checks locked amount/escrow fund of the _seller account of a specific token and then (keeps the fee and sends the amount) to the _buyer if the param <b>_success</b> is true, otherwise returns the (amount to seller and doesn't keep any fee). Then updates the escrow fund record for this seller. This function will be used from our backend application actually.<br>
_tokenContract_address is e.g: USDT contract address<br>
_tradeId is a unique random string<br>
_seller_address is any account address<br>
_buyer_address is any account address<br>
_amountWithFee is just an amount of the token<br>
_totalFee is just an amount of the token<br>
_success is a boolean value, true or false<br>

<b>unPauseContract(): onlyAdmin</b><br>
This function makes the pause status false.<br>

<b>withdrawFeeFund(_tokenContract_address, _to_address, _amount): onlyAdmin</b><br>
This function sends the _amount of a specific token to the _to_address account from fee fund of this contract.<br>
_tokenContract_address is e.g: USDT contract address<br>
_to_address is any account address<br>
_amoun is just an amount of regarding token<br>

<b>withdrawForUser(_tokenContract_address, _sender_address, _receiver_address,_amountWithoutFee, _totalFee, _note): onlyAdmin</b><br>
This function sends the amount(_amountWithoutFee) from this contract balance on a specific token to the _receiver_address account. This function will be used from our backend application actually.<br>
_tokenContract_address is e.g: USDT contract address,<br>
_sender_address is any account address<br>
_receiver_address is any account address (but not any owner address)<br>
_amountWithoutFee is just an amount of regarding token<br>
_totalFee is just an amount of regarding token<br>
_note is just a text<br>

<b>withdrawTrx(_tokenContract_address, _to_address, _amount): onlyAdmin</b><br>
This function sends (_amount)TRX from this contract balance if it holds TRX.<br>
_tokenContract_address is e.g: USDT contract address<br>
_to_address is any account address<br>
_amoun is just an amount of regarding token<br>