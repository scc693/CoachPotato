Agents.md — Coach Potato Development (v1)

**Version:** 1.0  
**Scope:** Coach Potato iOS App — Local Development Stack  
**Status:** Baseline clean workflow; no legacy pipeline components.

This file defines how all agents, tools, and processes interact inside this repository. It exists to keep development consistent, predictable, and Codex-friendly.

---

# 1. Project Structure & Root Paths

**Repository root:**

```
/Users/stuart/Desktop/CoachPotato
```

**Key directories:**

```
Coach Potato/                       ← Xcode project folder
Coach Potato/Coach Potato.xcodeproj ← App project file

DevStack/
   Tools/                           ← Build, test, accessibility, visual diff scripts
   Reference/
      Docs/
         index.yaml                 ← AppleDocs index
         AppleDocs/                 ← Local documentation set
         Scripts/                   ← Auto-indexing scripts (full + append)
```

This is a **local-only** development stack.  
There is **no remote repo**, no MCP servers, no cloud dependencies.

---

# 2. Agents

This project uses three functional “agents”:  
**Planner**, **Codex**, and **DocScripts**.  
Each has specific responsibilities, boundaries, and rules.

---

## 2.1 Planner (Codex)

**Role:** Architecture, reasoning, planning, writing prompts, documentation.

**Responsibilities:**

- Produce Codex-ready prompts with the correct environment assumptions.  
- Define or revise architecture:  
  - `App/` = app entry, navigation, DI  
  - `Core/` = pure Swift logic, domain models, utilities  
  - `Data/` = HTTP clients, repositories, SwiftData stack  
  - `Features/` = self-contained feature modules  
- Write or update documentation (`Agents.md`, design notes, data models).  
- Propose clean refactors and enforce structural boundaries.  
- Never perform ad-hoc code edits — that is Codex’s job.

**Non-responsibilities:**

- Editing code files  
- Running build/test tools  
- Handling simulator/device config

Planner is responsible for **thinking**, not **doing**.

---

## 2.2 Codex (Coding Agent)

**Role:** Modify project files, implement features, refactor code, and run the DevStack tools.

**Environment Assumptions:**

- Project location:

  ```
  /Users/stuart/Desktop/CoachPotato/Coach Potato/Coach Potato.xcodeproj
  ```

- Dev tools (from repo root):

  ```
  DevStack/Tools/build.sh
  DevStack/Tools/test.sh
  DevStack/Tools/axe.sh
  DevStack/Tools/peekaboo.sh
  ```

- AppleDocs:

  ```
  DevStack/Reference/Docs/index.yaml
  DevStack/Reference/Docs/AppleDocs/
  ```

**Rules for Codex:**

1. **Use DevStack tools — NOT raw xcodebuild.**
   - For builds: `DevStack/Tools/build.sh`
   - For tests: `DevStack/Tools/test.sh`
   - For UI/AX: `DevStack/Tools/axe.sh`
   - For visual diffs: `DevStack/Tools/peekaboo.sh`

2. **Never guess Apple APIs.  
   Use local AppleDocs first.**
   - SwiftUI  
   - SwiftData  
   - Concurrency  
   - Networking  
   - HIG  
   - Foundation models (if used later)

3. **Feature boundaries must stay clean:**
   - `Core/` has **no SwiftUI imports**
   - `Data/` has **no SwiftUI imports**
   - `Features/` contains UI + view models only
   - Repositories exposed via protocols, injected via DI

4. **Incremental work only.**
   - Modify only the files relevant to the current task  
   - Write clear summaries of:
     - What changed  
     - Why  
     - Which tools were run  
     - Build/test results

5. **On test failures:**  
   - Fix unit tests first  
   - Treat UI test failures as optional unless the task specifies otherwise

---

## 2.3 DocScripts (Documentation Indexing)

**Role:** Maintain the AppleDocs index.

**Scripts live in:**

```
DevStack/Reference/Docs/Scripts/
```

**Two responsibilities:**

1. **Full index rebuild:**

   ```
   auto_index_docs.sh
   ```

   Scans the AppleDocs folder and regenerates the entire  
   `index.yaml`.

2. **Append on file-drop:**

   ```
   append-to-index.sh
   ```

   Used by Folder Actions to add new docs automatically.

**Codex does not call these scripts.**  
Planner may instruct you to run them manually after adding/renaming docs.

---

# 3. Architectural Guardrails

These rules exist to keep the codebase healthy:

### Language & Platform
- iOS 17+
- Swift 6
- SwiftUI for UI
- SwiftData for persistence
- async/await everywhere possible
- URLSession for networking

### Encapsulation
- UI is in `Features/`
- Domain logic is in `Core/`
- Persistence + API clients are in `Data/`
- App shell + DI lives in `App/`

### Data Layer
- Repositories expose protocol-based interfaces
- SwiftData models live under `Data/Models`
- HTTP clients live under `Data/Clients`
- No direct HTTP calls from views or view models

### Unit Tests
- Unit tests run through `DevStack/Tools/test.sh`
- UI tests moved to `axe.sh` to isolate flakiness

---

# 4. Workflow Summary

## 1. Planning → Planner
User describes a task → Planner generates Codex prompt  
Planner includes:
- Environment contract
- File targets
- Expected changes
- Any architectural notes

## 2. Implementation → Codex  
Codex applies changes:
- Writes/modifies files
- Uses DevStack tools
- Reports results

## 3. Documentation → DocScripts  
When docs change, run:
- Full rebuild — `auto_index_docs.sh`
- Incremental append — `append-to-index.sh`

---

# 5. Anti-Patterns (Things to Avoid)

- Views touching `ModelContext` directly unless explicitly needed  
- Networking inside SwiftUI Views  
- Business logic hidden in view models  
- Massive God Views instead of modular components  
- Guessing SwiftUI/SwiftData APIs without checking AppleDocs  
- Letting UI tests break the whole pipeline (isolated under axe)

---

# 6. Tooling Contract (Codex Environment)

This contract defines the **exact environment, paths, and tools** that Codex is authorized to use within this repository. Codex must follow these rules strictly and never guess or invent behavior.

---

## 6.1 Project Paths

**Xcode project file:**

```
/Users/stuart/Desktop/CoachPotato/Coach Potato/Coach Potato.xcodeproj
```

**Repository root:**

```
/Users/stuart/Desktop/CoachPotato
```

All Codex paths are assumed to be relative to this root unless explicitly stated.

---

## 6.2 DevStack Tooling

Codex must use the following scripts for all local builds, tests, and analysis:

### Build
```
DevStack/Tools/build.sh
```

### Unit Tests (required)
```
DevStack/Tools/test.sh
```

### Accessibility / UI Tests (optional)
```
DevStack/Tools/axe.sh
```
⚠️ UI/AX tests may be flaky.  
Codex should not rely on axe unless explicitly instructed.

### Visual Regression (optional)
```
DevStack/Tools/peekaboo.sh
```
If Peekaboo is not installed, Codex must treat failures as non-blocking.

---

## 6.3 AppleDocs Access

Codex must reference the **local Apple documentation index** before attempting to infer APIs.

**Index file:**
```
DevStack/Reference/Docs/index.yaml
```

**Document roots:**
```
DevStack/Reference/Docs/AppleDocs/
```

Codex must:

1. Use the index to locate API references.
2. Not invent APIs that do not appear in the index.
3. Prefer AppleDocs wording for SwiftUI, SwiftData, Swift Concurrency, and HIG definitions.
4. If no documentation relative to the current task exist Codex must tell the user what documentation it is looking for and ask for a copy to be added to to the AppleDocs directory

---

## 6.4 Schemes & Targets

Codex must assume the following scheme exists for all build/test operations:

```
Scheme: "Coach Potato"
```

Codex must not create new schemes unless explicitly instructed.

---

## 6.5 Simulator Contract

Codex uses the following simulator target for all builds/tests:

```
platform=iOS Simulator,name=iPhone 17,OS=26.1
```

If Xcode changes the OS version, Codex may update only:

- `OS=x.x`
- The simulator name (if not available)

But **may not** change device class (e.g., can't switch to iPad) unless instructed.

---

## 6.6 File Editing Rules

Codex may:

- Create or modify files under:
  - `App/`
  - `Core/`
  - `Data/`
  - `Features/`
  - `Coach PotatoTests/`

Codex may **not** modify:

- Anything under `DevStack/`  
- The AppleDocs library  
- The auto-indexing scripts  
- System-level directories  

Unless explicitly instructed.

---

## 6.7 Expected Output Format

For every task, Codex must produce:

1. **Change Summary**  
2. **Modified Files** (with unified diffs or created file contents)  
3. **DevStack Tool Results**:
   - `build.sh`  
   - `test.sh`  
   - Optional: `axe.sh` / `peekaboo.sh` only when relevant  
4. **Post-conditions** confirming whether the codebase compiles and tests pass.

---

**This tooling contract is mandatory for all Codex interactions.**

# 7. Versioning Rule

- Any major change to:
  - DevStack tools  
  - Folder structure  
  - Agent responsibilities  
  - Documentation pipeline  
- MUST bump the version number in this file.

---

**This is the starting point — Agents v1.**  
Everything else builds from here.
