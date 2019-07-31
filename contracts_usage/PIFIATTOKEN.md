# Contract PiFiatToken

*A contract designed to handle Fiat Tokens*

## balanceOf (address _user)

Function used to get the balance of an account.

> token.methods.balanceOf(_user).call()

## transfer (address _to, uint _value)

Function used to transfer token (_value) to an address (_to). 

> token.methods.transfer(_to, _value).send({from: account, gas: gasLimit})

## setDexOrder (uint _value, address receiving, uint price, address exchangeAddress) public returns (bytes32)

Function used to set an order of *_value* amount, buying certain token with address *receiving* (address(0) when buying PI) and price *price*. The order will be set in the *PIDEX* contract with address *exchangeAddress*. The function returns the ID of the order.

> token.setDexOrder(_value, receiving, price, exchangeAddress).send({from: account, gas: gasLimit})

## approve (address _to, uint _value)

Function used to approve another address (_to) to transfer token from the aproving address. The max amount *_to* can spend is *_value*. 

> token.methods.approve(_to, _value).send({from: account, gas: gasLimit})

## disapprove (address _spender) 

Function used to disapprove a previously approved *_spender*.

> token.methods.disapprove(_spender).send({from: account, gas: gasLimit})

## transferFrom (address _to, address payable _from)

Function used to transfer ALL the approved amount of token from *_from* address to *_to* address.

> token.methods.transferFrom(_to, _from).send({from: account, gas: gasLimit})

## transferFromValue (address _to, address payable _from, uint _value)

Function used to transfer PART (*_value*) of the approved amount of token from *_from* address to *_to* address.

> token.methods.transferFromValue(_to, _from, _value).send({from: account, gas: gasLimit})

## mint (address _to, uint _value)

Function used to the creation of certain amount (*_value*) of token. The created tokens go to the balance of address *_to*. This function is only callable from the owner of the token.

> token.methods.mint(_to, _value).send({from: account, gas: gasLimit})

## burn (uint _value) 

Function used to the redemption of certain amount (*_value*) of token from the address who originated the transaction. This function is only callable from the owner of the token.

> token.methods.burn(_value).send({from: account, gas: gasLimit})