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
from wb import *

from core import smart_indent, Args


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
    aliases['mx'] = _mx
    aliases['raxt'] = _raxt

    aliases['killport'] = _kill_port

    aliases['npmrc'] = _npmrc


def _mcdir(args):
    mkdir @(args[0]) && cd @(args[0])


def _mx(args):
    help = smart_indent("""
        # Make File/Dir Extra
        Create files or dirs with valid user and group at same time

        ## Exmaples of usage:
        $ mx -f user:group u+x,g+rw,o-a name-of-file.txt
        $ mx -d user:group u+x,g+rw,o-a name-of-dir

        ## Options
        -h, --help  - Show help
        -f, --file  - Create file
        -d, --dir   - Create dir
        -s, --sudo  - Prefix all commands with sudo
        -b, --debug - Enable debug mode

        ## FAQ
        1) Problems with sudo permissions?
        - Simply run `mx` command with sudo
    """)

    args = Args(args)

    options = args.get_options()
    positionals = args.get_positionals()

    target = ''

    is_file = ('-f' in options) or ('--file' in options)
    is_dir = ('-d' in options) or ('--dir' in options)
    is_help = ('-h' in options) or ('--help' in options)
    is_debug = ('-b' in options) or ('--debug' in options)
    is_sudo = ('-s' in options) or ('--sudo' in options)

    if is_debug:
        print('Options:', options)
        print('Positionals:', positionals)
        print('Is File:', is_file)
        print('Is Dir:', is_dir)
        print('Is Help:', is_help)
        print('Is Debug:', is_debug)
        print('Is Sudo:', is_sudo)

    if is_help:
        print(help)
        return

    if is_file and is_dir:
        print('Unexpected file and dir usage together. Run `mx --help` for help')
        return

    if is_file:
        target = 'file'
    elif is_dir:
        target = 'directory'
    else:
        print(f'Unexpected target "{target}", abort.')
        return

    if is_debug:
        print('Target:', target) 

    user_group, permissions, target_name = positionals
    permissions = permissions.split(',')

    if not user_group or not permissions or not target_name:
        print('Unexpected params for command. Run `mx --help` for help')
        return

    if target == 'directory':
        if is_sudo:
            sudo mkdir @(target_name)
            sudo chown -R @(user_group) @(target_name)
            
            for permission in permissions:
                sudo chmod -R @(permission) @(target_name)
        else:
            mkdir @(target_name)
            chown -R @(user_group) @(target_name)
            
            for permission in permissions:
                chmod -R @(permission) @(target_name)

        print(f'Dir "{target_name}" created.')
    elif target == 'file':
        if is_sudo:
            sudo touch @(target_name)
            sudo chown @(user_group) @(target_name)
            
            for permission in permissions:
                sudo chmod @(permission) @(target_name)
        else:
            touch @(target_name)
            chown @(user_group) @(target_name)
            
            for permission in permissions:
                chmod @(permission) @(target_name)

        print(f'File "{target_name}" created.')
    else:
        print(f'Unexpected prommatical type for target "{target}", check code for validity')
        return


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
        sudo grub-reboot 4 && sudo reboot


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

def _kill_port(args):
	port = args[0]
	pid = $(sudo lsof -t f'-i:{port}').strip()
	sudo kill -9 @(pid)

def _npmrc(args):
    help = smart_indent("""
        Tool to turn on/off npmrc file. Work like toggle

        # Syntax
        
        npmrc {on|off|use|list} {name_of_npmrc_profile}

        # Examples of usage

        npmrc off profile1
        npmrc on profile2
        npmrc use profile3 // off current + on profile 3
        npmrc list

        # Register profile

        To register profile with name "example":
        1. Add file ~/.npmrc_example
        2. Add "### profile: example" line to the to of file

        New profile registered, run `npmrc list` to check.
    """)

    is_help = args[0] == '--help' or args[0] == '-h'

    if is_help:
        print(help)
        return

    mode = args[0]

    is_on = mode == 'on'
    is_off = mode == 'off'
    is_use = mode == 'use'
    is_list = mode == 'list'

    if not is_on and not is_off and not is_use and not is_list:
        print(f'Error: Invalid mode {mode}')
        return

    get_npmrc_filename = lambda profile: os.path.expanduser(f'~/.npmrc_{profile}')

    default_npmrc = os.path.expanduser('~/.npmrc')
    is_default_exists = os.path.exists(default_npmrc)

    profile = args[1] if not is_list else ''
    current_profile = ''

    if is_default_exists:
        with open(default_npmrc, 'r') as file:
            file_contents = file.read()
            match = re.search(r'### profile: (.*)', file_contents)
            current_profile = match.group(1) if match else ''

    profile_npmrc = get_npmrc_filename(profile)
    current_npmrc = get_npmrc_filename(current_profile)

    is_profile_exists = os.path.exists(profile_npmrc)
    if_current_exists = os.path.exists(current_npmrc)

    has_current_profile = is_default_exists and current_profile != ''

    if is_on:
        if not is_profile_exists:
            print(f'Error: "{profile_npmrc}" file do not exists, it is required for this operation.')
            return
        if has_current_profile:
            print(f'Error: There is profile "{current_profile}" in use. Try `use` command to switch profiles.')
            return

        os.rename(profile_npmrc, default_npmrc)
        
        print(f'Success!! Now using profile "{profile}".')
        return

    elif is_off:
        if is_profile_exists:
            print(f'Error: "{profile_npmrc}" file already exists. Try to remove it to solve issue.')
            return
        if not is_default_exists:
            print(f'Error: There is no "{default_npmrc}", so cannot disable profile.')
            return

        os.rename(default_npmrc, profile_npmrc)

        print(f'Success!! STOP using profile "{profile}".')
        return

    elif is_use:
        if is_default_exists:
            os.rename(default_npmrc, current_npmrc)

        if not is_profile_exists:
            print(f'Error: "{profile_npmrc}" file do not exists, it is required for this operation.')
            return
        
        os.rename(profile_npmrc, default_npmrc)

        print(f'Success!! Switched from "{current_profile}" to "{profile}"')
        return

    elif is_list:
        profiles = [file for file in os.listdir(os.path.expanduser('~')) if file.startswith(".npmrc_")]

        if has_current_profile:
            profiles.append(current_npmrc.replace(os.path.expanduser('~/.npmrc_'), ''))

        if len(profiles) == 0:
            print('No profiles available.')
            return

        print('Available profiles:\n')

        for profile in profiles:
            profile_clear = profile.replace('.npmrc_', '')
            print(f' - {profile_clear}')

        print('\nListed', len(profiles), 'profiles.')

        if has_current_profile:
            print(f'\nCurrent profile is "{current_profile}"')

        return


apply_aliases()
