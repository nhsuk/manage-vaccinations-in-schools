# 7. Consent form starting URL

Date: 2023-08-22

## Status

In progress

## Summary

Parents will be directed to our service to give consent with a URL sent to them
by the school / SAIS team. In the scenarios we're designing for, schools will
send an email to parents on behalf of the SAIS teams.

There are different options for what information we include in the URL we send.
This ADR presents the different options available and documents which option we
accepted.

## Options

### Option 1: Individual tokens in URL path and in each journey step

The parents receive a token in the URL they receive from the school. This token
stays in the URL as part of the path for each step of the consent form journeys.

The reason a `token` is used here instead of a `consent_id` is for security
considerations. Internal identifiers are usually integers and allocated
sequentially, which means they are easily guessed. A token would be designed to
have high entropy and be hard to guess. This is important when using it anywhere
that the user may access, to prevent them from trying to access someone else's
consent information.

This would allow parents to share the URL to, for example, send to their
partner to verify answers or maybe continue the journey if they get interrupted.
It would, however, prevent parents from being able to share a URL with other
parents simply.

```
GET /consent/:token/start -> ParentalConsentController#start
GET /consent/:token/name -> ParentalConsent::NameController#show
GET /consent/:token/confirm -> ParentalConsentController#confirm
```

### Option 2: Individual tokens in URL path saved in session data

Similar to the above, parents would receive individual URLs with a token. This
would be used on the first step of the consent journey, but instead of being
present in the URL path of each step the consent id is saved in the session
store linked to the session cookie.

This links the consent form to a specific child, as before, but doesn't allow
sharing of the consent information. Also, because the initial URL does have an
unique token tied to their consent form, they couldn't simply share it with
other parents who simply want the URL to submit consent for their own children.

```
# :token could also be a query param
GET /consent/start/:token -> ParentalConsentController#start

# save consent_id in session store
GET /consent/name -> ParentalConsent::NameController#show
GET /consent/confirm -> ParentalConsentController#confirm
```

### Option 3: Session specific identifier

The URL sent to parents include an identifier for the session. This would tie
the consent to a specific vaccine and school, both of which are used and
required through the consent form journey.

```
# :session_id could also be a query param
GET /sessions/:session_id/consents/start -> ParentalConsentController#start
```

Then, to complete the consent journey the `consent_id` could be part of the URL.
Every step in the journey would be required to authorise that the `consent_id`
matches what's stored in the sessions store. However this would also better
accomodate multiple consent forms that parents may need to fill in.

```
GET /sessions/:session_id/consents/:consent_id/name -> ParentalConsent::NameController#show
GET /sessions/:session_id/consents/:consent_id/confirm -> ParentalConsentController#confirm
```

Optionally the `consent_id` could be retrieved from the session store:

```
GET /sessions/:session_id/consent/name -> ParentalConsent::NameController#show
GET /sessions/:session_id/consent/confirm -> ParentalConsentController#confirm
```

### Option 4: Vaccine-specific URL

It may be sufficient to only provide a programme identifier as part of the URL.
This would work similarly to the option to provide a session id, however we may
need to get information from the parent about what school their child goes to.

```
GET /flu/consent/start -> ParentalConsentController#start

# save consent_id in session store
GET /consent/name -> ParentalConsent::NameController#show
GET /consent/confirm -> ParentalConsentController#confirm
```

## Discussion

If we use individualised URL then we will be able to tie consent forms directly
to children. However there are usability of doing this. We believe parents may
share URLs to the consent service with other parents, where having an
individualised URL would get in the way or maybe even present data protection
risks. This could be used by parents who can't locate the consent invitation
email, or ones who never received it but have children in the class.

At the very least we will need to know which vaccine the consent form is for,
and almost certainly we'll need to know which programme specifically. Having the
programme will tell us in addition to the vaccine, which year and school. The
year will be useful as vaccines can change year on year, and the school
information may be part of the consent form to confirm attendance information.

## Decision

We will adopt option 3, using a session specific identifier. In addition, we'll
store the consent form ID in the user session, so that users can't access other
consent forms by changing the consent form ID in the URL. The consent form ID
will form part of the URL, however parents won't be able to edit more than one
consent form at a time until designs for how this would work are done.

## Consequences

- Users will not be able to edit multiple consent forms at the same time, for
  example if they have multiple kids in the same school
