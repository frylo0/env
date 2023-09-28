import os

from datetime import datetime

from creds import *


class Xsolla:
    def __init__(self):
        self.metaframe = XsollaMetaframe()


class XsollaMetaframe:
    def __init__(self):
        aliases['xsolla.metaframe.push'] = lambda args: self.push(args)

    def push(self, args):
        if (len(args) < 1):
            print('Example of usage: xsolla.metaframe.push 13-425. 13 - number of deploy today, 425 - number of task')
            return

        deploy_number = args[0]

        branch_name = $(git rev-parse --abbrev-ref HEAD).strip()
        stage_branch_name = f'stage-{deploy_number}'.lower().strip()
        today = datetime.today().strftime('%Y%m%d')
        tag_name = f'stage-{today}-{deploy_number}'

        git checkout -b @(stage_branch_name) \
        && yarn changeset \
        && yarn version-packages:stage \
        && git add . \
        && git commit -m "docs(changeset): version packages stage" \
        && git push -u origin @(stage_branch_name) \
        && git tag @(tag_name) && git push origin @(tag_name) \
        && git checkout @(branch_name)



_xsl = Xsolla()
