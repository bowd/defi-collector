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

const DependencyRegistry = contract.fromArtifact('DependencyRegistry');
const [ owner, acc0, acc1 ] = accounts;

describe("DependencyRegistry", async () => {
    beforeEach(async () => {
        this.dependencyRegistry = await DependencyRegistry.new([acc0], 3)
    });

    context('deploy', async () => {
        it('deploys successfully', async () => {
            expect(this.dependencyRegistry.address != null)
        });

        it('fails if the initial deps is too large', async () => {
            expectRevert(
                DependencyRegistry.new([acc0, acc0, acc0, acc0], 3),
                "dependency-registry:initial-deps-too-large"
            );
        })
    });

    context('reading dependencies', async () => {
        it('reverts when it is not set', async () => {
            expectRevert(
                this.dependencyRegistry.getDependency(1),
                "dependency-registry:dep-not-set"
            );
        });

        it('returns the dependency set on deploy', async () => {
            expect(this.dependencyRegistry.getDependency(0) == acc0);
        });

        it('returns the dependency set manually', async () => {
            await this.dependencyRegistry.setDependency(1, acc1);
            expect(this.dependencyRegistry.getDependency(1) == acc1);
        });

        it('revert when reading out of bounds', async () => {
            expectRevert(
                this.dependencyRegistry.getDependency(5),
                "dependency-registry:index-out-of-range"
            );
        });
    });

    context('setting dependencies', async () => {
        it('reverts when it is not the owner', async () => {
            expectRevert(
                this.dependencyRegistry.setDependency(5, acc1, { from: acc0 }),
                "Ownable: caller is not the owner."
            );
        });
        it('reverts when the index is out of range', async () => {
            expectRevert(
                this.dependencyRegistry.setDependency(5, acc1),
                "dependency-registry:index-out-of-range"
            );
        });
    });
});
