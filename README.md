# Operation: Digital Anarchy

### Cybersecurity Awareness Toolkit for Classroom Instruction

A collection of harmless, visually dramatic terminal scripts designed for cybersecurity instructors to demonstrate social engineering, scareware, credential harvesting, and persistence techniques in controlled lab environments. Every script is **completely non-destructive** — no files are modified, no data is exfiltrated, no system changes persist beyond the terminal session.

Built for use in **authorized training environments** alongside MITRE ATT&CK curriculum.

---

## Table of Contents

- [Overview](#overview)
- [Compatibility](#compatibility)
- [Toolkit Contents](#toolkit-contents)
  - [hackers_prank.sh — The Hackers (1995) Experience](#hackers_pranksh--the-hackers-1995-experience)
  - [keylogger_demo.sh — Credential Harvester Demonstration](#keylogger_demosh--credential-harvester-demonstration)
  - [digital_anarchy.sh — Punk Rock Scareware](#digital_anarchysh--punk-rock-scareware)
- [Deployment & Persistence Methods](#deployment--persistence-methods)
  - [Quick Start](#quick-start)
  - [Novel Persistence Options](#novel-persistence-options)
- [Instructor Setup](#instructor-setup)
- [MITRE ATT&CK Mapping](#mitre-attck-mapping)
- [Technical Details](#technical-details)
- [Removal & Cleanup](#removal--cleanup)
- [Troubleshooting](#troubleshooting)
- [Disclaimer](#disclaimer)
- [License](#license)

---

## Overview

These scripts serve a dual purpose in cybersecurity training:

1. **Immediate visceral impact** — Students experience firsthand what scareware, credential harvesting, and ransomware look like from the victim's perspective. The panic is real. The lesson sticks.

2. **Persistence technique education** — Each script is deployed using real-world persistence mechanisms (T1546.004, T1547.001) that students must then locate and remove as a detection exercise. The hiding spots are deliberately chosen to be places students won't think to check.

Every script includes a **full reveal phase** that explains exactly what happened, which MITRE ATT&CK techniques were demonstrated, and how to detect them in the wild.

### Design Principles

- **Zero dependencies** — Pure bash, ANSI escape codes, and coreutils. No Python, no ncurses, no external packages.
- **Zero harm** — No files are read, written, modified, or deleted. No data leaves the terminal (except a static notification string in `keylogger_demo.sh`). No system configuration is changed.
- **Zero persistence** — Scripts do not install themselves or create any artifacts. Deployment is manual and fully controlled by the instructor.
- **Signal trapping** — Students cannot Ctrl+C, Ctrl+Z, Ctrl+\, or `kill` their way out. They must watch and learn.
- **Clean exit** — Terminal state (cursor, colors, echo, stty, mouse tracking) is fully restored via EXIT traps regardless of how the script terminates.

---

## Compatibility

All scripts are tested and validated on:

| Distribution | Version | Bash Version | Status |
|---|---|---|---|
| Ubuntu | 18.04 LTS+ | 4.4+ | Fully supported |
| Debian | 9 (Stretch) | 4.4 | Fully supported |
| Debian | 12 (Bookworm) | 5.2 | Fully supported |
| Kali Linux | All versions | 5.x | Fully supported |

### Portability guarantees

- **Pure 7-bit ASCII** — No Unicode characters anywhere. Works on `LANG=C`, broken locales, and minimal installs without UTF-8 support.
- **No tput dependency** — All terminal manipulation uses raw ANSI escape sequences with `tput` as an optional enhancement when `ncurses-bin` is installed.
- **No Unicode box-drawing** — All borders and frames use `#`, `=`, `+`, `-`, `|` characters.
- **Bash 4.3+ only features** — No namerefs (`declare -n`), no `${var@Q}` expansion, no other 4.4+ constructs.
- **POSIX signal names** — Uses `INT`, `TERM`, `TSTP` instead of `SIGINT`, `SIGTERM`, `SIGTSTP`.
- **Unix LF line endings** — Files are validated to contain no carriage returns. If `\r` characters are introduced during transfer, run `sed -i 's/\r$//' <script>.sh` or `dos2unix <script>.sh` before executing.

---

## Toolkit Contents

---

### `hackers_prank.sh` — The Hackers (1995) Experience

A love letter to the 1995 film *Hackers*, this script puts students through 35 seconds of cinematic terminal chaos.

**Phases:**

| Phase | Duration | Description |
|---|---|---|
| Breach | 0–6s | Rapid-fire fake intrusion log with timestamps — SYN floods, RSA cracking, SSH key extraction, rootkit deployment. Personalized with the student's real username and hostname. |
| Skull | 6–16s | Large multi-shaded ASCII skull fills the terminal. "SYSTEM COMPROMISED // ALL FILES ENCRYPTED" banner with reverse-video screen flashes. |
| Matrix Rain | 16–28s | Screen fills with cascading characters while iconic *Hackers* quotes rotate through the center — "HACK THE PLANET," "Mess with the best, die like the rest," "The Gibson has been hacked." |
| Backtrace | 28–33s | "BACKTRACE COMPLETE" box showing the student's username, hostname, and a randomly generated fake IP. Countdown: "UPLOADING EVIDENCE TO INSTRUCTOR IN... 5... 4... 3..." |
| Reveal | 33–35s | Small green skull. "Relax — nothing happened. Welcome to class." |

**Signal Trapping:** `INT`, `TERM`, `QUIT`, `TSTP`, `HUP`, `ABRT`, `USR1`, `USR2`, `PIPE`, `DEBUG`

**MITRE ATT&CK Relevance:** Demonstrates the visual language of scareware (T1491.001) and social engineering pressure tactics.

---

### `keylogger_demo.sh` — Credential Harvester Demonstration

Simulates a credential harvesting attack by faking an SSH session disconnect and re-authentication prompt. The student types their "password" into an attacker-controlled prompt — but the input is **immediately discarded** and never stored, logged, or transmitted.

Only a static `[KEYLOGGER DEMO] password captured` notification (containing zero credential data) is sent to the instructor's listener.

**Stages:**

| Stage | Description |
|---|---|
| Fake Disconnect | Realistic SSH broken-pipe messages (`packet_write_wait`, `client_loop: send disconnect`). Random 1–3 second delay before triggering so it doesn't look scripted. |
| Fake Re-auth | SSH login prompt with randomly generated ED25519 fingerprint. Student's real `user@host` format. `stty -echo` suppresses input display exactly like a real password prompt. |
| Input Capture | Password is read into a variable, **immediately overwritten** with the string `"DISCARDED"`, and unset. The actual password never exists in memory for more than one instruction cycle. |
| Notification | Static string `[KEYLOGGER DEMO] password captured -- user=<user>@<host> -- <timestamp>` sent to instructor at `10.50.160.2:6666`. Uses bash `/dev/tcp` with fallback to `nc`/`ncat`/`netcat`. Retries 3x with 1s gaps. All output suppressed — zero error messages leak to the student terminal. |
| Sell It | Shows "Permission denied, please try again." with a second fake prompt. Maximum panic. |
| Reveal | Full debrief: what happened, which ATT&CK techniques were used, how to detect it. |

**Instructor Listener Setup:**

```bash
# Single student
nc -lnvp 6666

# Multiple students (basic nc exits after each connection)
while true; do nc -lnvp 6666; done

# Or using ncat (Kali) — stays open for multiple connections
ncat -lnvkp 6666
```

**Configuration:** Edit these variables at the top of the script to match your lab environment:

```bash
_KD_INSTRUCTOR_IP="10.50.160.2"
_KD_INSTRUCTOR_PORT="6666"
```

**MITRE ATT&CK Techniques Demonstrated:**
- T1056.001 — Input Capture: Keylogging
- T1056.002 — Input Capture: GUI Input Capture
- T1078 — Valid Accounts (credential theft vector)
- T1557 — Adversary-in-the-Middle

---

### `digital_anarchy.sh` — Punk Rock Scareware

The flagship script. 40 seconds of maximum intimidation with 3D ASCII art, fake ransomware encryption, fake disk wipes, XTerm mouse capture, and a full terminal lockdown.

**Phases:**

| Phase | Duration | Description |
|---|---|---|
| Glitch Storm | 0–5s | Screen floods with fake hex memory dump. Corruption blocks tear across random positions. Reverse-video flashes. |
| 3D Punk Skull | 5–15s | Large ASCII skull with a mohawk, rendered with a dark shadow layer offset by +1 row and +2 columns for pseudo-3D depth. Mohawk spikes flash between magenta, red, and cyan. Yellow glowing eyes. |
| Ransomware | 15–25s | Fake "ENCRYPTING /home/<user>/" with live progress bar cycling through real directory names (Documents, .ssh, .gnupg, .aws, backups). 3D block-letter "ANARCHY" header. Ransom demands include "Bring your instructor a large coffee" and "Admit that you did not check ~/.ssh/rc." 15-second countdown with increasingly frantic flashing hits 00:00. |
| Disk Wipe | 25–33s | Fake `dd if=/dev/urandom of=/dev/sda` output with simulated write speeds. Hex digit cascade fills the screen. |
| Reveal | 33–40s | ASCII anarchy symbol. "NICE PANIC. NOTHING HAPPENED." Auto-detects which persistence method was used and tailors the lesson. Shows ATT&CK techniques and detection commands. |

**Terminal Lockdown Features:**
- XTerm mouse tracking (`\033[?1000h`, `\033[?1003h`, `\033[?1006h`) — mouse clicks are captured and discarded
- `stty -echo -icanon raw` — keyboard echo disabled, canonical mode off
- Full signal trapping — `INT`, `TERM`, `QUIT`, `TSTP`, `HUP`, `ABRT`, `USR1`, `USR2`, `PIPE`, `DEBUG`
- Cursor hidden via `\033[?25l`
- All state restored cleanly via EXIT trap

**Auto-Detection Reveal:** The reveal phase checks `~/.ssh/rc`, `PROMPT_COMMAND`, `~/.bash_login`, `/etc/profile.d/`, and `~/.config/autostart/` to determine how the script was launched, then tells the student exactly where it was hiding.

---

## Deployment & Persistence Methods

### Quick Start

```bash
# Clone the repo
git clone https://github.com/<your-username>/digital-anarchy.git
cd digital-anarchy

# Test any script directly
bash hackers_prank.sh
bash keylogger_demo.sh
bash digital_anarchy.sh
```

### Novel Persistence Options

All methods below are real-world persistence techniques (MITRE ATT&CK T1546.004 / T1547.001). Each is deliberately chosen because students will not think to check these locations.

#### Option 1: `~/.ssh/rc` (Recommended for SSH labs)

**How it works:** The `sshd` daemon executes `~/.ssh/rc` on every SSH login, before the login shell starts. Because `sshd` runs this file with `/bin/sh` (not bash), a two-file setup is required.

**Sneakiness:** Almost no one knows this file exists. Students will exhaustively search `.bashrc`, `.profile`, `crontab`, and `systemd` without finding anything.

```bash
# Place the real script somewhere innocuous
cp digital_anarchy.sh /opt/.sys_health_check.sh

# Create the sh-compatible launcher
mkdir -p ~/.ssh
echo 'bash /opt/.sys_health_check.sh' > ~/.ssh/rc
```

**Prerequisite:** `PermitUserRC yes` in `/etc/ssh/sshd_config` (this is the default on all target distros).

**Detection:**
```bash
cat ~/.ssh/rc
ls -la ~/.ssh/
auditctl -w /home/*/.ssh/rc -p wa -k ssh_rc_monitor
```

---

#### Option 2: `PROMPT_COMMAND` injection (Recommended for maximum stealth)

**How it works:** Bash executes the contents of `$PROMPT_COMMAND` before displaying every prompt. The `unset PROMPT_COMMAND` at the end makes it fire only once.

**Sneakiness:** This *is* technically in `.bashrc`, but students will `grep` for `source`, `bash`, or the script filename. `PROMPT_COMMAND` is an environment variable assignment — it doesn't look like execution.

```bash
echo 'PROMPT_COMMAND="bash /opt/.sys_health_check.sh;unset PROMPT_COMMAND"' >> ~/.bashrc
```

**Detection:**
```bash
grep PROMPT_COMMAND ~/.bashrc
echo "$PROMPT_COMMAND"
```

---

#### Option 3: `~/.bash_login`

**How it works:** Login shells read these files in order, stopping at the **first one found**: `~/.bash_profile` → `~/.bash_login` → `~/.profile`. Most students only know about `.bashrc` and `.profile`.

**Sneakiness:** If `~/.bash_profile` does NOT exist on the student's workstation, `~/.bash_login` will be the first file read — and students won't think to check it.

```bash
echo 'bash /opt/.sys_health_check.sh' > ~/.bash_login
```

**Detection:**
```bash
ls -la ~/.bash_login
cat ~/.bash_login
```

---

#### Option 4: `/etc/profile.d/` drop (Requires root)

**How it works:** Every `.sh` file in `/etc/profile.d/` is sourced by `/etc/profile` on login for ALL users.

**Sneakiness:** Dot-prefix hides the file from a basic `ls`. The filename looks like a system utility.

```bash
cp digital_anarchy.sh /etc/profile.d/.gpu-firmware-check.sh
```

**Detection:**
```bash
ls -la /etc/profile.d/          # Note the -a flag
find /etc/profile.d/ -name '.*' # Find hidden files
```

---

#### Option 5: XDG Autostart (For graphical/VNC sessions)

**How it works:** Desktop environments execute `.desktop` files in `~/.config/autostart/` at graphical login.

```bash
mkdir -p ~/.config/autostart
cat > ~/.config/autostart/gpu-check.desktop << 'EOF'
[Desktop Entry]
Type=Application
Name=GPU Firmware Check
Exec=bash /opt/.sys_health_check.sh
Hidden=false
EOF
```

**Detection:**
```bash
ls -la ~/.config/autostart/
grep -r Exec ~/.config/autostart/
```

---

#### Persistence Comparison Matrix

| Method | Requires Root | Fires On | Students Check Here | Stealth Rating |
|---|---|---|---|---|
| `~/.ssh/rc` | No | Every SSH login | Almost never | Excellent |
| `PROMPT_COMMAND` | No | First prompt draw | Rarely (looks like a variable) | Excellent |
| `~/.bash_login` | No | Login shell start | Almost never | Very Good |
| `/etc/profile.d/` | Yes | All user logins | Rarely (looks like system file) | Very Good |
| XDG autostart | No | Graphical login | Sometimes | Good |

---

## Instructor Setup

### Pre-Deployment Checklist

1. **Test each script** on a machine matching your lab environment before deploying to student workstations
2. **Verify SSH config** if using `~/.ssh/rc`: `grep PermitUserRC /etc/ssh/sshd_config` should show `yes` (default)
3. **Start your listener** if using `keylogger_demo.sh`:
   ```bash
   # On your instructor workstation (10.50.160.2)
   while true; do nc -lnvp 6666; done
   ```
4. **Plan your reveal timing** — these scripts work best at the start of a class on social engineering or persistence

### Batch Deployment Example

```bash
#!/bin/bash
# deploy_prank.sh — Run as root on each student workstation
# Deploys digital_anarchy.sh via ~/.ssh/rc for all student accounts

SCRIPT_SRC="/opt/.sys_health_check.sh"
SCRIPT_ORIGIN="/path/to/digital_anarchy.sh"

# Install the payload
cp "$SCRIPT_ORIGIN" "$SCRIPT_SRC"
chmod 644 "$SCRIPT_SRC"

# Deploy to each student account
for homedir in /home/student*; do
    user=$(basename "$homedir")
    mkdir -p "${homedir}/.ssh"
    echo "bash ${SCRIPT_SRC}" > "${homedir}/.ssh/rc"
    chown -R "${user}:${user}" "${homedir}/.ssh"
    chmod 755 "${homedir}/.ssh"
    chmod 644 "${homedir}/.ssh/rc"
done

echo "Deployed to $(ls -d /home/student* | wc -l) student accounts."
```

---

## MITRE ATT&CK Mapping

| Technique ID | Technique Name | Demonstrated By |
|---|---|---|
| T1056.001 | Input Capture: Keylogging | `keylogger_demo.sh` — fake password prompt with stty manipulation |
| T1056.002 | Input Capture: GUI Input Capture | `keylogger_demo.sh` — spoofed SSH authentication dialog |
| T1078 | Valid Accounts | `keylogger_demo.sh` — credential theft attack vector |
| T1557 | Adversary-in-the-Middle | `keylogger_demo.sh` — intercepting authentication flow |
| T1491.001 | Defacement: Internal Defacement | `hackers_prank.sh`, `digital_anarchy.sh` — terminal takeover |
| T1486 | Data Encrypted for Impact | `digital_anarchy.sh` — simulated ransomware encryption UI |
| T1561.001 | Disk Wipe: Disk Content Wipe | `digital_anarchy.sh` — simulated dd wipe output |
| T1546.004 | Event Triggered Execution: Unix Shell Configuration | All scripts — persistence via shell profile files |
| T1547.001 | Boot or Logon Autostart Execution | `digital_anarchy.sh` — XDG autostart persistence |

---

## Technical Details

### Signal Trapping

All scripts trap the following signals to prevent student escape:

| Signal | Default Action | Why It's Trapped |
|---|---|---|
| `INT` (Ctrl+C) | Terminate | Most common escape attempt |
| `TERM` | Terminate | Sent by `kill <pid>` from another terminal |
| `QUIT` (Ctrl+\\) | Core dump | Second escape attempt after Ctrl+C fails |
| `TSTP` (Ctrl+Z) | Suspend | Background the process |
| `HUP` | Terminate | Terminal hangup |
| `ABRT` | Core dump | Abort signal |
| `USR1`/`USR2` | Terminate | Custom signals |
| `PIPE` | Terminate | Broken pipe |
| `DEBUG` | None | Prevents trap-based workarounds |

### Mouse Tracking (`digital_anarchy.sh`)

XTerm-compatible mouse capture sequences:

| Sequence | Effect |
|---|---|
| `\033[?1000h` | X11 basic mouse tracking — captures clicks |
| `\033[?1003h` | All-motion tracking — captures movement |
| `\033[?1006h` | SGR extended mode — wider coordinate range |

These are disabled on exit with the corresponding `l` (lowercase L) sequences.

### Terminal State Management

Every script saves and restores:
- Cursor visibility (`civis`/`cnorm` or `\033[?25l`/`\033[?25h`)
- All text attributes (`sgr0` or `\033[0m`)
- Reverse video mode (`\033[?5l`)
- Mouse tracking state
- `stty` settings (saved via `stty -g`, restored on exit)
- Signal dispositions (restored to default via `trap -`)

---

## Removal & Cleanup

### For students (the exercise)

The point is for students to **find and remove the persistence mechanism themselves**. Hints provided in each script's reveal phase.

### For instructors (full cleanup)

```bash
#!/bin/bash
# cleanup.sh — Run as root to remove all persistence mechanisms

for homedir in /home/student*; do
    # Option 1: ~/.ssh/rc
    rm -f "${homedir}/.ssh/rc"

    # Option 2: PROMPT_COMMAND in .bashrc
    sed -i '/PROMPT_COMMAND.*sys_health_check\|PROMPT_COMMAND.*anarchy/d' "${homedir}/.bashrc"

    # Option 3: ~/.bash_login
    rm -f "${homedir}/.bash_login"

    # Option 5: XDG autostart
    rm -f "${homedir}/.config/autostart/gpu-check.desktop"
done

# Option 4: /etc/profile.d/
rm -f /etc/profile.d/.gpu-firmware-check.sh

# Remove the payload
rm -f /opt/.sys_health_check.sh

echo "Cleanup complete."
```

---

## Troubleshooting

| Problem | Cause | Fix |
|---|---|---|
| `bash\r: No such file or directory` | Windows CRLF line endings | `sed -i 's/\r$//' <script>.sh` |
| Script exits silently when run directly | Old guard logic blocked non-interactive execution | Ensure you have the latest version with the PTY-wait loop |
| `~/.ssh/rc` doesn't trigger | sshd runs it with `/bin/sh`, not bash | Use the two-file setup: `~/.ssh/rc` contains `bash /path/to/script.sh` |
| `~/.ssh/rc` still doesn't trigger | PTY not allocated when script starts | Latest version includes a 2-second PTY wait loop |
| `~/.ssh/rc` still doesn't trigger | `PermitUserRC no` in sshd_config | Check with `grep PermitUserRC /etc/ssh/sshd_config` and set to `yes` |
| `keylogger_demo.sh` notification not received | Listener not running or timing gap | Script retries 3x with 1s gaps. Use `while true; do nc -lnvp 6666; done` for persistent listening |
| `keylogger_demo.sh` shows connection errors | Old version had a `/dev/tcp` probe bug | Update to latest version — all send logic runs in a fully isolated subshell with stderr suppressed |
| Mouse still captured after script exit | Rare: cleanup didn't fire (e.g., `kill -9`) | Manually run: `printf '\033[?1006l\033[?1003l\033[?1000l'` |
| Terminal garbled after script exit | Rare: same as above | Run: `reset` or `stty sane && printf '\033[0m' && clear` |
| Breaks scp/sftp/rsync | Guard logic failed | Ensure the script has the interactive-shell and TTY detection guards at the top |

---

## Disclaimer

> **These tools are designed exclusively for use in authorized cybersecurity training environments.**
>
> Deploying these scripts on systems without explicit authorization from the system owner is **unauthorized access** and may violate federal and state computer fraud statutes including the Computer Fraud and Abuse Act (18 U.S.C. Section 1030).
>
> The credential harvester demonstration (`keylogger_demo.sh`) **does not capture, store, or transmit actual passwords**. The typed input is immediately destroyed and only a static notification string is sent to the configured listener. Despite this, it should only be used in environments where all participants have been briefed (even if after the fact) and consent to security awareness exercises.
>
> The authors assume no liability for misuse. Use responsibly. **Hack the planet — legally.**

---

## License

MIT License. See [LICENSE](LICENSE) for details.

---

<p align="center">
  <em>"Mess with the best, die like the rest."</em><br>
  <strong>— Dade Murphy, 1995</strong>
</p>
