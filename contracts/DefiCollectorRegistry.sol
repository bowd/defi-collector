pragma solidity >=0.4.25 <0.7.0; pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/ownership/Ownable.sol";

import "./Defi.sol";
import "./IDefiPlatformCollector.sol";

contract DefiCollectorRegistry is Ownable {
	bytes32[] collectors;
	mapping(bytes32 => uint) collectorIndex;
	mapping(bytes32 => address) collectorAddresses;

    constructor(bytes32[] memory ids, address[] memory addresses) Ownable() public {
        for (uint i = 0; i < ids.length; i++) {
            setCollector(ids[i], addresses[i]);
        }
    }

	function setCollector(bytes32 id, address ctr) public onlyOwner {
		if (collectorIndex[id] == 0) {
			collectors.push(id);
			collectorIndex[id] = collectors.length;
		}
        collectorAddresses[id] = ctr;
	}

	function removeCollector(bytes32 id) public onlyOwner {
        uint256 index = collectorIndex[id];
		require(index > 0);

		bytes32 lastItem = collectors[collectors.length - 1];
		collectors[index - 1] = lastItem;
		collectors.length -= 1;
		collectorIndex[id] = 0;
        collectorAddresses[id] = address(0);
	}

	function getPositions(address target) public view returns(Defi.Platform[] memory) {
		Defi.Platform[] memory platforms = new Defi.Platform[](collectors.length);
		for (uint i = 0; i < collectors.length; i++) {
			bytes32 id = collectors[i];
			address addr = collectorAddresses[id];
			IDefiPlatformCollector collector = IDefiPlatformCollector(addr);
            (Defi.Position[] memory borrows, Defi.Position[] memory supplies) = collector.getPositions(target);
            platforms[i] = Defi.Platform(id, borrows, supplies);
		}
        return platforms;
	}
}
