# .bashrcをロード
if [ -f ~/.bashrc ] ; then
    . ~/.bashrc
fi

##
# Your previous /Users/guri/.bash_profile file was backed up as /Users/guri/.bash_profile.macports-saved_2019-03-31_at_18:09:42
##

# MacPorts Installer addition on 2019-03-31_at_18:09:42: adding an appropriate PATH variable for use with MacPorts.
export PATH="/opt/local/bin:/opt/local/sbin:$PATH"
# Finished adapting your PATH environment variable for use with MacPorts.


export PATH="$HOME/.cargo/bin:$PATH"
