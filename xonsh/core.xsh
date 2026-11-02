import re
import os
from datetime import datetime

def smart_indent(string: str, prefix = '', postfix = '', extra_indent = ''):
    lines = string.split('\n')

    start_i = 0
    while re.match(r'^\s*$', lines[start_i]):
        start_i += 1

    end_i = len(lines) - 1
    while re.match(r'^\s*$', lines[end_i]):
        end_i -= 1

    lines = lines[start_i:end_i+1]

    first_line = lines[0]
    indent = re.match(r'^(\s+)', first_line)

    indent = indent.groups()[0] if indent else ''

    lines = map(lambda line: line.replace(indent, '', 1), lines)
    lines = map(lambda line: extra_indent + line, lines)

    return prefix + '\n'.join(lines) + postfix


def help(title: str, help_text: str):
    year = datetime.now().year

    print(smart_indent(
        help_text, 
        prefix=f'\n   {C.Bold}{title}{C.End}\n   © fritylo {year}, MIT\n\n',
        extra_indent='   '
    ))


def get_answer(question, validate_answer):
    while True:
        answer = input(question)
        is_valid_answer = validate_answer(answer)

        if is_valid_answer:
            return answer


class Args:
    args_list = ''

    def __init__(self, args_list):
        self.args_list = args_list

    def get_options(self):
        return [arg for arg in self.args_list if arg.startswith('--') or arg.startswith('-')]

    def get_positionals(self):
        return [arg for arg in self.args_list if not arg.startswith('--') and not arg.startswith('-')]


class C:
    Header = '\033[95m'
    OkBlue = '\033[94m'
    OkCyan = '\033[96m'
    OkGreen = '\033[92m'
    Warn = '\033[93m'
    Fail = '\033[91m'
    End = '\033[0m'
    Bold = '\033[1m'
    Underline = '\033[4m'


class Env:
    is_vpn = False
    is_openvpn = False
    is_amnezia = False

    git_local_username = ''
    git_global_username = ''

    npmrc = { 'current_profile': '', 'is_current_profile': False }


    def __init__(self):
        self.update()

    def update(self):
        git_info = self.get_git_info()

        self.git_global_username = git_info['username']['global']
        self.git_local_username = git_info['username']['local']


    def get_git_info(self):
        global_username = $(git config --global user.name).strip()
        local_username = $(git config user.name).strip()

        return {
            "username": {
                "global": global_username,
                "local": local_username,
            },
        }

    
env = Env()
