#!/usr/bin/env bash
# =============================================================================
#  HACKERS (1995) THEMED LOGIN PRANK
#  "Mess with the best, die like the rest."
#
#  Compatible: Ubuntu (18.04+), Debian 9, Debian 12, Kali (all versions)
#  Requirements: bash >= 4.3 (ships with all targets), coreutils
#  Dependencies: NONE -- tput used only when available, pure ANSI fallbacks
#  Harmful actions: NONE -- no files read, written, or modified
#
#  USAGE:
#    Add to student .bashrc:
#      source /path/to/hackers_prank.sh
#    Or:
#      bash /path/to/hackers_prank.sh
#
#  The script auto-detects non-interactive shells and exits silently,
#  so it will NOT break scp, sftp, rsync, cron, or piped commands.
# =============================================================================

# -- Guard: skip when sourced into non-interactive shells (scp, sftp, rsync) --
# When executed directly (bash script.sh), always proceed.
# When sourced, only proceed if the parent shell is interactive.
_hp_is_sourced=0
if (return 0 2>/dev/null); then
    _hp_is_sourced=1
fi
if [ "${_hp_is_sourced}" -eq 1 ]; then
    case "$-" in
        *i*) ;;
        *)   return 2>/dev/null ;;
    esac
fi
# Regardless of how invoked, require a real terminal on stdin/stdout
if [ ! -t 1 ] || [ ! -t 0 ]; then
    if [ "${_hp_is_sourced}" -eq 1 ]; then
        return 2>/dev/null
    else
        exit 0
    fi
fi

# -- Ensure we are actually running under bash >=4 --
if [ -z "${BASH_VERSION}" ]; then
    return 2>/dev/null || exit 0
fi
BASH_MAJOR="${BASH_VERSINFO[0]:-0}"
if [ "${BASH_MAJOR}" -lt 4 ]; then
    return 2>/dev/null || exit 0
fi

# -- Duration Configuration --
TOTAL_DURATION=35
_HP_START="${SECONDS}"

# -- Portable terminal capability wrappers --
# Works whether tput/ncurses-bin is installed or not
_hp_has_tput=0
if command -v tput >/dev/null 2>&1; then
    _hp_has_tput=1
fi

_hp_cols() {
    if [ "${_hp_has_tput}" -eq 1 ]; then
        tput cols 2>/dev/null || echo 80
    elif [ -n "${COLUMNS}" ]; then
        echo "${COLUMNS}"
    else
        local _c
        _c=$(stty size 2>/dev/null | cut -d' ' -f2)
        echo "${_c:-80}"
    fi
}

_hp_rows() {
    if [ "${_hp_has_tput}" -eq 1 ]; then
        tput lines 2>/dev/null || echo 24
    elif [ -n "${LINES}" ]; then
        echo "${LINES}"
    else
        local _r
        _r=$(stty size 2>/dev/null | cut -d' ' -f1)
        echo "${_r:-24}"
    fi
}

_hp_hide_cursor() {
    if [ "${_hp_has_tput}" -eq 1 ]; then
        tput civis 2>/dev/null
    else
        printf '\033[?25l'
    fi
}

_hp_show_cursor() {
    if [ "${_hp_has_tput}" -eq 1 ]; then
        tput cnorm 2>/dev/null
    else
        printf '\033[?25h'
    fi
}

_hp_reset_attrs() {
    if [ "${_hp_has_tput}" -eq 1 ]; then
        tput sgr0 2>/dev/null
    fi
    printf '\033[0m'
}

# -- Disable all escape routes --
trap '' INT TERM QUIT TSTP HUP ABRT USR1 USR2 PIPE
# DEBUG trap -- may not work on very old bash; ignore errors
trap '' DEBUG 2>/dev/null || true

# -- Restore on clean exit --
_hp_cleanup() {
    trap - INT TERM QUIT TSTP HUP ABRT USR1 USR2 PIPE
    trap - DEBUG 2>/dev/null || true
    _hp_show_cursor
    _hp_reset_attrs
    printf '\033[?5l'       # ensure reverse video is off
    clear
    echo ""
    echo "  Session initialized. Welcome back, $(whoami)."
    echo ""
}
trap _hp_cleanup EXIT

# -- Hide cursor, clear screen --
_hp_hide_cursor
clear

# -- ANSI color definitions (pure escape codes -- no tput dependency) --
_R='\033[1;31m'      # bold red
_G='\033[1;32m'      # bold green
_Y='\033[1;33m'      # bold yellow
_C='\033[1;36m'      # bold cyan
_M='\033[1;35m'      # bold magenta
_W='\033[1;37m'      # bold white
_DG='\033[0;32m'     # dim green
_DR='\033[0;31m'     # dim red
_DM='\033[0;35m'     # dim magenta
_BG_R='\033[41m'     # bg red
_BG_B='\033[40m'     # bg black
_BLINK='\033[5m'
_REVERSE='\033[7m'
_BOLD='\033[1m'
_DIM='\033[2m'
_N='\033[0m'         # reset

# -- Helper: time remaining --
_hp_time_left() {
    local _elapsed=$(( SECONDS - _HP_START ))
    echo $(( TOTAL_DURATION - _elapsed ))
}

# -- Helper: center text on terminal --
_hp_center() {
    local _text="$1"
    local _c
    _c=$(_hp_cols)
    # Strip ANSI escapes to measure visible length
    local _clean
    _clean=$(printf '%b' "$_text" | sed 's/\x1b\[[0-9;]*m//g' 2>/dev/null || echo "$_text")
    local _len=${#_clean}
    local _pad=$(( (_c - _len) / 2 ))
    [ "${_pad}" -lt 0 ] && _pad=0
    printf "%${_pad}s" ""
    printf '%b\n' "$_text"
}

# -- Helper: print at row,col (ANSI -- no tput needed) --
_hp_pos() {
    printf '\033[%d;%dH' "$1" "$2"
}

# -- Helper: random int in range [min, max] --
_hp_rng() {
    echo $(( RANDOM % ($2 - $1 + 1) + $1 ))
}

# -- Helper: portable fractional sleep --
_hp_msleep() {
    sleep "$1" 2>/dev/null || sleep 1
}

# -- Helper: portable timestamp --
_hp_timestamp() {
    local _ts
    _ts=$(date '+%H:%M:%S.%N' 2>/dev/null)
    if [ -n "${_ts}" ]; then
        echo "${_ts:0:12}"
    else
        date '+%H:%M:%S' 2>/dev/null || echo "00:00:00"
    fi
}

# =====================================================================
#  PHASE 1: INITIAL "BREACH" SPLASH  (0 - ~6s)
# =====================================================================
_hp_phase_breach() {
    clear
    echo ""
    _hp_center "${_DR}+----------------------------------------------------------+${_N}"
    _hp_center "${_DR}|${_R}${_BLINK}  ##     UNAUTHORIZED NEURAL LINK DETECTED     ##  ${_N}${_DR}|${_N}"
    _hp_center "${_DR}+----------------------------------------------------------+${_N}"
    echo ""

    local _log_lines=(
        "Tracing route to $(whoami)@$(hostname)..."
        "SYN flood on ports 1-65535 .......... ${_R}CAPTURED${_N}"
        "Cracking RSA-4096 handshake ......... ${_Y}IN PROGRESS${_N}"
        "Decrypting /etc/shadow .............. ${_G}BYPASSED${_N}"
        "Injecting polymorphic shellcode ..... ${_G}LOADED${_N}"
        "Enumerating kernel modules .......... ${_M}47 found${_N}"
        "Pivoting through ${_C}$(hostname)${_N} gateway"
        "Extracting SSH private keys ......... ${_R}FOUND${_N}"
        "Mapping internal subnet ............. ${_G}10.0.0.0/8${_N}"
        "Deploying rootkit to MBR ............ ${_Y}STANDBY${_N}"
        "Intercepting keystrokes ............. ${_G}ACTIVE${_N}"
        "Exfiltrating /home/$(whoami)/* ...... ${_R}0%%${_N}"
    )

    local _line
    for _line in "${_log_lines[@]}"; do
        [ "$(_hp_time_left)" -le 29 ] && return
        printf "  ${_DG}[$(_hp_timestamp)]${_N} %b\\n" "$_line"
        _hp_msleep 0.18
    done
    _hp_msleep 0.5
}

# =====================================================================
#  PHASE 2: THE SKULL  (6 - ~16s)
# =====================================================================
_hp_phase_skull() {
    clear
    echo ""

    # Pure 7-bit ASCII skull -- no Unicode, safe on every locale
    local _skull=(
"${_R}                      ##################                      "
"${_R}                  ####${_DR}................${_R}####                  "
"${_R}              ####${_DR}......................${_R}####              "
"${_R}            ##${_DR}............................${_R}##            "
"${_R}          ##${_DR}................................${_R}##          "
"${_R}        ##${_DR}....................................${_R}##        "
"${_R}       ##${_DR}......................................${_R}##       "
"${_R}      ##${_DR}......${_R}########${_DR}..........${_R}########${_DR}......${_R}##      "
"${_R}     ##${_DR}....${_R}####${_W}@@@@@@@@${_R}##${_DR}......${_R}##${_W}@@@@@@@@${_R}####${_DR}....${_R}##     "
"${_R}     ##${_DR}....${_R}##${_W}@@${_R}####${_W}@@@@${_R}##${_DR}......${_R}##${_W}@@@@${_R}####${_W}@@${_R}##${_DR}....${_R}##     "
"${_R}    ##${_DR}.....${_R}##${_W}@@@@@@@@@@@@${_R}##${_DR}..${_R}##${_W}@@@@@@@@@@@@${_R}##${_DR}.....${_R}##    "
"${_R}    ##${_DR}......${_R}##${_W}@@@@@@@@${_R}##${_DR}......${_R}##${_W}@@@@@@@@${_R}##${_DR}......${_R}##    "
"${_R}    ##${_DR}........${_R}########${_DR}..........${_R}########${_DR}........${_R}##    "
"${_R}    ##${_DR}..................${_DM}####${_DR}..................${_R}##    "
"${_R}     ##${_DR}................${_DM}##${_DR}..${_DM}##${_DR}................${_R}##     "
"${_R}     ##${_DR}......................................${_R}##     "
"${_R}      ##${_DR}...${_R}##${_DR}........................${_R}##${_DR}...${_R}##      "
"${_R}       ##${_DR}...${_R}##${_DR}......................${_R}##${_DR}...${_R}##       "
"${_R}        ##${_DR}...${_R}####${_DR}................${_R}####${_DR}...${_R}##        "
"${_R}         ##${_DR}....${_R}####################${_DR}.....${_R}##         "
"${_R}          ###${_DR}.........................${_R}###          "
"${_R}            ####${_DR}....................${_R}####            "
"${_R}               ########################               "
    )

    local _line
    for _line in "${_skull[@]}"; do
        _hp_center "$_line"
    done

    echo ""
    _hp_center "${_R}${_BOLD}====================================================${_N}"
    _hp_center "${_BG_R}${_W}${_BOLD}    SYSTEM COMPROMISED  ///  ALL FILES ENCRYPTED    ${_N}"
    _hp_center "${_R}${_BOLD}====================================================${_N}"
    _hp_msleep 2.5

    # Flash effect -- reverse video (ANSI standard DEC private mode)
    local _i
    for _i in 1 2 3; do
        [ "$(_hp_time_left)" -le 19 ] && return
        printf '\033[?5h'
        _hp_msleep 0.08
        printf '\033[?5l'
        _hp_msleep 0.12
    done
    _hp_msleep 1
}

# =====================================================================
#  PHASE 3: MATRIX RAIN + CRYPTIC MESSAGES  (16 - ~28s)
# =====================================================================
_hp_phase_matrix() {
    clear
    local _rows _cols
    _rows=$(_hp_rows)
    _cols=$(_hp_cols)

    local _cryptic_messages=(
        "HACK THE PLANET"
        "Type cookie -- God will give you a cookie"
        "The Gibson has been hacked"
        "Mess with the best, die like the rest"
        "There is no right and wrong. Only fun and boring."
        "Pool on the roof must have a leak"
        "RISC architecture is gonna change everything"
        "Never fear, I is here"
        "We got a wake-up call from the Nintendo Generation"
        "Permission denied -- just kidding... or am I?"
        "$(whoami): your mass storage has been reorganized"
        "YO -- I AM INVINCIBLE"
        "Accessing $(whoami) webcam ......... STREAMING"
        "I hope you dont use the same password everywhere"
        "Shall we play a game?"
        "The Plague sends his regards"
    )

    # Matrix rain chars -- pure 7-bit ASCII, zero locale issues
    local _chars='0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz!@#$%^&*(){}[]|/<>~:;=+-_'

    local _msg_index=0
    local _frame=0
    local _chars_len=${#_chars}

    while [ "$(_hp_time_left)" -gt 7 ]; do
        # Paint columns of "rain"
        local _cc
        for (( _cc=0; _cc < _cols / 2; _cc++ )); do
            local _rx=$(_hp_rng 1 "$_rows")
            local _cx=$(_hp_rng 1 "$_cols")
            local _ci=$(_hp_rng 0 $(( _chars_len - 1 )))
            local _ch="${_chars:${_ci}:1}"

            _hp_pos "$_rx" "$_cx"
            case $(( RANDOM % 4 )) in
                0) printf "${_G}%s${_N}" "$_ch" ;;
                1) printf "${_DG}%s${_N}" "$_ch" ;;
                2) printf "${_W}%s${_N}" "$_ch" ;;
                3) printf "${_C}%s${_N}" "$_ch" ;;
            esac
        done

        # Every ~8 frames, flash a cryptic Hackers quote
        if [ $(( _frame % 8 )) -eq 0 ]; then
            local _msg="${_cryptic_messages[$_msg_index]}"
            _msg_index=$(( (_msg_index + 1) % ${#_cryptic_messages[@]} ))
            local _mrow=$(( _rows / 2 ))

            local _clean_msg
            _clean_msg=$(printf '%b' "$_msg" | sed 's/\x1b\[[0-9;]*m//g' 2>/dev/null || echo "$_msg")
            local _mcol=$(( (_cols - ${#_clean_msg} - 8) / 2 ))
            [ "${_mcol}" -lt 1 ] && _mcol=1

            # Black bar behind message for readability
            _hp_pos "$_mrow" 1
            printf "${_BG_B}"
            printf "%${_cols}s" ""
            _hp_pos "$_mrow" "$_mcol"

            case $(( _msg_index % 4 )) in
                0) printf "${_R}${_BOLD}${_BLINK}>>> %s <<<${_N}" "$_msg" ;;
                1) printf "${_C}${_BOLD}[ %s ]${_N}" "$_msg" ;;
                2) printf "${_Y}${_BOLD}${_REVERSE} %s ${_N}" "$_msg" ;;
                3) printf "${_M}${_BOLD}// %s //${_N}" "$_msg" ;;
            esac
        fi

        _frame=$(( _frame + 1 ))
        _hp_msleep 0.06
    done
}

# =====================================================================
#  PHASE 4: "TRACE COMPLETE" COUNTDOWN  (28 - ~33s)
# =====================================================================
_hp_phase_trace() {
    clear
    local _rows _cols
    _rows=$(_hp_rows)
    _cols=$(_hp_cols)
    local _mid=$(( _rows / 2 ))
    local _fake_ip="$(_hp_rng 10 192).$(_hp_rng 0 255).$(_hp_rng 0 255).$(_hp_rng 1 254)"

    _hp_pos $(( _mid - 6 )) 1

    _hp_center "${_R}${_BOLD}+====================================================+${_N}"
    _hp_center "${_R}${_BOLD}|                                                    |${_N}"
    _hp_center "${_R}${_BOLD}|${_W}      ##  BACKTRACE COMPLETE  ##                    ${_R}|${_N}"
    _hp_center "${_R}${_BOLD}|                                                    |${_N}"
    _hp_center "${_R}${_BOLD}|${_Y}  Target : ${_C}$(whoami)@$(hostname)                         ${_R}${_BOLD}|${_N}"
    _hp_center "${_R}${_BOLD}|${_Y}  Origin : ${_C}${_fake_ip}                            ${_R}${_BOLD}|${_N}"
    _hp_center "${_R}${_BOLD}|${_Y}  Status : ${_G}LOCKED ON                              ${_R}${_BOLD}|${_N}"
    _hp_center "${_R}${_BOLD}|                                                    |${_N}"
    _hp_center "${_R}${_BOLD}+====================================================+${_N}"
    echo ""

    local _i
    for _i in 5 4 3 2 1; do
        [ "$(_hp_time_left)" -le 2 ] && break
        _hp_center "${_R}${_BOLD}${_BLINK}  UPLOADING EVIDENCE TO INSTRUCTOR IN... ${_W}${_i}${_N}"
        _hp_msleep 1
        printf '\033[1A\033[2K'
    done

    _hp_msleep 0.3

    local _f
    for _f in 1 2 3 4; do
        printf '\033[?5h'; _hp_msleep 0.05
        printf '\033[?5l'; _hp_msleep 0.05
    done
}

# =====================================================================
#  PHASE 5: REVEAL  (33 - 35s)
# =====================================================================
_hp_phase_reveal() {
    clear
    local _rows
    _rows=$(_hp_rows)
    local _mid=$(( _rows / 2 ))

    local _small_skull=(
"${_DG}            ################"
"${_DG}        ####${_N}............${_DG}####"
"${_DG}      ##${_N}....${_DG}####${_N}..${_DG}####${_N}....${_DG}##"
"${_DG}      ##${_N}....${_DG}####${_N}..${_DG}####${_N}....${_DG}##"
"${_DG}      ##${_N}........${_DG}##${_N}........${_DG}##"
"${_DG}       ##${_N}.${_DG}##${_N}..........${_DG}##${_N}.${_DG}##"
"${_DG}        ##${_N}.${_DG}##########${_N}.${_DG}##"
"${_DG}          ##############"
    )

    _hp_pos $(( _mid - 6 )) 1

    local _line
    for _line in "${_small_skull[@]}"; do
        _hp_center "$_line"
    done

    echo ""
    _hp_center "${_G}${_BOLD}============================================${_N}"
    _hp_center "${_W}${_BOLD}  Relax -- nothing happened. Welcome to class.  ${_N}"
    _hp_center "${_DG}  \"Hack the planet.\" -- Dade Murphy, 1995       ${_N}"
    _hp_center "${_G}${_BOLD}============================================${_N}"
    _hp_msleep 2
}

# =====================================================================
#  MAIN EXECUTION
# =====================================================================
_hp_phase_breach
_hp_phase_skull
_hp_phase_matrix
_hp_phase_trace
_hp_phase_reveal

# cleanup runs via EXIT trap
exit 0
