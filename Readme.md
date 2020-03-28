# DefiCollector

![License](https://img.shields.io/github/license/bowd/deficollector)
[![CircleCI](https://circleci.com/gh/bowd/deficollector.svg?style=shield)](https://circleci.com/gh/cleanunicorn/deficollector)
![Version](https://img.shields.io/github/package-json/v/bowd/deficollector)

## Description

DefiCollector is utility contract that helps lookup all defi positions on multiple platforms starting from an address.
It aims to normalize the data associated with a defi positions across protocols.

## Contracts

The system consists of:
    - `DefiCollectorRegistry` and
    - multiple contracts that implement `IDefiPlatformCollector`:
        - `MakerCollector`
        - `CompoundCollector`

It also introduces a `DependencyRegistry` contract that helps manage external dependencies. It's used as part of the platform collector implementations to maintain references to the platform dependencies (e.g Maker contracts, Compound contracts, etc).

### `DefiCollectorRegistry`

The role of the `DefiCollectorRegistry` is to keep track of all registered platform collectors and provide the main entry point that then aggregates positions from each platform collector and returns everything.

It makes it easier to "upgrade" the system with new DeFi protocols by just implementing a new collector and registering it with the registry.

### `IDefiPlatformCollector`

A defi collector must implement this interface so that the `DefiCollectorRegistry` can register it and use it to collect data.
There currently are two platform collectors that implement this interface: `MakerCollector` and `CompoundCollector`.

### `DependencyRegistry`

This helper contract acts as way to abstract the setting and getting external dependency addresses.
It has a constructor which receives a list of `initialDeps` and a `maxDeps` which represents the total number of dependencies this contract has. The `initialDeps` array must have at most `maxDeps` items.

The contracts that extend this contract should statically define `maxDeps` as part of the constructor and can also define constants to keep track of the dependencies.
Example from `MakerCollector`:
```solidity
uint8 constant ProxyRegistryIndex = 0;
uint8 constant GetCdpsIndex = 1;
uint8 constant DeployIndex = 2;
uint8 constant CdpManagerIndex = 3;

constructor(address[] memory initialDeps) DependencyRegistry(initialDeps, 4) Ownable() public {}
```

This allows the system to invoke the dependencies as follows:

```solidity
IProxyRegistry proxyRegistry = IProxyRegistry(getDependency(ProxyRegistryIndex));
```

The `getDependency` function will ensure that the dependency is in range and set.
