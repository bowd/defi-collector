pragma solidity >=0.4.25 <0.7.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/ownership/Ownable.sol";

contract DependencyRegistry is Ownable {
    mapping(uint => address) internal dependencies;
    uint internal maxDeps;

    constructor(address[] memory initialDeps, uint8 maxDeps_) public {
        require(initialDeps.length <= maxDeps_, "dependency-registry:initial-deps-too-large");
        maxDeps = maxDeps_;

        for (uint i = 0; i < initialDeps.length; i++) {
            dependencies[i] = initialDeps[i];
        }
    }

    function setDependency(uint8 index, address dependency) public onlyOwner {
        require(index <= maxDeps, "dependency-registry:index-out-of-range");
        dependencies[index] = dependency;
    }

    function getDependency(uint8 index) public view returns (address) {
        require(index < maxDeps, "dependency-registry:index-out-of-range");
        address addr = dependencies[index];
        // require(addr > address(0), "dependency-registry:dep-not-set");
        return addr;
    }
}
