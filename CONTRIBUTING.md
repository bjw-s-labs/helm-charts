# Contributing Guidelines

Contributions are welcome via GitHub pull requests. This document outlines the process to help get your contribution accepted.

## Sign off Your Work

The Developer Certificate of Origin (DCO) is a lightweight way for contributors to certify that they wrote or otherwise have the right to submit the code they are contributing to the project. Here is the full text of the [DCO](http://developercertificate.org/). Contributors must sign-off that they adhere to these requirements by adding a `Signed-off-by` line to commit messages.

```
This is my commit message

Signed-off-by: Random J Developer <random@developer.example.org>
```

See `git help commit`:

```
-s, --signoff
    Add Signed-off-by line by the committer at the end of the commit log
    message. The meaning of a signoff depends on the project, but it typically
    certifies that committer has the rights to submit this work under the same
    license and agrees to a Developer Certificate of Origin (see
    http://developercertificate.org/ for more information).
```

## How to Contribute

1. Fork this repository, develop, and test your changes
1. Remember to sign off your commits as described above
1. Submit a pull request

**_NOTE_**: In order to make testing and merging of PRs easier, please submit changes to multiple charts in separate PRs.

### Setting up a local development environment

I rely on [mise-en-place](https://mise.jdx.dev) to set up my development environment. Once you have installed mise-en-place, you can run the `mise up` command which will then install all the required tools.
To see which tools are installed you can take a look at the [mise configuration](.mise.toml) file.

### Technical Requirements

- Must follow [Charts best practices](https://helm.sh/docs/topics/chart_best_practices/).
- Must pass CI jobs for linting and installing changed charts.
- Any change to a chart requires a version bump following [semver](https://semver.org/) principles. See [Immutability](#immutability) and [Versioning](#versioning) below.

Once changes have been merged, the release job will automatically run to package and release changed charts.

### Immutability

Chart releases must be immutable. Any change to a chart warrants a chart version bump even if it is only a change to the documentation.

### Versioning

The chart `version` should follow [semver](https://semver.org/).
