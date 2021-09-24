const BlindAuction = artifacts.require("BlindAuction");

module.exports = function (deployer) {
    deployer.deploy(BlindAuction, [60 * 60 * 24, 60 * 60 * 24, 0x0000000000000000000000000000000000000000]);
};
