const {describe, beforeEach, afterEach, it} = require("mocha");
const abi = require('ethereumjs-abi');
// var BN = require('bn.js');

const {
    accounts,
    contract,
} = require('@openzeppelin/test-environment');

const {
    expect,
} = require('chai');

const {
    BN,
    expectEvent,
    expectRevert,
} = require('@openzeppelin/test-helpers');

const MakerCollector = contract.fromArtifact('MakerCollector');
const MockContract = contract.fromArtifact('MockContract');
const IProxyRegistry = contract.fromArtifact('IProxyRegistry');
const IJug = contract.fromArtifact('IJug');
const ISpotter = contract.fromArtifact('ISpotter');
const IDssDeploy = contract.fromArtifact('IDssDeploy');
const IGetCdps = contract.fromArtifact('IGetCdps');
const IVat = contract.fromArtifact('IVat');

const [ owner, acc0, proxy, urn, pip, cdpManager ] = accounts;

describe("MakerCollector", async () => {
    context('deploy', async () => {
        it('deploys successfully', async () => {
            let collector = await MakerCollector.new([]);
            expect(collector.address != null);
        });

        it('deploys with the right number of deps', async () => {
            let collector = await MakerCollector.new([acc0, acc0, acc0, acc0]);
            expect(collector.address != null);
        });

        it('fails if the initial deps is too large', async () => {
            expectRevert(
                MakerCollector.new([acc0, acc0, acc0, acc0, acc0]),
                "dependency-registry:initial-deps-too-large"
            );
        })
    });

    context('getPositions', async () => {
        let proxyRegistry, getCdps, vat, jug, spotter, deploy, collector;

        before(async () => {
            proxyRegistry = await MockContract.new();
            getCdps = await MockContract.new();
            vat = await MockContract.new();
            jug = await MockContract.new();
            spotter = await MockContract.new();
            deploy = await MockContract.new();
            collector = await MakerCollector.new([
                proxyRegistry.address,
                getCdps.address,
                deploy.address,
                cdpManager,
            ])
        });

        afterEach(async () => {
            await Promise.all([
                proxyRegistry, getCdps, vat, jug, spotter, deploy
            ].map(mock => mock.reset()));
        });

        beforeEach(async () => {
            await proxyRegistry.givenMethodReturnAddress(
                abi.methodID("proxies", ['address']),
                proxy
            );

            await getCdps.givenMethodReturn(
                abi.methodID("getCdpsAsc", ['address', 'address']),
                abi.rawEncode(
                    ['uint256[]', 'address[]', 'bytes32[]'],
                    [
                        [111], // CDP ID
                        [urn], // URN address
                        [0x123], // ILK id
                    ]
                )
            );

            await vat.givenMethodReturn(
                abi.methodID("ilks", ['bytes32']),
                abi.rawEncode(
                    ['uint256', 'uint256', 'uint256', 'uint256', 'uint256'],
                    [
                        new BN('217617321291512452471819'),
                        new BN('1014575419890055374603858827'),
                        new BN('91056666666666666666666666666'),
                        new BN('50000000000000000000000000000000000000000000000000000'),
                        new BN('20000000000000000000000000000000000000000000000'),
                    ]
                )
            );

            await vat.givenMethodReturn(
                abi.methodID('urns', ['bytes32', 'address']),
                abi.rawEncode(
                    ['uint256', 'uint256'],
                    [new BN('500000000000000000'), new BN('19712635884814530082')]
                )
            );

            await jug.givenMethodReturn(
                abi.methodID('ilks', ['bytes32']),
                abi.rawEncode(
                    ['uint256', 'uint256'],
                    [new BN('1000000001243680656318820312'), 1585341032]
                )
            );

            await spotter.givenMethodReturn(
                abi.methodID('ilks', ['bytes32']),
                abi.rawEncode(
                    ['address', 'uint256'],
                    [pip, new BN('1500000000000000000000000000')],
                )
            );

            await deploy.givenMethodReturnAddress(
                abi.methodID("vat", []),
                vat.address
            );
            await deploy.givenMethodReturnAddress(
                abi.methodID("spotter", []),
                spotter.address
            );
            await deploy.givenMethodReturnAddress(
                abi.methodID("jug", []),
                jug.address
            );
        });

        it('returns correct data', async () => {
            const positions = await collector.getPositions(owner);
            const platformID = positions[0];
            const borrows = positions[1];
            const supplies = positions[2];
            expect(platformID === 0x4d616b65724d4344000000000000000000000000000000000000000000000000); // MakerMCD
            expect(borrows.length === 1);
            expect(supplies.length === 1);
            expect(borrows[0]).to.deep.equal([
                "0x000000000000000000000000000000000000000000000000000000000000006f",
                "0x444149",
                "19999955829975475112121321033250969915872733814",
                "0",
                "3414632541220154458722137733",
                "0x0000000000000000000000000000000000000000033b2e3cb112f1349de86fd8",
            ]);
            expect(supplies[0]).to.deep.equal([
                "0x000000000000000000000000000000000000000000000000000000000000006f",
                "0x0123000000000000000000000000000000000000000000000000000000000000",
                "500000000000000000",
                "0",
                "0",
                "0x",
            ]);
        })
    })
});
