# 11. Develop Reporting Component In Python

Date: 2025-06-18

## Status

Proposed

## Context

Development of the Mavis application thus far has been in Ruby on Rails, as detailed in [ADR 00004](./adr/00004-language-and-framework.md).
This was deemed acceptable at the time, as Ruby was [on the Tech Radar as PROPOSED](https://github.com/NHSDigital/tech-radar/blob/main/site/data/data.js#L157) and initially the project was viewed as a Proof-of-Concept.

However, now that Mavis has progressed to processing real-world data from genuine clinical practitioners, we have been advised that new components must be developed in a MAINSTREAM technology. We are about to start on a moderately significant piece of work to meet the reporting needs of the NHS Commissioners and the SAIS teams which report data to them, and this work is sufficiently self-contained that it lends itself to being used as a pilot for a mainstream technology.

## Decision

We have decided to adopt Python as the MAINSTREAM technology. (see entry in the [Tech Radar](https://github.com/NHSDigital/tech-radar/blob/main/site/data/data.js#L150))

Justification:

- other teams in NHS Digital are already using Python for similar web-based services, providing the opportunity for reuse and sharing of common components such as NHS Design System implementation
- similar paradigm to Ruby - a general-purpose procedural language with functions and classes, suitable for scripting and back-end data processing as well as web development
- there are web frameworks available for Python which are similar in approach to familiar Ruby frameworks (Django approximates Rails in functionality, Flask is more similar to Sinatra)
- several of the existing team are already somewhat familiar with Python

## Consequences

We will need to create a new repository for the Python application, and configure CI/CD pipelines appropriately for a different build pipeline.
Future ADRs will consider:

- the appropriate AWS architecture changes to allow Mavis to serve & monitor two separate application processes behind a single user-facing domain
- authentication mechanisms such that the user will only have to log in once to both applications, whichever they visited first
