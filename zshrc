export PATH=$HOME/.asdf/bin:$PATH
export PATH=$HOME/.local/bin:$PATH
export PATH=$PATH:$HOME/.cargo/bin
export PATH=$PATH:/opt/homebrew/bin
export PATH="${KREW_ROOT:-$HOME/.krew}/bin:$PATH"

export TERM="xterm-256color"
export HOMEBREW_API_DOMAIN="https://mirrors.tuna.tsinghua.edu.cn/homebrew-bottles/api"
export HOMEBREW_BREW_GIT_REMOTE="https://mirrors.tuna.tsinghua.edu.cn/git/homebrew/brew.git"
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8

autoload -U +X compinit && compinit
autoload -U +X bashcompinit && bashcompinit

# Created by newuser for 5.8

### Added by Zinit's installer
if [[ ! -f $HOME/.local/share/zinit/zinit.git/zinit.zsh ]]; then
    print -P "%F{33} %F{220}Installing %F{33}ZDHARMA-CONTINUUM%F{220} Initiative Plugin Manager (%F{33}zdharma-continuum/zinit%F{220})…%f"
    command mkdir -p "$HOME/.local/share/zinit" && command chmod g-rwX "$HOME/.local/share/zinit"
    command git clone https://github.com/zdharma-continuum/zinit "$HOME/.local/share/zinit/zinit.git" && \
        print -P "%F{33} %F{34}Installation successful.%f%b" || \
        print -P "%F{160} The clone has failed.%f%b"
fi
source "$HOME/.local/share/zinit/zinit.git/zinit.zsh"

autoload -Uz _zinit
(( ${+_comps} )) && _comps[zinit]=_zinit

# Load a few important annexes, without Turbo
# (this is currently required for annexes)
zinit light-mode for \
    zdharma-continuum/zinit-annex-as-monitor \
    zdharma-continuum/zinit-annex-bin-gem-node \
    zdharma-continuum/zinit-annex-patch-dl \
    zdharma-continuum/zinit-annex-rust

### End of Zinit's installer chunk

export POWERLEVEL9K_INSTANT_PROMPT=quiet
zinit ice depth=1; zinit light romkatv/powerlevel10k

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

zinit wait lucid light-mode for \
  atinit"zicompinit; zicdreplay" \
      zdharma-continuum/fast-syntax-highlighting \
    OMZP::colored-man-pages \
  atload"_zsh_autosuggest_start" \
      zsh-users/zsh-autosuggestions \
  blockf atpull'zinit creinstall -q .' \
      zsh-users/zsh-completions \

# omz plugin
zinit light-mode for \
  as"completion" \
    OMZP::docker/completions/_docker \
    OMZL::completion.zsh

zinit light-mode for \
    hlissner/zsh-autopair \
    superbrothers/zsh-kubectl-prompt \
    OMZP::kubectl \
    OMZP::gitignore \
    OMZP::cp \
    OMZP::asdf \
    OMZL::clipboard.zsh \
    OMZL::history.zsh \

zinit ice atload"unalias grv"; zinit snippet OMZP::git

zinit from"gh-r" as"program" mv"direnv* -> direnv" \
    atclone'./direnv hook zsh > zhook.zsh' atpull'%atclone' \
    pick"direnv" src="zhook.zsh" for \
        direnv/direnv

# zsh-vi-mode
zinit ice depth=1; zinit light jeffreytse/zsh-vi-mode
# For postponing loading `fzf`
zinit ice lucid wait; zinit snippet OMZP::fzf


load_completion_with_zinit() {
  # Check if an argument is provided
  if [ -z "$1" ]; then
    echo "Usage: load_completion_with_zinit <command>"
    return 1
  fi

  # Generate and load completion script using Zinit
  zinit ice as"completion" wait"0" lucid
  zinit snippet <<<"$($1 completion zsh)"
}

_exists() { (( $+commands[$1])) }
_exists exa     && alias ls='exa --icons' && alias ll='ls -lh'
_exists htop    && alias top='htop'
_exists fdfind  && alias fd='fdfind'
_exists batcat  && alias cat='batcat'
_exists free    && alias free='free -h'
_exists less    && export PAGER=less
_exists less    && alias more='less'
_exists ag      && alias grep='ag'
_exists rg      && alias grep='rg'
_exists curlie  && alias curl='curlie' && compdef _curl curlie
_exists delta   && alias diff='delta'
_exists difft   && alias diff='difft'
# _exists kubectl && load_completion_with_zinit kubectl

if _exists nvim; then
    export EDITOR=nvim
    export VISUAL=nvim
    export MANPAGER="nvim +Man!"
    alias vim='nvim'
    alias vi='nvim'
fi

unfunction _exists

# if [[ -n $TERM ]]; then
#     alias pbcopy='xargs tmux set-buffer'
# fi
eval "$(gh copilot alias -- zsh)"
