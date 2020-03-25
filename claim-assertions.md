%%%
title = "Claim Assertions"
abbrev = "claim-assertions"
ipr = "none"
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
organization="Santander"
 [author.address]
 email = "alberto.pulido@santander.co.uk"

[[author]]
initials="V."
surname="Herraiz, Ed."
fullname="Victor Herraiz Posada"
organization="Santander"
 [author.address]
 email = "victor.herraiz@santander.co.uk"

[[author]]
initials="J."
surname="Oliva"
fullname="Jorge Oliva Fernandez"
organization="Santander"
 [author.address]
 email = "Jorge.OlivaFernandez@santander.co.uk"

%%%

.# Abstract

This specification defines a new claim that allows assertions over existing claims.

{mainmatter}

# Introduction {#Introduction}

In order to avoid an unnecessary leak of information, the answer to some claims may be only a boolean, verifying the claim instead of returning the actual value. As an example, assert that one is older than 18 without revealing the actual age.

Section 5.5.1 of the OpenID Connect specification [@!OIDC] defines a query syntax that allows for the member `value` of the requested claim to be a JSON object with additional information/constraints. For doing so it defines three members (essential, value and values) with special query meanings and allows for other special members to be defined. Any members that are not understood, must be ignored. This mechanism does not cover the above requirements and in this specification we will try to complement the [@!OIDC] specification with a richer syntax.

## Notational conventions

The key words "SHALL", "SHALL NOT", "SHOULD", "SHOULD NOT", "MAY", and "CAN" in this document are to be interpreted as described in "Key words for use in RFCs to Indicate Requirement Levels" [@!RFC2119]. These key words are not used as dictionary terms such that any occurrence of them shall be interpreted as key words and are not to be interpreted with their natural language meanings.

## Terminology

This specification uses the terms "Claim", "Claim Type", "Claims Provider","ID Token", "OpenID Provider (OP)", "Relying Party (RP)", and "UserInfo Endpoint" defined by OpenID Connect [@!OIDC]

# Request

This specification defines a generic mechanism to request assertions over claims using the new element `assertion_claims`. This new element will be used inside the parameter `claims`, as specified in section 5.5 of [@!OIDC] as a normal claim at `id_token` or `userinfo` level. It will contain the assertions of any claims relating to the End-User.

The top level elements of the `assertion_claims` JSON object are the actual claim names with `assertion` member nested inside:

```json
{
"id_token": {
    "assertion_claims": {
      "given_name": {
        "assertion": { "eq": "William" }
      }
    }
  }
}
```

The following members are defined for every claim:

* `assertion` REQUIRED, Object: Expression that will be evaluated against the actual value of the claim.
* `purpose` OPTIONAL, String: String describing the purpose of the request to the End-User.
* `essential` OPTIONAL, Boolean: As defined at section 5.5.1 [@!OIDC]

Every other member that is not recognized by the OP SHOULD be ignored.

# Expression language

The `assertion` member contains the expression (a JSON object) that will be evaluated as a `boolean` depending on the actual value of the named claim.

This language SHOULD be defined by the OP and it MUST be discoverable at the well-known endpoint, see section [OP Metadata](#op-metadata).

Recommended operations (if applicable):

* eq: The value is equal to the given value.
* gt: The value should be greater than the given value.
* lt: The value should be lower than the given value.
* gte: The value is equal or greater than the given value.
* lte: The value is equal or lower than the given value.
* in: The value is equal to one of the elements in the list.

The OP is entitled to change the specification to match any individual requirements.

## Simple types

Every claim value has a type (i.e. String, Number) and depending on this type of the claim some operators will not be valid.

In some cases the value requires some manipulation before executing the expression (e.g. phone numbers require normalization).

In the following example, `given_name` type is `string` and the result of the expression evaluation becomes `true` only if the value of the claim is `William`.

```json
{
  "assertion_claims": {
    "given_name": {
      "assertion": { "eq": "William" }
    }
  }
}
```

In the following case the type does not match and its behavior is undefined. The OP could then return an error in this case:

```json
{
  "assertion_claims": {
    "given_name": {
      "assertion": { "eq": 1701 }
    }
  }
}
```

In some cases the evaluation requires conversions. For instance, `simple_balance` contains a decimal number as a `string` and requires a conversion before evaluation. The following expression becomes `true` only if the value of the claim is greater than `1234.00`.

```json
{
  "assertion_claims": {
    "simple_balance": {
      "assertion": { "gt": "1234.00" }
    }
  }
}
```

If there are multiple operators (e.g. `gt` or `lte`), the expression will be evaluated as `true` if all operators return `true`. In other words, it behaves as a logical `and`. The following example will be `true` only if the claim value is greater than `1234.00` and less than or equal to `20000.00`:

```json
{
  "assertion_claims": {
    "simple_balance": {
      "assertion": {
        "gt": "1234.00",
        "lte": "20000.00"
      }
    }
  }
}
```

An empty assertion always returns `true`.

## Complex types

Some claim values are objects and to provide assertions over properties of those values, a new operator is required. This will prevent any collision between operators and property names. We will use `props` for that purpose.

`balance` claim value example:

```json
{
  "balance": {
    "amount": "1200.00",
    "currency": "GBP"
  }
}
```

`props` is used in the following example:

```json
{
  "assertion_claims": {
    "balance": {
      "assertion": {
        "props": {
          "amount": { "gt": "1000.00" },
          "currency": { "eq": "GBP" }
        }
      }
    }
  }
}
```

This expression will become `true` only if `amount` and `currency` expressions are `true`.

Any property that is not included in the expression will not affect the evaluation. For example, if `currency` is not included in the assertion, it will not affect the outcome.

Any assertion over a missing property returns `false`.

## Example

The following is a non normative example of a request containing assertions:

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

The request will return the result of the assertion execution and any potential errors.

Implementers MUST return an object for each claim inside `assertion_claims` element with the following fields:

* `result` REQUIRED. Boolean: it indicates if the claim value meets the assertion. If the claim is not found, does not match, the OP does not understand the expression or any other problem resolving the value, then this element should be equal to `null`.
* `error` OPTIONAL, Any: Available information about the error resolving the assertion.

The following is a non normative example of the response:

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

The OP SHOULD advertise their capabilities with respect to assertion claims in their `openid-configuration` (see [@!OIDC.Discovery]) using the following new elements:

* `assertion_claims_supported`: Boolean value indicating support of assertion claims.
* `claims_in_assertion_claims_supported`: List of claims that can be included in the `assertion_claims` element.
* `assertion_claims_query_language_supported`: List of members supported in the claims included in the `assertion_claims` element.

Non normative example:

```json
{
  "assertion_claims_query_language_supported": {
    "date": [
      "eq",
      "gt",
      "lt",
      "gte",
      "lte",
      "in"
    ],
    "decimal": [
      "eq",
      "gt",
      "lt",
      "gte",
      "lte"
    ],
    "number": [
      "eq",
      "gt",
      "lt",
      "gte",
      "lte"
    ],
    "object": [],
    "phone_number": [
      "eq",
      "in"
    ],
    "string": [
      "eq",
      "in"
    ]
  },
  "assertion_claims_supported": true,
  "claims_in_assertion_claims_supported": {
    "total_balance": {
      "type": "object",
      "props": {
        "amount": {
          "type": "decimal"
        },
        "currency": {
          "type": "string"
        }
      }
    },
    "phone_number": {
      "type": "phone_number"
    },
    "email": {
      "type": "string"
    },
    "birthdate": {
      "type": "date"
    },
    "family_name": {
      "type": "string"
    },
    "given_name": {
      "type": "string"
    }
  }
}

```

# IANA Considerations

To be done.
