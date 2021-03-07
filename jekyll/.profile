# Suitable for git beauty PS1
parse_git_branch() {
    if command -v git &> /dev/null
    then
        git branch 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/(\1)/'
    else
        :
    fi
}

if [ `whoami` = root ]; then
    export PS1="\[\e[36m\]\u \[\e[31m\]\xE2\x9D\xA4  \[\e[35m\]\h \[\e[33m\]\A \[\e[32m\]\w \[\e[91m\]$(parse_git_branch)\n\[\e[00m\]\$ "
else
    export PS1="\[\e[36m\]\u \[\e[33m\]\xE2\x98\x85  \[\e[35m\]\h \[\e[33m\]\A \[\e[32m\]\w \[\e[91m\]$(parse_git_branch)\n\[\e[00m\]\$ "
fi

alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'
