const {describe, beforeEach, it} = require("mocha");

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
const [ owner, acc0, acc1 ] = accounts;

describe("MakerCollector", async () => {
    beforeEach(async () => {
        this.makerCollector = await MakerCollector.new([acc0])
    });

    context('deploy', async () => {
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
});
