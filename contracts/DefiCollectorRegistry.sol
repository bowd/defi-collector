pragma solidity >=0.4.25 <0.7.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/ownership/Ownable.sol";

import "./IDefiPlatformCollector.sol";
import "./lib/Defi.sol";

contract DefiCollectorRegistry is Ownable {
	address[] collectors;
	mapping(address => uint) collectorIndex;

    constructor(address[] memory addresses) Ownable() public {
        for (uint i = 0; i < addresses.length; i++) {
            addCollector(addresses[i]);
        }
    }

	function addCollector(address collectorAddress) public onlyOwner {
        IDefiPlatformCollector collector = IDefiPlatformCollector(collectorAddress);
        require(collector.isDefiPlatformCollector(), "collector-registry:not-a-defi-collector");
		if (collectorIndex[collectorAddress] == 0) {
			collectors.push(collectorAddress);
			collectorIndex[collectorAddress] = collectors.length;
		}
	}

	function removeCollector(address collector) public onlyOwner {
        uint256 index = collectorIndex[collector];
		require(index > 0);

		address lastItem = collectors[collectors.length - 1];
		collectors[index - 1] = lastItem;
		collectors.length -= 1;
		collectorIndex[collector] = 0;
	}

	function getPositions(address target) public view returns(Defi.PlatformResult[] memory) {
		Defi.PlatformResult[] memory platforms = new Defi.PlatformResult[](collectors.length);
		for (uint i = 0; i < collectors.length; i++) {
			IDefiPlatformCollector collector = IDefiPlatformCollector(collectors[i]);
            platforms[i] = collector.getPositions(target);
		}
        return platforms;
	}
}
