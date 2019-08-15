const expect = require("chai").expect;
const truffleAssert = require('truffle-assertions');
const delay = ms => new Promise(res => setTimeout(res, ms));
const BN = web3.utils.BN;

const dexABI = [{"constant":false,"inputs":[{"name":"token","type":"address"}],"name":"listToken","outputs":[],"payable":false,"stateMutability":"nonpayable","type":"function"},{"constant":false,"inputs":[{"name":"_from","type":"address"},{"name":"_value","type":"uint256"}],"name":"tokenFallback","outputs":[],"payable":false,"stateMutability":"nonpayable","type":"function"},{"constant":true,"inputs":[{"name":"","type":"address"}],"name":"salt","outputs":[{"name":"","type":"uint256"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":true,"inputs":[{"name":"","type":"address"}],"name":"listedTokens","outputs":[{"name":"","type":"bool"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":false,"inputs":[{"name":"orderId","type":"bytes32"}],"name":"cancelOrder","outputs":[],"payable":false,"stateMutability":"nonpayable","type":"function"},{"constant":true,"inputs":[{"name":"","type":"address"},{"name":"","type":"address"}],"name":"receivedTokens","outputs":[{"name":"","type":"uint256"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":true,"inputs":[{"name":"","type":"bytes32"}],"name":"orders","outputs":[{"name":"nonce","type":"uint256"},{"name":"owner","type":"address"},{"name":"sending","type":"address"},{"name":"receiving","type":"address"},{"name":"amount","type":"uint256"},{"name":"price","type":"uint256"},{"name":"side","type":"uint256"},{"name":"open","type":"bool"},{"name":"close","type":"bool"},{"name":"cancelled","type":"bool"},{"name":"dealed","type":"bool"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":true,"inputs":[{"name":"_orderId","type":"bytes32"}],"name":"getDeals","outputs":[{"name":"","type":"bytes32[]"},{"name":"","type":"bytes32[]"},{"name":"","type":"uint256[]"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":false,"inputs":[{"name":"receiving","type":"address"},{"name":"price","type":"uint256"},{"name":"side","type":"uint256"}],"name":"setPiOrder","outputs":[{"name":"","type":"bytes32"}],"payable":true,"stateMutability":"payable","type":"function"},{"constant":false,"inputs":[{"name":"owner","type":"address"},{"name":"amount","type":"uint256"},{"name":"receiving","type":"address"},{"name":"price","type":"uint256"},{"name":"side","type":"uint256"}],"name":"setTokenOrder","outputs":[{"name":"","type":"bytes32"}],"payable":false,"stateMutability":"nonpayable","type":"function"},{"constant":false,"inputs":[{"name":"orderA","type":"bytes32"},{"name":"orderB","type":"bytes32"},{"name":"side","type":"uint256"}],"name":"dealOrder","outputs":[{"name":"","type":"bytes32"}],"payable":false,"stateMutability":"nonpayable","type":"function"},{"inputs":[{"name":"dex","type":"address"}],"payable":false,"stateMutability":"nonpayable","type":"constructor"},{"anonymous":false,"inputs":[{"indexed":true,"name":"owner","type":"address"},{"indexed":true,"name":"buying","type":"address"},{"indexed":true,"name":"selling","type":"address"},{"indexed":false,"name":"amount","type":"uint256"},{"indexed":false,"name":"price","type":"uint256"},{"indexed":false,"name":"id","type":"bytes32"}],"name":"SetOrder","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"name":"owner","type":"address"},{"indexed":true,"name":"buying","type":"address"},{"indexed":true,"name":"selling","type":"address"},{"indexed":false,"name":"amount","type":"uint256"},{"indexed":false,"name":"price","type":"uint256"},{"indexed":false,"name":"id","type":"bytes32"}],"name":"CancelOrder","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"name":"id","type":"bytes32"},{"indexed":false,"name":"orderA","type":"bytes32"},{"indexed":false,"name":"orderB","type":"bytes32"}],"name":"Deal","type":"event"}];
const dexADDRESS = "0x0000000000000000000000000000000000000015"
const instance = new web3.eth.Contract(dexABI, dexADDRESS);

const factoryABI = [{"constant":false,"inputs":[{"name":"_new","type":"address"}],"name":"setOwner","outputs":[],"payable":false,"stateMutability":"nonpayable","type":"function"},{"constant":false,"inputs":[],"name":"withdrawFunds","outputs":[],"payable":false,"stateMutability":"nonpayable","type":"function"},{"constant":false,"inputs":[{"name":"name","type":"string"},{"name":"symbol","type":"string"},{"name":"initialSupply","type":"uint256"},{"name":"utf8Symbol","type":"string"}],"name":"createToken","outputs":[{"name":"","type":"address"}],"payable":true,"stateMutability":"payable","type":"function"},{"constant":true,"inputs":[{"name":"","type":"uint256"}],"name":"tokens","outputs":[{"name":"","type":"address"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":true,"inputs":[],"name":"owner","outputs":[{"name":"","type":"address"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":true,"inputs":[],"name":"price","outputs":[{"name":"","type":"uint256"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":false,"inputs":[{"name":"newPrice","type":"uint256"}],"name":"changePrice","outputs":[],"payable":false,"stateMutability":"nonpayable","type":"function"},{"constant":true,"inputs":[{"name":"","type":"bytes32"}],"name":"reservedSymbol","outputs":[{"name":"","type":"bool"}],"payable":false,"stateMutability":"view","type":"function"},{"inputs":[{"name":"_price","type":"uint256"}],"payable":false,"stateMutability":"nonpayable","type":"constructor"},{"anonymous":false,"inputs":[{"indexed":true,"name":"_address","type":"address"},{"indexed":false,"name":"name","type":"string"},{"indexed":false,"name":"symbol","type":"string"},{"indexed":false,"name":"owner","type":"address"},{"indexed":false,"name":"initialSupply","type":"uint256"},{"indexed":false,"name":"utf8Symbol","type":"string"}],"name":"TokenCreated","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"name":"old","type":"address"},{"indexed":true,"name":"current","type":"address"}],"name":"NewOwner","type":"event"}];
const factoryADDRESS = "0x0000000000000000000000000000000000000016";
const factory = new web3.eth.Contract(factoryABI, factoryADDRESS);

const tokenABI = [{"constant":true,"inputs":[],"name":"name","outputs":[{"name":"","type":"string"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":false,"inputs":[{"name":"_to","type":"address"},{"name":"_value","type":"uint256"}],"name":"approve","outputs":[],"payable":false,"stateMutability":"nonpayable","type":"function"},{"constant":false,"inputs":[{"name":"_to","type":"address"},{"name":"_from","type":"address"}],"name":"transferFrom","outputs":[],"payable":false,"stateMutability":"nonpayable","type":"function"},{"constant":false,"inputs":[{"name":"_spender","type":"address"}],"name":"disapprove","outputs":[],"payable":false,"stateMutability":"nonpayable","type":"function"},{"constant":true,"inputs":[],"name":"totalSupply","outputs":[{"name":"","type":"uint256"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":true,"inputs":[{"name":"","type":"address"}],"name":"balances","outputs":[{"name":"","type":"uint256"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":true,"inputs":[],"name":"decimals","outputs":[{"name":"","type":"uint8"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":false,"inputs":[{"name":"_from","type":"address"},{"name":"_value","type":"uint256"}],"name":"tokenFallback","outputs":[],"payable":false,"stateMutability":"nonpayable","type":"function"},{"constant":false,"inputs":[{"name":"_to","type":"address"},{"name":"_value","type":"uint256"}],"name":"mint","outputs":[],"payable":false,"stateMutability":"nonpayable","type":"function"},{"constant":false,"inputs":[{"name":"_value","type":"uint256"}],"name":"burn","outputs":[],"payable":false,"stateMutability":"nonpayable","type":"function"},{"constant":false,"inputs":[{"name":"_to","type":"address"},{"name":"_from","type":"address"},{"name":"_value","type":"uint256"}],"name":"transferFromValue","outputs":[],"payable":false,"stateMutability":"nonpayable","type":"function"},{"constant":true,"inputs":[{"name":"_user","type":"address"}],"name":"balanceOf","outputs":[{"name":"balance","type":"uint256"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":true,"inputs":[],"name":"symbol","outputs":[{"name":"","type":"string"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":false,"inputs":[{"name":"_to","type":"address"},{"name":"_value","type":"uint256"}],"name":"charge","outputs":[],"payable":false,"stateMutability":"nonpayable","type":"function"},{"constant":false,"inputs":[{"name":"_to","type":"address"},{"name":"_value","type":"uint256"}],"name":"transfer","outputs":[],"payable":false,"stateMutability":"nonpayable","type":"function"},{"constant":true,"inputs":[],"name":"_owner","outputs":[{"name":"","type":"address"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":true,"inputs":[],"name":"emisorAddress","outputs":[{"name":"","type":"address"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":false,"inputs":[{"name":"_value","type":"uint256"},{"name":"receiving","type":"address"},{"name":"price","type":"uint256"},{"name":"side","type":"uint256"},{"name":"exchangeAddress","type":"address"}],"name":"setDexOrder","outputs":[{"name":"","type":"bytes32"}],"payable":false,"stateMutability":"nonpayable","type":"function"},{"constant":true,"inputs":[{"name":"","type":"address"},{"name":"","type":"address"}],"name":"approved","outputs":[{"name":"","type":"uint256"}],"payable":false,"stateMutability":"view","type":"function"},{"inputs":[{"name":"name","type":"string"},{"name":"symbol","type":"string"},{"name":"owner","type":"address"},{"name":"initialSupply","type":"uint256"}],"payable":false,"stateMutability":"nonpayable","type":"constructor"},{"anonymous":false,"inputs":[{"indexed":true,"name":"charger","type":"address"},{"indexed":true,"name":"charged","type":"address"},{"indexed":false,"name":"value","type":"uint256"}],"name":"Charge","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"name":"from","type":"address"},{"indexed":true,"name":"to","type":"address"},{"indexed":false,"name":"value","type":"uint256"}],"name":"Transfer","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"name":"owner","type":"address"},{"indexed":true,"name":"spender","type":"address"},{"indexed":false,"name":"value","type":"uint256"}],"name":"Approval","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"name":"from","type":"address"},{"indexed":true,"name":"to","type":"address"},{"indexed":false,"name":"value","type":"uint256"},{"indexed":true,"name":"data","type":"bytes"}],"name":"Transfer","type":"event"}];
const tokenADDRESS = "0x0000000000000000000000000000000000000014";
const token = new web3.eth.Contract(tokenABI, tokenADDRESS);

const account1 = "0xf6bD003d07eBA2027C34fACE6af863Fd3f8B5a14";


require('chai')
  .use(require('chai-bignumber')(BN))
  .should();

contract("PIDEX", async (accounts) => {

  it("should list a token", async () => {
    let rand = Math.random();
    let result = await factory.methods.createToken('name', String(rand), 1000, 'utf8symbol').send({from: account1, gas: 8000000});
    let address = result.events.TokenCreated.returnValues._address;
    let result2 = await instance.methods.listToken(String(address)).send({from: account1});
    let isListed = await instance.methods.listedTokens(String(address)).call();
    expect(isListed).to.equal(true);
  });

  it("should set Pi order", async () => {
    let receiving = "0x0000000000000000000000000000000000000017";
    let price = 2;
    let side = 1;
    let result = await instance.methods.setPiOrder(receiving, price, side).send({from: account1, value: 100, gas: 8000000});
    let id = result.events.SetOrder.returnValues.id;
    let order = await instance.methods.orders(String(id)).call();
    expect(order.owner).to.equal(account1);
    expect(order.sending).to.equal("0x0000000000000000000000000000000000000000");
    expect(order.receiving).to.equal(receiving);
    expect(order.amount).to.equal('100');
    expect(order.price).to.equal(String(price));
    expect(order.side).to.equal(String(side));
  });

  /*it("should set a token Order", async () => {
    let value = 1;
    let receiving = "0x0000000000000000000000000000000000000000";
    let price = 1;
    let side = 1;
    console.log(await token.methods.balanceOf(account1).call())
    let result = await token.methods.setDexOrder(value, receiving, price, side, dexADDRESS).send({from: account1, gas: 8000000});
    console.log(result)
    expect(isListed).to.equal(true);
  });*/

  it("should cancel an order", async () => {
    let receiving = "0x0000000000000000000000000000000000000017";
    let price = 2;
    let side = 1;
    let result = await instance.methods.setPiOrder(receiving, price, side).send({from: account1, value: 100, gas: 8000000});
    let id = result.events.SetOrder.returnValues.id;
    await instance.methods.cancelOrder(id).send({from: account1, gas: 8000000});
    let order = await instance.methods.orders(String(id)).call();
    expect(order.cancelled).to.equal(true);
  });

});
