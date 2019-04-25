alias ll 'ls -la'

alias rm 'rm -i'
alias mv 'mv -i'
alias cp 'cp -i'

# cd したら ll する
functions --copy cd standard_cd
function cd
    standard_cd $argv; and ll
end

function tree
    pwd;find . | sort | sed '1d;s/^\.//;s/\/\([^/]*\)$/|--\1/;s/\/[^/|]*/| /g'
end
