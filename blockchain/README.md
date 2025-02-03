# Simulator

## Scenario for testing

- money mule
- smurfing

## What we measurement?

- Count step/effort to complete suspend all relevant fund/transaction.
- TBD
  
<!-- Response Time, Recovery Time and Post-Incident Analysis -->

## Prerequisite

- docker
- docker-compose
- python3
- pip

Start local network with command.

``` shell
yarn besu:start
```

Stop local network with command.

``` shell
yarn besu:stop
```

## Network Configuration

In simulator the private network will use `hyperledger/besu` as blockchain client.

> [!WARNING] go-ethereum
> If you preferred to use `geth` last version that support Proof of Authority (Clique) is `v1.13.15`

API_HTTP: `http://localhost:8545`  
API_WS: `ws://localhost:8546`  
CHAIN_ID: `8080`

## Run simulator

with `yarn`

```shell
yarn simulation
```

with `x`

```shell
# command
```

## Reading result

``` shell
# command
```
