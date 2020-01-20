# Testing Guide

This Helm Chart requires extensive testing to ensure expected behavior are met for everyone.

## Test Driven Development

"TDD" practise (Test Driven Development) should be followed when adding a new feature or fixing a bug.

It means that you are expected to:

1. Start by adding a test describing the expected behaviour, that should fails (either because the bug exists in initial state, or because the new feature had not been implemented),
2. Then, change the code according to your intent (fixing a bug, adding a feature or refactoring),
3. Finally, the test suite (including the new test you added earlier) must pass.

## Test Kinds

Please note that this chart has the following kind of tests (see respective sections below for description):

- [Static Testing](#static-testing)

<!-- TODO: Add Unit testing -->

<!-- TODO: Add E2E testing -->

### Static Testing

The static test suite has the following properties:

- Static tests are about linting the YAML files, shell scripts and Helm elements. It is also a set of verifications around versions, names, etc.
- Static tests are fast to run, hence it must be run for each commit and pull requests and are considered blocking when failing.
- Static test suite is run by inovking the make target `lint`: `make lint`. It is run by default on the CI.

The static test suite is implemented with the tool [`ct` (Chart Testing)](https://github.com/helm/chart-testing):

- The Docker image of `ct` is used to ensure all sub-dependencies (helm, kubectl, yamale, etc.) are met for an easier experience for contributor.
  - If you cannot or do not to use docker, you need to install [`ct`'s prerequisites](https://github.com/helm/,chart-testing#prerequisites), and set the variable `LINT_USE_DOCKER` to a value different than true: `LINT_USE_DOCKER= make lint`.
- All configuration of `ct` and linters are stored in the directory `test/`. In particular, the file `test/ct.yaml` contains
the `ct` configuration.
- Version Increment Check is done against the against the original repository, with the branch `master`. This repository is added as an additional git remote named `traefik` by the make target `lint`. If you wish to temporarly change this behavior, please edit the files `Makefile` and `test/ct.yaml`.
