source /usr/share/cachyos-fish-config/cachyos-config.fish

# overwrite greeting
# potentially disabling fastfetch
function fish_greeting
end
set -gx EDITOR vim

# Custom eza aliases to hide metadata
alias l='eza -lh --icons=auto --no-permissions --no-user --no-filesize --time-style="+%Y/%-m/%-d %I:%M %p"'
alias ls='eza -1 --icons=auto'
alias ll='eza -lha --icons=auto --sort=name --group-directories-first --no-permissions --no-user --no-filesize --time-style="+%Y/%-m/%-d %I:%M %p"'
alias ld='eza -lhD --icons=auto --no-permissions --no-user --no-filesize --time-style="+%Y/%-m/%-d %I:%M %p"'
alias la='eza -lha --icons=auto --no-permissions --no-user --no-filesize --time-style="+%Y/%-m/%-d %I:%M %p"'
alias lsa='eza -lha --icons=auto --no-permissions --no-user --no-filesize --time-style="+%Y/%-m/%-d %I:%M %p"'

# Task management functions
function todo
    python3 ~/.local/share/bin/manage_tasks.py todo "$argv"
    fastfetch
end

function doing
    python3 ~/.local/share/bin/manage_tasks.py doing "$argv"
    fastfetch
end

function donetask
    python3 ~/.local/share/bin/manage_tasks.py done "$argv"
    fastfetch
end

function rmtask
    python3 ~/.local/share/bin/manage_tasks.py remove "$argv"
    fastfetch
end

function edittask
    set -l editor_cmd $EDITOR
    if test -z "$editor_cmd"
        if type -q nano
            set editor_cmd nano
        else if type -q vim
            set editor_cmd vim
        else
            set editor_cmd vi
        end
    end
    eval $editor_cmd ~/.config/fastfetch/tasks.txt
    fastfetch
end
