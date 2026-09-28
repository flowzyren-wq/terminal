#!/bin/bash
# Entrypoint: rapikan volume, sshd (opsional), lalu ttyd + tmux. Provider AI diatur lewat variabel environment.
set -e

H=/home/dev
mkdir -p "$H"

# Volume Railway di-mount sebagai root -> kembalikan ke user dev
if [ "$(stat -c %u "$H")" != "1000" ]; then
  chown -R dev:dev "$H"
fi
for f in .bashrc .profile; do
  [ -f "$H/$f" ] || { cp "/etc/skel/$f" "$H/$f"; chown dev:dev "$H/$f"; }
done

# ---- Password terminal web (TTYD_PASSWORD). Kalau kosong: dibuat sekali & disimpan di volume ----
TTYD_USER="${TTYD_USER:-dev}"
if [ -z "$TTYD_PASSWORD" ]; then
  if [ ! -s "$H/.ttyd-password" ]; then
    tr -dc 'A-Za-z0-9' </dev/urandom | head -c 20 > "$H/.ttyd-password"
    chown dev:dev "$H/.ttyd-password"; chmod 600 "$H/.ttyd-password"
  fi
  TTYD_PASSWORD="$(cat "$H/.ttyd-password")"
  echo "[start] TTYD_PASSWORD tidak di-set. Password login terminal: $TTYD_USER / $TTYD_PASSWORD"
fi

# ---- Provider AI: cukup set variabel di Railway, semua CLI membacanya langsung dari environment ----
#   Claude Code : ANTHROPIC_BASE_URL + ANTHROPIC_AUTH_TOKEN (+ ANTHROPIC_MODEL)
#   Codex/OpenAI-compatible : OPENAI_BASE_URL + OPENAI_API_KEY
#   CodeBuddy CLI : CODEBUDDY_API_KEY
[ -n "$ANTHROPIC_AUTH_TOKEN" ] && echo "[start] Claude Code -> ${ANTHROPIC_BASE_URL:-api.anthropic.com} (model ${ANTHROPIC_MODEL:-default})"
[ -n "$OPENAI_API_KEY" ]       && echo "[start] OPENAI_BASE_URL -> ${OPENAI_BASE_URL:-api.openai.com}"
[ -n "$CODEBUDDY_API_KEY" ]    && echo "[start] CodeBuddy CLI: API key terpasang"

# ---- SSH opsional (SSH_PASSWORD) untuk app Termius/JuiceSSH lewat Railway TCP Proxy port 22 ----
if [ -n "$SSH_PASSWORD" ]; then
  echo "dev:$SSH_PASSWORD" | chpasswd
  mkdir -p "$H/.sshd"
  [ -f "$H/.sshd/ssh_host_ed25519_key" ] || ssh-keygen -q -t ed25519 -N "" -f "$H/.sshd/ssh_host_ed25519_key"
  chmod 700 "$H/.sshd"; chmod 600 "$H/.sshd/ssh_host_ed25519_key"
  /usr/sbin/sshd -p 22 -h "$H/.sshd/ssh_host_ed25519_key" \
    -o PasswordAuthentication=yes -o PermitRootLogin=no -o AllowUsers=dev -o UsePAM=no
  echo "[start] sshd aktif di port 22 (user dev). Nyalakan TCP Proxy port 22 di Railway."
fi

echo "=================================================================="
echo "  Terminal web siap di port ${PORT:-7681}. Login: $TTYD_USER"
echo "  Sesi tmux 'main' tetap jalan walau browser/HP ditutup."
echo "=================================================================="

export HOME="$H"
exec gosu dev ttyd -W \
  -p "${PORT:-7681}" \
  -c "$TTYD_USER:$TTYD_PASSWORD" \
  -m 5 \
  -w "$H" \
  -t fontSize=15 \
  -t disableLeaveAlert=true \
  -t titleFixed=Terminal \
  tmux new -A -s main
