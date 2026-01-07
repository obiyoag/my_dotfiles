# confirm before overwriting something
alias cp="cp -i"
alias mv='mv -i'
alias rm='rm -i'

alias df='df -h'
alias du='du -h'

alias clash="export https_proxy=http://127.0.0.1:7890 http_proxy=http://127.0.0.1:7890 all_proxy=socks5://127.0.0.1:7890"
alias unclash="unset http_proxy https_proxy all_proxy HTTP_PROXY HTTPS_PROXY ALL_PROXY"

alias vim="nvim"
alias tmux="tmux -u"

alias c="clear"
alias claude='claude --append-system-prompt "$(cat ~/.config/claude/system-prompt.txt)"'
