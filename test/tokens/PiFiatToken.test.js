const expect = require("chai").expect;
const truffleAssert = require('truffle-assertions');
const delay = ms => new Promise(res => setTimeout(res, ms));
const tokenABI = [{"constant":true,"inputs":[],"name":"name","outputs":[{"name":"","type":"string"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":false,"inputs":[{"name":"_to","type":"address"},{"name":"_value","type":"uint256"}],"name":"approve","outputs":[],"payable":false,"stateMutability":"nonpayable","type":"function"},{"constant":false,"inputs":[{"name":"_to","type":"address"},{"name":"_from","type":"address"}],"name":"transferFrom","outputs":[],"payable":false,"stateMutability":"nonpayable","type":"function"},{"constant":false,"inputs":[{"name":"_spender","type":"address"}],"name":"disapprove","outputs":[],"payable":false,"stateMutability":"nonpayable","type":"function"},{"constant":true,"inputs":[],"name":"totalSupply","outputs":[{"name":"","type":"uint256"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":true,"inputs":[{"name":"","type":"address"}],"name":"balances","outputs":[{"name":"","type":"uint256"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":true,"inputs":[],"name":"decimals","outputs":[{"name":"","type":"uint8"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":false,"inputs":[{"name":"_from","type":"address"},{"name":"_value","type":"uint256"}],"name":"tokenFallback","outputs":[],"payable":false,"stateMutability":"nonpayable","type":"function"},{"constant":false,"inputs":[{"name":"_to","type":"address"},{"name":"_value","type":"uint256"}],"name":"mint","outputs":[],"payable":false,"stateMutability":"nonpayable","type":"function"},{"constant":false,"inputs":[{"name":"_value","type":"uint256"}],"name":"burn","outputs":[],"payable":false,"stateMutability":"nonpayable","type":"function"},{"constant":false,"inputs":[{"name":"_to","type":"address"},{"name":"_from","type":"address"},{"name":"_value","type":"uint256"}],"name":"transferFromValue","outputs":[],"payable":false,"stateMutability":"nonpayable","type":"function"},{"constant":true,"inputs":[{"name":"_user","type":"address"}],"name":"balanceOf","outputs":[{"name":"balance","type":"uint256"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":true,"inputs":[],"name":"symbol","outputs":[{"name":"","type":"string"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":false,"inputs":[{"name":"_to","type":"address"},{"name":"_value","type":"uint256"}],"name":"charge","outputs":[],"payable":false,"stateMutability":"nonpayable","type":"function"},{"constant":false,"inputs":[{"name":"_to","type":"address"},{"name":"_value","type":"uint256"}],"name":"transfer","outputs":[],"payable":false,"stateMutability":"nonpayable","type":"function"},{"constant":true,"inputs":[],"name":"_owner","outputs":[{"name":"","type":"address"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":true,"inputs":[],"name":"emisorAddress","outputs":[{"name":"","type":"address"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":false,"inputs":[{"name":"_value","type":"uint256"},{"name":"receiving","type":"address"},{"name":"price","type":"uint256"},{"name":"side","type":"uint256"},{"name":"exchangeAddress","type":"address"}],"name":"setDexOrder","outputs":[{"name":"","type":"bytes32"}],"payable":false,"stateMutability":"nonpayable","type":"function"},{"constant":true,"inputs":[{"name":"","type":"address"},{"name":"","type":"address"}],"name":"approved","outputs":[{"name":"","type":"uint256"}],"payable":false,"stateMutability":"view","type":"function"},{"inputs":[{"name":"name","type":"string"},{"name":"symbol","type":"string"},{"name":"owner","type":"address"},{"name":"initialSupply","type":"uint256"}],"payable":false,"stateMutability":"nonpayable","type":"constructor"},{"anonymous":false,"inputs":[{"indexed":true,"name":"charger","type":"address"},{"indexed":true,"name":"charged","type":"address"},{"indexed":false,"name":"value","type":"uint256"}],"name":"Charge","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"name":"from","type":"address"},{"indexed":true,"name":"to","type":"address"},{"indexed":false,"name":"value","type":"uint256"}],"name":"Transfer","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"name":"owner","type":"address"},{"indexed":true,"name":"spender","type":"address"},{"indexed":false,"name":"value","type":"uint256"}],"name":"Approval","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"name":"from","type":"address"},{"indexed":true,"name":"to","type":"address"},{"indexed":false,"name":"value","type":"uint256"},{"indexed":true,"name":"data","type":"bytes"}],"name":"Transfer","type":"event"}];
const tokenADDRESS = "0x0000000000000000000000000000000000000017";
const instance = new web3.eth.Contract(tokenABI, tokenADDRESS);
const account1 = "0xf6bd003d07eba2027c34face6af863fd3f8b5a14";
const account2 = "0x41592fabe9d48ad34decb858f4483dd17449e1c3";

contract("PiFiatToken", async (accounts) => {

  it("should return token name", async () => {
    let name = await instance.methods.name().call();
    expect(name).to.equal('Token Bolivar');
  });

  it("should return token symbol", async () => {
    let symbol = await instance.methods.symbol().call();
    expect(symbol).to.equal('VESx');
  });

  it("should return token decimals", async () => {
    let decimals = await instance.methods.decimals().call();
    expect(decimals).to.equal('18');
  });

  it("initial Balance should be greater than 0", async () => {
    let balance = await instance.methods.balanceOf(account1).call();
    expect(parseInt(balance)).to.be.above(0);
  });

  it("should transfer from acc1 to acc2", async () => {
    let value = 1;
    let balance1a = await instance.methods.balanceOf(account1).call();
    let balance2a = await instance.methods.balanceOf(account2).call();
    balance1a = parseInt(balance1a);
    balance2a = parseInt(balance2a);
    let result = await instance.methods.transfer(account2, value).send({from: account1});
    let balance1b = await instance.methods.balanceOf(account1).call();
    let balance2b = await instance.methods.balanceOf(account2).call();
    balance1b = parseInt(balance1b);
    balance2b = parseInt(balance2b);
    expect(balance1b).to.equal(balance1a-value);
    expect(balance2b).to.equal(balance2a+value);
  });

  it("should approve acc1", async () => {
    let value = 2;
    let approved1 = await instance.methods.approved(account1, account1).call();
    let result = await instance.methods.approve(account1, value).send({from: account1});
    let approved2 = await instance.methods.approved(account1, account1).call();
    expect(parseInt(approved2)).to.equal(parseInt(approved1)+value);
  });

  it("should transferFrom just value", async () => {
    let value = 1;
    let approved1 = await instance.methods.approved(account1, account1).call();
    let result = await instance.methods.transferFromValue(account1, account1, value).send({from: account1});
    let approved2 = await instance.methods.approved(account1, account1).call();
    expect(parseInt(approved2)).to.equal(parseInt(approved1)-value);
  });

  it("should transferFrom all aproved", async () => {
    let result = await instance.methods.transferFrom(account1, account1).send({from: account1});
    let approved2 = await instance.methods.approved(account1, account1).call();
    expect(parseInt(approved2)).to.equal(0);
  });

  it("should approve and then disapprove", async () => {
    let value = 1;
    let result = await instance.methods.approve(account1, value).send({from: account1});
    let approved1 = await instance.methods.approved(account1, account1).call();
    let result2 = await instance.methods.disapprove(account1).send({from: account1});
    let approved2 = await instance.methods.approved(account1, account1).call();
    expect(parseInt(approved1)).to.be.above(0);
    expect(parseInt(approved2)).to.equal(0);
  });

  it("should mint amount of token", async () => {
    let value = 100;
    let balance1 = await instance.methods.balanceOf(account1).call();
    let result = await instance.methods.mint(account1, value).send({from: account1});
    let balance2 = await instance.methods.balanceOf(account1).call();
    expect(parseInt(balance2)).to.equal(parseInt(balance1)+value);
  });

  it("should burn amount of token", async () => {
    let value = 10;
    let balance1 = await instance.methods.balanceOf(account1).call();
    let result = await instance.methods.burn(value).send({from: account1});
    let balance2 = await instance.methods.balanceOf(account1).call();
    expect(parseInt(balance2)).to.equal(parseInt(balance1)-value);
  });
});
