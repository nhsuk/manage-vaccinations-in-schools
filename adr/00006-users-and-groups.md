# 6. Users and groups

Date: 2023-08-21

## Status

In progress

## Context

We will need to have users and groups in the system to support authentication,
auditing and access controls. Our current understanding is that access control
will be primarily given at the team level, with the possibility of having an
admin role. Designs have only partially been done for these features, so we
don't fully understand all the features we need to build yet.

Requirements around authentication is also not completely understood, we will
likely need to connect using NHS Care Identity Service 2 (NHS CIS2), which is an
OIDC solution. We don't know how much time and effort it'll take to gain acces
to NHS CIS2 so for until we can connect with it we'll use a locally saved
identity and password.

## Decision

- We will add users and groups with support for roles.
- We will use Devise to implement this in the app.
- We will add role-based authorisation using the Pundit gem (or similar) sooner rather than later.
- We will use Devise to store authentication and identity details locally until
  we have a way to connect with an OIDC offer such as NHS CIS2.

## Consequences

TBC
