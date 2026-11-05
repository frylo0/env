import os
import sys
import datetime
import subprocess

from creds import *
from core import env, Args, help


class WB:
    def __init__(self):
        aliases['wb.vpn'] = lambda args: self.vpn(args[0])
        aliases['wb.git_repo_sign'] = lambda args: self.git_repo_sign()
        aliases['wb.dep'] = lambda args: self.dep(args)
        aliases['wb.fix_mcp_oauth'] = 'socat TCP6-LISTEN:19876,bind=[::1],reuseaddr,fork TCP4:127.0.0.1:19876'

    def vpn(self, enable):
        if (enable == 'on'):
            sudo systemctl start wb_vpn
            sudo systemctl status wb_vpn
            return
        elif (enable == 'off'):
            sudo systemctl stop wb_vpn
            sudo systemctl status wb_vpn
            return

        try:
            nmcli con up id wb2026
            print("\nVPN is up. Press Ctrl+C to disconnect...")

            $RAISE_SUBPROC_ERROR = True
            while True:
                sleep 3600

        except (subprocess.CalledProcessError):
            $RAISE_SUBPROC_ERROR = False
            nmcli con down id wb2026

    def git_repo_sign(self):
        wb_username = creds['wb']['user_name']
        wb_email = creds['wb']['user_email']

        git config '--local' core.sshCommand "ssh -i ~/.ssh/wb-gitlab -F /dev/null"

        git config '--local' user.signingKey "~/.ssh/wb-gitlab.pub"
        git config '--local' user.name @(wb_username)
        git config '--local' user.email @(wb_email)

        git config '--local' '--bool' commit.gpgsign true

        git config '--local' gpg.format ssh

    def dep(self, args):
        target_branch = args[0]
        current_branch = self._get_current_branch()
        
        if (self._exists_branch(target_branch)):
            git checkout @(target_branch) \
            && git reset --hard @(current_branch) \
            && git push -f
        else:
            git checkout -b @(target_branch) \
            && git push -u origin @(target_branch)

        git checkout @(current_branch)


_wb = WB()
