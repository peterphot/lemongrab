```
                                    ___
                                 .-'   `-.
                                /         \
                               |  O     O  |
                               |     __    |
                                \   |  |  /
                                 \  |__|  /
                                  '.____.'
                                    |  |
                              .-----'  '-----.
                             /                 \
                            |   UNACCEPTABLE!   |
                            |                   |
                            |   ONE MILLION     |
                            |   YEARS DUNGEON!  |
                             \                 /
                              '---------------'
                                    |  |
                                    |  |
                                   /    \
                                  /      \
                                 /        \
```

# Lemongrab

**A TDD + Spec-Driven Development Template for Claude Code**

Lemongrab is a project template that helps you build software the right way: by thinking before coding, testing before implementing, and documenting along the way. It combines Test-Driven Development (TDD) with spec-driven development concepts from [GitHub's spec-kit](https://github.com/github/spec-kit).

---

## What is Lemongrab?

Lemongrab is a starter template you can clone whenever you start a new project. It sets up a multi-agent workflow for Claude Code that ensures:

- **No assumptions** - Requirements are gathered and clarified before any code is written
- **Tests first** - Tests are written before implementation (TDD)
- **Minimal code** - Only write what's needed to pass tests
- **Clean code** - Refactoring is a dedicated step
- **Documentation** - The "why" is captured, not just the "what"

### Who is this for?

- Developers who want to build software with fewer bugs
- Teams that want consistent, documented code
- Anyone learning TDD or spec-driven development
- Projects where requirements clarity is important

### What problems does it solve?

| Problem | How Lemongrab Helps |
|---------|---------------------|
| "I started coding before understanding the requirements" | Clarifier agent asks questions first |
| "I wrote code without tests" | Test Writer creates tests before implementation |
| "My code is too complex" | Simplifier agent removes unnecessary complexity |
| "I don't remember why I made this decision" | Documenter records the reasoning |
| "Each feature is built differently" | Constitution ensures consistent principles |

---

## Quick Start

Choose your path:
- **New project?** Start with [Option A: New Project](#option-a-new-project-5-minutes)
- **Existing project?** Start with [Option B: Existing Project](#option-b-existing-project-5-minutes)

---

### Option A: New Project (5 minutes)

#### Step 1: Clone the Template

```bash
git clone https://github.com/your-username/lemongrab.git my-new-project
cd my-new-project
rm -rf .git  # Remove template's git history
git init     # Start fresh
```

#### Step 2: Install Spec-Kit

```bash
# Install uv (Python package manager) if you don't have it
curl -LsSf https://astral.sh/uv/install.sh | sh

# Install spec-kit
uv tool install specify-cli --from git+https://github.com/github/spec-kit.git

# Initialize spec-kit in your project
specify init my-new-project
```

Now skip to [Step 3: Create Your Project Constitution](#step-3-create-your-project-constitution).

---

### Option B: Existing Project (5 minutes)

#### Step 1: Install Spec-Kit

**Prerequisites:** Python 3.11+, Git

```bash
# Install uv (Python package manager) if you don't have it
curl -LsSf https://astral.sh/uv/install.sh | sh

# Install spec-kit
uv tool install specify-cli --from git+https://github.com/github/spec-kit.git

# Verify it works
specify check
```

#### Step 2: Add Lemongrab to Your Project

```bash
cd your-existing-project

# Initialize spec-kit
specify init .

# Download the workflow file
curl -o AGENTIC-WORKFLOW.md https://raw.githubusercontent.com/your-username/lemongrab/main/AGENTIC-WORKFLOW.md
```

Or manually copy `AGENTIC-WORKFLOW.md` from the Lemongrab template into your project root.

Now continue to Step 3 below.

---

### Step 3: Create Your Project Constitution

Open Claude Code in your project directory:

```bash
cd your-project
claude
```

Then say:

```
/speckit.constitution
```

**Spec-kit will ask you about:**
- Code quality standards (formatting, linting, typing)
- Testing requirements (coverage %, types of tests)
- Technology stack (language, frameworks, tools)
- Performance expectations
- Security requirements

**Example answers:**
- "We use TypeScript with strict mode"
- "All code must have 80% test coverage"
- "We're building a Node.js API with Express"
- "API responses must be under 200ms"

Your answers become `.specify/memory/constitution.md` - the foundation for all development.

### Step 4: Set Up the Lemongrab Agents

Tell Claude to set up the TDD workflow agents:

```
Read AGENTIC-WORKFLOW.md and set up the agentic workflow. Create all the agent
files in .claude/agents/ and the docs folder structure as specified.
```

**What Claude will do:**
1. Read the AGENTIC-WORKFLOW.md file
2. Create `.claude/agents/` with all 6 agent definition files
3. Create `docs/requirements/`, `docs/plans/`, and `docs/decisions/` folders
4. Confirm everything is set up

**Verify it worked:**
```bash
ls .claude/agents/
# Should show: clarifier.md, documenter.md, implementer.md,
#              planner.md, simplifier.md, test-writer.md

ls docs/
# Should show: decisions/, plans/, requirements/
```

### Step 5: You're Ready!

Now you can start building features. For your first feature, say:

```
Use the clarifier agent to gather requirements for <your feature>
```

See the "Step-by-Step: Your First Feature" section below for a complete walkthrough.

### What Gets Created

```
your-project/
├── .specify/                     # Created by spec-kit
│   ├── memory/
│   │   └── constitution.md       # Your project principles
│   ├── specs/                    # Feature specifications
│   └── templates/                # Spec-kit templates
├── .claude/
│   └── agents/
│       ├── clarifier.md          # Requirements gathering
│       ├── planner.md            # Technical design
│       ├── test-writer.md        # Write failing tests
│       ├── implementer.md        # Make tests pass
│       ├── simplifier.md         # Clean up code
│       └── documenter.md         # Document the why
├── docs/
│   ├── requirements/             # Feature requirements
│   ├── plans/                    # Technical plans
│   └── decisions/                # Decision logs
├── AGENTIC-WORKFLOW.md           # Workflow documentation
└── README.md                     # This file
```

---

## The Workflow Explained

Here's how features get built with Lemongrab:

```
┌─────────────────────────────────────────────────────────────────────┐
│                         YOUR FEATURE REQUEST                         │
└─────────────────────────────────────────────────────────────────────┘
                                   │
                                   ▼
┌─────────────────────────────────────────────────────────────────────┐
│  1. CLARIFIER                                                        │
│     "What exactly do you need?"                                      │
│     → Asks questions, documents requirements                         │
│     → Output: docs/requirements/<feature>.md                         │
└─────────────────────────────────────────────────────────────────────┘
                                   │
                                   ▼
┌─────────────────────────────────────────────────────────────────────┐
│  2. PLANNER                                                          │
│     "How should we build this?"                                      │
│     → Creates architecture, breaks into tasks                        │
│     → Output: docs/plans/<feature>.md                                │
└─────────────────────────────────────────────────────────────────────┘
                                   │
                                   ▼
┌─────────────────────────────────────────────────────────────────────┐
│  3-5. FOR EACH TASK (repeat until done)                              │
│                                                                      │
│     ┌─────────────────┐                                              │
│     │  TEST WRITER    │  Write tests for this task                   │
│     │  (RED phase)    │  → Tests should FAIL (that's correct!)       │
│     └────────┬────────┘                                              │
│              │                                                       │
│              ▼                                                       │
│     ┌─────────────────┐                                              │
│     │  IMPLEMENTER    │  Write minimal code to pass tests            │
│     │  (GREEN phase)  │  → Tests should now PASS                     │
│     └────────┬────────┘                                              │
│              │                                                       │
│              ▼                                                       │
│     ┌─────────────────┐                                              │
│     │  SIMPLIFIER     │  Clean up without breaking tests             │
│     │  (REFACTOR)     │  → Tests must stay GREEN                     │
│     └─────────────────┘                                              │
└─────────────────────────────────────────────────────────────────────┘
                                   │
                                   ▼
┌─────────────────────────────────────────────────────────────────────┐
│  6. DOCUMENTER                                                       │
│     "Why did we build it this way?"                                  │
│     → Adds comments, creates decision log                            │
│     → Output: docs/decisions/<feature>.md                            │
└─────────────────────────────────────────────────────────────────────┘
```

### Why This Order Matters

1. **Clarifier first** - You can't build the right thing if you don't know what "right" means
2. **Planner second** - Design before you code prevents rewrites
3. **Tests before code** - Tests define what "done" looks like
4. **Minimal implementation** - Less code = fewer bugs
5. **Simplify after it works** - Don't optimize prematurely
6. **Document at the end** - You now know what you actually built

---

## Meet the Agents

### Constitution (One-Time Setup via Spec-Kit)

**When to use:** Once, when setting up a new project

**What it does:** Asks you about your project's standards and creates a constitution document that all other agents will follow.

**How to use:**
```
/speckit.constitution
```

**What it asks about:**
- Code formatting and linting preferences
- Testing requirements (what coverage? what types of tests?)
- Performance expectations
- Security requirements
- Technology constraints

**Output:** `.specify/memory/constitution.md`

---

### Clarifier Agent

**When to use:** At the start of every new feature or change

**What it does:** Asks questions to understand exactly what you want before any code is written.

**How to use:**
```
Use the clarifier agent to gather requirements for <your feature>
```

**What you'll get:** A requirements document with:
- User stories (who wants what and why)
- Acceptance criteria (how do we know it's done)
- Edge cases (what could go wrong)
- Out of scope (what we're NOT building)

---

### Planner Agent

**When to use:** After requirements are clear, before writing any code

**What it does:** Creates a technical plan and breaks the work into ordered tasks.

**How to use:**
```
Use the planner agent to create a technical plan for <your feature>
```

**What you'll get:** A plan document with:
- Architecture overview
- Data model (if needed)
- API contracts (if needed)
- Ordered task list with dependencies
- Tasks marked [P] that can run in parallel

---

### Test Writer Agent

**When to use:** For each task that needs tests (before implementation)

**What it does:** Writes tests that will fail - and that's correct! The tests define what the code should do.

**How to use:**
```
Use the test-writer agent for task [T001]
```

**What you'll get:** Test files that:
- Describe expected behavior
- Fail because the code doesn't exist yet
- Will pass once the implementer is done

---

### Implementer Agent

**When to use:** After tests are written and failing

**What it does:** Writes the minimum code needed to make tests pass. Nothing more.

**How to use:**
```
Use the implementer agent for task [T001]
```

**What you'll get:** Working code that:
- Passes all the tests
- Does exactly what was required
- Avoids unnecessary complexity

---

### Simplifier Agent

**When to use:** After tests are passing, when code feels too complex

**What it does:** Makes code simpler while keeping tests green.

**How to use:**
```
Use the simplifier agent to clean up the <feature> implementation
```

**What it looks for:**
- Dead code to remove
- Complex logic to simplify
- Duplication to eliminate
- Clever code to make obvious

---

### Documenter Agent

**When to use:** After implementation is complete and simplified

**What it does:** Documents the "why" - the reasoning behind decisions.

**How to use:**
```
Use the documenter agent to document <feature>
```

**What you'll get:**
- Inline comments explaining non-obvious decisions
- A decision log explaining what was built and why
- Updated project documentation

---

## Step-by-Step: Your First Feature

Let's walk through building a feature called "User Authentication" using the full workflow.

### 1. Clarify Requirements

**You say:**
```
Use the clarifier agent to gather requirements for user authentication
```

**Claude asks you questions like:**
- Should users log in with email, username, or both?
- Do you need password reset functionality?
- Should sessions expire? After how long?
- What happens when login fails 3 times?

**You get:** `docs/requirements/user-authentication.md`

### 2. Create Technical Plan

**You say:**
```
Use the planner agent to create a technical plan for user authentication
```

**Claude asks you questions like:**
- Should we use JWT tokens or sessions?
- Where should we store user data?
- Do you want OAuth support later?

**You get:** `docs/plans/user-authentication.md` with tasks like:
```
[T001] [US1] Setup: Create user model
[T002] [US1] Test: Write tests for user registration
[T003] [US1] Implement: Create registration endpoint
[T004] [US1] Test: Write tests for login
[T005] [US1] Implement: Create login endpoint
...
```

### 3. Build Task by Task

**For each task, you run three agents:**

```
Use the test-writer agent for task T002
```
→ Tests are written and FAIL (expected!)

```
Use the implementer agent for task T002
```
→ Code is written, tests now PASS

```
Use the simplifier agent for the registration code
```
→ Code is cleaned up, tests still PASS

**Repeat for T003, T004, T005...**

### 4. Document

**You say:**
```
Use the documenter agent for user authentication
```

**You get:** `docs/decisions/user-authentication.md` explaining:
- Why you chose JWT over sessions
- Why passwords are hashed with bcrypt
- Why sessions expire after 24 hours

---

## Working with Spec-Kit

[GitHub's spec-kit](https://github.com/github/spec-kit) is a spec-driven development framework. Lemongrab integrates its concepts into the multi-agent workflow.

### What is Spec-Kit?

Spec-kit provides slash commands for AI agents that guide you through structured software development. It works with Claude Code, GitHub Copilot, Cursor, and other AI coding assistants.

### Installing Spec-Kit

Spec-kit is a Python CLI tool. You need Python 3.11+ and Git.

```bash
# Install uv (Python package manager) if needed
curl -LsSf https://astral.sh/uv/install.sh | sh

# Install spec-kit globally
uv tool install specify-cli --from git+https://github.com/github/spec-kit.git

# Verify installation
specify check
```

Initialize spec-kit in your project:

```bash
specify init my-project
```

This creates a `.specify/` folder with templates and memory files.

### Spec-Kit Commands

Once installed, you can use these slash commands in Claude Code:

| Command | What It Does | Example |
|---------|--------------|---------|
| `/speckit.constitution` | Create project principles | `/speckit.constitution` |
| `/speckit.specify` | Write a feature spec | `/speckit.specify user authentication` |
| `/speckit.clarify` | Resolve ambiguities in a spec | `/speckit.clarify` |
| `/speckit.plan` | Create technical design | `/speckit.plan` |
| `/speckit.tasks` | Generate ordered task list | `/speckit.tasks` |
| `/speckit.implement` | Build the feature | `/speckit.implement` |

### How Lemongrab Maps to Spec-Kit

| Spec-Kit Command | Lemongrab Agent | What It Does |
|------------------|-----------------|--------------|
| `/speckit.constitution` | Constitution | Establish project principles |
| `/speckit.specify` | Clarifier | Define requirements |
| `/speckit.clarify` | Clarifier | Resolve ambiguities |
| `/speckit.plan` | Planner | Create technical design |
| `/speckit.tasks` | Planner | Break into ordered tasks |
| `/speckit.implement` | Test Writer + Implementer | Build the feature |
| (no equivalent) | Simplifier | Refactor for simplicity |
| (no equivalent) | Documenter | Record decisions |

### When to Use Which

**Use Lemongrab agents when:**
- You want TDD (test-first development)
- You want explicit refactoring and documentation steps
- You want per-task test → implement cycles

**Use spec-kit commands when:**
- You want spec-kit's detailed specification templates
- You're using a non-Claude AI assistant
- You want the `.specify/` folder structure

### Using Both Together (Recommended)

First, initialize spec-kit in your project:
```bash
specify init my-project
```

Then in Claude Code, use both systems:

```
# 1. Use spec-kit for detailed specifications (creates .specify/specs/user-auth/)
/speckit.specify user authentication

# 2. Use spec-kit to clarify ambiguities
/speckit.clarify

# 3. Switch to Lemongrab for TDD implementation
Use the planner agent to create a plan based on the spec in .specify/specs/user-auth/

# 4. Build with TDD (for each task in the plan)
Use the test-writer agent for task T001
Use the implementer agent for task T001
# ... continue for each task

# 5. Finish with Lemongrab
Use the simplifier agent for the authentication code
Use the documenter agent for user authentication
```

This gives you spec-kit's structured specifications plus Lemongrab's TDD discipline.

---

## Project Structure

```
your-project/
│
├── .specify/                      # Created by spec-kit
│   ├── memory/
│   │   └── constitution.md        # YOUR project's principles
│   ├── specs/                     # Feature specifications
│   │   └── <feature-name>/        # One folder per feature
│   └── templates/                 # Spec-kit templates
│
├── .claude/
│   └── agents/                    # Agent definitions for Claude Code
│       ├── clarifier.md           # Gathers requirements
│       ├── planner.md             # Creates technical plans
│       ├── test-writer.md         # Writes failing tests
│       ├── implementer.md         # Makes tests pass
│       ├── simplifier.md          # Removes complexity
│       └── documenter.md          # Records decisions
│
├── docs/
│   ├── requirements/              # Feature requirements
│   │   └── <feature-name>.md      # One file per feature
│   │
│   ├── plans/                     # Technical plans
│   │   └── <feature-name>.md      # Architecture + task breakdown
│   │
│   └── decisions/                 # Decision logs
│       └── <feature-name>.md      # Why we built it this way
│
├── src/                           # Your source code (structure varies)
│
├── tests/                         # Your tests (structure varies)
│
├── AGENTIC-WORKFLOW.md            # Detailed workflow documentation
│
└── README.md                      # This file
```

### What Each Folder Is For

| Folder | Purpose | Created By |
|--------|---------|------------|
| `.specify/memory/constitution.md` | Project-wide principles and standards | `/speckit.constitution` |
| `.specify/specs/` | Detailed feature specifications | `/speckit.specify` |
| `.claude/agents/` | Agent instructions for Claude Code | Setup process |
| `docs/requirements/` | What each feature should do | Clarifier agent |
| `docs/plans/` | How to build each feature | Planner agent |
| `docs/decisions/` | Why features were built this way | Documenter agent |

---

## FAQ / Troubleshooting

### "Do I have to use all the agents?"

No! Use what helps you. At minimum:
- **Constitution** - Always run `/speckit.constitution` once to set project standards
- **Clarifier** - Always useful to prevent misunderstandings
- **Test Writer + Implementer** - Core TDD loop

Skip what you don't need:
- **Planner** - Skip for very simple features
- **Simplifier** - Skip if code is already clean
- **Documenter** - Skip for throwaway code

### "The test-writer says tests are failing - is that wrong?"

No! That's correct! In TDD, you write tests FIRST, before the code exists. Tests are supposed to fail initially. The implementer agent then writes code to make them pass.

### "Can I skip straight to implementation?"

You can, but you lose the benefits:
- Without clarifier → You might build the wrong thing
- Without planner → You might have to rewrite later
- Without test-writer → You might have bugs
- Without simplifier → Your code might be harder to maintain
- Without documenter → You'll forget why you made decisions

### "How is this different from just asking Claude to build something?"

When you just say "build X", Claude might:
- Make assumptions about requirements
- Skip tests
- Over-engineer or under-engineer
- Not document decisions

The agent workflow ensures each step is done properly, by an agent focused on that specific task.

### "What if an agent gets stuck or makes a mistake?"

- You can always interrupt and correct
- Run the same agent again with clarifications
- Skip an agent if it's not helpful for your situation

### "How do I customize the agents?"

Edit the files in `.claude/agents/`. Each file is a markdown document with:
- `name` - Agent identifier
- `description` - When to use it
- `tools` - What Claude tools it can use
- `model` - Which Claude model (sonnet/opus)
- Instructions - What the agent does

