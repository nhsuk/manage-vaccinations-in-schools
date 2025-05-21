# 10. Autoscaling for ECS

Date: 2025-05-21

## Status

Accepted

## Context

To ensure high availability without over-provisioning resources, we need to implement autoscaling for our ECS tasks.
This implementation is also crucial to meet the NHS Red Lines guidelines of autoscaling down to 40% of peak utilization
during non-peak hours.

## Decision

- We have implement autoscaling for the user-facing ECS service.
  - The background service will not be autoscaled as it is not clear autoscaling will be beneficial.
- Autoscaling pattern is target tracking based on CPU utilization.
  - This is the most common and straightforward approach for autoscaling ECS tasks.
  - We will set a target CPU utilization of 60% for scaling decisions.
    - Conservative and at current utilization should not lead to unnecessary scaling.
    - As we do not see big spikes in CPU utilization, this should be sufficient.
  - We will not consider memory utilization for scaling decisions.
    - Memory utilization is not a good indicator of load in our case as it tracks the memory reserved by the task,
      not the memory actually used.
- We will not use scheduled scaling as our tasks do not experience any regular spikes in CPU utilization that would
  warrant scheduled scaling.
- To be conservative we set the minimum task count to 2 and the maximum to 4.
  - This is to ensure that we have enough resources available during peak times without over-provisioning.
  - Having a minimum of 2 tasks ensures that we have redundancy in case one task/availability-zone goes down.

## Consequences

- The user-facing ECS service will run at a base of 2 tasks with a maximum autoscaling to 4 tasks.
- We will evaluate the autoscaling configuration after release to see if there is potential for fine-tuning.
