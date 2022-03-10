
# Coding Style Rules

This document contains a collection of rules as they emerge from
day-to-day discussions.  If you are unhappy with anything, open a PR
that changes it, which will trigger a discussion.  These PRs of course
shouldn't just be reviewed by one more person, but reach a wider
consent at least inside Wire before getting merged.

These rules are by no means enforced consistently at the time of
writing this, but they are offer a way to avoid debate when reviewing
current pull requests: if you can point to a rule in this file, you
win the argument.

FUTUREWORK: make rules automatic (eg by adding hlint rules to CI.)

### Module boundaries

1. All modules must have explicit export lists.

2. All imports must be either explicit (`import Data.Id (UserId)`) or
   qualified (`import qualified Data.Id`).
