# Terminal 24 jam di browser HP (tanpa VS Code): ttyd + tmux + Claude Code / OpenCode / CodeBuddy CLI + gh
# Buka https://<domain-railway> -> login user/password -> langsung terminal (sesi tmux "main" yang awet)
FROM debian:bookworm-slim

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
      ca-certificates curl git gnupg tmux gosu openssh-server openssh-client \
      python3 jq nano less procps unzip \
    && curl -fsSL https://deb.nodesource.com/setup_22.x | bash - \
    && apt-get install -y --no-install-recommends nodejs \
    && curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
         -o /usr/share/keyrings/githubcli-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
         > /etc/apt/sources.list.d/github-cli.list \
    && apt-get update && apt-get install -y --no-install-recommends gh \
    && rm -rf /var/lib/apt/lists/*

# ttyd = terminal web (binary resmi)
RUN curl -fsSL https://github.com/tsl0922/ttyd/releases/latest/download/ttyd.x86_64 -o /usr/local/bin/ttyd \
    && chmod +x /usr/local/bin/ttyd

# Agent CLI (di image, tidak makan volume)
RUN npm install -g @anthropic-ai/claude-code opencode-ai @tencent-ai/codebuddy-code && npm cache clean --force

RUN useradd -m -u 1000 -s /bin/bash dev && mkdir -p /run/sshd

# tmux enak dipakai di HP: mouse/scroll jalan, history panjang
RUN printf '%s\n' \
      'set -g mouse on' \
      'set -g history-limit 50000' \
      'set -g default-terminal "screen-256color"' \
      'set -g status-left " #S "' \
      'set -g status-right " %H:%M "' \
      'set -g escape-time 10' \
      > /etc/tmux.conf

COPY start.sh /start.sh
RUN chmod +x /start.sh

ENV HOME=/home/dev PORT=7681
EXPOSE 7681 22
VOLUME ["/home/dev"]

CMD ["/start.sh"]
