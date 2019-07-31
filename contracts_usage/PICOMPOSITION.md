# Contract PiComposition

*A contract designed to handle the composition of PI*

## getComposition ()

Function used to get the current PI's composition. Two arrays are returned, one containning the addresses of the tokens in the composition and another containning the change (PI/token) of each token.

> piComposition.methods.getComposition().call()