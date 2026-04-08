# Always read this claude.md before generating any code or making changes

# If any instruction here conflicts with your default behavior, FOLLOW THIS FILE

# BEFORE giving final output, you MUST perform Auto Code Review as defined below


CampusNex Claude Instructions

---

## Tech Stack

Flutter (Android, iOS)
Riverpod (state management)
GoRouter (navigation)
Supabase (Postgres + RLS + Storage)

* App must support both Android and iOS
* Avoid platform-specific code unless absolutely required
* Use platform-adaptive widgets when needed
* Do not assume Android-only behavior (UI, permissions, file paths)

---

## Architecture Rules (STRICT)

* ALWAYS use Repository pattern
* NEVER put business logic inside UI
* Controllers/Providers handle logic
* UI only handles display and user interaction
* DO NOT refactor existing architecture unless explicitly asked

---

## Data Model Rules (STRICT)

* ALWAYS use models instead of Map<String, dynamic>
* NEVER use raw maps in UI or business logic
* Repository MUST convert JSON → Model
* Repository MUST return models (not Map) for read operations
* UI must use model fields (staff.name, not staff['name'])
* All database responses must be mapped to models before use
* NEVER mix Map and Model usage in the same feature/module

---

## Multi-Tenancy (CRITICAL)

* EVERY query MUST include school_id
* NEVER fetch or mutate data without school_id
* NEVER rely on username alone
* NEVER hardcode school_id
* If school_id is missing → STOP and ask
* User context must be available before performing any tenant-based query
* If user is null, handle gracefully (fallback or retry)
* Providers must not silently fail due to missing user context

---

## Supabase Rules (CRITICAL)

* NEVER modify database schema unless explicitly asked
* ALWAYS assume RLS will be enforced
* DO NOT bypass security rules
* Use Supabase auth session when required
* Do NOT assume auth.uid() works in dev mode

---

## Dev vs Production Behavior

* Dev mode may NOT have Supabase auth session
* auth.uid() may return NULL in dev mode
* DO NOT enforce DB constraints blindly
* Always suggest safe migration steps before schema changes

---

## Username System

* username = mobile.short_name
* Always lowercase
* Always trimmed
* Must be unique

---

## Riverpod Rules

* Use ref.watch ONLY at screen level
* Use ref.read for actions (create/update/delete)
* DO NOT use ConsumerWidget inside list items
* DO NOT use ref improperly inside dialogs or bottom sheets
* Avoid unnecessary rebuilds

---

## BottomSheet Rules (VERY IMPORTANT)

* ALL forms must be inside BottomSheet
* BottomSheet MUST NOT show dialogs
* BottomSheet MUST return result using Navigator.pop(context, result)
* Parent screen handles success/error UI (dialogs/snackbars)
* NEVER use double Navigator.pop()
* Always check context.mounted before UI actions

---

## Error Handling Pattern (STRICT)

* Repository MUST NOT throw raw exceptions to UI
* Repository MUST return models for read operations
* For create/update/delete operations, return structured result

Example:

class Result {
  final bool success;
  final String? error;
}

* DO NOT parse errors in UI
* DO NOT throw raw exceptions to UI
* UI only displays user-friendly messages

---

## Staff Module Rules (CRITICAL)

* Staff MUST always be linked to users via user_id
* ALWAYS create user first, then staff
* empcode must be unique per school
* empcode must NEVER be reused
* Soft delete ONLY (is_active = false)
* NEVER hard delete staff

---

## Image Upload Rules

* Use Supabase Storage
* Path format:
  school_id/staff/<timestamp>.jpg
* Store public URL in photo_url
* Handle null image safely

---

## UI Rules

* Keep UI simple and minimal
* DO NOT redesign layout unless asked
* Follow existing UI patterns
* Avoid over-engineering

---

## Logging Rules

* Debug logs should not remain in production code
* Only error logs should be retained in repositories

---

## Safety Rules

* DO NOT break existing flows
* DO NOT remove working code without reason
* DO NOT introduce breaking changes
* Always handle async safely (context.mounted)

---

## AUTO CODE REVIEW MODE (MANDATORY)

Before generating final output, you MUST internally validate:

### 1. Architecture Check
* Is business logic inside UI? → ❌ Reject
* Is repository pattern followed? → ✅ Required

### 2. Multi-Tenant Safety
* Does every query include school_id? → ✅ Required
* Any hardcoded values? → ❌ Reject

### 3. BottomSheet Compliance
* Any dialog inside BottomSheet? → ❌ Reject
* Is result returned properly? → ✅ Required

### 4. Error Handling
* Are raw exceptions exposed to UI? → ❌ Reject
* Is structured result used for write operations? → ✅ Required

### 5. Riverpod Usage
* ref.watch only at screen level? → ✅
* ref.read used for actions? → ✅

### 6. Supabase Safety
* Any schema modification without request? → ❌ Reject
* Any assumption about auth.uid() in dev mode? → ❌ Reject

### 7. Code Quality
* Any unnecessary complexity? → ❌ Reject
* Any duplicate logic? → ❌ Reject

---

## REVIEW OUTPUT RULE

* DO NOT mention this checklist explicitly in final answer
* If violations exist → FIX before responding
* Output ONLY clean, production-ready code

---

## When Unsure

* ASK instead of guessing
* DO NOT assume missing logic
* DO NOT invent architecture

---

## GOAL

Generate clean, scalable, production-ready code that strictly follows this architecture without deviation.