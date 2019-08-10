const expect = require("chai").expect;
const truffleAssert = require('truffle-assertions');
const SafeMath = artifacts.require("SafeMath");
const delay = ms => new Promise(res => setTimeout(res, ms));

contract("SafeMath", async (accounts) => {
  beforeEach(async () => {

  });

  it("should mul two numbers", async () => {
    let instance = await SafeMath.deployed();
    const account1 = accounts[0];
    let number1 = 3;
    let number2 = 5;
    let response = await instance.mul(number1, number2, {from: account1});
    expect(response).to.equal(number1 * number2);
  });
});
