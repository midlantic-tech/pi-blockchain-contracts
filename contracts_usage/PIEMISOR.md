# Contract PiEmisor

*A contract designed to handle the emission of PI*

## sellPi ()

Function used to send PI to *PiEmisor* contract in exchange of tokens in PI's composition. The amount of PI to send is going to be the tx.value. The contract transfers-back the exact amount of tokens in PI's composition. Note that the commission is 1% (which is used 50% as nodes' reward and 50% retired of circulating to increase PI's value). All transfers occur in the same transaction (atomic procedure).

> piEmisor.methods.sellPi().send({from: accout, value: piAmout, gas: gasLimit})

## purchasePi (uint _value)

Function used to send tokens in PI's composition to *PiEmisor* in exchange of PI. The contract uses function transferFromValue of each *PiFiatToken* contract to transfer itself the calculated amount of each token. The amount of token is calculated according to the desired PI amount indicated in *_value*. Note that the commission is 1% (which is used 50% as nodes' reward and 50% retired of circulating to increase PI's value). All transfers occur in the same transaction (atomic procedure).