export PLUG_DIR=$HOME/.zim
if [[ ! -d $PLUG_DIR ]]; then
	curl -fsSL https://raw.githubusercontent.com/zimfw/install/master/install.zsh | zsh
	rm ~/.zimrc
	ln -s ~/.config/zsh/zimrc ~/.zimrc
fi

# Git-info performance optimization for zimfw
# https://github.com/zimfw/git-info

# Disable verbose mode (much faster - uses git diff instead of git status)
zstyle ':zim:git-info' verbose 'no'

# Ignore submodules completely
zstyle ':zim:git-info' ignore-submodules 'all'

# DELETE remote-checking formats to prevent hanging (don't just set to empty!)
# These cause git-info to run "git rev-list ...@{u}" which needs network access
# Using -d to delete the zstyle pattern entirely
zstyle -d ':zim:git-info:ahead' format
zstyle -d ':zim:git-info:behind' format
zstyle -d ':zim:git-info:diverged' format
zstyle -d ':zim:git-info:remote' format

# DELETE action format - git-action uses :A modifier which can hang on symlinks
zstyle -d ':zim:git-info:action' format
