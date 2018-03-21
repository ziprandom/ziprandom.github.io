+++
author = "ziprandom"
tags = ["federation"]
title = "Content Federation on the Internet"
date = "2018-03-20T19:00:00-03:00"
draft = false
+++

An old dream of mine is to be part of a social internet and to have a protocol or an infastructure that lets me keep contact with the many parties of the internet that I'm interested in.

<!--more-->

I've come to imagine these parties, which could be persons like friends and colleagues, groups of people or other bodies like companies or institution, newspapers or devices in the internet of things as mere identities that are represented by nothing more than a public key, which may or may not hold additional metadate like a name or a namespace to indicate its role.

The social net I envision is one in which these entities exist indepentent of the underlying infastructure (e.g. servers) and where content can be fed in or retrieved from different locations.

An entity may host its content on its dedicated domain and hardware but might as well relay on extern servers to host and distribute it to its audience.

I often find myself thinking about possible designs of such a networking semantic and have this far arrived at the following pillars:

# cryptographically established authenticity of identities

My Identies are public/private key pairs that I own and which basically allow me to sign content while it enables others to privately send me content. I organize other entities public keys in my Address Book where I can give them names, sort them in groups and define and assign trust.

# content boxes & individually defined content routes

After defining the nodes of the abstract network in the trivial way outlined above a system is needed to to take care of storing, sending retrieving and forwarding content along the lines of the internet thus establishing the edges of the social network.

These systems act very much like firewalls or routers by accepting/rejecting or forwarding messages. In order to put the design of the social network in the hands of the users another semantic needs to be established which might evolve around a concept like content boxes.

A box would be a namespace available on the internet to which content can be pushed or from which it can be retrieved. A box should itself be presented as an entity with a public/private key. The provider of a box defines its policy by deciding which entities are allowed to push and/or pull content and by establishing other behaviour like forwading content to other boxes or over active connections directly to subscribed entities.

While entities exist only as a signer of a message or as a public key in someones address book a box has a address in the physical network and enables discovery and content delivery in the network. The routing logic stays undefined and is subject to contracts that can be defined ontop of the basic semantic described here.

# just another Internet on top of the internet?

With the concept of identities, boxes and the admittedly still nebular system to enable the definition and negociation of content routing/storage/computation/... logic many network communication primitives like messaging, content servers, publish-subscribe or chat could be realised. Identies can exist independently of the changing underlying network infastructure and still use boxes, which can be provided as services to reach availablitity and discoverability.

The concept is so basic and abstract that I think of it as a very thin layer on top of the internet which needs a lot more contracts especially regarding the content of the messages exchanged and the metaprotocols. These metaprotocols would need to pay specific attention to problems of routing and related issues like DoS or amplification attacks.

# an application

This whole concept that might might get dismissed by the many people that already thought about and impelmented different approaches to the same problem has been riping in my head for a long time already. The reason I write it down is because of another idea I had when I thought about it the other day.

Just as identities in the network can only be reliably referred to by the fingerprint of their public key messages are referred to by a byte sequence that represents a hash of their entire content. This way servers (aka. boxes) can deduplicate content easily and content can be referenced unambiguously from other content.

Now some boxes might implement a content semantic of messages having one or more parents just like git commits which are stored as part of the body. this way lot's of interesting use cases can be implemented just the way that git handles decentralized stores of commit objects. commenting on a message becomes like branching and because the underlying semantics of these references is not to re-create a consistent file system like git does other ways of rearranging messages might be applied by means of defining cherry picked collections of messages and so on.

This idea is very fresh and may lead to nowhere like the whole outlined system here.

At the moment this just needs a place to rest until I come back to it.
