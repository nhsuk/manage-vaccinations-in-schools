# 7. Identifying parents or guardians for consent journey

Date: 2023-08-22

## Status

In progress

## Context

Some thoughts about routes, which we touched on in Slack. The point that we need the token for security is a good one, however I don’t think it’s clear whether we can send out individualised links to the consent form.

So I think here are some of our options. (these examples all use a `ParentalConsentController` for the start and confirm actions, which is a separate issue to discuss)

### Use :token in all URLs in journey

`:token` stays in the URL, allowing parents to re-use the URL to, for example, send to their partner to verify answers or maybe continue the journey if they get interrupted (e.g. by kids begging to go to KFC)

```
GET /consent/:token/start -> ParentalConsentController#start
GET /consent/:token/name -> ParentalConsent::NameController#show
GET /consent/:token/confirm -> ParentalConsentController#confirm
```

### Save consent_id in session cookie

`:token` only used at the start, then a consent id gets saved in the session store so the user can’t try to jump to another child’s consent form

```
# :token could also be a query param
GET /consent/start/:token -> ParentalConsentController#start
# save consent_id in session store
GET /consent/name -> ParentalConsent::NameController#show
GET /consent/confirm -> ParentalConsentController#confirm
```

---

If we can’t send individualised links to the parents, we should be able to at least send campaign-specific URLs to parents. This URL would include a campaign identifier, and it wouldn’t be necessary to make this obfuscated. However we should still avoid exposing easily guessable identifiers for consent records.

Another consideration is we can’t limit parents to only creating one consent record in this situation as parents will potentially have siblings in the same class.

### Generate :token and use in URLs in journey

`:token` gets generated at `/start` and then inserted into the URLs for the rest of the journey

```
# In theory we could also use a query param for campaign id
GET /campaigns/:id/consent/start -> ParentalConsentController#start
or
GET /consent/start?campaign_id=1 -> ParentalConsentController#start

GET /consent/:token/name -> ParentalConsent::NameController#show
GET /consent/:token/confirm -> ParentalConsentController#confirm
```

### Save consent_id in session cookie

```
GET /campaigns/:id/consent/start -> ParentalConsentController#start
or
GET /consent/start?campaign_id=1 -> ParentalConsentController#start

GET /consent/name -> ParentalConsent::NameController#show
GET /consent/confirm -> ParentalConsentController#confirm
```

## Decision

TBD

## Consequences

TBC
