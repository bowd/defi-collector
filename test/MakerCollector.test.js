const {describe, beforeEach, it} = require("mocha");
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
        beforeEach(async () => {
            this.makerCollector = await MakerCollector.new([acc0])
        });

        it('deploys successfully', async () => {
            expect(this.makerCollector.address != null)
        });

        it('deploys with the right number of deps', async () => {
            let mc = await MakerCollector.new([acc0, acc0, acc0, acc0]);
            expect(mc.address != null);
        })

        it('fails if the initial deps is too large', async () => {
            expectRevert(
                MakerCollector.new([acc0, acc0, acc0, acc0, acc0]),
                "dependency-registry:initial-deps-too-large"
            );
        })
    });

    context('getPositions', async () => {
        beforeEach(async () => {
            this.mockProxyRegistry = await MockContract.new();
            this.mockProxyRegistry.givenMethodReturnAddress(
                abi.methodID("proxies", ['address']),
                proxy
            );
            this.mockGetCdps = await MockContract.new();
            this.mockGetCdps.givenMethodReturn(
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

            this.mockVat = await MockContract.new();
            this.mockVat.givenMethodReturn(
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
            this.mockVat.givenMethodReturn(
                abi.methodID('urns', ['bytes32', 'address']),
                abi.rawEncode(
                    ['uint256', 'uint256'],
                    [new BN('500000000000000000'), new BN('19712635884814530082')]
                )
            );

            this.mockJug = await MockContract.new();
            this.mockJug.givenMethodReturn(
                abi.methodID('ilks', ['bytes32']),
                abi.rawEncode(
                    ['uint256', 'uint256'],
                    [new BN('1000000001243680656318820312'), 1585341032]
                )
            );

            this.mockSpotter = await MockContract.new();
            this.mockSpotter.givenMethodReturn(
                abi.methodID('ilks', ['bytes32']),
                abi.rawEncode(
                    ['address', 'uint256'],
                    [pip, new BN('1500000000000000000000000000')],
                )
            );

            this.mockDeploy = await MockContract.new();
            this.mockDeploy.givenMethodReturnAddress(
                abi.methodID("vat", []),
                this.mockVat.address
            );
            this.mockDeploy.givenMethodReturnAddress(
                abi.methodID("spotter", []),
                this.mockSpotter.address
            );
            this.mockDeploy.givenMethodReturnAddress(
                abi.methodID("jug", []),
                this.mockJug.address
            );

            this.makerCollector = await MakerCollector.new([
                this.mockProxyRegistry.address,
                this.mockGetCdps.address,
                this.mockDeploy.address,
                cdpManager,
            ])
        });

        it('returns correct data', async () => {
            const positions = await this.makerCollector.getPositions(owner);
            const borrows = positions[0];
            const supplies = positions[1];
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
