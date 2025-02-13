# Contributing Guide

This Helm Chart accepts contributions from GitHub pull requests.
You can find help in this document to get your contribution accepted.

## Helm Chart Guidelines

Please read the [Helm Chart Guidelines](./traefik/Guidelines.md) before editing this chart.

## Testing

Please read the [testing guidelines](./TESTING.md) to learn how testing is done with this chart.

## Guidelines

According to the Traefik HelmChart [philosophy](./README.md#philosophy),
the guidelines for future evolutions are:

- Fix bugs
* improve security
* improve HelmChart support
* improve Kubernetes features support
* improve Traefik default configuration

While encouraging contributions, the philosophy leads to avoid introducing:

- Specific use cases
- Third party CRD
- Dashboard exposition tuning
- Helm chart variables that shortcuts/expose static or dynamic Traefik configuration

## Commit messages

Commits messages should follow [conventional commits](https://www.conventionalcommits.org/en/v1.0.0/) specification and should specify a scope.

All commits will appear in traefik helm chart changelog with two exceptions:

- CRDs: CRDs are shared between Traefik and CRDs charts, thus, commits with this scope will appear in both charts changelog (e.g. `feat(CRDs): update Traefik Proxy CRDs to v3.x`)
- CRDs-.*: commits with `CRDs-` prefixed scope will appear only on CRDs chart changelog (e.g. `docs(CRDs-values): update values documentation`)   

## About CRDs

Some Traefik Helm chart users asked for help in managing CRDs installed by this chart (cf. [#1141](https://github.com/traefik/traefik-helm-chart/issues/1141), [#1209](https://github.com/traefik/traefik-helm-chart/issues/1209)).

Helm doesn't support CRDs upgrades (cf. [HIP-0011](https://github.com/helm/community/blob/main/hips/hip-0011.md) for details).

Our objectives are the following:

1. Support the nominal installation case following official Helm GuideLines
2. Stay conservative about CRDs to protect resource removal
3. Allow users to install multiple instances of Traefik chart along with helm managed CRDs

Several implementations have been experimented. Here are pros and cons of each:

<table>
    <thead>
    <tr>
        <td>solution</td>
        <td>pros</td>
        <td>cons</td>
    </tr>
    </thead>
    <tbody>
    <tr>
        <td>templatized CRDs within Traefik helm chart</td>
        <td>
            <ul>
                <li>simple</li>
                <li>users can specify only install a subset of CRDs</li>
                <li>users don't have to bother with CRDs upgrades</li>
            </ul>
        </td>
        <td>
            <ul>
                <li><code>--skip-crds</code> will be inefficient and can lost users</li>
                <li>the first installation fails are CRDs are not rendered first by helm</li>
                <li>when installing multiple instances, CRDs are attached to one instance</li>
            </ul>
        </td>
    </tr>
    <tr>
        <td>seperated CRDs chart as main chart dependency</td>
        <td>
            <ul>
                <li>users can specify only install a subset of CRDs</li>
                <li>users don't have to bother with CRDs upgrades</li>
                <li>CRDs are versioned aside from main chart</li>
                <li>users can install CRDs along with multiple instances of main chart</li>
            </ul>
        </td>
        <td>
            <ul>
                <li><code>--skip-crds</code> will be inefficient and can lost users</li>
                <li>the first installation fails are CRDs are not rendered first by helm (helm doesn't respect dependency order)</li>
                <li>when installing multiple instances, CRDs are attached to one instance</li>
            </ul>
        </td>
    </tr>
    <tr>
        <td>seperated CRDs chart</td>
        <td>
            <ul>
                <li>users can specify only install a subset of CRDs</li>
                <li>users don't have to bother with CRDs upgrades</li>
                <li>CRDs are versioned aside from main chart</li>
                <li>users can install CRDs along with multiple instances of main chart</li>
            </ul>
        </td>
        <td>
            <ul>
                <li><code>--skip-crds</code> will be inefficient and can lost users</li>
                <li>the first installation fails are CRDs are not rendered first by helm</li>
            </ul>
        </td>
    </tr>
    </tbody>
</table>

Consequently, we chose the last option, until the situation evolve on Helm side.

# Statistics

Once a year, [monocle](https://github.com/change-metrics/monocle) is used to gather statistics on this project.

They are gathered with this config file:

```yaml
---
workspaces:
  - name: monocle
    crawlers:
      - name: github-traefik
        provider:
          github_organization: traefik
          github_repositories:
            - traefik-helm-chart
        update_since: '2022-01-01'
```
