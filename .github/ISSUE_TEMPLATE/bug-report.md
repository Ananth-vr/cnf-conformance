---
name: Bug Report
about: Create a report to help us improve
title: "[BUG]"
labels: bug
assignees: ''

---

**Describe the bug**
A clear and concise description of what the bug is.

NOTE: you can enable higher logging level output via the command line or env var. to help with debugging

```
# cmd line
./cnf-conformance -l debug test

# make sure to use -- if running from source
crystal src/cnf-conformance.cr -- -l debug test 

# env var
LOGLEVEL=DEBUG ./cnf-conformance test
```

Also setting the verbose option for many tasks will add extra output to help with debugging

```
crystal src/cnf-conformance.cr test_name verbose
```

Check [usage documentation](https://github.com/cncf/cnf-conformance/blob/master/USAGE.md) for more info about invoking commands and loggin

**To Reproduce**
Steps to reproduce the behavior:
1. Go to '...'
2. Click on '....'
3. Scroll down to '....'
4. See error

**Expected behavior**
A clear and concise description of what you expected to happen.

**Screenshots**
If applicable, add screenshots to help explain your problem.

**Workstation (please complete the following information):**
 - OS [e.g. Linux]
 - Distro [e.g. Ubuntu]
 - Version [e.g. 18.04]
 - Architecture [e.g. x86, arm]

**Desktop (please complete the following information):**
 - OS: [e.g. iOS]
 - Browser [e.g. chrome, safari]
 - Version [e.g. 22]

**Smartphone (please complete the following information):**
 - Device: [e.g. iPhone6]
 - OS: [e.g. iOS8.1]
 - Browser [e.g. stock browser, safari]
 - Version [e.g. 22]

**Additional context**
Add any other context about the problem here.
