const SafeMath = artifacts.require("SafeMath");
const PiFiatToken = artifacts.require("PiFiatToken");

module.exports = function(deployer) {
  deployer.deploy(SafeMath);
  deployer.deploy(PiFiatToken, "Name", "Symbol", "0x0000000000000000000000000000000000000000", 1000000);
};
