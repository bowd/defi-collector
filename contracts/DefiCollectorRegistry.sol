pragma solidity ^0.5.17;
pragma experimental ABIEncoderV2;

import "./vendor/Ownable.sol";

import "./interfaces/IDefiPlatformCollector.sol";
import "./lib/Defi.sol";

contract DefiCollectorRegistry is Ownable {
	bytes32[] collectors;
	mapping(bytes32 => uint) collectorIndex;
    mapping(bytes32 => address) collectorAddress;

    constructor(address[] memory addresses) Ownable() public {
        for (uint i = 0; i < addresses.length; i++) {
            addOrSwapCollector(addresses[i]);
        }
    }

	function addOrSwapCollector(address location) public onlyOwner {
        IDefiPlatformCollector collector = IDefiPlatformCollector(location);
        require(collector.isDefiPlatformCollector(), "collector-registry:not-a-defi-collector");
        bytes32 id = collector.platformID();

		if (collectorIndex[id] == 0) {
            // Add ID to list if it's not there
			collectors.push(id);
			collectorIndex[id] = collectors.length;
		}
        // Record address (both on add and swap)
        collectorAddress[id] = location;
    }

	function removeCollector(address location) public onlyOwner {
        IDefiPlatformCollector collector = IDefiPlatformCollector(location);
        bytes32 id = collector.platformID();
        uint index = collectorIndex[id];

		require(index > 0);
        // Failsafe
        require(collectorAddress[id] == location);

		bytes32 lastItem = collectors[collectors.length - 1];
		collectors[index - 1] = lastItem;
		collectors.length -= 1;

		collectorIndex[id] = 0;
        collectorAddress[id] = address(0);
	}

	function getPositions(address target) public view returns(Defi.PlatformResult[] memory) {
		Defi.PlatformResult[] memory platforms = new Defi.PlatformResult[](collectors.length);
		for (uint i = 0; i < collectors.length; i++) {
			IDefiPlatformCollector collector = IDefiPlatformCollector(collectorAddress[collectors[i]]);
            platforms[i] = collector.getPositions(target);
		}
        return platforms;
	}
}
