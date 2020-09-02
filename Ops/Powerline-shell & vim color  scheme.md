# Powerline-shell & VIM colors scheme INSTALL

## Powerline-shell INSTALL

```bash
curl https://bootstrap.pypa.io/get-pip.py -o get-pip.py

python get-pip.py

pip install git+git://github.com/powerline/powerline

pip install powerline-gitstatus

pip install powerline-shell

wget https://github.com/powerline/powerline/raw/develop/font/PowerlineSymbols.otf

wget https://github.com/powerline/powerline/raw/develop/font/10-powerline-symbols.conf

mkdir -p /usr/share/fonts && cp PowerlineSymbols.otf /usr/share/fonts/

mkdir -p /etc/fonts/conf.d && mv 10-powerline-symbols.conf /etc/fonts/conf.d/

vim ~/.bashrc

---------------------------------------
function _update_ps1() {
    PS1=$(powerline-shell $?)
}

if [[ $TERM != linux && ! $PROMPT_COMMAND =~ _update_ps1 ]]; then
    PROMPT_COMMAND="_update_ps1; $PROMPT_COMMAND"
fi
---------------------------------------

source ~/.bashrc

vim /usr/lib/python2.7/site-packages/powerline_shell/themes/default.py

-------------------------------------------
class DefaultColor(object):
    """
    This class should have the default colors for every segment.
    Please test every new segment with this theme first.
    """
    # RESET is not a real color code. It is used as in indicator
    # within the code that any foreground / background color should
    # be cleared
    RESET = -1

    USERNAME_FG = 15
    USERNAME_BG = 240
    USERNAME_ROOT_BG = 33

    HOSTNAME_FG = 33
    HOSTNAME_BG = 15

    HOME_SPECIAL_DISPLAY = True
    HOME_BG = 31  # blueish
    HOME_FG = 15  # white
    PATH_BG = 70  # dark grey
    PATH_FG = 15  # light grey
    CWD_FG = 254  # nearly-white grey
    SEPARATOR_FG = 244

    READONLY_BG = 124
    READONLY_FG = 254

    SSH_BG = 166  # medium orange
    SSH_FG = 254

    REPO_CLEAN_BG = 148  # a light green color
    REPO_CLEAN_FG = 0  # black
    REPO_DIRTY_BG = 161  # pink/red
    REPO_DIRTY_FG = 15  # white

    JOBS_FG = 39
    JOBS_BG = 238

    CMD_PASSED_BG = 172
    CMD_PASSED_FG = 15
    CMD_FAILED_BG = 161
    CMD_FAILED_FG = 15

    SVN_CHANGES_BG = 148
    SVN_CHANGES_FG = 22  # dark green

    GIT_AHEAD_BG = 240
    GIT_AHEAD_FG = 250
    GIT_BEHIND_BG = 240
    GIT_BEHIND_FG = 250
    GIT_STAGED_BG = 22
    GIT_STAGED_FG = 15
    GIT_NOTSTAGED_BG = 130
    GIT_NOTSTAGED_FG = 15
    GIT_UNTRACKED_BG = 52
    GIT_UNTRACKED_FG = 15
    GIT_CONFLICTED_BG = 9
    GIT_CONFLICTED_FG = 15

    GIT_STASH_BG = 221
    GIT_STASH_FG = 0

    VIRTUAL_ENV_BG = 35  # a mid-tone green
    VIRTUAL_ENV_FG = 00

    BATTERY_NORMAL_BG = 22
    BATTERY_NORMAL_FG = 7
    BATTERY_LOW_BG = 196
    BATTERY_LOW_FG = 7

    AWS_PROFILE_FG = 39
    AWS_PROFILE_BG = 238

    TIME_FG = 250
    TIME_BG = 238


class Color(DefaultColor):
    """
    This subclass is required when the user chooses to use 'default' theme.
    Because the segments require a 'Color' class for every theme.
    """
    pass
-------------------------------------------

mkdir -p ~/.config/powerline-shell && powerline-shell --generate-config > ~/.config/powerline-shell/config.json

--------------------------------------------
{
  "segments": [
    "virtual_env",
    "hostname",
    "username",
    "cwd",
    "git",
    "hg",
    "jobs",
    "root"
  ]
}
--------------------------------------------
```

## VIM colors scheme INSTALL

```bash
yum install dos2unix -y

dos2unix /usr/share/vim/vim74/colors/molokai.vim

vim ~/.vimrc


--------------------------------------------
colorscheme molokai
set t_Co=256
set background=dark
set showmode
set nocompatible
set encoding=utf-8
set nobackup
set noswapfile
set tabstop=4
set shiftwidth=4
set expandtab
set smarttab
set autoread
set autoindent
set hlsearch
set ruler

set rtp+=/usr/lib/python2.7/site-packages/powerline/bindings/vim
set laststatus=2
--------------------------------------------
```
