def _prompt():
    ___gradient_ = '{BACKGROUND_#222} {BACKGROUND_#333} {BACKGROUND_#444} {BACKGROUND_#555} '
    _gradient___ = ' {BACKGROUND_#444} {BACKGROUND_#333} {BACKGROUND_#222} {RESET} '
    time = '{#aaa}{localtime}'
    _I_ = ' {#aaa}│ '
    cwd = '{#70a5db}{cwd_dir}{BOLD_#4ca5ff}{cwd_base}'
    dollar = '{BOLD_CYAN}{prompt_end}'
    node_ver = '{BOLD_INTENSE_GREEN}Node ' + $(node --version).strip()

    prompt = '\n' + \
        '{#555}╭─' + f'{___gradient_}{time}{_I_}{cwd}{_I_}{node_ver}{_gradient___}' + '{gitstatus}' + '\n' + \
        '{#555}╰─' + dollar + ' '

    return prompt


$PROMPT = _prompt

#$RIGHT_PROMPT = 'Right'
#$BOTTOM_TOOLBAR = 'Bottom'