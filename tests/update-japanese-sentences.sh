#!/usr/bin/env bash

set -euo pipefail

repo="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
test_dir="$(mktemp -d)"
trap 'rm -rf -- "$test_dir"' EXIT

fixture="$test_dir/upstream"
fake_bin="$test_dir/bin"
mkdir -p "$fixture/Recognition" "$fixture/Production" "$fake_bin"

printf '%s\n' '{"modelName":"Japanese sentences","inOrderFields":["SentKanji","VocabDef"],"cardTemplates":["Recognition","Production"]}' >"$fixture/template.json"
printf '%s\n' 'body { color: red; }' >"$fixture/template.css"
printf '%s\n' \
    '{{edit:furigana:VocabDef}} {{edit:hint:furigana:VocabDef}}' \
    'details_element.toggleAttribute("open", !is_mobile);' \
    >"$fixture/Recognition/front.html"
printf '%s\n' '{{FrontSide}}' >"$fixture/Recognition/back.html"
printf '%s\n' '{{edit:furigana:VocabDef}}' >"$fixture/Production/front.html"
printf '%s\n' '{{FrontSide}}' >"$fixture/Production/back.html"

cat >"$fake_bin/curl" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

output_file=""
request_data=""
request_url=""
while (($#)); do
    case "$1" in
        -o)
            output_file="$2"
            shift 2
            ;;
        -d)
            request_data="$2"
            shift 2
            ;;
        -X)
            shift 2
            ;;
        -*)
            shift
            ;;
        *)
            request_url="$1"
            shift
            ;;
    esac
done

if [ -n "$output_file" ]; then
    relative_path="${request_url#*Japanese%20sentences/}"
    cp "$UPSTREAM_FIXTURE/$relative_path" "$output_file"
    exit
fi

action="$(jq -r '.action' <<<"$request_data")"
printf '%s\n' "$action" >>"$ANKI_ACTION_LOG"
case "$action" in
    modelNames)
        if [ "$MODEL_EXISTS" = yes ]; then
            printf '%s\n' '{"result":["Japanese sentences"],"error":null}'
        else
            printf '%s\n' '{"result":[],"error":null}'
        fi
        ;;
    modelFieldNames)
        printf '%s\n' '{"result":["SentKanji","VocabDef"],"error":null}'
        ;;
    modelTemplates)
        printf '%s\n' '{"result":{"Recognition":{"Front":"old","Back":"old"},"Production":{"Front":"old","Back":"old"}},"error":null}'
        ;;
    createModel|updateModelTemplates|updateModelStyling)
        printf '%s\n' "$request_data" >"$ANKI_CAPTURE_DIR/$action.json"
        printf '%s\n' '{"result":null,"error":null}'
        ;;
    *)
        printf 'Unexpected AnkiConnect action: %s\n' "$action" >&2
        exit 1
        ;;
esac
EOF
chmod +x "$fake_bin/curl"

run_updater() {
    local model_exists="$1"
    local capture_dir="$2"
    mkdir -p "$capture_dir"
    : >"$capture_dir/actions.log"
    ANKI_ACTION_LOG="$capture_dir/actions.log" \
        ANKI_CAPTURE_DIR="$capture_dir" \
        MODEL_EXISTS="$model_exists" \
        PATH="$fake_bin:$PATH" \
        UPSTREAM_FIXTURE="$fixture" \
        "$repo/scripts/optional/japanese/update-japanese-sentences.sh" >/dev/null
}

create_capture="$test_dir/create"
run_updater no "$create_capture"
jq -e '
    .action == "createModel" and
    .params.modelName == "Japanese sentences" and
    .params.inOrderFields == ["SentKanji", "VocabDef"] and
    .params.css == "body { color: red; }\n" and
    .params.cardTemplates[0].Name == "Recognition" and
    .params.cardTemplates[0].Front == "{{edit:VocabDef}} {{edit:hint:VocabDef}}\ndetails_element.toggleAttribute(\"open\", true);\n" and
    .params.cardTemplates[1].Name == "Production" and
    .params.cardTemplates[1].Front == "{{edit:VocabDef}}\n"
' "$create_capture/createModel.json" >/dev/null

update_capture="$test_dir/update"
run_updater yes "$update_capture"
jq -e '
    .action == "updateModelTemplates" and
    .params.model.templates.Recognition.Front == "{{edit:VocabDef}} {{edit:hint:VocabDef}}\ndetails_element.toggleAttribute(\"open\", true);\n" and
    .params.model.templates.Production.Front == "{{edit:VocabDef}}\n"
' "$update_capture/updateModelTemplates.json" >/dev/null
jq -e '
    .action == "updateModelStyling" and
    .params.model.css == "body { color: red; }\n"
' "$update_capture/updateModelStyling.json" >/dev/null

printf '%s\n' '{{edit:furigana:VocabDef}}' >"$fixture/Recognition/front.html"
invalid_capture="$test_dir/invalid"
if run_updater no "$invalid_capture" 2>/dev/null; then
    echo 'Updater accepted an incompatible upstream Recognition template.' >&2
    exit 1
fi
test ! -s "$invalid_capture/actions.log"
