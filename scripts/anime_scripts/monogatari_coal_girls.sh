#!/bin/bash

declare -a folders=(
  '01. Bakemonogatari'
  '02. Kizumonogatari'
  '03. Nisemonogatari'
  '04. Nekomonogatari (Kuro)'
  '05. Nekomonogatari (Shiro)'
  '06. Kabukimonogatari'
  '07. Hanamonogatari'
  '08. Otorimonogatari'
  '09. Onimonogatari'
  '10. Koimonogatari'
  '11. Tsukimonogatari'
  '12. Koyomimonogatari'
  '13. Owarimonogatari'
  '14. Owarimonogatari 2nd Season'
  '15. Zoku Owarimonogatari'
)


declare -a folders_to_process=()
declare -a folders_to_ignore=()

for folder in "${folders[@]}"; do
    files=("$folder"/*)    

    ffprobe -i "${files[0]}" > "${files[0]}.txt" 2>&1

    if cat "${files[0]}.txt" | grep -iq 'coalgirls' ; then
      folders_to_process[${#folders_to_process[@]}]="$folder"
    else
      folders_to_ignore[${#folders_to_ignore[@]}]="$folder"
    fi

done


for folder_to_process in "${folders_to_process[@]}"; do
    for file in "$folder_to_process"/*.mkv; do

      tmp="temporary.mkv"
      ffmpeg -i "$file" -c copy -map 0:v -map 0:a -map 0:s -map -0:s:0 -map -0:s:1 -map -0:s:2 "$tmp"
      rm "$file"
      mv "$tmp" "$file"

    done

done

for folder_to_ignore in "${folders_to_ignore[@]}"; do
  echo 'BEWARE of MBTT SUBTITLES!!!' > "$folder_to_ignore/WARNING.txt" && chmod u+x "$folder_to_ignore/WARNING.txt"
done
