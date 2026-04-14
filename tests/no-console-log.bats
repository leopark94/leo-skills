#!/usr/bin/env bats
# rule-id: c8 (criterion 8)
# hook no-console-log — block console.log in .ts/.js (with allowlist)

HOOK="$HOME/utils/leo-skills/hooks/scripts/no-console-log.sh"

@test "hook script exists" {
    [ -f "$HOOK" ]
}

@test "hook has rule-id header comment" {
    head -10 "$HOOK" | grep -q "# rule-id:"
}

json_input() {
    # $1 = file path, $2 = content
    jq -n --arg path "$1" --arg content "$2" \
        '{tool_name:"Edit", tool_input:{file_path:$path, new_string:$content}}'
}

@test "BLOCK: console.log in .ts" {
    run bash "$HOOK" <<< "$(json_input "/tmp/x.ts" 'console.log("hi");')"
    [ "$status" -eq 2 ]
    [[ "$output" == *"console"* || "$stderr" == *"console"* ]] || true
}

@test "BLOCK: console.debug in .tsx" {
    run bash "$HOOK" <<< "$(json_input "/tmp/x.tsx" 'console.debug(x);')"
    [ "$status" -eq 2 ]
}

@test "ALLOW: // commented console.log" {
    run bash "$HOOK" <<< "$(json_input "/tmp/x.ts" '// console.log(hi);')"
    [ "$status" -eq 0 ]
}

@test "ALLOW: allowlist path packages/shared/logger/" {
    run bash "$HOOK" <<< "$(json_input "/Users/leo/utils/packages/shared/logger/a.ts" 'console.log("ok");')"
    [ "$status" -eq 0 ]
}

@test "ALLOW: test file" {
    run bash "$HOOK" <<< "$(json_input "/tmp/x.test.ts" 'console.log("in test");')"
    [ "$status" -eq 0 ]
}

@test "ALLOW: .py file (not filtered)" {
    run bash "$HOOK" <<< "$(json_input "/tmp/x.py" 'print("console.log is not tested here")')"
    [ "$status" -eq 0 ]
}
