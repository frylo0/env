from core import help

class PhpV:
    def __init__(self):
        aliases['phpv.list'] = lambda args: self.list()
        aliases['phpv.inst'] = lambda args: self.install(args[0])
        aliases['phpv.del'] = lambda args: self.delete(args[0])
        aliases['phpv.help'] = lambda args: self.help()


    def _packages_str(self, ver):
        return ' '.join([
            f"php{ver}", 
            f"php{ver}-fpm", 
            f"php{ver}-mysql", 
            f"libapache2-mod-php{ver}",
        ])


    def install(self, ver):
        packages = self._packages_str(ver)
        echo @(packages)
        sudo apt-get install @(packages) -y


    def delete(self, ver):
        packages = self._packages_str(ver)
        sudo apt-get purge @(packages)


    def list(self):
        dpkg --get-selections | grep -e 'php.*-fpm'


    def help(self):
        help('PHP-FPM Version Manager for Apache2', """
            phpv.inst {ver} 
                install target php-fpm version
                > phpv inst 7.4

            phpv.del {ver}
                remove target php-fpm version
                > phpv del 7.4

            phpv.list
                list installed versions
                > phpv list
        """)
        
_phpv = PhpV()