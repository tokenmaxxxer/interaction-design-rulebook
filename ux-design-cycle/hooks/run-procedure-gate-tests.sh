#!/usr/bin/env bash
# Test harness for ux-design-cycle's five procedure-enforcement gates
# (contract §11, §13, §20, §21). Each gate is exercised with one crafted
# VIOLATION (must be refused, non-zero) and one COMPLIANT case (must pass,
# exit 0). Prints PASS/FAIL per case; exits non-zero if any case fails.
set -uo pipefail

hook_dir="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" >/dev/null 2>&1 && pwd -P)"
work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT

fail_count=0
pass_count=0
pass() { echo "PASS: $1"; pass_count=$((pass_count + 1)); }
fail() { echo "FAIL: $1"; fail_count=$((fail_count + 1)); }

# run <gate> <project_dir> <cwd> <json>  -> sets OUT, returns exit code
run() {
  local gate="$1" pdir="$2" cwd="$3" json="$4"
  OUT="$(cd "$cwd" && printf '%s' "$json" | CLAUDE_PROJECT_DIR="$pdir" "$hook_dir/$gate" 2>&1)"
  return $?
}

wjson() { # tool_name Write, file_path, content  -> json
  python3 -c '
import json,sys
print(json.dumps({"tool_name":"Write","tool_input":{"file_path":sys.argv[1],"content":sys.argv[2]}}))
' "$1" "$2"
}
bjson() { # command -> Bash json
  python3 -c 'import json,sys; print(json.dumps({"tool_name":"Bash","tool_input":{"command":sys.argv[1]}}))' "$1"
}

root="$work/proj"
mkdir -p "$root/docs/reports/records/subj-a"

# ===== record-fields-gate (§20) =====
bad_rec='---
loop_state: drafting
---
just some notes'
run record-fields-gate.sh "$root" "$root" "$(wjson "docs/reports/records/subj-a/ux-design.md" "$bad_rec")"
[ $? -ne 0 ] && pass "record-fields: violation (missing sections) refused" || fail "record-fields: violation ALLOWED: $OUT"

good_rec='---
loop_state: reviewed
---
## What was done
Drafted the onboarding flow wireframes.

## Basis
upstream: docs/reports/records/subj-a/product.md'
run record-fields-gate.sh "$root" "$root" "$(wjson "docs/reports/records/subj-a/ux-design.md" "$good_rec")"
[ $? -eq 0 ] && pass "record-fields: compliant record allowed" || fail "record-fields: compliant DENIED: $OUT"

# ===== path-ownership-gate (§11) =====
run path-ownership-gate.sh "$root" "$root" "$(wjson "docs/reports/records/subj-a/coding.md" "x")"
[ $? -ne 0 ] && pass "path-ownership: write to foreign role's record refused" || fail "path-ownership: foreign write ALLOWED: $OUT"

run path-ownership-gate.sh "$root" "$root" "$(wjson "docs/reports/records/subj-a/ux-design.md" "x")"
[ $? -eq 0 ] && pass "path-ownership: write to own record allowed" || fail "path-ownership: own write DENIED: $OUT"

# ===== doc-bucket-gate (§21 bucket half) =====
run doc-bucket-gate.sh "$root" "$root" "$(wjson "docs/scratch/notes.md" "x")"
[ $? -ne 0 ] && pass "doc-bucket: write outside the six buckets refused" || fail "doc-bucket: out-of-bucket ALLOWED: $OUT"

run doc-bucket-gate.sh "$root" "$root" "$(wjson "docs/specs/design-x.md" "x")"
[ $? -eq 0 ] && pass "doc-bucket: write into specs/ bucket allowed" || fail "doc-bucket: in-bucket DENIED: $OUT"

# ===== handbook-trigger-gate (§21 handbook half) =====
grepo="$work/grepo"
mkdir -p "$grepo"
( cd "$grepo" && git init -q && git config user.email t@t && git config user.name t )
# violation: stage an operational-surface file, no handbook touched.
printf '{}' > "$grepo/package.json"
( cd "$grepo" && git add package.json )
run handbook-trigger-gate.sh "$grepo" "$grepo" "$(bjson "git commit -m 'add manifest'")"
[ $? -ne 0 ] && pass "handbook-trigger: manifest change without handbook refused" || fail "handbook-trigger: unhandbooked change ALLOWED: $OUT"

# compliant: same manifest change PLUS a handbook update staged.
mkdir -p "$grepo/docs/handbooks"
printf '# pkg\n' > "$grepo/docs/handbooks/package.md"
( cd "$grepo" && git add docs/handbooks/package.md )
run handbook-trigger-gate.sh "$grepo" "$grepo" "$(bjson "git commit -m 'add manifest + handbook'")"
[ $? -eq 0 ] && pass "handbook-trigger: manifest change WITH handbook allowed" || fail "handbook-trigger: handbooked change DENIED: $OUT"

# ===== trailer-gate (§13) =====
run trailer-gate.sh "$grepo" "$grepo" "$(bjson "git commit -m 'no trailer here'")"
[ $? -ne 0 ] && pass "trailer: commit without Subject/Kind trailer refused" || fail "trailer: untrailer'd commit ALLOWED: $OUT"

good_msg='land ux-design record

Subject: subj-a
Kind: ux-design-record'
run trailer-gate.sh "$grepo" "$grepo" "$(bjson "git commit -m \"$good_msg\"")"
[ $? -eq 0 ] && pass "trailer: commit with Subject/Kind trailer allowed" || fail "trailer: trailer'd commit DENIED: $OUT"

# ===== fail-closed sanity: malformed JSON refused by a content gate =====
run record-fields-gate.sh "$root" "$root" 'not json {{{'
[ $? -ne 0 ] && pass "fail-closed: malformed JSON payload refused" || fail "fail-closed: malformed JSON ALLOWED: $OUT"

# ===== fail-closed on INTERNAL ERROR: each gate must resolve to exit 2 =====
# Two crash-inducing payloads per gate class:
#   - null byte in file_path: os.path.realpath raises ValueError, which
#     before hardening exited 1 (uncaught) = fail-open for a PreToolUse hook.
#     Must now map to exit 2 (DENY).
#   - malformed JSON: unparseable payload must deny (exit 2), never pass.
# The null is carried as the   escape (six literal chars in payload text);
# json.loads turns it into a real null char inside the judge.
nulljson_write() { # file_path-with-null-marker -> Write JSON (marker % -> \x00)
  python3 -c '
import json,sys
fp = sys.argv[1].replace("%", "\x00")
print(json.dumps({"tool_name":"Write","tool_input":{"file_path":fp,"content":"x"}}))
' "$1"
}

# doc-bucket-gate: null byte in a docs/ path reaches os.path.realpath -> ValueError
run doc-bucket-gate.sh "$root" "$root" "$(nulljson_write 'docs/spe%cs/x.md')"
[ $? -eq 2 ] && pass "fail-closed: doc-bucket null-byte file_path -> exit 2" || fail "fail-closed: doc-bucket null-byte did NOT exit 2 (got $?): $OUT"
run doc-bucket-gate.sh "$root" "$root" 'not json {{{'
[ $? -eq 2 ] && pass "fail-closed: doc-bucket malformed JSON -> exit 2" || fail "fail-closed: doc-bucket malformed JSON did NOT exit 2 (got $?): $OUT"

# path-ownership-gate: null byte reaches resolve()'s os.path.realpath -> ValueError
run path-ownership-gate.sh "$root" "$root" "$(nulljson_write 'docs/reports/records/subj-a%/coding.md')"
[ $? -eq 2 ] && pass "fail-closed: path-ownership null-byte file_path -> exit 2" || fail "fail-closed: path-ownership null-byte did NOT exit 2 (got $?): $OUT"
run path-ownership-gate.sh "$root" "$root" 'not json {{{'
[ $? -eq 2 ] && pass "fail-closed: path-ownership malformed JSON -> exit 2" || fail "fail-closed: path-ownership malformed JSON did NOT exit 2 (got $?): $OUT"

# record-fields-gate: malformed JSON must deny (exit 2)
run record-fields-gate.sh "$root" "$root" 'not json {{{'
[ $? -eq 2 ] && pass "fail-closed: record-fields malformed JSON -> exit 2" || fail "fail-closed: record-fields malformed JSON did NOT exit 2 (got $?): $OUT"

# trailer-gate: malformed JSON must deny (exit 2)
run trailer-gate.sh "$grepo" "$grepo" 'not json {{{'
[ $? -eq 2 ] && pass "fail-closed: trailer malformed JSON -> exit 2" || fail "fail-closed: trailer malformed JSON did NOT exit 2 (got $?): $OUT"

# handbook-trigger-gate: malformed JSON must deny (exit 2)
run handbook-trigger-gate.sh "$grepo" "$grepo" 'not json {{{'
[ $? -eq 2 ] && pass "fail-closed: handbook-trigger malformed JSON -> exit 2" || fail "fail-closed: handbook-trigger malformed JSON did NOT exit 2 (got $?): $OUT"

echo
echo "== $pass_count passed, $fail_count failed =="
[ "$fail_count" -eq 0 ]
