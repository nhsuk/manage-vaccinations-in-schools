# Contributing

## Code reviews

All pull requests should be reviewed by another developer on the team before
they can be merged in.

Don't be afraid to use "Request changes" when suggesting changes to a pull
request. This helps to make it easier to filter in lists of pull requests
which are still in need of a review, and the person who raised the pull
request can still dismiss the review if they disagree.

## Branch naming

We use simple descriptive names for branches such as `add-patient-model`.
To tie commits to Jira tickets etc. we use Git trailers in the comment, e.g.

```
Jira-Issue: MAV-1234
```

## Merging

We use a simple merge rather than a squash merge. Consider doing an interactive
rebase first, to squash any trivial commits that don't add any value to change
history by themselves.
