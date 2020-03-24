%%%
title = "Claim Assertions"
abbrev = "claim-assertions"
ipr = "trust200902"
area = "Identity"
workgroup = "connect"
keyword = ["security", "openid", "authorization", "trust"]
 
date = 2020-03-24T10:40:28Z
 
[seriesInfo]
name = "Internet-Draft"
value = "claim-assertions-00"
status = "standard"
 
[[author]]
initials="A."
surname="Pulido"
fullname="Alberto Pulido Moyano"
organization="Santander Technology"
 [author.address]
 email = "alberto.pulido@santander.co.uk"
 
[[author]]
initials="V."
surname="Herraiz, Ed."
fullname="Victor Herraiz Posada"
organization="Santander Technology"
 [author.address]
 email = "victor.herraiz@santander.co.uk"
 
[[author]]
initials="M."
surname="Herrero"
fullname="Miguel Revesado"
organization="Santander Technology"
 [author.address]
 email = "miguel.revesado@santander.co.uk"
 
[[author]]
initials="J."
surname="Oliva"
fullname="Jorge Oliva Fernandez"
organization="Santander Technology"
 [author.address]
 email = "Jorge.OlivaFernandez@santander.co.uk"
 
%%%

.# Abstract

This specification defines a new claim that allows assertions over known claims.

{mainmatter}

# Introduction {#Introduction}

In order to avoid unnecessary leak of information, the answer to some claims may be only a boolean verifying the claim instead of returning the actual value.

Section 5.5.1 of the OpenID Connect specification [@!OIDC] defines a query syntax that allows for the member `value` of the claim being requested to be a JSON object with additional information/constraints on the claim. For doing so it defines three members (essential, value and values) with special query meanings and allows for other special members to be defined (while stating that any members that are not understood must be ignored).

## Notational conventions

The key words "SHALL", "SHALL NOT", "SHOULD", "SHOULD NOT", "MAY", and "CAN" in this document are to be interpreted as described in "Key words for use in RFCs to Indicate Requirement Levels" [@!RFC2119]. These key words are not used as dictionary terms such that any occurrence of them shall be interpreted as key words and are not to be interpreted with their natural language meanings

## Terminology

This specification uses the terms "Claim", "Claim Type", "Claims Provider","ID Token", "OpenID Provider (OP)", "Relying Party (RP)", and "UserInfo Endpoint" defined by OpenID Connect [@!OIDC]

# Request

This specification defines a generic mechanisms to request assertions over claims using the new element `assertion_claims`. This new element will be use inside the parameter `claims` specified in section 5.5 of [@!OIDC] as a normal claim at `id_token` or `userinfo` level. It will contain the assertions of actual claims about the End-User.

The top level elements of `assertion_claims` JSON object are the actual claim names with an assertion:

```json
{
  "assertion_claims": {
    "given_name": {
      "assertion": { "eq": "William" }
    }
  }
}
```

The following members are defined per every claim:

* `assertion` REQUIRED: Expression that will be evaluated against the actual value of the claim
* `purpose` OPTIONAL: String describing the purpose of the request to the End-User
* `essential` OPTIONAL: As defined at section 5.5.1 [@!OIDC]

Every other member that is not understood by the OP SHOULD be ignored.

# Expression language

The `assertion` member contains the expression that it will be evaluated as true/false depending the actual value of the named claim.

This language SHOULD be defined by the OP and it MUST be discoverable at the well-known endpoint, see section [OP Metadata](#op-metadata).

Recommended names for operations (if applicable):

* gt: The value should be greater than the given value (Use in currency, numbers, dates..)
* lt: The value should be lower than the given value (Use in currency, numbers, dates...)
* gte: The value is equal or greater than the given value.
* lte: The value is equal or lower than the given value.
* eq: The value is equal to the given value.
* in: The value is equal to one of the elements in the list.

The OP is entitled to change the specification to match its requirements.

## Simple types

Every claim value has a type (i.e. String, Number), depending on the type of the claim some operators could be valid or not, or even perform some conversion before executing the expression.

In the following example, `given_name` type is `string` and the result of the expression evaluation becomes true only if the value of the claim is `William`.

```json
{
  "assertion_claims": {
    "given_name": {
      "assertion": { "eq": "William" }
    }
  }
}
```

In this case the type does not match and its behavior is undefined, the OP could return an error information in this case:

```json
{
  "assertion_claims": {
    "given_name": {
      "assertion": { "eq": 42 }
    }
  }
}
```

In some cases the evaluation requires conversions, `simple_balance` contains a decimal number as a `string` and require a conversion before evaluation. The following expression becomes `true` only if the value of the claim is greater that `1234.00`.

```json
{
  "assertion_claims": {
    "simple_balance": {
      "assertion": { "gt": "1234.00" }
    }
  }
}
```

An empty assertion always returns `true`.

## Complex types

Some claim values are objects, to provide assertions over properties of those values a new operator is required. This will prevent any collision between operator and property names.

`balance` claim value example:

```json
{
  "balance": {
    "amount": "1200.00",
    "currency": "GBP"
  }
}
```

`props` is use in the following example:

```json
{
  "assertion_claims": {
    "balance": {
      "assertion": {
        "props": {
          "amount": "1000.00",
          "currency": "GBP"
        }
      }
    }
  }
}
```

Any property that is not included in the expression do not affect the evaluation. For example, if `currency` is not included in the assertion will not affect the outcome.

Any assertion over a missing property returns `false`

## Example

The following is a non normative example of the request of an assertion claim:

```json
{
  "id_token": {
    "assertion_claims": {
      "given_name": {
        "assertion": { "eq": "Leonard" }
      },
      "balance": {
        "assertion": {
          "props": {
            "amount": { "gt": "1000.00" },
            "currency": { "eq": "USD" }
          }
        }
      },
      "email": {
        "assertion": { "eq": "nimoy@enterpise.fp" }
      }
    }
  }
}
```

# Response

The assertion claim will return the result of apply logical operators each requested claim

Implementators MUST return an object for each claim with the following fields:

* result: REQUIRED. Boolean, it indicates if the claim meets the query. If the claim is not found, does not match, OP does not understand any of the logical expression language member or any other problem resolving the value this element should be returned empty.
* error: OPTIONAL. When the OP is not able to understand one or more of the query members and error MAY be returned

The following is a non normative example of the response of an assertion claim

```json
{
  "assertion_claims": {
    "name": { "result": true },

    "balance": {
      "result": null,
      "error": "unknown_operator"
    },
    "address": { "result": true },
    "email": { "result": false }
  }
}
```

{backmatter}


<reference anchor="RFC2119" target="https://tools.ietf.org/html/rfc2119">
  <front>
    <title>Key words for use in RFCs to Indicate Requirement Levels</title>
    <author initials="S." surname="Bradner" fullname="Scott Bradner">
      <organization>Harvard University</organization>
    </author>
   <date month="March" year="1997"/>
  </front>
</reference>

<reference anchor="OIDC" target="http://openid.net/specs/openid-connect-core-1_0.html">
  <front>
    <title>OpenID Connect Core 1.0 incorporating errata set 1</title>
    <author initials="N." surname="Sakimura" fullname="Nat Sakimura">
      <organization>NRI</organization>
    </author>
    <author initials="J." surname="Bradley" fullname="John Bradley">
      <organization>Ping Identity</organization>
    </author>
    <author initials="M." surname="Jones" fullname="Mike Jones">
      <organization>Microsoft</organization>
    </author>
    <author initials="B." surname="de Medeiros" fullname="Breno de Medeiros">
      <organization>Google</organization>
    </author>
    <author initials="C." surname="Mortimore" fullname="Chuck Mortimore">
      <organization>Salesforce</organization>
    </author>
   <date day="8" month="Nov" year="2014"/>
  </front>
</reference>

<reference anchor="OIDC.Discovery" target="https://openid.net/specs/openid-connect-discovery-1_0.html">
  <front>
    <title>OpenID Connect Discovery 1.0 incorporating errata set 1</title>
    <author initials="N." surname="Sakimura" fullname="Nat Sakimura">
      <organization>NRI</organization>
    </author>
    <author initials="J." surname="Bradley" fullname="John Bradley">
      <organization>Ping Identity</organization>
    </author>
    <author initials="M." surname="Jones" fullname="Mike Jones">
      <organization>Microsoft</organization>
    </author>
    <author initials="E." surname="Jay" fullname="Edmund Jay">
      <organization>Illumila</organization>
    </author>
   <date day="8" month="Nov" year="2014"/>
  </front>
</reference>

# OP Metadata {#op-metadata}

The OP advertises its capabilities with respect to assertion Claims in its openid-configuration (see [@!OIDC.Discovery]) using the following new elements:

assertion_claims_supported: Boolean value indicating support of assertion claims.

claims_in_assertion_claims_supported: List of claims that can be included in assertion_claims claim.

assertion_claims_query_language_supported: List of members supported in claims included in the assertion_claims claim.

assertion_claims_regex_supported: type of expression language supported by the OP

assertion_claims_confidence_algorithm: Algorithm used by the confidence member

# IANA Considerations

To be done.
