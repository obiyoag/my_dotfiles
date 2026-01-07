bindkey -v

# 允许退格键删除进入插入模式前的文本
bindkey -M viins '^?' backward-delete-char
bindkey -M viins '^H' backward-delete-char

# visual 模式选中后 y 复制到系统剪切板
function vi-yank-clipboard {
	zle vi-yank
	echo -n "$CUTBUFFER" | pbcopy
}
zle -N vi-yank-clipboard
bindkey -M visual 'y' vi-yank-clipboard

# normal 模式 p 从系统剪切板粘贴
function vi-paste-clipboard {
	CUTBUFFER=$(pbpaste)
	zle vi-put-after
}
zle -N vi-paste-clipboard
bindkey -M vicmd 'p' vi-paste-clipboard

function zle-keymap-select {
	if [[ ${KEYMAP} == vicmd ]] || [[ $1 = 'block' ]]; then
		echo -ne '\e[1 q'
	elif [[ ${KEYMAP} == main ]] || [[ ${KEYMAP} == viins ]] || [[ ${KEYMAP} = '' ]] || [[ $1 = 'beam' ]]; then
		echo -ne '\e[5 q'
  fi
}
zle -N zle-keymap-select

# Use beam shape cursor on startup.
echo -ne '\e[5 q'

# Use beam shape cursor for each new prompt.
preexec() {
	echo -ne '\e[5 q'
}

# SSH 包装：重置光标并在退出后恢复
ssh() {
	echo -ne '\e[0 q'
	command ssh "$@"
	echo -ne '\e[5 q'
}

_fix_cursor() {
	echo -ne '\e[5 q'
}
precmd_functions+=(_fix_cursor)

KEYTIMEOUT=1

