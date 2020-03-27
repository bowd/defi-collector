# TrustBet

## Description

I need a way to create personal bets with friends easy to use and set up, so I created this.

## Actors

To make this work 3 types of actors exist Managers, Bettors and Trustees.

### Manager

The role of the **Manager** is to manage the creation, starting and closing of the bets.

They are able to do these actions:

- `createBet` creates a new bet
  - arguments
    - `name` - description of the bet
    - `options` - a list of options that the people can choose from
    - `trustee` - the address of the actor trusted by all parties which can force the result of the bet, in case the **Bettors** do not agree on the result
  - result
    - `betId` - the generated id of the newly created bet

- `startBet` after a bet was created and the bettors picked their options, the bet can start
  - arguments
    - `betId` - the bet to start



- `closeBet` after the bettors have chosen their options, and they agree on the result, the bet can be closed and the funds will be disbursed to the winner
  - arguments
    - `betId` - the bet to be resolved

## Bettors

The **Bettors** are the actors that participate in the bet and stake their money in the process.

They are able to do these actions:

- `acceptBet` accepts an already created bet with `createBet` and receives the funds needed for the bet
  - arguments
    - `betId` - the bet id to accept
    - `option` - the option to bet on

- `postBetResult` after the result is known, the bettors should post the results, even if they lose
  - arguments
    - `betId` - the bet id
    - `result` - the real result from one of the available options

## Trustee

In case the bettors do not post the results or they post incorrect results, a **Trustee** can set the right result for the bet.

They are able to do these actions:

- `resolveBet` after the bettors have chosen their options and if they don't agree on the result of the bet, this can be called to force a result and the funds will be disbursed to the winner
  - arguments
    - `betId` - the bet to forcefully resolve
    - `option` - the result of the bet

- `cancelBet` cancels the bet and sends the funds back to the original **Bettors**
  - arguments
    - `betId` - the id to identify the bet

