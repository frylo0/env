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

    aliases['gop'] = _gop
    aliases['gos'] = _gos
    aliases['gom'] = _gom


def _tagp(args): 
    git tag @(args[0]) && git push origin @(args[0])
    

def _gop(args): 
    git checkout -b @(args[0]) && git push -u origin @(args[0])
    
def _gos(args):
    git stash -u && git checkout @(args[0])

def _gom(args):
    branch = $(git rev-parse --abbrev-ref HEAD)

    git checkout @(args[0]) \
    && git pull \
    && git merge --no-ff @(branch)


main()