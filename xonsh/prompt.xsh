import os

def _prompt():
    ___gradient_ = '{BACKGROUND_#222} {BACKGROUND_#333} {BACKGROUND_#444} {BACKGROUND_#555} '
    _gradient___ = ' {BACKGROUND_#444} {BACKGROUND_#333} {BACKGROUND_#222} {RESET} '
    time = '{#aaa}{localtime}'
    _I_ = ' {#aaa}│ '
    cwd = '{#70a5db}{cwd_dir}{BOLD_#4ca5ff}{cwd_base}'
    dollar = '{BOLD_CYAN}{prompt_end}'
    node_ver = '{BOLD_INTENSE_GREEN}Node ' + $(node --version).strip()

    is_vpn_active = len($(ps -aux | grep 'openvpn').strip().split('\n')) > 1
    vpn = '{BOLD_INTENSE_RED}VPN' if is_vpn_active else ''

    is_npmrc = os.path.isfile('/home/fritylo/.npmrc')
    npmrc = '{BOLD_#ffa500}NPMRC' if is_npmrc else ''

    warns = [ vpn, npmrc ]
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
