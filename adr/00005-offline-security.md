# 5. Offline security

Date: 2023-05-04

## Status

In progress

## Context

To enable our users to work offline, we're building robust offline capabilities
into our application.

The heavy lifting is done by the ServiceWorker API. It enables us to intercept
requests to the server when the user has no or spotty connectivity, and reply
to those requests with offline pages.

Our pages contain sensitive data, as they need to display the names, NHS
numbers, and date of births of patients involved in a vaccination programme.

This data needs to be stored securely, otherwise any offline capabilities are
functionally equivalent to downloading a plaintext Excel or CSV of patient
data.

We've written a detailed analysis of [the available methods for secure offline storage](../docs/secure-offline-storage.md).

## Decision

We will disable page caching through the `Cache-Control: no-store` header, to
prevent the back button page cache items from being saved in plaintext on the
user's drive.

We will use an encrypted store for offline pages and offline data, based on
IndexedDB, and secured with a passphrase and state-of-the-art cryptography.

To store the encryption key, we'll rely on the user typing it in when
necessary, and storing it in their password manager or elsewhere.

## Consequences

- Asking users for the password is friction, and we'll have to devise ways to
  persist it across a single session, to work around limitations with
  ServiceWorkers going to sleep after a certain time
- The frontend becomes more JS heavy as we build encryption/decryption
  mechanisms into it
- Edge cases can occur where users go offline, work offline, but then forget
  the encryption password and need to continue working offline. We'll have to
  store the encryption key server-side on generation for user recovery
