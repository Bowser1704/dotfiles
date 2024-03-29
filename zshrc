export PATH=$HOME/.asdf/bin:$PATH
export PATH=$HOME/.local/bin:$PATH
export PATH=$PATH:$HOME/.cargo/bin
export PATH=$PATH:/opt/homebrew/bin

export HOMEBREW_API_DOMAIN="https://mirrors.tuna.tsinghua.edu.cn/homebrew-bottles/api"
export HOMEBREW_BREW_GIT_REMOTE="https://mirrors.tuna.tsinghua.edu.cn/git/homebrew/brew.git"

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

export POWERLEVEL9K_INSTANT_PROMPT=quiet

(( ${+commands[direnv]} )) && emulate zsh -c "$(direnv export zsh)"
# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi
(( ${+commands[direnv]} )) && emulate zsh -c "$(direnv hook zsh)"

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# zsh-vi-mode
zinit ice depth=1; zinit light jeffreytse/zsh-vi-mode

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
zinit snippet OMZP::asdf

# For postponing loading `fzf`
zinit ice lucid wait
zinit snippet OMZP::fzf

test -d ~/.linuxbrew && eval "$(~/.linuxbrew/bin/brew shellenv)"
test -d /home/linuxbrew/.linuxbrew && eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"

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

if _exists nvim; then
    export EDITOR=nvim
    export VISUAL=nvim
    export MANPAGER="nvim +Man!"
    alias vim='nvim'
    alias vi='nvim'
fi

_exists istioctl && istioctl completion zsh > ~/.local/completions/_istioctl
_exists argocd && argocd completion zsh > ~/.local/completions/_argocd
_exists kubectl && kubectl completion zsh > ~/.local/completions/_kubectl
_exists delta && compdef _gnu_generic delta
_exists vault && complete -o nospace -C $(which vault) vault
_exists terraform && complete -o nospace -C $(which terraform) terraform

unfunction _exists

# if [[ -n $TERM ]]; then
#     alias pbcopy='xargs tmux set-buffer'
# fi

zinit creinstall -q ~/.local/completions

function howto() {
    # read input from flags or stdin if no tty
    input=$(if [ -t 0 ]; then echo $@; else cat -; fi)

    # escape double quotes
    input=${input//\"/\\\"}

    content=$(cat<<EOF
I want you to act as a shell command assistant. I will type my goal in natural language, and you will output the shell command that can achieve my goal.
I want you to only output plain shell commands with corresponding escape, do not add any markdown tags, do not add any explanations. My first goal is: "${input}"
EOF
)
    output=$(openai api chat.completions.create -m 'gpt-3.5-turbo' -g user "${content}")
    print -z "$output"
}
