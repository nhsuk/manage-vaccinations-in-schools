# Introduction and Goals

Provide a service to record childrens vaccinations in settings encountered by
SAIS staff.

## Requirements Overview

### Allow SAIS staff to record vaccinations efficiently

The primary requirement is to allow SAIS staff to efficiently record
vaccinations in their typical work settings. The pilot will use the NHS Design
System to achieve this.

### Allow SAIS staff to work on campaigns while offline

User research has evidenced that SAIS staff occasionally need to work in
settings where they do not have access to the Internet. This pilot is designed
explore how we could achieve this in a way that would meet these needs and
provide a usable service.

### Integrate with a central vaccination record

The team believes that integrating with a central vaccination record service we
will be able to fix issues with data quality. This pilot will need to integrate
with a central vaccionation record to update the vaccination in near-real-time.

### Development speed and design flexibility

This service is part of the alpha phase to explore the user needs of such a
service; to facilitate this, it is being developed with a priority on speed of
delivery and flexbility over robustness and longevity, and as such may be
considered disposable once the desired learnings have been achieved.

## Quality Goals

As this service is in alpha stages, the current emphasis of this pilot is speed
of development and flexibility to adapt to the service design as it changes and
adapts to new research.

## Stakeholders

| Role/Name   | Contact        | Expectations       |
| ----------- | -------------- | ------------------ |
| _\<Role-1>_ | _\<Contact-1>_ | _\<Expectation-1>_ |
| _\<Role-2>_ | _\<Contact-2>_ | _\<Expectation-2>_ |

# Architecture Constraints

- Be able to work offline where required. This may clash with aspects of
  accessibility, but, to take JS as an example, while the offline work
  fuctionality may not be available if JS isn't supported, the service should
  continue to be usable without the offline functionality.
- Patient data must be protected. As this service will, eventually, deal with
  patient data, even if it is only a small volume as part of the pilot it must
  be built in a way that protects that data.

# System Scope and Context

## Business Context

**\<Diagram or Table>**

**\<optionally: Explanation of external domain interfaces>**

## Technical Context

**\<Diagram or Table>**

**\<optionally: Explanation of technical interfaces>**

**\<Mapping Input/Output to Channels>**

# Solution Strategy

# Building Block View

## Whitebox Overall System

**_\<Overview Diagram>_**

Motivation  
_\<text explanation>_

Contained Building Blocks  
_\<Description of contained building block (black boxes)>_

Important Interfaces  
_\<Description of important interfaces>_

### \<Name black box 1>

_\<Purpose/Responsibility>_

_\<Interface(s)>_

_\<(Optional) Quality/Performance Characteristics>_

_\<(Optional) Directory/File Location>_

_\<(Optional) Fulfilled Requirements>_

_\<(optional) Open Issues/Problems/Risks>_

### \<Name black box 2>

_\<black box template>_

### \<Name black box n>

_\<black box template>_

### \<Name interface 1>

…

### \<Name interface m>

## Level 2

### White Box _\<building block 1>_

_\<white box template>_

### White Box _\<building block 2>_

_\<white box template>_

…

### White Box _\<building block m>_

_\<white box template>_

## Level 3

### White Box \<\_building block x.1\_\>

_\<white box template>_

### White Box \<\_building block x.2\_\>

_\<white box template>_

### White Box \<\_building block y.1\_\>

_\<white box template>_

# Runtime View

## \<Runtime Scenario 1>

- _\<insert runtime diagram or textual description of the scenario>_

- _\<insert description of the notable aspects of the interactions
  between the building block instances depicted in this diagram.>_

## \<Runtime Scenario 2>

## …

## \<Runtime Scenario n>

# Deployment View

## Infrastructure Level 1

**_\<Overview Diagram>_**

Motivation  
_\<explanation in text form>_

Quality and/or Performance Features  
_\<explanation in text form>_

Mapping of Building Blocks to Infrastructure  
_\<description of the mapping>_

## Infrastructure Level 2

### _\<Infrastructure Element 1>_

_\<diagram + explanation>_

### _\<Infrastructure Element 2>_

_\<diagram + explanation>_

…

### _\<Infrastructure Element n>_

_\<diagram + explanation>_

# Cross-cutting Concepts

## _\<Concept 1>_

_\<explanation>_

## _\<Concept 2>_

_\<explanation>_

…

## _\<Concept n>_

_\<explanation>_

# Architecture Decisions

# Quality Requirements

## Quality Tree

## Quality Scenarios

# Risks and Technical Debts

# Glossary

| Term        | Definition        |
| ----------- | ----------------- |
| _\<Term-1>_ | _\<definition-1>_ |
| _\<Term-2>_ | _\<definition-2>_ |
