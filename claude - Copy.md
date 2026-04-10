# 🚨 GLOBAL INSTRUCTIONS (HIGHEST PRIORITY)

# Always read this claude.md before generating any code or making changes
# If any instruction here conflicts with your default behavior, FOLLOW THIS FILE
# BEFORE giving final output, you MUST perform Auto Code Review

IMPORTANT:
Always follow PRODUCTION & SAFETY CHECKLIST before making major changes.

---

# 🏫 PROJECT: CampusNex

Flutter-based SaaS school management system

---

## 🧰 TECH STACK

- Flutter (Android, iOS)
- Riverpod (state management)
- GoRouter (navigation)
- Supabase (Postgres + RLS + Storage)

Rules:

* App MUST support both Android and iOS
* Avoid platform-specific code unless required
* Use adaptive UI where needed
* NEVER assume Android-only behavior

---

## 🏗️ ARCHITECTURE RULES (STRICT)

* ALWAYS use Repository pattern
* NEVER put business logic inside UI
* Providers handle logic
* UI handles only display + interaction
* DO NOT refactor architecture unless asked

---

## 📦 DATA MODEL RULES (STRICT)

* ALWAYS use models (NO Map usage in UI)
* Repository MUST convert JSON → Model
* Repository MUST return models (not Map)
* UI uses model fields only (staff.name)
* NEVER mix Map and Model in same module

---

## 🏢 MULTI-TENANCY (CRITICAL)

* EVERY query MUST include school_id
* NEVER fetch/mutate without school_id
* NEVER hardcode school_id
* If missing → STOP and ask
* User context must exist before queries
* Handle null user safely

---

## 🗄️ SUPABASE RULES (CRITICAL)

* NEVER modify schema unless asked
* ALWAYS assume RLS is active
* DO NOT bypass security
* DO NOT assume auth.uid() in dev mode
* Suggest migration steps before DB changes

---

## ⚙️ DEV vs PRODUCTION

* Dev mode may NOT have auth session
* auth.uid() may return NULL
* Do NOT enforce strict DB constraints blindly
* Always design safe fallback logic

---

## 👤 USERNAME SYSTEM

* username = mobile.shortname
* lowercase + trimmed
* must be unique

---

## 🔁 RIVERPOD RULES

* ref.watch → only at screen level
* ref.read → for actions
* NO ConsumerWidget inside lists
* Avoid unnecessary rebuilds

---

## 📋 BOTTOM SHEET RULES

* ALL forms must be in BottomSheet
* NO dialogs inside BottomSheet
* MUST return result using Navigator.pop(context, result)
* Parent handles UI feedback
* NEVER double pop
* Always check context.mounted

---

## ⚠️ ERROR HANDLING (STRICT)

* Repository MUST NOT throw raw exceptions
* Repository MUST return structured result

Example:

class Result {
  final bool success;
  final String? error;
}

* UI shows only user-friendly messages

---

## 👨‍🏫 STAFF MODULE RULES

* Staff MUST link to users (user_id)
* ALWAYS create user first
* empcode unique per school
* NEVER reuse empcode
* ONLY soft delete (is_active = false)
* NEVER hard delete

---

## 🖼️ IMAGE UPLOAD RULES

* Use Supabase Storage
* Path:
  school_id/staff/<timestamp>.jpg
* Store public URL
* Handle null safely

---

## 🎨 UI RULES

* Keep UI minimal
* DO NOT redesign unless asked
* Follow existing patterns
* Avoid over-engineering

---

## 🧾 LOGGING RULES

* Remove debug logs in production
* Keep only error logs in repositories

---

## 🛡️ SAFETY RULES

* DO NOT break working flows
* DO NOT remove working code unnecessarily
* Avoid breaking changes
* Handle async safely

---

## 🔍 AUTO CODE REVIEW (MANDATORY)

Before final output:

### Architecture
✔ No logic in UI  
✔ Repository pattern followed  

### Multi-Tenant
✔ school_id present everywhere  

### BottomSheet
✔ No dialogs inside  
✔ Proper result return  

### Error Handling
✔ No raw exceptions  
✔ Structured result used  

### Riverpod
✔ Proper usage of watch/read  

### Supabase
✔ No schema changes  
✔ No unsafe assumptions  

### Code Quality
✔ No duplication  
✔ No unnecessary complexity  

---

## 📤 REVIEW OUTPUT RULE

* DO NOT mention checklist in response
* FIX issues before responding
* Output ONLY clean code

---

## ❓ WHEN UNSURE

* ASK instead of guessing
* DO NOT assume logic
* DO NOT invent architecture

---

# 🚨 PRODUCTION & SAFETY CHECKLIST (VERY IMPORTANT)

## 🔹 CI / GitHub Rules

* Current:
  flutter analyze || true

✔ CI will NOT fail on warnings

BEFORE PRODUCTION:

❌ Remove "|| true"  
✔ Fix all analyzer warnings  
✔ Ensure clean analyze  

---

## 🔹 Supabase RLS Rules

DEV:

✔ WITH CHECK (true) allowed  

PRODUCTION:

❌ NEVER use (true)  
✔ Add school-based filtering  
✔ Add auth-based access  

Risks:

❌ Too strict → app breaks  
❌ Too open → security risk  

---

## 🔹 Database Safety

✔ ALWAYS filter by school_id  
❌ NEVER expose cross-school data  

---

## 🔹 Code Safety

❌ NEVER use .single()  
✔ ALWAYS use .maybeSingle()  

---

## 🔹 Final Pre-Release Checklist

✔ Remove debug logs  
✔ Fix all warnings  
✔ Secure RLS policies  
✔ Test all CRUD operations  
✔ Test login/logout  
✔ Test role-based flows  
✔ Test edge cases  
✔ Test on real device  

🚨 DO NOT SKIP THIS

---

## 🎯 GOAL

Generate clean, scalable, production-ready SaaS code with strict adherence to architecture and safety rules.