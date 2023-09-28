from xonsh.tools import unthreadable, uncapturable

import os
import re

from creds import *
from localhost import *
from phpv import *
from git import *
from prompt import *
from cbd import *
from nvm_fix import *

from vk import *
from xsolla import *

from core import smart_indent


# $XONSH_SHOW_TRACEBACK = True
$COMPLETIONS_CONFIRM = True
$XONSH_AUTOPAIR = True

# Fix for root user warnings
__import__('warnings').filterwarnings('ignore', 'There is no current event loop', DeprecationWarning, 'prompt_toolkit.application.application')

# Coloured man page support
# using 'less' env vars (format is '\E[<brightness>;<colour>m')
$LESS_TERMCAP_mb = "\033[01;31m"     # begin blinking
$LESS_TERMCAP_md = "\033[01;31m"     # begin bold
$LESS_TERMCAP_me = "\033[0m"         # end mode
$LESS_TERMCAP_so = "\033[01;44;36m"  # begin standout-mode (bottom of screen)
$LESS_TERMCAP_se = "\033[0m"         # end standout-mode
$LESS_TERMCAP_us = "\033[00;36m"     # begin underline
$LESS_TERMCAP_ue = "\033[0m"         # end underline


__dir__ = os.path.dirname(__file__)


def apply_aliases():
    aliases['c'] = 'clear'

    aliases['cd.'] = 'cd ..'
    aliases['cd..'] = 'cd ../..'
    aliases['cd...'] = 'cd ../../..'

    aliases['py'] = 'python3.10'
    aliases['mdtpl'] = 'py /media/feodoritiy/HDD/CODE/VS_PY/md_tpl/md_tpl.py'
    aliases['dtl'] = 'node ~/Code/utils/dtl/dtl.mjs'

    aliases['upd'] = 'sudo apt-get update'
    aliases['upg'] = 'sudo apt-get upgrade'
    aliases['inst'] = 'sudo apt-get install'

    aliases['chrome'] = 'google-chrome-beta'

    aliases['dbd'] = 'py ~/Code/utils/mysql-git-sync/dbd.py'
    aliases['db-start'] = 'dbd start'
    aliases['db-pull'] = 'dbd pull'
    aliases['db-push'] = 'dbd push'

    aliases['kolssh'] = 'ssh admin@80.245.117.198 -p 1122'

    aliases['start-talkme'] = 'cd /var/www/talkme-front-end && sudo docker run -it talkme-front-end'

    aliases['gm'] = '/usr/local/bin/gm'

    aliases['bootto'] = _bootto
    aliases['windows'] = _windows

    aliases['mcdir'] = _mcdir
    aliases['raxt'] = _raxt


def _mcdir(args):
    mkdir @(args[0]) && cd @(args[0])


def _raxt(args):
    filename = args[0]
    new_filename = args[1]

    cwd = os.getcwd()
    files = os.listdir(cwd)

    was_replacement = False

    for file in files:
        filepath = os.path.join(cwd, file)
        fileext = re.sub(r'^.*?\.', '.', file)
        new_file = new_filename + fileext
        new_filepath = os.path.join(cwd, new_file)

        match = re.match('^' + re.escape(filename) + '.*$', file)

        if match:
            was_replacement = True
            print(f'{file} >> {new_file}')
            mv @(filepath) @(new_filepath)

    if not was_replacement:
        print('\n[!] Nothing to replace\n')
        pwd
        print('')
        ls -la


def _bootto(args):
    system, = args
    
    help = smart_indent("""
        On new system before use:
            sudo nano /etc/default/grub
            GRUB_DEFAULT=0 => GRUB_DEFAULT=saved
            sudo update-grub
        Usage:
            bootto win - booting to windows
            bootto lin - booting to linux
    """)

    if system == 'help':
        print(help)
    elif system == 'lin':
        sudo grub-reboot 0 && sudo reboot
    elif system == 'win':
        sudo grub-reboot 2 && sudo reboot


def _windows(args):
    help = smart_indent("""
        On new system before use:
            sudo nano /etc/default/grub
            GRUB_DEFAULT=0 => GRUB_DEFAULT=saved
            sudo update-grub
        Usage:
            windows - booting to windows
    """, prefix='\n', extra_indent='    ')

    need_help = len(args) > 0 && args[0]

    if need_help == 'help':
        print(help)
    else:
        bootto win


apply_aliases()
