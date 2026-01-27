---
name: simplifying-code
description: Simplify code through safe refactoring while keeping tests green. Use when cleaning up after implementation, removing complexity, improving readability, or refactoring. Provides refactoring patterns, code smell detection, and safety guidelines for maintaining test coverage.
---

# Simplifying Code

This skill guides safe code simplification - making working code cleaner without changing behavior. The key constraint: tests must stay GREEN throughout.

## When to Use

- After implementation passes tests (refactor phase of TDD)
- When code is correct but complex
- When reviewer flags maintainability concerns
- When preparing code for handoff
- When addressing technical debt

## Core Principle

**Simplify, don't complicate.** Every change should make the code:
- Shorter (fewer lines)
- Clearer (easier to understand)
- Simpler (less cognitive load)

If a change doesn't achieve at least one of these, don't make it.

## Safety Rules

### The Green Rule
```
1. Run tests → PASS (baseline)
2. Make ONE small change
3. Run tests → Must still PASS
4. If FAIL → Revert immediately
5. Repeat
```

### What NOT to Do
- Change multiple things at once
- Add new features
- Change behavior (even if "better")
- Ignore failing tests
- Refactor untested code

## Simplification Patterns

### 1. Remove Dead Code
```javascript
// Before
function calculate(x) {
  const unused = x * 2;  // Never used
  const temp = x + 1;    // Only used once
  return temp * 3;
}

// After
function calculate(x) {
  return (x + 1) * 3;
}
```

### 2. Inline Single-Use Variables
```javascript
// Before
const isValid = user.email && user.password;
if (isValid) {
  return login(user);
}

// After
if (user.email && user.password) {
  return login(user);
}
```

### 3. Early Returns
```javascript
// Before
function process(data) {
  let result;
  if (data) {
    if (data.valid) {
      result = transform(data);
    } else {
      result = null;
    }
  } else {
    result = null;
  }
  return result;
}

// After
function process(data) {
  if (!data) return null;
  if (!data.valid) return null;
  return transform(data);
}
```

### 4. Replace Conditionals with Guard Clauses
```javascript
// Before
function getDiscount(user) {
  if (user) {
    if (user.isPremium) {
      if (user.yearsActive > 5) {
        return 0.3;
      } else {
        return 0.2;
      }
    } else {
      return 0.1;
    }
  } else {
    return 0;
  }
}

// After
function getDiscount(user) {
  if (!user) return 0;
  if (!user.isPremium) return 0.1;
  if (user.yearsActive > 5) return 0.3;
  return 0.2;
}
```

### 5. Extract Repeated Logic
```javascript
// Before
const userTotal = user.items.reduce((sum, i) => sum + i.price, 0);
const cartTotal = cart.items.reduce((sum, i) => sum + i.price, 0);
const orderTotal = order.items.reduce((sum, i) => sum + i.price, 0);

// After
const sumPrices = (items) => items.reduce((sum, i) => sum + i.price, 0);
const userTotal = sumPrices(user.items);
const cartTotal = sumPrices(cart.items);
const orderTotal = sumPrices(order.items);
```

### 6. Replace Magic Numbers
```javascript
// Before
if (password.length < 8) { ... }
if (retries > 3) { ... }
setTimeout(callback, 86400000);

// After
const MIN_PASSWORD_LENGTH = 8;
const MAX_RETRIES = 3;
const ONE_DAY_MS = 24 * 60 * 60 * 1000;

if (password.length < MIN_PASSWORD_LENGTH) { ... }
if (retries > MAX_RETRIES) { ... }
setTimeout(callback, ONE_DAY_MS);
```

### 7. Simplify Boolean Logic
```javascript
// Before
if (isActive === true) { ... }
if (isValid === false) { ... }
return condition ? true : false;

// After
if (isActive) { ... }
if (!isValid) { ... }
return condition;
```

### 8. Use Built-in Methods
```javascript
// Before
let found = false;
for (const item of items) {
  if (item.id === targetId) {
    found = true;
    break;
  }
}

// After
const found = items.some(item => item.id === targetId);
```

## Code Smells to Look For

| Smell | Symptom | Fix |
|-------|---------|-----|
| Long function | >20 lines | Extract helper functions |
| Deep nesting | >3 levels | Early returns, extract methods |
| Duplicate code | Copy-paste | Extract shared function |
| Dead code | Unused vars/functions | Delete it |
| Magic numbers | Unexplained literals | Named constants |
| Long parameter list | >3 params | Use options object |
| Commented-out code | Old code kept "just in case" | Delete it (git has history) |

## When NOT to Simplify

### Don't Simplify If:
- Tests are failing
- You'd change behavior
- Code is untested (add tests first)
- Simplification is subjective
- It would obscure intent

### Leave Complex Code When:
```javascript
// This LOOKS complex but is correct and necessary
// Simplifying would break the algorithm
const result = items
  .filter(i => i.active && i.category === target)
  .sort((a, b) => b.priority - a.priority || a.name.localeCompare(b.name))
  .slice(0, limit);
// Don't "simplify" into multiple statements - this is clear as-is
```

## Simplification Checklist

Before each change:
- [ ] Tests are passing (baseline)
- [ ] Change is small and isolated
- [ ] Behavior won't change
- [ ] Code will be simpler after

After each change:
- [ ] Tests still pass
- [ ] Code is actually simpler
- [ ] Intent is still clear

Before finishing:
- [ ] All tests pass
- [ ] No dead code remains
- [ ] No obvious duplication
- [ ] Complexity reduced

## Questions to Ask

For every piece of code:

1. **Can this be shorter?**
   - Remove unused code
   - Inline single-use variables
   - Use built-in methods

2. **Can this be clearer?**
   - Better variable names
   - Extract well-named functions
   - Add constants for magic numbers

3. **Can this be simpler?**
   - Early returns vs nested ifs
   - Simpler algorithms
   - Less indirection

4. **Would a junior understand this?**
   - If no, simplify or add comment
   - Clever code is rarely good code

## Anti-Patterns

### Over-Abstracting
```javascript
// Bad: Abstraction for one use case
const createUserValidator = (rules) => (user) => rules.every(r => r(user));
const validateUser = createUserValidator([hasEmail, hasPassword]);

// Good: Direct implementation
const validateUser = (user) => user.email && user.password;
```

### Premature Optimization
```javascript
// Bad: Optimizing without evidence
const cache = new Map();
const getUser = (id) => cache.get(id) || (cache.set(id, db.find(id)), cache.get(id));

// Good: Simple first, optimize when needed
const getUser = (id) => db.find(id);
```

### "Improving" Working Code
```javascript
// Bad: Changing behavior while "simplifying"
// Original: returns null for not found
// "Simplified": throws error for not found
// This is NOT simplification - it's a behavior change!
```

## Output

After simplification, report:
- Lines removed
- Patterns applied
- Complexity reduction
- Tests still passing: YES
