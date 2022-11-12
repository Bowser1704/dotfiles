# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi
typeset -g POWERLEVEL9K_INSTANT_PROMPT=quiet

export PATH=$PATH:$HOME/.local/bin
export PATH=$PATH:/usr/local/go/bin
export PATH=$PATH:$HOME/go/bin
export PATH=$PATH:$HOME/.tiup/bin
export PATH=$PATH:$HOME/.spicetify

autoload -U +X compinit && compinit

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
zinit ice depth=1; zinit light romkatv/powerlevel10k

# zsh-vi-mode
zinit ice depth=1; zinit light jeffreytse/zsh-vi-mode

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# omz plugin
zinit light-mode for \
    zdharma-continuum/fast-syntax-highlighting \
    zsh-users/zsh-autosuggestions \
    zsh-users/zsh-completions \
    hlissner/zsh-autopair \
    superbrothers/zsh-kubectl-prompt

zinit snippet OMZ::plugins/git/git.plugin.zsh
zinit snippet OMZL::clipboard.zsh
zinit snippet OMZL::completion.zsh
zinit snippet OMZL::history.zsh
zinit snippet OMZP::colored-man-pages
zinit snippet OMZP::gitignore

# For postponing loading `fzf`
zinit ice lucid wait
zinit snippet OMZP::fzf

alias ll='ls -l'

_exists() { (( $+commands[$1])) }

_exists exa     && alias ls='exa --icons --git'
_exists htop    && alias top='htop'
_exists fdfind  && alias fd='fdfind'
_exists batcat  && alias cat='batcat'
_exists free    && alias free='free -h'
_exists less    && export PAGER=less
_exists less    && alias more='less'
_exists ag      && alias grep='ag'
_exists rg      && alias grep='rg'
_exists curlie  && alias curl='curlie'
_exists delta   && alias diff='delta'
if [[ -n $TERM ]]; then
    alias pbcopy='xargs tmux set-buffer'
fi

if _exists nvim; then
    export EDITOR=nvim
    export VISUAL=nvim
    export MANPAGER="nvim +Man!"
    alias vim='nvim'
    alias vi='nvim'
fi

if _exists nvm; then
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
    [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
fi

if _exists pyenv; then
    export PYENV_ROOT="$HOME/.pyenv"
    command -v pyenv >/dev/null || export PATH="$PYENV_ROOT/bin:$PATH"
    eval "$(pyenv init -)"
    eval "$(pyenv virtualenv-init -)"
fi

if _exists brew; then
    test -d ~/.linuxbrew && eval "$(~/.linuxbrew/bin/brew shellenv)"
    test -d /home/linuxbrew/.linuxbrew && eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
fi

_exists istioctl && source <(istioctl completion zsh); compdef _istioctl istioctl
_exists argocd && source <(argocd completion zsh); compdef _argocd argocd
_exists kubectl && source <(kubectl completion zsh); compdef _kubectl kubectl
_exists direnv && eval "$(direnv hook zsh)"

unfunction _exists
