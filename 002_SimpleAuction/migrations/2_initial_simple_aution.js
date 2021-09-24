const SimpleAuction = artifacts.require("SimpleAuction");

module.exports = function (deployer) {
    deployer.deploy(SimpleAuction, [60 * 60 * 24, "0x0000000000000000000000000000000000000000"]);
};
