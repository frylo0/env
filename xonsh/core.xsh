import re

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
    print(smart_indent(
        help_text, 
        prefix=f'\n   {C.Bold}{title}{C.End}\n   © fritylo 2023, MIT\n\n',
        extra_indent='   '
    ))


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
