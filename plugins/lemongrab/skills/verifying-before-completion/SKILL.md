---
name: verifying-before-completion
description: Enforce evidence-first verification before any success claims during lemongrab workflows. Use when agents report task completion, test results, or build status. Requires running verification commands and reading actual output before claiming success. Prevents premature "done" claims and assumed-good states.
version: 1.0.0
---

# Verifying Before Completion

This skill enforces one rule: **evidence before claims, always.**

## Core Principle

No agent may claim success, completion, or passing status without running the verification command and reading its actual output in this session.

## The Rule

| Claim | Requires | NOT Sufficient |
|-------|----------|----------------|
| "Tests pass" | Run `npm test`, read output, count 0 failures | "Should pass", previous run, "I checked earlier" |
| "Bug fixed" | Test original symptom, confirm resolved | "Changed the code", "assumed fixed" |
| "Task complete" | Run DONE DEFINITION command, exit 0 | Agent reports success without running it |
| "Implementation done" | All tests pass, `git diff` shows expected changes | "Wrote the code" |
| "No regressions" | Full test suite passes AFTER changes | Running only new tests |
| "Build succeeds" | Run build command, read output | "It compiled last time" |

## Red Flags

If you catch yourself thinking or writing any of these, STOP:

| Red Flag | What to Do Instead |
|----------|-------------------|
| "Should work now" | Run the test. Read the output. THEN say it works. |
| "Probably passes" | "Probably" means you didn't check. Check. |
| "I already tested this" | When? If not this session after your latest change, test again. |
| "Tests were passing before my change" | Run them after your change. That's the point. |
| "The code looks correct" | Looking correct and being correct are different. Run the test. |
| Using "Great!", "Done!", "Perfect!" before verification | These words come AFTER evidence, not before. |

## Verification Sequence

Before ANY completion claim:

```
1. IDENTIFY — What command proves this claim?
2. RUN     — Execute the command fresh (not from cache or memory)
3. READ    — Read the FULL output, don't skim
4. COUNT   — How many passed? How many failed? Any errors?
5. VERIFY  — Does the output actually confirm the claim?
6. CLAIM   — Only now state the result, WITH the evidence
```

## Output Format

When reporting verification results, always include the evidence:

```
WRONG: "All tests pass. Task complete."

RIGHT: "Ran `npm test -- --grep 'login'`: 6 passed, 0 failed, 0 errors.
        Ran DONE DEFINITION: `curl -s localhost:3000/api/login ...` exited 0.
        Task T003 complete."
```

## Agent-Specific Rules

**test-writer**: After writing tests, run them and verify they FAIL for the right reason. Show the failure output.

**implementer**: After each code change, run tests and show which test newly passes. After all code, run full suite and show output.

**reviewer**: Run `npm test` yourself. Don't trust the implementer's claim that tests pass.

**simplifier**: After each refactoring change, run tests and verify they still pass. Show output.

**qa-engineer**: Take screenshots as evidence. Don't claim UI works without visual proof.

## Compliance Check

Before returning your output, verify:

- [ ] Every "pass" claim has a command output backing it
- [ ] Every "complete" claim has a DONE DEFINITION exit code
- [ ] No tentative language ("should", "probably", "seems") for verified facts
- [ ] No success celebrations before verification
- [ ] Fresh verification (not from a previous run)
