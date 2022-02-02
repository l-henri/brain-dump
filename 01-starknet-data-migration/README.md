# Extracting data from Starknet

So recently I worked a bit on migrating user data from one old smart contract to another on StarkNet. Doing so I've learned a bunch of stuff that I thought I'd document here

## The goal
I published [this repo](https://github.com/l-henri/starknet-cairo-101) 3 weeks ago. It is a set of exercices to learn Cairo, where users collect points. My issues with it were the following:
### The exercices needed to evolve to accomodate new functionalities
In its first version, the tutorial involved sending your account address as a parameter to every function call. This was due tothe fact that it was not possible to send transactions through Voyager with Argent X!

Since then, both teams worked to add this functionnality to Voyager. Try it out! So I needed to update the exercices to take this into account.

This also solved the necessity for salt in function calls. Basically a transaction hash in StarkNet depends on the method called, the contract called and the parameters sent. The is no notion of account at the transaction level; so no notion of nonce. This means that it is possible to have two transactions with the same hash. But the sequencer won't accept transactions that were executed in the past

In the tutorial, some functions had to be called various times with the same parameters; this lead to some players being stuck. Hence why Iadded a parameter "salt" in the function calls: by putting random values in it, players where ableto move forward by having different transaction hashes.

As mentionned though, this is not an issue when using an account contract. These need to implement replay protection, so they need to have some concept of nonce. This nonce is passed as a parameter; and so for every function call, a new tx hash will appear.

### Non evolutive ERC20
When I deployed the first version of the tutorial, interacting with StarkNet in an authenticated maner was non trivial. And I was in a hurry. So I designed an ERC20 that was pretty much set in stone:
- After deployment, anyone can set minters (no one was looking so I'm confident I'm the only one that did)
- Then anyone can "close" the setup phase. After that, it becomes impossible to add/remove minters

This meant I couldn't add new exercices, or remove old / bug ones. Not optimal

### Contract specific state for exercice completion
The goal of the tutorial is for people to accumulate points. But if some people can get more points than other, then it's no fun :-(. 
Initially, the fact that you had completed an exercice was stored in a variable inside the exercice. This was easy to implement, and straight forward to understand for the curious bunch that looked at the code.

The issue is the following: Imagine user A finishes exercise 3, but user B has an issue because of a bug in exercise 3. He can't complete it anymore. Then, I'd like to be able to redeploy exercice 3; have B validate it and get point; but have A not being able to re do the exercise and get more points.

Basically, the same way I have a contract to store points (TDERC20), I want a contract to store progression. So I wrote this

### People had already started playing
Like, 96 people had already done at least part of the tutorial. I could have just redeployed, and scratch everybody's balance. But that's not cool! So I figured I needed to be able to transfer both the points amount + the progression to the new system.

### Facilitate data extraction
Working towards this made me realize that extracting data from StarkNet was non trivial. Etherscan makes it easy for you to see holders of a token on Ethereum; Voyager does not yet. 

While the infrastructure is getting there (we now have events in contracts to facilitate indexing, and Voyager is starting to register them), I wanted to add a way to store data in the smart contract state for easier retrieval.

This is not a very good pattern for smart contracts development btw. Storage in smart contracts cost money! But
1. This is on testnet with no expectation to go on mainnet
2. Done is better than perfect
3. This will facilitate maintenance a lot, and allow us to produce more content. The (testnet) cost of storage is worth the trade off.


## Getting started
### Adding a players registry


