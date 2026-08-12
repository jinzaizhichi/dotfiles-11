#!/usr/bin/env bash

set -euo pipefail

model_name='Japanese sentences'
frequency_field='VocabFreq'
upstream_repository='https://github.com/Ajatt-Tools/AnkiNoteTypes.git'
upstream_ref='acc6d71d7fb0e9fc7f8cf286b813a128ad3d0c84'
anki_connect_url='http://127.0.0.1:8765'
download_dir="$(mktemp -d)"
trap 'rm -rf -- "$download_dir"' EXIT

usage() {
    cat <<'EOF'
Usage: update-japanese-sentences.sh [--check-upstream | --upstream-ref COMMIT]

With no arguments, install the locally reviewed, pinned upstream revision.
  --check-upstream       Compare the pin with upstream main without changing Anki.
  --upstream-ref COMMIT  Apply an explicitly selected 40-character commit once.
EOF
}

case "${1:-}" in
    '') ;;
    --check-upstream)
        [ "$#" -eq 1 ] || { usage >&2; exit 2; }
        command -v git >/dev/null || { echo 'git is required.' >&2; exit 1; }
        latest_ref="$(git ls-remote "$upstream_repository" refs/heads/main | cut -f1)"
        [ -n "$latest_ref" ] || { echo 'Unable to resolve upstream main.' >&2; exit 1; }
        printf 'Pinned:        %s\nUpstream main: %s\n' "$upstream_ref" "$latest_ref"
        if [ "$upstream_ref" = "$latest_ref" ]; then
            echo 'The pin is current.'
        else
            printf 'Update available. Review it, then test with: %s --upstream-ref %s\n' "$0" "$latest_ref"
        fi
        exit 0
        ;;
    --upstream-ref)
        [ "$#" -eq 2 ] || { usage >&2; exit 2; }
        if [[ ! "$2" =~ ^[0-9a-fA-F]{40}$ ]]; then
            echo '--upstream-ref requires a full 40-character commit SHA.' >&2
            exit 2
        fi
        upstream_ref="$2"
        ;;
    *)
        usage >&2
        exit 2
        ;;
esac

upstream_base="https://raw.githubusercontent.com/Ajatt-Tools/AnkiNoteTypes/$upstream_ref/templates/Japanese%20sentences"

for dependency in curl jq; do
    command -v "$dependency" >/dev/null || {
        echo "$dependency is required." >&2
        exit 1
    }
done

download() {
    local upstream_path="$1"
    local destination="$2"
    curl -fsSL "$upstream_base/$upstream_path" -o "$download_dir/$destination"
}

patch_once() {
    local template_file="$1"
    local old_expression="$2"
    local new_expression="$3"
    local description="$4"
    local count

    count="$(grep -oF -- "$old_expression" "$template_file" | wc -l || true)"
    if [ "$count" -ne 1 ]; then
        printf 'Upstream %s changed: expected one %s expression, found %s. Anki was not modified.\n' \
            "$description" "$old_expression" "$count" >&2
        exit 1
    fi
    sed -i "s|$old_expression|$new_expression|" "$template_file"
}

append_dictionary_labels() {
    local template_file="$1"

    cat >>"$template_file" <<'EOF'
<script>
document.querySelectorAll('li[data-dictionary] > i:first-child').forEach((label) => {
    const dictionary = label.parentElement.dataset.dictionary;
    if (!dictionary) return;

    label.classList.add('tsc__dictionary_label');
    label.textContent = dictionary
        .replace(/\s*\[[^\]]+\]\s*$/, '')
        .replace(/\.org$/i, '');
    label.title = dictionary;
    label.addEventListener('click', (event) => {
        event.preventDefault();
        event.stopPropagation();
    });
});
</script>
EOF
}

anki_request() {
    local action="$1"
    local params="$2"
    local payload response

    payload="$(jq -cn --arg action "$action" --argjson params "$params" \
        '{action: $action, version: 6, params: $params}')"
    response="$(curl -fsS "$anki_connect_url" -X POST -d "$payload")" || {
        echo 'Unable to reach AnkiConnect. Start Anki and try again.' >&2
        exit 1
    }
    if ! jq -e 'has("result") and .error == null' >/dev/null <<<"$response"; then
        printf 'AnkiConnect %s failed: %s\n' "$action" \
            "$(jq -r '.error // "invalid response"' <<<"$response")" >&2
        exit 1
    fi
    jq -c '.result' <<<"$response"
}

download 'template.json' 'template.json'
download 'template.css' 'template.css'
download 'Recognition/front.html' 'recognition-front.html'
download 'Recognition/back.html' 'recognition-back.html'
download 'Production/front.html' 'production-front.html'
download 'Production/back.html' 'production-back.html'

jq -e '
    .modelName == "Japanese sentences" and
    (.inOrderFields | type == "array" and length > 0) and
    .cardTemplates == ["Recognition", "Production"]
' "$download_dir/template.json" >/dev/null || {
    echo 'Upstream Japanese Sentences manifest changed. Anki was not modified.' >&2
    exit 1
}

patch_once "$download_dir/recognition-front.html" \
    '{{edit:furigana:VocabDef}}' '{{edit:VocabDef}}' 'Recognition template'
patch_once "$download_dir/recognition-front.html" \
    '{{edit:hint:furigana:VocabDef}}' '{{edit:hint:VocabDef}}' 'Recognition hint template'
patch_once "$download_dir/recognition-front.html" \
    'details_element.toggleAttribute("open", !is_mobile);' \
    'details_element.toggleAttribute("open", true);' \
    'mobile image visibility code'
patch_once "$download_dir/recognition-front.html" \
    'When the back side is visible, Images should be placed after (under) notes.' \
    'On the back, keep images beside the sentence so context is visible without scrolling.' \
    'back-side image placement comment'
patch_once "$download_dir/recognition-front.html" \
    'const images_anchor = document.querySelector("#tsc__backside_images");' \
    'const images_anchor = document.querySelector(".tsc__back_side .sent-center");' \
    'back-side image placement'
patch_once "$download_dir/recognition-front.html" \
    '<div class="definitions">' \
    '{{#VocabFreq}}<div class="tsc__frequencies">{{VocabFreq}}</div>{{/VocabFreq}}<div class="definitions">' \
    'Recognition frequency placement'
patch_once "$download_dir/production-front.html" \
    '{{edit:furigana:VocabDef}}' '{{edit:VocabDef}}' 'Production template'
patch_once "$download_dir/production-front.html" \
    '<div class="definitions">' \
    '{{#VocabFreq}}<div class="tsc__frequencies">{{VocabFreq}}</div>{{/VocabFreq}}<div class="definitions">' \
    'Production frequency placement'

append_dictionary_labels "$download_dir/recognition-front.html"
append_dictionary_labels "$download_dir/production-front.html"
cat >>"$download_dir/template.css" <<'EOF'

/* Compact dictionary provenance exported by Yomitan's {glossary} marker. */
li[data-dictionary] > .tsc__dictionary_label {
    display: inline-block;
    margin-inline-end: 0.45em;
    padding: 0.12em 0.55em;
    border-radius: 4px;
    background: #aa66cc;
    color: #fff;
    cursor: pointer;
    font-size: 0.72em;
    font-style: normal;
    font-weight: 600;
    line-height: 1.45;
    transition: filter 80ms ease, transform 80ms ease;
    user-select: none;
    vertical-align: 0.08em;
}

li[data-dictionary] > .tsc__dictionary_label:hover { filter: brightness(1.08); }
li[data-dictionary] > .tsc__dictionary_label:active { transform: translateY(1px); }

/* Frequency sources retained by Yomitan, shown compactly on answer sides. */
.tsc__frequencies {
    font-family: "Noto Sans", "Noto Sans CJK JP", sans-serif;
    font-size: 0.72em;
    line-height: 1.45;
    margin: 0.25em 0 0.45em;
}

.tsc__frequencies ul {
    display: flex;
    flex-wrap: wrap;
    gap: 0.3em;
    list-style: none;
    margin: 0;
    padding: 0;
}

.tsc__frequencies li {
    background: var(--color-background-tags, hsl(0deg 0% 50% / 12%));
    border-radius: 3px;
    color: var(--color-text-tags, inherit);
    font-weight: 600;
    padding: 0.12em 0.45em;
}
EOF

upstream_fields="$(jq -c '.inOrderFields' "$download_dir/template.json")"
fields="$(jq -c --arg field "$frequency_field" '
    if index($field) then . else .[0:8] + [$field] + .[8:] end
' <<<"$upstream_fields")"
frequency_field_index="$(jq -r --arg field "$frequency_field" 'index($field)' <<<"$fields")"
templates="$(jq -cn \
    --rawfile recognition_front "$download_dir/recognition-front.html" \
    --rawfile recognition_back "$download_dir/recognition-back.html" \
    --rawfile production_front "$download_dir/production-front.html" \
    --rawfile production_back "$download_dir/production-back.html" \
    '{
        Recognition: {Front: $recognition_front, Back: $recognition_back},
        Production: {Front: $production_front, Back: $production_back}
    }')"
css="$(jq -Rs . <"$download_dir/template.css")"
model_names="$(anki_request modelNames '{}')"

if jq -e --arg model_name "$model_name" 'index($model_name) != null' >/dev/null <<<"$model_names"; then
    request_params="$(jq -cn --arg modelName "$model_name" '{modelName: $modelName}')"
    installed_fields="$(anki_request modelFieldNames "$request_params")"
    if ! jq -e --argjson required "$upstream_fields" '($required - .) | length == 0' \
        >/dev/null <<<"$installed_fields"; then
        echo 'The installed Japanese sentences note type is missing upstream fields. Anki was not modified.' >&2
        exit 1
    fi

    if ! jq -e --arg field "$frequency_field" 'index($field) != null' >/dev/null <<<"$installed_fields"; then
        add_field="$(jq -cn --arg modelName "$model_name" --arg fieldName "$frequency_field" \
            '{modelName: $modelName, fieldName: $fieldName}')"
        anki_request modelFieldAdd "$add_field" >/dev/null
        reposition_field="$(jq -cn \
            --arg modelName "$model_name" \
            --arg fieldName "$frequency_field" \
            --argjson index "$frequency_field_index" \
            '{modelName: $modelName, fieldName: $fieldName, index: $index}')"
        anki_request modelFieldReposition "$reposition_field" >/dev/null
    fi

    installed_templates="$(anki_request modelTemplates "$request_params")"
    if ! jq -e 'has("Recognition") and has("Production")' >/dev/null <<<"$installed_templates"; then
        echo 'The installed Japanese sentences note type is missing Recognition or Production. Anki was not modified.' >&2
        exit 1
    fi

    update_templates="$(jq -cn --arg name "$model_name" --argjson templates "$templates" \
        '{model: {name: $name, templates: $templates}}')"
    anki_request updateModelTemplates "$update_templates" >/dev/null

    update_styling="$(jq -cn --arg name "$model_name" --argjson css "$css" \
        '{model: {name: $name, css: $css}}')"
    anki_request updateModelStyling "$update_styling" >/dev/null
    echo 'Japanese sentences note type updated.'
else
    create_model="$(jq -cn \
        --arg modelName "$model_name" \
        --argjson inOrderFields "$fields" \
        --argjson templates "$templates" \
        --argjson css "$css" \
        '{
            modelName: $modelName,
            inOrderFields: $inOrderFields,
            cardTemplates: [
                {Name: "Recognition", Front: $templates.Recognition.Front, Back: $templates.Recognition.Back},
                {Name: "Production", Front: $templates.Production.Front, Back: $templates.Production.Back}
            ],
            css: $css
        }')"
    anki_request createModel "$create_model" >/dev/null
    echo 'Japanese sentences note type created.'
fi

echo 'Restart Anki once so AJT Japanese can refresh its injected CSS and JavaScript.'
