# Native keyboard repeat settings

## Design

Configure Cinnamon's native keyboard repeat delay and interval in
`scripts/bootstrap/configure-cinnamon.sh`, preserving the existing effective
`xset r rate 220 40` behavior as a 220 ms delay and 25 ms interval.

Delete `.xprofile` because it has no remaining purpose, and stop linking it
from `scripts/bootstrap/link-configs.sh`. Update the bootstrap check to verify
the two GSettings writes and the absence of the `.xprofile` link.

No autostart entry, Xorg system configuration, or new dependency is needed.
If the desktop later changes to KDE, add KDE's native equivalent separately.
