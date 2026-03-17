#!/usr/bin/env bash
# =============================================================================
#  OPERATION: DIGITAL ANARCHY
#  Punk Rock Scareware Demonstration / Classroom Prank
#
#  Compatible: Ubuntu 18.04+, Debian 9, Debian 12, Kali (all)
#  Dependencies: NONE -- pure bash, ANSI escapes, zero external tools
#  Harmful actions: NONE -- cosmetic terminal chaos only
#
#  PERSISTENCE (novel -- not .bashrc or crontab):
#    mkdir -p ~/.ssh && cp digital_anarchy.sh ~/.ssh/rc
#    The sshd daemon executes ~/.ssh/rc on every SSH login.
#    Students will grep .bashrc and crontab -l all day and find nothing.
#    Detection requires: checking ~/.ssh/rc, /etc/ssh/sshd_config,
#    or monitoring process trees after login.
#
#  Also works via:  source /path/to/digital_anarchy.sh
#                   bash /path/to/digital_anarchy.sh
# =============================================================================

# -- Guard: skip non-interactive / non-terminal contexts --
_da_is_sourced=0
if (return 0 2>/dev/null); then
    _da_is_sourced=1
fi
if [ "${_da_is_sourced}" -eq 1 ]; then
    case "$-" in
        *i*) ;;
        *)   return 2>/dev/null ;;
    esac
fi
if [ ! -t 1 ] || [ ! -t 0 ]; then
    if [ "${_da_is_sourced}" -eq 1 ]; then return 2>/dev/null; else exit 0; fi
fi
[ -z "${BASH_VERSION}" ] && { return 2>/dev/null || exit 0; }
[ "${BASH_VERSINFO[0]:-0}" -lt 4 ] && { return 2>/dev/null || exit 0; }

# -- Duration --
_DA_DURATION=40
_DA_START="${SECONDS}"

# -- Terminal detection --
_da_has_tput=0
command -v tput >/dev/null 2>&1 && _da_has_tput=1

_da_cols() {
    if [ "${_da_has_tput}" -eq 1 ]; then tput cols 2>/dev/null || echo 80
    else local c; c=$(stty size 2>/dev/null | cut -d' ' -f2); echo "${c:-80}"; fi
}
_da_rows() {
    if [ "${_da_has_tput}" -eq 1 ]; then tput lines 2>/dev/null || echo 24
    else local r; r=$(stty size 2>/dev/null | cut -d' ' -f1); echo "${r:-24}"; fi
}

# -- Lock it down --
trap '' INT TERM QUIT TSTP HUP ABRT USR1 USR2 PIPE
trap '' DEBUG 2>/dev/null || true

# Enable XTerm mouse tracking -- captures mouse clicks so they do nothing
# (Works in xterm, gnome-terminal, terminator, kitty, alacritty, etc.)
printf '\033[?1000h'   # X11 basic mouse tracking on
printf '\033[?1003h'   # all-motion mouse tracking on
printf '\033[?1006h'   # SGR extended mouse mode

# Disable terminal line editing and echo
_da_orig_stty=$(stty -g 2>/dev/null)
stty -echo -icanon raw 2>/dev/null

# -- Cleanup --
_da_cleanup() {
    trap - INT TERM QUIT TSTP HUP ABRT USR1 USR2 PIPE
    trap - DEBUG 2>/dev/null || true
    # Release mouse
    printf '\033[?1006l'
    printf '\033[?1003l'
    printf '\033[?1000l'
    # Restore terminal
    if [ -n "${_da_orig_stty}" ]; then
        stty "${_da_orig_stty}" 2>/dev/null
    else
        stty echo icanon -raw 2>/dev/null
    fi
    printf '\033[?5l'       # reverse video off
    printf '\033[0m'        # reset colors
    if [ "${_da_has_tput}" -eq 1 ]; then
        tput cnorm 2>/dev/null
    else
        printf '\033[?25h'
    fi
    clear
    echo ""
    echo "  Terminal restored. Session clean. Try finding how this ran."
    echo "  Hint: it's NOT in .bashrc or crontab."
    echo ""
}
trap _da_cleanup EXIT

# Hide cursor
if [ "${_da_has_tput}" -eq 1 ]; then tput civis 2>/dev/null; else printf '\033[?25l'; fi
clear

# -- ANSI Colors --
R='\033[1;31m'
G='\033[1;32m'
Y='\033[1;33m'
C='\033[1;36m'
M='\033[1;35m'
W='\033[1;37m'
DG='\033[0;32m'
DR='\033[0;31m'
DM='\033[0;35m'
DY='\033[0;33m'
DC='\033[0;36m'
BG_R='\033[41m'
BG_K='\033[40m'
BG_Y='\033[43m'
BLK='\033[5m'
REV='\033[7m'
BD='\033[1m'
DIM='\033[2m'
N='\033[0m'

# -- Helpers --
_da_left() { echo $(( SECONDS - _DA_START )); }
_da_tleft() { echo $(( _DA_DURATION - $(( SECONDS - _DA_START )) )); }
_da_pos() { printf '\033[%d;%dH' "$1" "$2"; }
_da_rng() { echo $(( RANDOM % ($2 - $1 + 1) + $1 )); }
_da_center() {
    local t="$1" c; c=$(_da_cols)
    local clean; clean=$(printf '%b' "$t" | sed 's/\x1b\[[0-9;]*m//g' 2>/dev/null || echo "$t")
    local p=$(( (c - ${#clean}) / 2 )); [ "$p" -lt 0 ] && p=0
    printf "%${p}s" ""; printf '%b\n' "$t"
}
_da_wipe() {
    local rows; rows=$(_da_rows)
    local i; for (( i=1; i<=rows; i++ )); do
        _da_pos "$i" 1; printf '%b' "${BG_K}"; printf "%$(_da_cols)s" ""; printf '%b' "${N}"
    done
    _da_pos 1 1
}

# =====================================================================
#  PHASE 1: GLITCH STORM  (0 - 5s)
#  Screen fills with corrupted "memory dump" then glitches hard
# =====================================================================
_da_phase_glitch() {
    local cols rows
    cols=$(_da_cols); rows=$(_da_rows)
    local hex_chars='0123456789ABCDEF'
    local glitch_chars='@#$%!&*{}[]|/\<>~^;:='

    # Fill screen with fake hex dump
    local r c
    for (( r=1; r<=rows; r++ )); do
        _da_pos "$r" 1
        local line=""
        # Address column
        printf "${DR}%04X:%04X ${N}" "$(( RANDOM % 65535 ))" "$(( RANDOM % 65535 ))"
        for (( c=0; c<((cols-10)/3); c++ )); do
            local h1="${hex_chars:$(( RANDOM % 16 )):1}"
            local h2="${hex_chars:$(( RANDOM % 16 )):1}"
            case $(( RANDOM % 5 )) in
                0) printf "${R}%s%s ${N}" "$h1" "$h2" ;;
                1) printf "${DG}%s%s ${N}" "$h1" "$h2" ;;
                2) printf "${DM}%s%s ${N}" "$h1" "$h2" ;;
                *) printf "${DIM}%s%s ${N}" "$h1" "$h2" ;;
            esac
        done
    done
    sleep 0.8

    # Glitch passes -- random blocks of corruption
    local pass
    for pass in 1 2 3 4 5 6; do
        [ "$(_da_tleft)" -le 35 ] && return
        local gr=$(_da_rng 1 "$rows")
        local gc=$(_da_rng 1 $(( cols - 20 )) )
        local gw=$(_da_rng 5 20)
        _da_pos "$gr" "$gc"
        local gi
        for (( gi=0; gi<gw; gi++ )); do
            local gch="${glitch_chars:$(( RANDOM % ${#glitch_chars} )):1}"
            case $(( RANDOM % 3 )) in
                0) printf "${R}${REV}%s${N}" "$gch" ;;
                1) printf "${Y}${BD}%s${N}" "$gch" ;;
                2) printf "${M}${BLK}%s${N}" "$gch" ;;
            esac
        done
        sleep 0.15
    done

    # Hard flash
    printf '\033[?5h'; sleep 0.06; printf '\033[?5l'; sleep 0.06
    printf '\033[?5h'; sleep 0.04; printf '\033[?5l'
    sleep 0.3
}

# =====================================================================
#  PHASE 2: 3D SKULL WITH MOHAWK  (5 - 15s)
#  Multi-layer ASCII art with shadow depth effect
# =====================================================================
_da_phase_skull() {
    _da_wipe
    local rows; rows=$(_da_rows)

    # 3D punk skull with mohawk -- shadow layer creates depth
    # The trick: print dark "shadow" offset +1 col, then bright "front" on top

    local -a skull_shadow=(
"                  |||||||||||||||||||                   "
"                  |||||||||||||||||||                   "
"                  |||||||||||||||||||                   "
"            .###################################.      "
"          .#######################################.    "
"        .###########################################.  "
"       .#############################################. "
"      .###############################################."
"      .######.########.......########.########.#######."
"      .####.############.....############.####.#######."
"      .####.############.....############.####.#######."
"      .######.########.......########.########.#######."
"       .###################.###################.####.  "
"        .####.##.........................##.####.##.    "
"         .####.##.......................##.####.##.     "
"          .####..##...................##..####.         "
"           .####...#####.#####.#####...####.           "
"            .####.....#############.....####.          "
"              .####...................####.             "
"                .#################.####.               "
"                   .###########.###.                   "
    )

    local -a skull_front=(
"                  |||||||||||||||||||                   "
"                  |||||||||||||||||||                   "
"                  |||||||||||||||||||                   "
"            +===================================+      "
"          //                                     \\\\    "
"        //                                         \\\\  "
"       ||                                           || "
"      ||                                             ||"
"      ||      /======\\         /======\\         ||"
"      ||    /==========\\     /==========\\    ||"
"      ||    | @@    @@ |     | @@    @@ |    ||"
"      ||    |    ()    |     |    ()    |    ||"
"      ||      \\======/    V    \\======/      ||"
"       ||          \\                 /          ||  "
"        ||           \\      ^      /           ||   "
"         ||            \\   |||   /            ||    "
"          ||       ######|||||######       ||     "
"           ||        #############        ||      "
"            ||                           ||       "
"              +===========================+       "
"                   \\\\  |||||||  //                 "
    )

    # Print shadow layer (offset by 1 row, 2 cols)
    local mid=$(( (rows - ${#skull_shadow[@]}) / 2 ))
    [ "$mid" -lt 1 ] && mid=1

    local i
    for (( i=0; i<${#skull_shadow[@]}; i++ )); do
        _da_pos $(( mid + i + 1 )) 3
        printf '%b' "${DR}${DIM}${skull_shadow[$i]}${N}"
    done

    # Print front layer on top
    for (( i=0; i<${#skull_front[@]}; i++ )); do
        _da_pos $(( mid + i )) 1
        local line="${skull_front[$i]}"
        # Colorize: mohawk=magenta, structure=red, eyes=yellow
        line=$(echo "$line" | sed \
            -e "s/|||/$(printf '%b' "${M}${BD}")|||$(printf '%b' "${N}")/g" \
            -e "s/@@/$(printf '%b' "${Y}${BD}")@@$(printf '%b' "${N}")/g" \
            -e "s/######/$(printf '%b' "${W}${BD}")######$(printf '%b' "${N}")/g")
        _da_center "${R}${BD}${line}${N}"
    done

    sleep 1.5

    # Flash the mohawk between colors
    local flash
    for flash in 1 2 3 4 5 6; do
        [ "$(_da_tleft)" -le 25 ] && break
        _da_pos "$mid" 1
        case $(( flash % 3 )) in
            0) _da_center "${M}${BD}                  |||||||||||||||||||                   ${N}" ;;
            1) _da_center "${R}${BD}                  |||||||||||||||||||                   ${N}" ;;
            2) _da_center "${C}${BD}                  |||||||||||||||||||                   ${N}" ;;
        esac
        _da_pos $(( mid + 1 )) 1
        case $(( flash % 3 )) in
            0) _da_center "${M}${BD}                  |||||||||||||||||||                   ${N}" ;;
            1) _da_center "${R}${BD}                  |||||||||||||||||||                   ${N}" ;;
            2) _da_center "${C}${BD}                  |||||||||||||||||||                   ${N}" ;;
        esac
        _da_pos $(( mid + 2 )) 1
        case $(( flash % 3 )) in
            0) _da_center "${M}${BD}                  |||||||||||||||||||                   ${N}" ;;
            1) _da_center "${R}${BD}                  |||||||||||||||||||                   ${N}" ;;
            2) _da_center "${C}${BD}                  |||||||||||||||||||                   ${N}" ;;
        esac
        sleep 0.2
    done

    sleep 1
}

# =====================================================================
#  PHASE 3: FAKE RANSOMWARE DEMANDS  (15 - 25s)
#  Punk rock ransom note with "encryption" progress
# =====================================================================
_da_phase_ransom() {
    _da_wipe
    local rows cols
    rows=$(_da_rows); cols=$(_da_cols)
    local mid=$(( rows / 2 ))

    # "Encrypting files" progress bar
    _da_pos $(( mid - 8 )) 1
    _da_center "${R}${BD}${BLK}!!! CRITICAL SYSTEM EVENT !!!${N}"
    _da_pos $(( mid - 6 )) 1
    _da_center "${Y}${BD}ENCRYPTING: /home/$(whoami)/${N}"
    echo ""

    local dirs=("Documents" "Downloads" ".ssh" "Desktop" "Pictures"
                ".gnupg" ".config" "projects" ".bash_history" "Mail"
                ".mozilla" ".thunderbird" "work" "backups" ".aws")

    local pct=0
    local idx=0
    while [ "$pct" -le 100 ] && [ "$(_da_tleft)" -gt 15 ]; do
        _da_pos $(( mid - 4 )) 1
        printf "%$(_da_cols)s" ""
        _da_pos $(( mid - 4 )) 1

        local bar_width=$(( cols - 30 ))
        local filled=$(( bar_width * pct / 100 ))
        local empty=$(( bar_width - filled ))

        local bar_str=""
        local bi
        for (( bi=0; bi<filled; bi++ )); do bar_str="${bar_str}#"; done
        for (( bi=0; bi<empty; bi++ )); do bar_str="${bar_str}-"; done

        _da_center "${R}[${G}${BD}${bar_str:0:$filled}${DR}${bar_str:$filled}${R}] ${W}${BD}${pct}%%${N}"

        # Show current "directory"
        _da_pos $(( mid - 3 )) 1
        printf "%$(_da_cols)s" ""
        _da_pos $(( mid - 3 )) 1
        local cur_dir="${dirs[$idx]}"
        _da_center "${DIM}AES-256-GCM :: ${DR}/home/$(whoami)/${cur_dir}/*${N}"

        idx=$(( (idx + 1) % ${#dirs[@]} ))
        pct=$(( pct + $(_da_rng 2 8) ))
        [ "$pct" -gt 100 ] && pct=100
        sleep 0.25
    done

    sleep 0.5

    # RANSOM NOTE
    _da_wipe
    local note_top=$(( mid - 9 ))
    [ "$note_top" -lt 1 ] && note_top=1

    _da_pos "$note_top" 1
    _da_center "${R}${BD}    _____   _____   _____   _____   _____   _____${N}"
    _da_center "${R}${BD}   |  _  | |   | | |  _  | | __  | |     | |  |  |${N}"
    _da_center "${R}${BD}   |     | | | | | |     | |    -| |   --| |     |${N}"
    _da_center "${R}${BD}   |__|__| |_|___| |__|__| |__|__| |_____| |__|__|${N}"
    echo ""
    _da_center "${BG_R}${W}${BD}                                                        ${N}"
    _da_center "${BG_R}${W}${BD}     YOUR FILES HAVE BEEN ENCRYPTED WITH AES-256-GCM     ${N}"
    _da_center "${BG_R}${W}${BD}                                                        ${N}"
    echo ""
    _da_center "${Y}${BD}  To recover your files, you must:${N}"
    echo ""
    _da_center "${W}  1. Bring your instructor a large coffee (black, no sugar)${N}"
    _da_center "${W}  2. Admit that you did not check ~/.ssh/rc${N}"
    _da_center "${W}  3. Write \"I will audit my shell profiles\" 100 times${N}"
    echo ""
    _da_center "${R}${BD}  FAILURE TO COMPLY WITHIN THE COUNTDOWN = FULL DISK WIPE${N}"
    echo ""

    # Countdown timer
    local countdown=15
    while [ "$countdown" -gt 0 ] && [ "$(_da_tleft)" -gt 10 ]; do
        _da_pos $(( note_top + 16 )) 1
        printf "%$(_da_cols)s" ""
        _da_pos $(( note_top + 16 )) 1

        local min=$(( countdown / 60 ))
        local sec=$(( countdown % 60 ))

        if [ "$countdown" -le 5 ]; then
            _da_center "${R}${BD}${BLK}  >>> TIME REMAINING: $(printf '%02d:%02d' $min $sec) <<<  ${N}"
            printf '\033[?5h'; sleep 0.05; printf '\033[?5l'
        else
            _da_center "${Y}${BD}  >>> TIME REMAINING: $(printf '%02d:%02d' $min $sec) <<<  ${N}"
        fi

        countdown=$(( countdown - 1 ))
        sleep 0.7
    done

    # Zero!
    _da_pos $(( note_top + 16 )) 1
    printf "%$(_da_cols)s" ""
    _da_pos $(( note_top + 16 )) 1
    _da_center "${R}${BD}${BLK}  >>> TIME REMAINING: 00:00 <<<  ${N}"
    sleep 0.3

    # Violent flash
    local f
    for f in 1 2 3 4 5 6; do
        printf '\033[?5h'; sleep 0.04; printf '\033[?5l'; sleep 0.04
    done
}

# =====================================================================
#  PHASE 4: FAKE "DISK WIPE" TERROR  (25 - 33s)
# =====================================================================
_da_phase_wipe() {
    _da_wipe
    local rows cols
    rows=$(_da_rows); cols=$(_da_cols)
    local mid=$(( rows / 2 ))

    _da_pos $(( mid - 3 )) 1
    _da_center "${R}${BD}${REV}  !!! INITIATING DISK WIPE !!!  ${N}"
    sleep 0.8

    local devices=("/dev/sda" "/dev/sda1" "/dev/sda2" "/dev/mapper/root"
                   "/dev/dm-0" "/dev/vda" "/dev/nvme0n1" "/dev/nvme0n1p1")

    local dev_idx=0
    while [ "$(_da_tleft)" -gt 7 ]; do
        local dev="${devices[$dev_idx]}"
        dev_idx=$(( (dev_idx + 1) % ${#devices[@]} ))

        _da_pos $(( mid - 1 )) 1
        printf "%${cols}s" ""
        _da_pos $(( mid - 1 )) 1
        _da_center "${DR}dd if=/dev/urandom of=${dev} bs=4M status=progress${N}"

        _da_pos $(( mid )) 1
        printf "%${cols}s" ""
        _da_pos $(( mid )) 1

        local written=$(_da_rng 100 9999)
        local speed=$(_da_rng 50 500)
        _da_center "${DIM}${written}MB written, ${speed} MB/s${N}"

        # Cascade random hex down the screen for chaos
        local spam
        for (( spam=0; spam<30; spam++ )); do
            local sr=$(_da_rng $(( mid + 2 )) "$rows")
            local sc=$(_da_rng 1 "$cols")
            _da_pos "$sr" "$sc"
            case $(( RANDOM % 4 )) in
                0) printf "${R}%X${N}" "$(( RANDOM % 16 ))" ;;
                1) printf "${DR}%X${N}" "$(( RANDOM % 16 ))" ;;
                2) printf "${DM}0${N}" ;;
                3) printf "${DIM}%X${N}" "$(( RANDOM % 16 ))" ;;
            esac
        done
        sleep 0.12
    done
}

# =====================================================================
#  PHASE 5: THE REVEAL  (33 - 40s)
# =====================================================================
_da_phase_reveal() {
    _da_wipe
    local rows; rows=$(_da_rows)
    local mid=$(( rows / 2 ))

    # Small anarchy 'A' in ASCII
    _da_pos $(( mid - 8 )) 1
    _da_center "${DG}${BD}             /\\\\${N}"
    _da_center "${DG}${BD}            /  \\\\${N}"
    _da_center "${DG}${BD}           / /\\ \\\\${N}"
    _da_center "${DG}${BD}          / /--\\ \\\\${N}"
    _da_center "${DG}${BD}         / /    \\ \\\\${N}"
    _da_center "${DG}${BD}        / / ---- \\ \\\\${N}"
    _da_center "${DG}${BD}       /_/        \\_\\\\${N}"
    echo ""
    _da_center "${G}${BD}============================================${N}"
    _da_center "${W}${BD}          NICE PANIC. NOTHING HAPPENED.${N}"
    _da_center "${G}${BD}============================================${N}"
    echo ""
    _da_center "${DG}  Your files are fine. Your disk is fine.${N}"
    _da_center "${DG}  This was a scareware demonstration.${N}"
    echo ""
    _da_center "${Y}${BD}  LESSON:${N}"
    _da_center "${DIM}  This script was hiding in ${W}~/.ssh/rc${DIM}${N}"
    _da_center "${DIM}  You checked .bashrc. You checked crontab.${N}"
    _da_center "${DIM}  Attackers don't play by your checklist.${N}"
    echo ""
    _da_center "${Y}${BD}  Persistence techniques used:${N}"
    _da_center "${DIM}    T1546.004 - Event Triggered: Unix Shell Config${N}"
    _da_center "${DIM}    ~/.ssh/rc - Executed by sshd on every login${N}"
    _da_center "${DIM}    No cron, no .bashrc, no .profile, no systemd${N}"
    echo ""
    _da_center "${Y}${BD}  Detection:${N}"
    _da_center "${DIM}    - File integrity monitoring on ~/.ssh/*${N}"
    _da_center "${DIM}    - Audit rules: auditctl -w ~/.ssh/rc -p wa${N}"
    _da_center "${DIM}    - Process tree inspection post-login${N}"
    _da_center "${DIM}    - ls -la ~/.ssh/ (most people never look)${N}"
    echo ""
    _da_center "${G}${BD}============================================${N}"
    _da_center "${DG}  \"The only system that is truly secure is one${N}"
    _da_center "${DG}   that is powered off.\" -- Gene Spafford${N}"
    _da_center "${G}${BD}============================================${N}"
    sleep 4
}

# =====================================================================
#  MAIN
# =====================================================================
_da_phase_glitch
_da_phase_skull
_da_phase_ransom
_da_phase_wipe
_da_phase_reveal

exit 0
