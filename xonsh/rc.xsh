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

from ai import *

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

# OpenCode install
$PATH += ['~/.opencode/bin']


__dir__ = os.path.dirname(__file__)


def apply_aliases():
    aliases['c'] = 'clear'

    aliases['cd.'] = 'cd ..'
    aliases['cd..'] = 'cd ../..'
    aliases['cd...'] = 'cd ../../..'

    aliases['py'] = 'python3'
    aliases['pip'] = 'pip3'
    aliases['dtl'] = 'node ~/Code/utils/dtl/dtl.mjs'

    aliases['upd'] = 'sudo apt-get update'
    aliases['upg'] = 'sudo apt-get upgrade'
    aliases['inst'] = 'sudo apt-get install'

    aliases['chrome'] = 'google-chrome-beta'

    aliases['mcdir'] = _mcdir
    aliases['killport'] = _kill_port
    aliases['windows'] = _windows
    aliases['hls-download'] = _hls_download

    aliases['npmrc'] = _set_npmrc_file


def _mcdir(args):
    mkdir @(args[0]) && cd @(args[0])


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

    if need_help == '--help':
        print(help)
    else:
        sudo grub-reboot 4 && sudo reboot


def _kill_port(args):
    sudo fuser -k -n tcp @(args[0]) && echo -e 'ok' || echo -e 'fail'


def _set_npmrc_file(args):
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


def _hls_download(args):
    if len(args) != 2:
        echo "Использование: hls-download 'ссылка_на_плейлист' '/путь/video.mp4'"
        return 2

    playlist_url, output_path = args
    playlist_path = output_path.removesuffix(".mp4") + ".m3u8"

    echo @(f"Скачиваю плейлист в {playlist_path}")
    curl --location --fail --show-error --retry 3 --retry-delay 2 --output @(playlist_path) @(playlist_url)

    echo @(f"Собираю видео в {output_path}")

    ffmpeg \
        -hide_banner \
        -stats \
        -y \
        -reconnect 1 \
        -reconnect_streamed 1 \
        -reconnect_delay_max 5 \
        -seg_max_retry 10 \
        -allowed_extensions ALL \
        -protocol_whitelist 'file,http,https,tcp,tls,crypto,httpproxy' \
        -i @(playlist_path) \
        -map 0 \
        -c copy \
        '-bsf:a' 'aac_adtstoasc' \
        -movflags '+faststart' \
        @(output_path)


apply_aliases()
