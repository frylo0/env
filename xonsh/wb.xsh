import os

from creds import *
from core import env


class WB:
    def __init__(self):
        aliases['wb.vpn'] = lambda args: self.vpn()

    def vpn(self):
        if (env.is_vpn):
            print('🛑 Another VPN is enabled, abort')
            return

        vpn_path = '/home/fritylo/Downloads/wb.ovpn'
        openvpn --config @(vpn_path)


_wb = WB()
