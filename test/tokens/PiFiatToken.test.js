const expect = require("chai").expect;
const truffleAssert = require('truffle-assertions');
const PiFiatToken = artifacts.require("PiFiatToken");
const delay = ms => new Promise(res => setTimeout(res, ms));

contract("PiFiatToken", async (accounts) => {
  beforeEach(async () => {

  });

  it("initial Balance should be 0", async () => {
    let instance = await PiFiatToken.deployed();
    const account1 = accounts[0];
    let response = await instance.balanceOf(account1);
    expect(response.toNumber()).to.equal(0);
  });
});
