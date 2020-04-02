pragma solidity ^0.5.17;

import "../vendor/Ownable.sol";

contract DependencyRegistry is Ownable {
    mapping(uint => address) internal dependencies;
    uint internal maxDeps;

    constructor(address[] memory initialDeps, uint maxDeps_) public {
        require(initialDeps.length <= maxDeps_, "dependency-registry:initial-deps-too-large");
        maxDeps = maxDeps_;

        for (uint i = 0; i < initialDeps.length; i++) {
            dependencies[i] = initialDeps[i];
        }
    }

    function setDependency(uint index, address dependency) public onlyOwner {
        require(index <= maxDeps, "dependency-registry:index-out-of-range");
        dependencies[index] = dependency;
    }

    function getDependency(uint index) public view returns (address) {
        require(index < maxDeps, "dependency-registry:index-out-of-range");
        address addr = dependencies[index];
        require(addr != address(0), "dependency-registry:dep-not-set");
        return addr;
    }
}
