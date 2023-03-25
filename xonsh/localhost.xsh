from core import smart_indent, help

class Localhost:
    """Localhost Apache2 manager"""

    def __init__(self):
        aliases['lh.cd.host'] = lambda args: self.cd('host')
        aliases['lh.cd.conf'] = lambda args: self.cd('conf')
        aliases['lh.new'] = lambda args: self.new(*args)
        aliases['lh.purge'] = lambda args: self.purge(*args)
        aliases['lh.help'] = lambda args: self.help()

    
    def new(self, folder_name: str, site_url: str):
        folder_path = f'/var/www/{folder_name}'

        # Create folder
        sudo mkdir @(folder_path)
        sudo chmod -R 0777 @(folder_path)

        # Update hosts
        echo -e f'\n# Site folder: {folder_path}\n127.0.0.1\t{site_url}' | sudo tee -a /etc/hosts

        # Create apache config
        apache_conf = smart_indent(f"""
            <VirtualHost *:80>
                # Domain of virtual host
                ServerName {site_url}
                ServerAlias www.{site_url}
                
                # Maybe used in sendmail
                ServerAdmin admin@localhost
                # Defines base folder, which must be defined after
                DocumentRoot {folder_path}
                
                # Defining document root folder
                <Directory {folder_path}>
                    Options Indexes FollowSymLinks
                    AllowOverride All
                    Require all granted
                </Directory>

                # Log configuration
                ErrorLog ${{APACHE_LOG_DIR}}/error.log
                CustomLog ${{APACHE_LOG_DIR}}/access.log combined

                <IfModule mod_dir.c>
                    DirectoryIndex index.php index.pl index.cgi index.html index.xhtml index.htm
                </IfModule>
            </VirtualHost>

            # vim: syntax=apache ts=4 sw=4 sts=4 sr noet"
        """)

        conf_filename = f'{site_url}.conf'

        echo @(apache_conf) | sudo tee f'/etc/apache2/sites-available/{conf_filename}'

        cd /etc/apache2/sites-enabled
        sudo ln -s f'../sites-available/{conf_filename}' f'{conf_filename}'
        
        sudo apache2ctl restart
        cd -

        # Start VS Code
        code @(folder_path)
        

    def purge(self, folder_name: str, site_url: str):
        # Remove folder
        folder_path = f'/var/www/{folder_name}'
        sudo rm -r @(folder_path)

        # Update hosts, remove old data
        sudo cat /etc/hosts | sed -z f's%\n# Site folder: {folder_path}\n127.0.0.1\t{site_url}%%g' | sudo tee /etc/hosts

        # Remove apache config
        conf_filename = f'{site_url}.conf'
        sudo rm f'/etc/apache2/sites-available/{conf_filename}'
        sudo rm f'/etc/apache2/sites-enabled/{conf_filename}'
        sudo rm f'/etc/apache2/sites-available/host.{conf_filename}'
        sudo rm f'/etc/apache2/sites-enabled/host.{conf_filename}'
        sudo apache2ctl restart

    
    def cd(self, folder: str):
        if folder == 'conf':
            cd /etc/apache2/sites-enabled
        elif folder == 'host':
            cd /var/www
        else:
            print('Unexpected folder. Use one of this: `lh.cd(\'conf\')`, `lh.cd(\'host\')`')


    def help(self):
        help('Localhost Apache2 Manager', """
            lh.new {folder_name} {site_url}
               - creates new site in /var/www/{folder_name},
               - then register site in /etc/hosts,
               - then create new apache config,
               - then open folder in VS Code.
               example: lh.new vue_learn vue.learn
            
            lh.purge {folder_name} {site_url}
               - remove site, created by `lh.new {folder_name} {site_url}`
               example: lh.purge vue_learn vue.learn
            
            lh.cd.conf
            lh.cd.host
               - go to bokmarked dir
        """)


_lh = Localhost()
