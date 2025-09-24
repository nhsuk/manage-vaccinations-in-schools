# Branching strategy

We follow the patterns and conventions in [GitHub Flow](https://docs.github.com/en/get-started/using-github/github-flow).

- Try to only put related changes into a single PR and keep them as small and as focused
  as is reasonable.
  - If you start shaving yaks consider putting these changes into
    a separate PR.
- Likewise, if you find the change you're making is quite large, you can spread it across
  multiple PRs
  - Even if functionality is only partly
    complete any one of them.
- Include a link to the Jira card in a relevant commit message and in the PR
  description.

Below is a visual representation of the branching strategy. For concreteness lets consider
the next version being developed for release v2.0.0:

Generally, features for the upcoming release are merged into `next`:

```mermaid
gitGraph
commit id: "v2.0.0-feature-1"
commit id: "v2.0.0-feature-2"
```

Any work for a later version, v2.1.0 in this case, can go onto a dedicated branch, `v2.1.0-wip` for instance:

```mermaid
gitGraph
commit id: "v2.0.0-feature-1"
commit id: "v2.0.0-feature-2" tag: "v2.0.0-rc1"
branch v2.1.0-wip
checkout v2.1.0-wip
commit id: "v2.1.0-feature-1"
commit id: "v2.1.0-feature-2"
```

Once the release has been confirmed good and release approvals have been given,
`next` is merged into `main`, tagged as the new version (`v2.0.0`), and deployed to production:

```mermaid
gitGraph
commit id: "v2.0.0-feature-1"
commit id: "v2.0.0-feature-2" tag: "v2.0.0-rc1"
branch v2.1.0-wip
checkout v2.1.0-wip
commit id: "v2.1.0-feature-1"
commit id: "v2.1.0-feature-2"
checkout main
commit id: "v2.0.0-patch-1" tag: "v2.0.0-rc2, v2.0.0"
checkout "v2.1.0-wip"
cherry-pick id: "v2.0.0-patch-1"
```

At this point the wip branch can be merged into `next` and feature development for v2.1.0
can continue on `next` branch:

```mermaid
gitGraph
commit id: "v2.0.0-feature-1"
commit id: "v2.0.0-feature-2" tag: "v2.0.0-rc1"
branch v2.1.0-wip
checkout v2.1.0-wip
commit id: "v2.1.0-feature-1"
commit id: "v2.1.0-feature-2"
checkout main
commit id: "v2.0.0-patch-1" tag:"v2.0.0-rc2, v2.0.0"
checkout v2.1.0-wip
cherry-pick id: "v2.0.0-patch-1"
checkout main
merge v2.1.0-wip
commit id: "v2.1.0-feature-3"
```
