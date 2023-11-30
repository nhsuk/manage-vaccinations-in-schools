# ADR 2: Application Architecture

**Date Created:** 2022-12-22

**Status:** Research

## Context

The Manage vaccinations in schools service has the rare requirement that it must
be usable in situations where no Internet connection is available. This
requirement for offline work requires an application architecture that is rarely
used in today's NHSUK and GOVUK services. However, there are approaches that may
be used to achieve this.

### Option 1: Hybrid server/client side rendering with Service Worker to manage offline functionality

This is a hybrid approach that leverages server-side rendering of the HTML and
uses progressive enhancement
so that cached data can be used while offline. It relies on Service Workers to
manage offline functionality with advanced caching, etc. To realise the
benefits, the choice of server-side framework is relevant — it should be well
suited to generating the view required by the front-end. For the purpose of this
analysis we assume Ruby on Rails will be used.

#### Pros:

- Server-side rendering can be simpler to implement with existing libraries and
  components. NB: there is an assumption here that the existing [GOVUK
  components library](https://github.com/DFE-Digital/govuk-components) can be
  adapted to the NHSUK design system relatively easily.
- Better browser compatibility as the primary browser feature that this approach
  depends on is Service Workers. The one notable browser that does not support
  this is IE11, however as of 15 June 2022 Microsoft has ended support on a
  large portion of their Windows operating system. Likewise, NHS has withdrawn
  official support for it (see [Internet Explorer goes out of support on 15
  June](https://digital.nhs.uk/about-nhs-digital/standards-for-web-products/withdrawal-of-support-for-internet-explorer)
  on NHS Digital's site).
- The use of a well known (by the team) framework that is optimised for
  delivering webapps quickly will accelerate the development of the service
  prototype.
- Performance (smaller JS bundle, and runs better on clients with slower CPUs)
- Better accessibility.
- Progressive enhancement would make this solution work for more users.

#### Cons:

- There is a risk that either adapting the GOVUK Components library to the NHSUK
  frontend and styling, or developing the custom JS to handle offline mode, will
  be more work than anticipated and make this approach non-viable.
- The usability of a service which blends online and offline usability is
  unknown and untested. User research will be needed to understand if users will
  find this a usable solution.

### Option 2: Full client side rendering with Service Workers to manage offline functionality

A fully browser-based application developed using an existing JS framework may,
in theory, require less work, as the HTML rendering will only occur in one
place. It would rely on Service Workers to manage offline functionality, however
no known framework provides the both the necessary browser-based rendering and
the offline features required so a certain amount of custom coding would be
necessary.

#### Pros:

- Browser-based rendering would keep all rendering in one place.
- If we can use the [NHSUK Frontend](https://github.com/nhsuk/nhsuk-frontend)
  for client side rendering it will likely mean less work adapting the GOVUK
  components. However, this likelihood of this would have to be spiked.

#### Cons:

- There is the risk that the [NHSUK Frontend](https://github.com/nhsuk/nhsuk-frontend)
  will not be usable for client side rendering, or it may be more work than
  expected to adapt them.
- A fully client-side SPA may exclude some users still using legacy browsers,
  more than just relying on the Service Worker feature.
- The usability of a service which blends online and offline usability is
  unknown and untested. User research will be needed to understand if users will
  find this a usable solution.
- Managing individual state in multiple single page application clients is a
  hard distributed systems problem.

### Option 3: Desktop app using web-based framework, such as Electron, with server side API

This approach would require the user to download and install an application that
would be styled using the NHSUK styling, and would rely on data available via an
API for shared data storage.

#### Pros:

- This may be more naturally usable for users, but this requires testing.
- We should be able to make better use of NHSUK Frontend by using npm within the
  Electron app.
- Having a clearer distinction between client and server via an API may provide
  a better user experience. (i.e. without relying on advanced caching via Service
  Workers)
- Less reliance on the browser should make this approach more accessible on
  legacy systems (e.g. if anyone is stuck using IE11).

#### Cons:

- Not all users may be able to install an application, this may be a common
  scenario although we haven't done research to determine this.
- As a corollary to the above, installing applications may depend on central IT
  teams which could present additional challenges.
- Once installed, keeping the app updated may be a challenge and may require a
  completely different release-cycle approach.
- There is additional uncertainty to the delivery of such an app as there may be
  additional challenges that the team, who are not experts in this area, aren't
  aware of.

## Decision

We will spike option 1 first to determine it's viability, and then make a
decision on whether we want to proceed with it, or spike out option 2 and/or 3.

## Consequences

TBD
