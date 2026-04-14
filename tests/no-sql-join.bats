#!/usr/bin/env bats
# rule-id: c9 (criterion 9)
# hook no-sql-join — block JOIN in TS/SQL, skip comments + string literals

HOOK="$HOME/utils/leo-skills/hooks/scripts/no-sql-join.sh"

@test "hook script exists" {
    [ -f "$HOOK" ]
}

@test "hook has rule-id header comment" {
    head -10 "$HOOK" | grep -q "# rule-id:"
}

json_input() {
    jq -n --arg path "$1" --arg content "$2" \
        '{tool_name:"Edit", tool_input:{file_path:$path, new_string:$content}}'
}

@test "BLOCK: JOIN in .ts template literal" {
    run bash "$HOOK" <<< "$(json_input "/tmp/x.ts" 'const q = \`SELECT * FROM a INNER JOIN b ON a.id=b.a_id\`;')"
    [ "$status" -eq 2 ]
}

@test "ALLOW: JOIN inside line comment //" {
    run bash "$HOOK" <<< "$(json_input "/tmp/x.ts" '// use JOIN for speed')"
    [ "$status" -eq 0 ]
}

@test "ALLOW: JOIN inside string literal (double quotes)" {
    run bash "$HOOK" <<< "$(json_input "/tmp/x.ts" 'const s = "word JOIN another";')"
    [ "$status" -eq 0 ]
}

@test "ALLOW: migration path" {
    run bash "$HOOK" <<< "$(json_input "/Users/leo/app/migrations/001.sql" 'SELECT a FROM x JOIN y;')"
    [ "$status" -eq 0 ]
}

@test "ALLOW: .py file (not filtered)" {
    run bash "$HOOK" <<< "$(json_input "/tmp/x.py" 'df.join(other)')"
    [ "$status" -eq 0 ]
}
