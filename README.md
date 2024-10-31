# Strike Finance Options Smart Contract

## Introduction

This repo contains the smart contract for options trading on Strike Finance. V1 implementation of options trading on Strike Finance will be p2p (peer-to-peer). We understand Cardano has a liquidity problem and is currently exploring a pooled options alternative. This is an American Options platform, where users will have the right, but not the obligation, to exercise their contracts.

## What Are Options

An option contract gives the holder the right to buy or sell an asset at a predetermined price before a certain date. In options contracts, there are puts and calls. A put option allows the holder to sell an asset at a specific price, while a call option allows the holder to buy an asset at a specific price. Traders buy put options when they anticipate an asset will decline in value and call options when they anticipate an asset will rise in value.

**Call Option:**

- Gives the right to buy assets at a certain price
- Issuer locks up ADA or other CNTs
- When exercised, the holder sends stablecoins to the issuer and redeems the locked ADA or CNTs

**Put Option:**

- Gives the right to sell ADA or CNTs at a certain price
- Issuer locks up stablecoins
- When exercised, the holder sends ADA or CNTs to the issuer and receives stablecoins

## References

1. [Specification](/docs/specs.md)
