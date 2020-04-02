const {describe, beforeEach, afterEach, before, it} = require("mocha");
const abi = require('ethereumjs-abi');

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

const CompoundCollector = contract.fromArtifact('CompoundCollector');
const MockContract = contract.fromArtifact('MockContract');
const IComptroller = contract.fromArtifact('IComptroller');
const ICToken = contract.fromArtifact('ICToken');
const IPriceOracle = contract.fromArtifact('ICompoundPriceOracle');

const [ owner, acc0, proxy, urn, pip, cdpManager ] = accounts;

describe("CompoundCollector", async () => {
    context('deploy', async () => {
        it('deploys successfully', async () => {
            let collector = await CompoundCollector.new([]);
            expect(collector.address != null)
        });

        it('deploys with the right number of deps', async () => {
            let collector = await CompoundCollector.new([acc0, acc0]);
            expect(collector.address != null);
        });

        it('fails if the initial deps is too large', async () => {
            expectRevert(
                CompoundCollector.new([acc0, acc0, acc0, acc0, acc0]),
                "dependency-registry:initial-deps-too-large"
            );
        })
    });

    context('getPositions', async () => {
        let cETH, cDAI, priceOracle, comptroller, collector;
        before(async() => {
            cETH = await MockContract.new();
            cDAI = await MockContract.new();
            priceOracle = await MockContract.new();
            comptroller = await MockContract.new();
            collector = await CompoundCollector.new([comptroller.address, priceOracle.address]);
        });

        beforeEach(async () => {
            await cETH.givenMethodReturn(
                abi.methodID('getAccountSnapshot', ['address']),
                abi.rawEncode(
                    ['uint256', 'uint256', 'uint256', 'uint256'],
                    [
                        0,
                        2363459098,
                        0,
                        new BN('211554327396132189699912438')
                    ]
                )
            );
            await cETH.givenMethodReturnUint(
                abi.methodID('balanceOfUnderlying', ['address']),
                new BN('500011646936995413')
            );
            await cETH.givenMethodReturnUint(
                abi.methodID('getCash', ['address']),
                new BN('500011646936995413')
            );
            await cETH.givenMethodReturnUint(
                abi.methodID('borrowRatePerBlock', []),
                new BN('10272521633')
            );
            await cETH.givenMethodReturnUint(
                abi.methodID('supplyRatePerBlock', []),
                new BN('1109275653')
            );
            await cETH.givenMethodReturn(
                abi.methodID('name', []),
                abi.rawEncode(['string'], ['Compound ETH'])
            );

            await cDAI.givenMethodReturn(
                abi.methodID('getAccountSnapshot', ['address']),
                abi.rawEncode(
                    ['uint256', 'uint256', 'uint256', 'uint256'],
                    [
                        0,
                        0,
                        new BN('900147079582746659'),
                        new BN('200006564333340841295767583'),
                    ]
                )
            );
            await cDAI.givenMethodReturnUint(
                abi.methodID('balanceOfUnderlying', ['address']),
                0
            );
            await cDAI.givenMethodReturnUint(
                abi.methodID('getCash', ['address']),
                new BN('1234500011646936995413')
            );
            await cDAI.givenMethodReturnUint(
                abi.methodID('borrowRatePerBlock', []),
                new BN('9609367882')
            );
            await cDAI.givenMethodReturnUint(
                abi.methodID('supplyRatePerBlock', []),
                new BN('6493851')
            );
            await cDAI.givenMethodReturn(
                abi.methodID('name', []),
                abi.rawEncode(['string'], ['Compound DAI'])
            );

            await priceOracle.givenMethodReturnUint(
                abi.methodID('getUnderlyingPrice', ['address']),
                new BN('5250000000000000')
            );

            await comptroller.givenMethodReturn(
                abi.methodID('getAssetsIn', ['address']),
                abi.rawEncode(['address[]'], [
                    [cETH.address, cDAI.address]
                ])
            );
        });

        it('returns correct data', async () => {
            const result = await collector.getPositions(owner);
            expect(result[0] === "0x436f6d706f756e64000000000000000000000000000000000000000000000000"); // Compound
            expect(result[1].length === 1);
            const cETHencoded = cETH.address.replace('0x', '').toLocaleLowerCase();
            const cDAIencoded = cDAI.address.replace('0x', '').toLocaleLowerCase();
            expect(result[1][0]).to.deep.equal([
                '0x000000000000000000000000'+cDAIencoded,
                '0x000000000000000000000000'+cDAIencoded+'0000000000000000000000000000000000000000000000000000000000000040000000000000000000000000000000000000000000000000000000000000000c436f6d706f756e64204441490000000000000000000000000000000000000000',
                '900147079582746659',
                '0',
                '0',
                '0x000000000000000000000000000000000000000000000000000000023cc3514a',
            ]);
            expect(result[2].length === 1);
            expect(result[2][0]).to.deep.equal([
                '0x000000000000000000000000'+cETHencoded,
                '0x000000000000000000000000'+cETHencoded+'0000000000000000000000000000000000000000000000000000000000000040000000000000000000000000000000000000000000000000000000000000000c436f6d706f756e64204554480000000000000000000000000000000000000000',
                '499999999805659273',
                '0',
                '0',
                '0x00000000000000000000000000000000000000000000000000000000421e3405',
            ]);
        })
    })
});
