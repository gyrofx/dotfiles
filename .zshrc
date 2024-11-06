# editors
export VISUAL=vim
export EDITOR=$VISUAL
export EDITOR=code

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
[[ -f $(brew --prefix asdf)/libexec/asdf.sh ]] && export ASDF_DIR=$(brew --prefix asdf)/libexec
[[ -f $(brew --prefix asdf)/libexec/asdf.sh ]] && $(brew --prefix asdf)/libexec/asdf.sh

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


fzf-git-branch() {
    git rev-parse HEAD > /dev/null 2>&1 || return

    git branch --color=always --all --sort=-committerdate |
        grep -v HEAD |
        fzf --height 50% --ansi --no-multi --preview-window right:65% \
            --preview 'git log -n 50 --color=always --date=short --pretty="format:%C(auto)%cd %h%d %s" $(sed "s/.* //" <<< {})' |
        sed "s/.* //"
}

fzf-git-checkout() {
    git rev-parse HEAD > /dev/null 2>&1 || return

    local branch

    branch=$(fzf-git-branch)
    if [[ "$branch" = "" ]]; then
        echo "No branch selected."
        return
    fi

    # If branch name starts with 'remotes/' then it is a remote branch. By
    # using --track and a remote branch name, it is the same as:
    # git checkout -b branchName --track origin/branchName
    if [[ "$branch" = 'remotes/'* ]]; then
        git checkout --track $branch
    else
        git checkout $branch;
    fi
}

alias gb='fzf-git-branch'
alias geco='fzf-git-checkout'

alias opensslshort="openssl x509 -noout -subject -subject_hash -serial -fingerprint -sha256 -dates -issuer -issuer_hash -ext subjectAltName"

eval "$(starship init zsh)"

source $ZSH/oh-my-zsh.sh

source <(fzf --zsh)
