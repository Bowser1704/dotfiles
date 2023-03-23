# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi
typeset -g POWERLEVEL9K_INSTANT_PROMPT=quiet

export PATH=$HOME/.local/bin:$PATH
export PATH=$PATH:/usr/local/go/bin
export PATH=$PATH:$HOME/go/bin
export PATH=$PATH:$HOME/.tiup/bin
export PATH=$PATH:$HOME/.spicetify
export PATH=$PATH:$HOME/.krew/bin

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
zinit ice depth=1; zinit light romkatv/powerlevel10k

# zsh-vi-mode
zinit ice depth=1; zinit light jeffreytse/zsh-vi-mode

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# zsh completion
zinit ice blockf; zinit light zsh-users/zsh-completions
zstyle ':completion:*:*:make:*' tag-order 'targets'

# omz plugin
zinit light-mode for \
    zdharma-continuum/fast-syntax-highlighting \
    zsh-users/zsh-autosuggestions \
    hlissner/zsh-autopair \
    superbrothers/zsh-kubectl-prompt

zinit snippet OMZL::clipboard.zsh
zinit snippet OMZL::completion.zsh
zinit snippet OMZL::history.zsh
zinit snippet OMZP::colored-man-pages
zinit snippet OMZP::git
zinit snippet OMZP::gitignore
zinit snippet OMZP::cp

# For postponing loading `fzf`
zinit ice lucid wait
zinit snippet OMZP::fzf

test -d ~/.linuxbrew && eval "$(~/.linuxbrew/bin/brew shellenv)"
test -d /home/linuxbrew/.linuxbrew && eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"

_exists() { (( $+commands[$1])) }

_exists exa     && alias ls='exa --icons --git' && alias ll='ls -lh'
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

export PYENV_ROOT="$HOME/.pyenv"
command -v pyenv >/dev/null || export PATH="$PYENV_ROOT/bin:$PATH"
if _exists pyenv; then
    eval "$(pyenv init -)"
    eval "$(pyenv virtualenv-init -)"
fi

_exists istioctl && istioctl completion zsh > ~/.local/completions/_istioctl
_exists argocd && argocd completion zsh > ~/.local/completions/_argocd
_exists kubectl && kubectl completion zsh > ~/.local/completions/_kubectl
_exists delta && compdef _gnu_generic delta
_exists vault && complete -o nospace -C $(which vault) vault

_exists direnv && eval "$(direnv hook zsh)"

unfunction _exists

zinit creinstall ~/.local/completions
