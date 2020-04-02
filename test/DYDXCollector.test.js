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

const DYDXCollector = contract.fromArtifact('DYDXCollector');
const MockContract = contract.fromArtifact('MockContract');
const ISoloMargin = contract.fromArtifact('ISoloMargin');

const [ owner, acc0, target, soloMargin ] = accounts;

describe("CompoundCollector", async () => {
    context('deploy', async () => {
        it('deploys successfully', async () => {
            let collector = await DYDXCollector.new([]);
            expect(collector.address != null)
        });

        it('deploys with the right number of deps', async () => {
            let collector = await DYDXCollector.new([acc0]);
            expect(collector.address != null);
        });

        it('fails if the initial deps is too large', async () => {
            expectRevert(
                DYDXCollector.new([acc0, acc0, acc0, acc0, acc0]),
                "dependency-registry:initial-deps-too-large"
            );
        })
    });

    context('getPositions', async () => {
        let soloMargin, wETH, DAI, USDC, collector;

        before(async() => {
            soloMargin = await MockContract.new();
            wETH = await MockContract.new();
            DAI = await MockContract.new();
            USDC = await MockContract.new();
            collector = await DYDXCollector.new([soloMargin.address]);
        });

        async function makeERC20(mock, name, balance) {
            await mock.givenMethodReturn(
                abi.methodID('name', []),
                abi.rawEncode( ['string'], [name])
            );
            await mock.givenMethodReturn(
                abi.methodID('balanceOf', ['address']),
                abi.rawEncode( ['uint256'], [balance])
            );
        }

        async function makeMarket(mock, marketId, address, borrowOrSupply, amount, price, totalBorrow, totalSupply) {
            await soloMargin.givenCalldataReturn(
                Buffer.concat([
                    abi.methodID('getAccountWei', ['(address,uint256)', 'uint256']),
                    Buffer.concat([
                        abi.rawEncode(['address', 'uint256'], [target, 0]),
                        abi.rawEncode(['uint256'], [marketId]),
                    ])
                ]),
                abi.rawEncode(['bool','uint256'], [borrowOrSupply, amount])
            );
            await soloMargin.givenCalldataReturn(
                Buffer.concat([
                    abi.methodID('getMarketPrice', ['uint256']),
                    abi.rawEncode(['uint256'], [marketId])
                ]),
                abi.rawEncode(['uint256'], [price])
            );
            await soloMargin.givenCalldataReturn(
                Buffer.concat([
                    abi.methodID('getMarketTokenAddress', ['uint256']),
                    abi.rawEncode(['uint256'], [marketId])
                ]),
                abi.rawEncode(['address'], [address])
            );
            await soloMargin.givenCalldataReturn(
                Buffer.concat([
                    abi.methodID('getMarketTotalPar', ['uint256']),
                    abi.rawEncode(['uint256'], [marketId])
                ]),
                abi.rawEncode(['uint256','uint256'], [totalBorrow, totalSupply])
            );
        }

        beforeEach(async () => {
            await makeERC20(wETH, "wETH", new BN('1000000000000000000000000000'));
            await makeERC20(DAI, "DAI", new BN('1000000000000000000000000000'));
            await makeERC20(USDC, "USDC", new BN('1000000000000000000000000000'));

            await soloMargin.givenMethodReturn(
                abi.methodID('getNumMarkets', []),
                abi.rawEncode(['uint256'], [3])
            );

            await makeMarket(
                soloMargin,
                0,
                wETH.address,
                true,
                new BN("100000000000000000"),
                new BN("100000000000000000"),
                new BN("105000000000000000000"),
                new BN("155000000000000000000"),
            );
            await makeMarket(
                soloMargin,
                1,
                DAI.address,
                false,
                new BN("1000000000000000000"),
                new BN("50000000000000000"),
                new BN("705000000000000000000"),
                new BN("1255000000000000000000"),
            );
            await makeMarket(
                soloMargin,
                2,
                USDC.address,
                true,
                new BN("9000000000000000000"),
                new BN("120000000000000000"),
                new BN("55000000000000000000"),
                new BN("255000000000000000000"),
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
