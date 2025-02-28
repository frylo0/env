import os
import datetime

from creds import *
from core import env


class WB:
    def __init__(self):
        self.deploy = WBDeploy()

        aliases['wb.vpn'] = lambda args: self.vpn()

    def vpn(self):
        if (env.is_vpn):
            print('🛑 Another VPN is enabled, abort')
            return
        
        login = creds['wb']['vpn_login']
        password = creds['wb']['vpn_pass']
        
        vpn_path = os.path.expanduser('~/Downloads/wb.ovpn')
        vpn_auth_file = os.path.expanduser('~/wb-vpn-auth.txt')
        
        echo f'{password}' > @(vpn_auth_file)
        sudo openvpn --config @(vpn_path) --askpass @(vpn_auth_file)


class WBDeploy:
    def __init__(self):
        aliases['wb.deploy.prod'] = lambda args: self.prod()
        aliases['wb.deploy.stage'] = lambda args: self.stage()
        aliases['wb.deploy.feat'] = lambda args: self.feat()

    def _exists_branch(self, branch_name):
        return $(git rev-parse --verify f'{branch_name}') != ''

    def _get_main_branch(self):
        return 'master' if self._exists_branch('master') else 'main'

    def _get_last_tag(self):
        return $(git describe --abbrev=0)

    def _get_current_branch(self):
        branch = $(git rev-parse --abbrev-ref HEAD)
        return branch

    def _checkout_or_merge_then_push(self, target_branch):
        current_branch = self._get_current_branch()
        
        if (self._exists_branch(target_branch)):
            git checkout @(target_branch) \
            && git merge @(current_branch) \
            && git push
        else:
            git checkout -b @(target_branch) \
            && git push -u origin @(target_branch)

        git checkout @(current_branch)

    def _two_step_notify(self, host_name, durations):
        tg_token = creds['personal']['telegramBot']['token']
        tg_api = creds['personal']['telegramBot']['api']
        tg_chat_id = creds['personal']['telegramBot']['chats']['notify']

        now = datetime.datetime.now().time()

        duration_ci_check = durations.get('ci_check') or '30s'
        duration_ci_gen = durations.get('ci_gen') or '1m'
        duration_build = durations.get('build') or '9m'
        duration_deploy = durations.get('deploy') or '5m'

        echo f'\n\n[{now}] Wait {duration_ci_check} + {duration_ci_gen} + {duration_build}...' \
        && sleep @(duration_ci_check) \
        && sleep @(duration_ci_gen) \
        && sleep @(duration_build) \
        && curl -s -X POST f"{tg_api}{tg_token}/sendMessage" \
            -H "Content-Type: application/json" \
            -d f'{{ "chat_id": "{tg_chat_id}", "text": "🧱 *Build* finished ({host_name})", "parse_mode": "Markdown" }}' \
        && echo f'\n\n[{now}] Wait {duration_deploy}...' \
        && sleep @(duration_deploy) \
        && curl -s -X POST f"{tg_api}{tg_token}/sendMessage" \
            -H "Content-Type: application/json" \
            -d f'{{ "chat_id": "{tg_chat_id}", "text": "🚀 *Deploy* finished ({host_name})", "parse_mode": "Markdown" }}' \
        && echo f'\n\n[{now}] Success!'

    def prod(self):
        main_branch = self._get_main_branch()
        last_tag = self._get_last_tag()

        tag_name = input('Tag name: ')
        tag_message = input('Tag description: ')

        git checkout @(main_branch) \
        && git pull \
        && git tag -a @(tag_name) -m @(tag_message) \
        && git push --tags

        self._two_step_notify('prod', { 'deploy': '5m' })

    def stage(self):
        release_branch = input('Release branch name: ')
        current_branch = self._get_current_branch()

        self._checkout_or_merge_then_push(release_branch)
        self._two_step_notify(f'{release_branch}', { 'deploy': '3m' })
    
    def feat(self):
        feature_branch = input('Feature branch name: ')
        current_branch = self._get_current_branch()

        self._checkout_or_merge_then_push(feature_branch)
        self._two_step_notify(f'{feature_branch}', { 'deploy': '3m' })


_wb = WB()
