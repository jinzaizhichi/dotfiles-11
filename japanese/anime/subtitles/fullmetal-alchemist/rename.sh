#!/bin/sh
set -u

root=${1:-.}
failed=0

rename_file() {
    source=$root/$1
    target=$root/$2
    if [ -e "$source" ]; then
        if [ -e "$target" ]; then
            printf 'Refusing to overwrite: %s\n' "$target" >&2
            failed=1
        else
            mv "$source" "$target"
            printf '%s -> %s\n' "$1" "$2"
        fi
    elif [ ! -e "$target" ]; then
        printf 'Missing source and target: %s\n' "$1" >&2
        failed=1
    fi
}

rename_file 'S01E28 - One Is All, All Is One.mkv' 'Fullmetal_Alchemist 28 - One Is All, All Is One.mkv'
rename_file 'S01E02 - Body of the Sanctioned.mkv' 'Fullmetal_Alchemist 02 - Body of the Sanctioned.mkv'
rename_file 'S01E03 - Mother....mkv' 'Fullmetal_Alchemist 03 - Mother.mkv'
rename_file 'S01E04 - Transmutation of Love.mkv' 'Fullmetal_Alchemist 04 - Transmutation of Love.mkv'
rename_file 'S01E05 - Dash! Automail.mkv' 'Fullmetal_Alchemist 05 - Dash! Automail.mkv'
rename_file 'S01E06 - The State Alchemist Certification Examination.mkv' 'Fullmetal_Alchemist 06 - The State Alchemist Certification Examination.mkv'
rename_file 'S01E07 - Night of the Chimera'\''s Cry.mkv' 'Fullmetal_Alchemist 07 - Night of the Chimera'\''s Cry.mkv'
rename_file 'S01E08 - The Philosopher'\''s Stone.mkv' 'Fullmetal_Alchemist 08 - The Philosopher'\''s Stone.mkv'
rename_file 'S01E09 - The Dog of the Military'\''s Silver Watch.mkv' 'Fullmetal_Alchemist 09 - The Dog of the Military'\''s Silver Watch.mkv'
rename_file 'S01E10 - The Phantom Thief Psiren.mkv' 'Fullmetal_Alchemist 10 - The Phantom Thief Psiren.mkv'
rename_file 'S01E11 - Earth of Gravel, Part 1.mkv' 'Fullmetal_Alchemist 11 - Earth of Gravel, Part 1.mkv'
rename_file 'S01E12 - Earth of Gravel, Part 2.mkv' 'Fullmetal_Alchemist 12 - Earth of Gravel, Part 2.mkv'
rename_file 'S01E13 - Flame vs. Fullmetal.mkv' 'Fullmetal_Alchemist 13 - Flame vs Fullmetal.mkv'
rename_file 'S01E14 - The Right Hand of Destruction.mkv' 'Fullmetal_Alchemist 14 - The Right Hand of Destruction.mkv'
rename_file 'S01E15 - The Ishbal Massacre.mkv' 'Fullmetal_Alchemist 15 - The Ishbal Massacre.mkv'
rename_file 'S01E16 - That Which Is Lost.mkv' 'Fullmetal_Alchemist 16 - That Which Is Lost.mkv'
rename_file 'S01E17 - House of the Waiting Family.mkv' 'Fullmetal_Alchemist 17 - House of the Waiting Family.mkv'
rename_file 'S01E18 - Marcoh`s Notes.mkv' 'Fullmetal_Alchemist 18 - Marcoh`s Notes.mkv'
rename_file 'S01E19 - Behind What Is Behind the Truths.mkv' 'Fullmetal_Alchemist 19 - Behind What Is Behind the Truths.mkv'
rename_file 'S01E20 - Soul of the Guardian.mkv' 'Fullmetal_Alchemist 20 - Soul of the Guardian.mkv'
rename_file 'S01E21 - Red Glow.mkv' 'Fullmetal_Alchemist 21 - Red Glow.mkv'
rename_file 'S01E22 - Created People.mkv' 'Fullmetal_Alchemist 22 - Created People.mkv'
rename_file 'S01E23 - Fullmetal Heart.mkv' 'Fullmetal_Alchemist 23 - Fullmetal Heart.mkv'
rename_file 'S01E24 - Bonding of Memories.mkv' 'Fullmetal_Alchemist 24 - Bonding of Memories.mkv'
rename_file 'S01E25 - Farewell Ceremonies.mkv' 'Fullmetal_Alchemist 25 - Farewell Ceremonies.mkv'
rename_file 'S01E26 - Her Reasons.mkv' 'Fullmetal_Alchemist 26 - Her Reasons.mkv'
rename_file 'S01E27 - Sensei.mkv' 'Fullmetal_Alchemist 27 - Sensei.mkv'
rename_file 'S01E01 - He Who Would Challenge the Sun.mkv' 'Fullmetal_Alchemist 01 - He Who Would Challenge the Sun.mkv'
rename_file 'S01E29 - The Undefiled Child.mkv' 'Fullmetal_Alchemist 29 - The Undefiled Child.mkv'
rename_file 'S01E30 - Attack on the Southern Command Center.mkv' 'Fullmetal_Alchemist 30 - Attack on the Southern Command Center.mkv'
rename_file 'S01E31 - Sin.mkv' 'Fullmetal_Alchemist 31 - Sin.mkv'
rename_file 'S01E32 - Dante of the Deep Forest.mkv' 'Fullmetal_Alchemist 32 - Dante of the Deep Forest.mkv'
rename_file 'S01E33 - Al Taken Prisoner.mkv' 'Fullmetal_Alchemist 33 - Al Taken Prisoner.mkv'
rename_file 'S01E34 - The Theory of Avarice.mkv' 'Fullmetal_Alchemist 34 - The Theory of Avarice.mkv'
rename_file 'S01E35 - Reunion of Fools.mkv' 'Fullmetal_Alchemist 35 - Reunion of Fools.mkv'
rename_file 'S01E36 - The Sinner Within.mkv' 'Fullmetal_Alchemist 36 - The Sinner Within.mkv'
rename_file 'S01E37 - The Flame Alchemist, the Fighting Lieutenant, and the Mystery of Warehouse 13.mkv' 'Fullmetal_Alchemist 37 - The Flame Alchemist, the Fighting Lieutenant, and the Mystery of Warehouse 13.mkv'
rename_file 'S01E38 - With the River`s Flow.mkv' 'Fullmetal_Alchemist 38 - With the River`s Flow.mkv'
rename_file 'S01E39 - Civil War in the East.mkv' 'Fullmetal_Alchemist 39 - Civil War in the East.mkv'
rename_file 'S01E40 - Scars.mkv' 'Fullmetal_Alchemist 40 - Scars.mkv'
rename_file 'S01E41 - Holy Mother.mkv' 'Fullmetal_Alchemist 41 - Holy Mother.mkv'
rename_file 'S01E42 - His Name Is Unknown.mkv' 'Fullmetal_Alchemist 42 - His Name Is Unknown.mkv'
rename_file 'S01E43 - The Stray Dog Han Run Away.mkv' 'Fullmetal_Alchemist 43 - The Stray Dog Han Run Away.mkv'
rename_file 'S01E44 - Hohenheim of Light.mkv' 'Fullmetal_Alchemist 44 - Hohenheim of Light.mkv'
rename_file 'S01E45 - That Which Degrades the Heart.mkv' 'Fullmetal_Alchemist 45 - That Which Degrades the Heart.mkv'
rename_file 'S01E46 - Human Transmutation.mkv' 'Fullmetal_Alchemist 46 - Human Transmutation.mkv'
rename_file 'S01E47 - Sealing the Homunculus.mkv' 'Fullmetal_Alchemist 47 - Sealing the Homunculus.mkv'
rename_file 'S01E48 - Goodbye.mkv' 'Fullmetal_Alchemist 48 - Goodbye.mkv'
rename_file 'S01E49 - To the Other Side of the Gate.mkv' 'Fullmetal_Alchemist 49 - To the Other Side of the Gate.mkv'
rename_file 'S01E50 - Death.mkv' 'Fullmetal_Alchemist 50 - Death.mkv'
rename_file 'S01E51 - Laws and Promises.mkv' 'Fullmetal_Alchemist 51 - Laws and Promises.mkv'

exit "$failed"
