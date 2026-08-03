#!/usr/bin/env bash

set -euo pipefail

model_name='Japanese sentences'
upstream_base='https://raw.githubusercontent.com/Ajatt-Tools/AnkiNoteTypes/main/templates/Japanese%20sentences'
anki_connect_url='http://127.0.0.1:8765'
download_dir="$(mktemp -d)"
trap 'rm -rf -- "$download_dir"' EXIT

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
patch_once "$download_dir/production-front.html" \
    '{{edit:furigana:VocabDef}}' '{{edit:VocabDef}}' 'Production template'

fields="$(jq -c '.inOrderFields' "$download_dir/template.json")"
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
    if ! jq -e --argjson required "$fields" '($required - .) | length == 0' \
        >/dev/null <<<"$installed_fields"; then
        echo 'The installed Japanese sentences note type is missing upstream fields. Anki was not modified.' >&2
        exit 1
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
