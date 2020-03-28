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
const [ owner, notOwner, dep0, dep1, dep2, dep3 ] = accounts;

describe("DependencyRegistry", async () => {
    context('deploy', async () => {
        it('deploys successfully', async () => {
            const registry = await DependencyRegistry.new([], 1);
            expect(registry.address != null)
        });

        it('fails if the initial deps is too large', async () => {
            expectRevert(
                DependencyRegistry.new([dep0, dep1, dep2, dep3], 3),
                "dependency-registry:initial-deps-too-large"
            );
        })
    });

    context('reading dependencies', async () => {
        let registry;
        before(async () => {
            registry = await DependencyRegistry.new([dep0], 3)
        });

        it('reverts when it is not set', async () => {
            expectRevert(
                registry.getDependency(1),
                "dependency-registry:dep-not-set"
            );
        });

        it('returns the dependency set on deploy', async () => {
            const dep = await registry.getDependency(0);
            expect(dep === dep0);
        });

        it('returns the dependency set manually', async () => {
            await registry.setDependency(1, dep1);
            expect(await registry.getDependency(1) === dep1);
        });

        it('reverts when reading out of bounds', async () => {
            expectRevert(
                registry.getDependency(5),
                "dependency-registry:index-out-of-range"
            );
        });
    });

    context('setting dependencies', async () => {
        let registry;
        before(async () => {
            registry = await DependencyRegistry.new([], 3)
        });

        it('reverts when it is not the owner', async () => {
            expectRevert(
                registry.setDependency(2, dep2, { from: notOwner }),
                "Ownable: caller is not the owner."
            );
        });
        it('reverts when the index is out of range', async () => {
            expectRevert(
                registry.setDependency(5, dep2),
                "dependency-registry:index-out-of-range"
            );
        });
    });
});
