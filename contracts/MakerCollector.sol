pragma solidity ^0.5.17;
pragma experimental ABIEncoderV2;

import "./vendor/SafeMath.sol";

import "./interfaces/maker/IProxyRegistry.sol";
import "./interfaces/maker/IGetCdps.sol";
import "./interfaces/maker/IVat.sol";
import "./interfaces/maker/ISpotter.sol";
import "./interfaces/maker/IDssDeploy.sol";
import "./interfaces/maker/IJug.sol";
import "./interfaces/IDefiPlatformCollector.sol";

import "./lib/DependencyRegistry.sol";
import "./lib/PositionsHelper.sol";

contract MakerCollector is IDefiPlatformCollector, Ownable, DependencyRegistry, PositionsHelper {
    using SafeMath for uint256;
    bytes32 constant public platformID = 0x4d616b65724d4344000000000000000000000000000000000000000000000000; // MakerMCD
    function isDefiPlatformCollector() public pure returns (bool) { return true; }
    // function platformID() public view returns (bytes32) { return platformID_; }

    uint constant ProxyRegistryIndex = 0;
    uint constant GetCdpsIndex = 1;
    uint constant DeployIndex = 2;
    uint constant CdpManagerIndex = 3;

    constructor(address[] memory initialDeps) DependencyRegistry(initialDeps, 4) Ownable() public {}

    function getCdps(address target) internal view returns (uint256[] memory ids, address[] memory urns, bytes32[] memory ilks) {
        IProxyRegistry proxyRegistry = IProxyRegistry(getDependency(ProxyRegistryIndex));
        IGetCdps getCdps_ = IGetCdps(getDependency(GetCdpsIndex));
        address proxy = proxyRegistry.proxies(target);
        address cdpManager = getDependency(CdpManagerIndex);
        return getCdps_.getCdpsAsc(cdpManager, proxy);
    }

    function getVatUrns(bytes32 ilk, address urn) internal view returns (uint256, uint256) {
        IDssDeploy deploy = IDssDeploy(getDependency(DeployIndex));
        IVat vat = IVat(deploy.vat());
        return vat.urns(ilk, urn);
    }

    function getVatIlks(bytes32 ilk) internal view returns (uint256, uint256, uint256, uint256, uint256) {
        IDssDeploy deploy = IDssDeploy(getDependency(DeployIndex));
        IVat vat = IVat(deploy.vat());
        return vat.ilks(ilk);
    }

    function getSpotterIlks(bytes32 ilk) internal view returns (address, uint256) {
        IDssDeploy deploy = IDssDeploy(getDependency(DeployIndex));
        ISpotter spotter = ISpotter(deploy.spotter());
        return spotter.ilks(ilk);
    }

    function getJugIlks(bytes32 ilk) internal view returns (uint256, uint256) {
        IDssDeploy deploy = IDssDeploy(getDependency(DeployIndex));
        IJug jug = IJug(deploy.jug());
        return jug.ilks(ilk);
    }

    function getCdp(bytes32 ilk, address urn) internal view returns (uint256, uint256, uint256, uint256, uint256, uint256) {
        (uint256 ink, uint256 art) = getVatUrns(ilk, urn);
        (,uint256 rate, uint256 spot,,) = getVatIlks(ilk);
        (,uint256 mat) = getSpotterIlks(ilk);
        (uint256 duty,) = getJugIlks(ilk);
        return (rate, spot, ink, art, mat, duty);
    }

    function getPositions(address target) public view returns (Defi.PlatformResult memory) {
        (uint256[] memory ids, address[] memory urns, bytes32[] memory ilks) = getCdps(target);
        Defi.Position[] memory borrows = new Defi.Position[](ids.length);
        Defi.Position[] memory supplies = new Defi.Position[](ids.length);
        uint borrowIndex = 0;

        for (uint i = 0; i < ids.length; i++) {
            (uint256 rate, uint256 spot, uint256 ink, uint256 art, uint256 mat, uint256 duty) = getCdp(ilks[i], urns[i]);

            supplies[i] = Defi.Position(
                abi.encodePacked(ids[i]),
                abi.encodePacked(ilks[i]),
                ink,
                0,
                0,
                abi.encodePacked()
            );

            if (art > 0) {
                borrows[borrowIndex] = Defi.Position(
                    abi.encodePacked(ids[i]),
                    abi.encodePacked("DAI"),
                    (art * rate),
                    0,
                    (ink * spot * mat) / (art * rate),
                    abi.encode(duty)
                );
                borrowIndex += 1;
            }
        }

        return Defi.PlatformResult(
            platformID,
            repackPositions(borrows, borrowIndex),
            supplies
        );
    }
}
