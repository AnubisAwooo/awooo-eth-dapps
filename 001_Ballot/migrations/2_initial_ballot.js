const Ballot = artifacts.require("Ballot");

module.exports = function (deployer) {
  // 还是不能够部署，truffle 的语法要学了才行，等后面把 truffle 学习完毕，再回头部署
  deployer.deploy(Ballot, [["Proposal1", "Proposal2"]]); 
};
