#    _               _
#   | |__   __ _ ___| |__  _ __ ___
#   | '_ \ / _` / __| '_ \| '__/ __|
#  _| |_) | (_| \__ \ | | | | | (__
# (_)_.__/ \__,_|___/_| |_|_|  \___|
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return
PS1='[\u@\h \W]\$ '

# -----------------------------------------------------
# LOAD CUSTOM .bashrc_custom if exists
# -----------------------------------------------------
if [ -f ~/.bashrc_custom ]; then
  source ~/.bashrc_custom
fi

# Import colorscheme from 'wal' asynchronously
# &   # Run the process in the background.
# ( ) # Hide shell job control messages.
# Not supported in the "fish" shell.
(cat ~/.cache/wal/sequences &)

# -----------------------------------------------------
# LOAD SECRETS (API keys etc.) if exists
# -----------------------------------------------------
if [ -f ~/.bashrc_secrets ]; then
  source ~/.bashrc_secrets
fi

if [[ $(tty) == *"pts"* ]]; then
  fastfetch 2>/dev/null
else
  echo
  echo "Start Hyprland with command Hyprland"
fi

export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init --path)"
export CLOUDSDK_PYTHON=$(pyenv which python)

export ANDROID_HOME=$HOME/android-sdk
export PATH=$PATH:$ANDROID_HOME/platform-tools

export JAVA_HOME=/usr/lib/jvm/java-17-openjdk

eval "$(starship init bash)"

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"                   # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion" # This loads nvm bash_completion
export PATH=$HOME/.local/bin:$PATH
export PATH="$HOME/.cargo/bin:$PATH"

# Install packages and track them in dotfiles
pkg() {
    yay -S "$@" && for p in "$@"; do
        [[ "$p" == -* ]] && continue
        grep -qx "$p" ~/dotfiles/packages.txt 2>/dev/null || echo "$p" >> ~/dotfiles/packages.txt
    done
    notify-send "Dotfiles" "packages.txt updated — remember to commit and push"
}
