# vim: expandtab

def main():
    aliases['go'] = 'git checkout'
    aliases['gs'] = 'git status'
    aliases['ga'] = 'git add'
    aliases['branch'] = 'git branch'
    aliases['commit'] = 'git commit'
    aliases['merge'] = 'git merge'
    aliases['pull'] = 'git pull'
    aliases['push'] = 'git push'
    aliases['stash'] = 'git stash'
    aliases['reset'] = 'git reset'
    aliases['revert'] = 'git revert'
    aliases['remote'] = 'git remote'
    aliases['rebase'] = 'git rebase'
    aliases['chpick'] = 'git cherry-pick'
    aliases['chpickm'] = 'git cherry-pick -m 1'
    aliases['chpicks'] = 'git cherry-pick --skip'
    aliases['chpickc'] = 'git cherry-pick --continue'
    aliases['revoke'] = 'node ~/Code/utils/git-revoke/index.mjs'

    aliases['tagp'] = _tagp

    aliases['creb'] = _creb
    aliases['renb'] = _renb
    aliases['delb'] = _delb

    aliases['gop'] = _gop
    aliases['gos'] = _gos
    aliases['gom'] = _gom
    aliases['goml'] = _goml

    aliases['reprune'] = _reprune


def _tagp(args): 
    git tag @(args[0]) && git push origin @(args[0])
    

def _gop(args): 
    git checkout -b @(args[0]) && git push -u origin @(args[0])

def _gos(args):
    git stash -u && git checkout @(args[0])

def _gom(args):
    branch = $(git rev-parse --abbrev-ref HEAD)
    bash -c f'git checkout {args[0]} && git pull && git merge --no-ff {branch}'

def _goml(args):
    branch = $(git rev-parse --abbrev-ref HEAD)
    bash -c f'git checkout {args[0]} && git merge --no-ff {branch}'

def _creb(args):
    name = args[0]

    git branch @(name) && git push -u origin f'{name}:{name}'

def _renb(args):
    curr_name = args[0]
    new_name = args[1]

    git branch -m @(curr_name) @(new_name) && git push --set-upstream origin @(new_name) && git push -d origin @(curr_name)

def _delb(args):
    name = args[0]

    git branch -D @(name) && git push -d origin @(name)

def _reprune(args):
    # `git fetch --prune` - deletes remote branches
    # `git branch --v` - lists the local branches verbosely
    # `grep "\[gone\]"` - finds all the branches whose remote branch is gone
    # `awk '{print $1}'` - outputs only the name of the matching local branches
    # `xargs git branch -D` - deletes all the matching local branches

    git fetch --prune && git branch --v | grep "\\[gone\\]" | awk '{print $1}' | xargs git branch -D


main()
