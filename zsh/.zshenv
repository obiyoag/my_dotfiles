# Skip system-wide compinit on Ubuntu
# Ubuntu's /etc/zsh/zshrc calls compinit, which conflicts with Zimfw
# This variable tells the system config to skip compinit initialization
# Let Zimfw's completion module handle it instead
skip_global_compinit=1
