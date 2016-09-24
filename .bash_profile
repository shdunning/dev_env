source /Library/Developer/CommandLineTools/usr/share/git-core/git-prompt.sh
source ~/.cdstack.sh

PS1="\u:\w\[\e[0;31m\]\$(__git_ps1)\[\e[m\]> "

alias stn="/Applications/Sublime\ Text.app/Contents/MacOS/Sublime\ Text -n > /dev/null 2>&1"
alias top="top -o cpu"
