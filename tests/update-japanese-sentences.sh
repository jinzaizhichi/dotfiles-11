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
    '/* When the back side is visible, Images should be placed after (under) notes. */' \
    'const images_anchor = document.querySelector("#tsc__backside_images");' \
    'details_element.toggleAttribute("open", !is_mobile);' \
    '<div class="definitions">definitions</div>' \
    >"$fixture/Recognition/front.html"
printf '%s\n' '{{FrontSide}}' >"$fixture/Recognition/back.html"
printf '%s\n' \
    '{{edit:furigana:VocabDef}}' \
    '<div class="definitions">definitions</div>' \
    >"$fixture/Production/front.html"
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
    printf '%s\n' "$request_url" >>"$UPSTREAM_URL_LOG"
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
        if [ "$MODEL_HAS_FREQ" = yes ]; then
            printf '%s\n' '{"result":["SentKanji","VocabFreq","VocabDef"],"error":null}'
        else
            printf '%s\n' '{"result":["SentKanji","VocabDef"],"error":null}'
        fi
        ;;
    modelTemplates)
        printf '%s\n' '{"result":{"Recognition":{"Front":"old","Back":"old"},"Production":{"Front":"old","Back":"old"}},"error":null}'
        ;;
    createModel|updateModelTemplates|updateModelStyling|modelFieldAdd|modelFieldReposition)
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

cat >"$fake_bin/git" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

if [ "$1" = ls-remote ] && [ "$3" = refs/heads/main ]; then
    printf '%s\t%s\n' '1111111111111111111111111111111111111111' 'refs/heads/main'
    exit
fi
exit 1
EOF
chmod +x "$fake_bin/git"

run_updater() {
    local model_exists="$1"
    local capture_dir="$2"
    shift 2
    mkdir -p "$capture_dir"
    : >"$capture_dir/actions.log"
    : >"$capture_dir/upstream-urls.log"
    ANKI_ACTION_LOG="$capture_dir/actions.log" \
        ANKI_CAPTURE_DIR="$capture_dir" \
        MODEL_EXISTS="$model_exists" \
        MODEL_HAS_FREQ="${MODEL_HAS_FREQ_OVERRIDE:-no}" \
        PATH="$fake_bin:$PATH" \
        UPSTREAM_FIXTURE="$fixture" \
        UPSTREAM_URL_LOG="$capture_dir/upstream-urls.log" \
        "$repo/scripts/optional/japanese/update-japanese-sentences.sh" "$@" >/dev/null
}

create_capture="$test_dir/create"
run_updater no "$create_capture"
test "$(wc -l <"$create_capture/upstream-urls.log")" -eq 6
grep -q '/acc6d71d7fb0e9fc7f8cf286b813a128ad3d0c84/templates/' \
    "$create_capture/upstream-urls.log"
jq -e '
    .action == "createModel" and
    .params.modelName == "Japanese sentences" and
    .params.inOrderFields == ["SentKanji", "VocabDef", "VocabFreq"] and
    (.params.css | startswith("body { color: red; }\n")) and
    (.params.css | contains("li[data-dictionary] > .tsc__dictionary_label")) and
    (.params.css | contains("background: #aa66cc")) and
    (.params.css | contains("border-radius: 4px")) and
    (.params.css | contains(".tsc__frequencies")) and
    (.params.css | contains("cursor: pointer")) and
    .params.cardTemplates[0].Name == "Recognition" and
    (.params.cardTemplates[0].Front | startswith("{{edit:VocabDef}} {{edit:hint:VocabDef}}\n/* On the back, keep images beside the sentence so context is visible without scrolling. */\nconst images_anchor = document.querySelector(\".tsc__back_side .sent-center\");\ndetails_element.toggleAttribute(\"open\", true);\n")) and
    (.params.cardTemplates[0].Front | contains("label.classList.add(\u0027tsc__dictionary_label\u0027)")) and
    (.params.cardTemplates[0].Front | contains(".replace(/\\.org$/i, \u0027\u0027)")) and
    (.params.cardTemplates[0].Front | contains("event.stopPropagation()")) and
    (.params.cardTemplates[0].Front | contains("{{#VocabFreq}}<div class=\"tsc__frequencies\">{{VocabFreq}}</div>{{/VocabFreq}}")) and
    .params.cardTemplates[1].Name == "Production" and
    (.params.cardTemplates[1].Front | startswith("{{edit:VocabDef}}\n")) and
    (.params.cardTemplates[1].Front | contains("label.title = dictionary"))
' "$create_capture/createModel.json" >/dev/null

update_capture="$test_dir/update"
run_updater yes "$update_capture"
jq -e '
    .action == "modelFieldAdd" and
    .params == {modelName: "Japanese sentences", fieldName: "VocabFreq"}
' "$update_capture/modelFieldAdd.json" >/dev/null
jq -e '
    .action == "modelFieldReposition" and
    .params == {modelName: "Japanese sentences", fieldName: "VocabFreq", index: 2}
' "$update_capture/modelFieldReposition.json" >/dev/null
jq -e '
    .action == "updateModelTemplates" and
    (.params.model.templates.Recognition.Front | contains("tsc__dictionary_label")) and
    (.params.model.templates.Production.Front | contains("tsc__dictionary_label"))
' "$update_capture/updateModelTemplates.json" >/dev/null
jq -e '
    .action == "updateModelStyling" and
    (.params.model.css | startswith("body { color: red; }\n")) and
    (.params.model.css | contains("background: #aa66cc")) and
    (.params.model.css | contains("transform: translateY(1px)"))
' "$update_capture/updateModelStyling.json" >/dev/null

idempotent_capture="$test_dir/idempotent"
MODEL_HAS_FREQ_OVERRIDE=yes run_updater yes "$idempotent_capture"
test ! -e "$idempotent_capture/modelFieldAdd.json"
test ! -e "$idempotent_capture/modelFieldReposition.json"

override_capture="$test_dir/override"
run_updater yes "$override_capture" --upstream-ref 2222222222222222222222222222222222222222
test "$(wc -l <"$override_capture/upstream-urls.log")" -eq 6
grep -q '/2222222222222222222222222222222222222222/templates/' \
    "$override_capture/upstream-urls.log"

check_output="$(PATH="$fake_bin:$PATH" \
    "$repo/scripts/optional/japanese/update-japanese-sentences.sh" --check-upstream)"
grep -q 'Pinned:        acc6d71d7fb0e9fc7f8cf286b813a128ad3d0c84' <<<"$check_output"
grep -q 'Upstream main: 1111111111111111111111111111111111111111' <<<"$check_output"
grep -q -- '--upstream-ref 1111111111111111111111111111111111111111' <<<"$check_output"

printf '%s\n' '{{edit:furigana:VocabDef}}' >"$fixture/Recognition/front.html"
invalid_capture="$test_dir/invalid"
if run_updater no "$invalid_capture" 2>/dev/null; then
    echo 'Updater accepted an incompatible upstream Recognition template.' >&2
    exit 1
fi
test ! -s "$invalid_capture/actions.log"
