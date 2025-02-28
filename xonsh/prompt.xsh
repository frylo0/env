import os

from core import env

def _prompt():
    global env

    env.update()

    ___gradient_ = '{BACKGROUND_#222} {BACKGROUND_#333} {BACKGROUND_#444} {BACKGROUND_#555} '
    _gradient___ = ' {BACKGROUND_#444} {BACKGROUND_#333} {BACKGROUND_#222} {RESET} '
    time = '{#aaa}{localtime}'
    _I_ = ' {#aaa}│ '
    cwd = '{#70a5db}{cwd_dir}{BOLD_#4ca5ff}{cwd_base}'
    dollar = '{BOLD_CYAN}{prompt_end}'
    node_ver = '{BOLD_#70bc29}🌿 ' + $(node --version).strip()

    vpn_openvpn = '{BOLD_INTENSE_RED}🔒' if env.is_openvpn else ''
    vpn_amnezia = '{BOLD_INTENSE_RED}🧿' if env.is_amnezia else ''
    vpn_wireguard = '{BOLD_INTENSE_PURPLE}🐲' if env.is_wgvpn else ''
    
    vpn = [ vpn_wireguard, vpn_openvpn, vpn_amnezia ]
    vpn = filter(lambda item: item != '', vpn)
    vpn = ', '.join(vpn)

    npmrc = ''

    if env.npmrc['is_current_profile']:
        npmrc = '{BOLD_#ffea00}🔑 ' + env.npmrc['current_profile']

    git_username = env.git_local_username
    git_person = ''

    if git_username == env.git_global_username:
        git_person = '{BOLD_INTENSE_YELLOW}🧔 ' + git_username
    else:
        git_person = '{BOLD_INTENSE_YELLOW}🧝 ' + git_username

    warns = [ vpn, npmrc, git_person ]
    warns = filter(lambda item: item != '', warns)
    warns = '{BOLD_WHITE}, '.join(warns)

    if warns:
        warns = _I_ + warns

    prompt = '\n' + \
        '{#555}╭─' + f'{___gradient_}{time}{_I_}{cwd}{_I_}{node_ver}{warns}{_gradient___}' + '{gitstatus}' + '\n' + \
        '{#555}╰─' + dollar + ' '

    return prompt


$PROMPT = _prompt

#$RIGHT_PROMPT = 'Right'
#$BOTTOM_TOOLBAR = 'Bottom'
