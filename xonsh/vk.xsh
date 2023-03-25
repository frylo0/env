import os

from creds import *


class VK:
    def __init__(self):
        self.start = VKStart()
        self.fsw = VKFsw()

    def vpn(self, otp):
        key = otp
        key_prefix = creds['vk']['key_prefix']
        login = creds['vk']['login']
        vpn_path = '/home/fritylo/Downloads/barbos-100.ovpn'
        ovpn_pass_file = '/home/fritylo/vk-vpn-pass.txt'

        echo f'{login}\n{key_prefix}{key}' > @(ovpn_pass_file)
        sudo openvpn --config @(vpn_path) --auth-user-pass @(ovpn_pass_file)

    def browserstack(self):
        ~/Downloads/BrowserStackLocal-linux-x64/BrowserStackLocal

    def npmrc(self):
        enabled_npmrc = '/home/fritylo/.npmrc'
        disabled_npmrc = '/home/fritylo/._vk_npmrc'

        if os.path.isfile(enabled_npmrc):
            mv @(enabled_npmrc) @(disabled_npmrc)
            echo "VK .npmrc Disabled"
        else:
            mv @(disabled_npmrc) @(enabled_npmrc)
            echo "VK .npmrc Enabled"


class VKStart:
    def resplash(self):
        npm run copy && $NODE_OPTIONS='--max-old-space-size=1048576' npx rollup -c --environment 'BUILD:development'

    def whiteline(self):
        $NODE_OPTIONS='--max-old-space-size=1048576' npx rollup -c --environment 'mode:development,browsers:both'


class VKFsw:
    def resplash(self):
        fswatch -or ./dist \
            | xargs '-n1' '-I{}' rsync -rlptzv --progress --delete \
                ./dist/* f'lfdev8:/home/f.nikonov/resplash/dist'

    def whiteline(self):
        fswatch -or ./dist \
            | xargs '-n1' '-I{}'  rsync -rlptzv --progress --delete \
                ./dist/* f'lfdev8:/home/f.nikonov/serve'


vk = VK()