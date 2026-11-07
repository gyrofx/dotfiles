# editors
export VISUAL=vim
export EDITOR=$VISUAL
export EDITOR=code
export TERM=xterm

# history settings
setopt hist_ignore_all_dups inc_append_history
HISTFILE=~/.zhistory
HISTSIZE=4096
SAVEHIST=4096

export ERL_AFLAGS="-kernel shell_history enabled"


# awesome cd movements from zshkit
setopt autocd autopushd pushdminus pushdsilent pushdtohome cdablevars
DIRSTACKSIZE=5



# extra files in ~/.zsh/configs/pre , ~/.zsh/configs , and ~/.zsh/configs/post
# these are loaded first, second, and third, respectively.
_load_settings() {
  _dir="$1"
  if [ -d "$_dir" ]; then
    if [ -d "$_dir/pre" ]; then
      for config in "$_dir"/pre/**/*~*.zwc(N-.); do
        . $config
      done
    fi

    for config in "$_dir"/**/*(N-.); do
      case "$config" in
        "$_dir"/(pre|post)/*|*.zwc)
          :
          ;;
        *)
          . $config
          ;;
      esac
    done

    if [ -d "$_dir/post" ]; then
      for config in "$_dir"/post/**/*~*.zwc(N-.); do
        . $config
      done
    fi
  fi
}
_load_settings "$HOME/.zsh/configs"



# brew
export BREW_HOME="/home/linuxbrew/.linuxbrew/bin"
export PATH="$PATH:$BREW_HOME"
export HOMEBREW_NO_ANALYTICS=1

# asdf
command -v brew >/dev/null && [[ -f $(brew --prefix asdf)/libexec/asdf.sh ]] && export ASDF_DIR=$(brew --prefix asdf)/libexec
command -v brew >/dev/null && [[ -f $(brew --prefix asdf)/libexec/asdf.sh ]] && chmod +x $(brew --prefix asdf)/libexec/asdf.sh && $(brew --prefix asdf)/libexec/asdf.sh

# mise version manager
command -v mise &>/dev/null && eval "$(mise activate zsh)"

# oh my zsh
ZSH_THEME=""
HIST_STAMPS="yyyy-mm-dd"

plugins=(
  git
  yarn
  asdf
  kubectl
  kubectx
  python
  systemadmin
)
export ZSH=$HOME/.oh-my-zsh



# pulumi
export PATH=$PATH:$HOME/.pulumi/bin

# Local config
[[ -f ~/.zshrc.local ]] && source ~/.zshrc.local

# aliases
[[ -f ~/.aliases ]] && source ~/.aliases

[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh



# bun completions
[ -s "/home/felix/.bun/_bun" ] && source "/home/felix/.bun/_bun"

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

# autojump
[ -f /usr/share/autojump/autojump.sh ] &&. /usr/share/autojump/autojump.sh
[ -f /home/linuxbrew/.linuxbrew/etc/profile.d/autojump.sh ] && . /home/linuxbrew/.linuxbrew/etc/profile.d/autojump.sh

# zoxide (autojump replacement)
command -v zoxide &>/dev/null && eval "$(zoxide init zsh)"

# zf: pick a directory with fzf and cd into it
#   lists your zoxide history, then the folders below the current one; ctrl-t shows only the subfolders
zf() {
  # passed to fzf as env vars so the ctrl-t reload doesn't need nested quoting
  local ZF_FD="fd --type d --hidden --exclude .git --absolute-path | sed 's:/\$::'"
  local ZF_ALL="{ zoxide query --list; $ZF_FD; } | awk '!seen[\$0]++'"
  local dir
  dir=$(eval "$ZF_ALL" | ZF_FD=$ZF_FD ZF_ALL=$ZF_ALL fzf --scheme=path --tiebreak=index \
    --prompt 'z> ' --query "$*" \
    --header 'ctrl-t: all/subfolders only · ctrl-/: preview' \
    --preview 'fzf-preview {}' --preview-window 'right,50%,border-left' \
    --bind "ctrl-t:transform:[[ \$FZF_PROMPT == z* ]] && echo 'change-prompt(dirs> )+reload(eval \"\$ZF_FD\")' || echo 'change-prompt(z> )+reload(eval \"\$ZF_ALL\")'" \
    --bind 'ctrl-/:toggle-preview') && cd -- "$dir"
}

# fzf-git-branch and fzf-git-checkout live in ~/.local/bin
alias gb='fzf-git-branch'
alias geco='fzf-git-checkout'

alias opensslshort="openssl x509 -noout -subject -subject_hash -serial -fingerprint -sha256 -dates -issuer -issuer_hash -ext subjectAltName"

eval "$(starship init zsh)"

source $ZSH/oh-my-zsh.sh

source <(fzf --zsh)


# alt-z: open zf (after oh-my-zsh so it isn't overwritten)
bindkey -s '^[z' 'zf\n'
