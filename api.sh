#!/bin/bash

source ~/Code/creds.sh

export PS1="\u\[$(tput sgr0)\]\[$(tput bold)\]\[\033[38;5;251m\]@\[$(tput sgr0)\]\[\033[38;5;248m\]\h\[$(tput sgr0)\] \[$(tput sgr0)\]\[$(tput bold)\]\[\033[38;5;232m\]\T\[$(tput sgr0)\]\n\[$(tput sgr0)\]\[\033[38;5;215m\]\w\[$(tput sgr0)\]\n\[$(tput sgr0)\]\[\033[38;5;226m\]\W\[$(tput sgr0)\] \[$(tput bold)\]\\$\[$(tput sgr0)\] \[$(tput sgr0)\]"


# For JoyDev TalkMe project and NPM
#export NODE_OPTIONS=--openssl-legacy-provider


#CUSTOM ALIASES
alias c='clear'

alias cd.='cd ..'
alias cd..='cd ../..'
alias cd...='cd ../../..'

alias gs='git status'
alias ga='git add'
alias ga.='git add .'
alias gb='git branch'
alias gbgo='git checkout -b'
alias gc='git commit'
alias gd='git diff'
alias gh='git hist'
alias go='git checkout'
alias ghmxc='git log hist --max-count'
alias gacm='ga . ; gcm'
alias gr='git remote'
alias pull='git pull'
alias push='git push'

alias py='python3.10'
alias mdtpl='py /media/feodoritiy/HDD/CODE/VS_PY/md_tpl/md_tpl.py'
alias dtl='node ~/Code/utils/dtl/dtl.mjs'

alias upd='sudo apt-get update'
alias upg='sudo apt-get upgrade'
alias inst='sudo apt-get install'

alias chrome='google-chrome-beta'

alias dbd='py ~/Code/utils/mysql-git-sync/dbd.py'
alias db-start='dbd start'
alias db-pull='dbd pull'
alias db-push='dbd push'

alias kolssh='ssh admin@80.245.117.198 -p 1122'

alias start-talkme='cd /var/www/talkme-front-end && sudo docker run -it talkme-front-end'

alias gm='/usr/local/bin/gm'


function crcp() {
    case $1 in
        "-f") node ~/Desktop/dtl/dtl.mjs new frity-ReactComponent $2 ;;
        "-j") node ~/Desktop/dtl/dtl.mjs new joydev-ReactComponent $2 ;;
    esac
}

function crct() {
    case $1 in
        "-f") node ~/Desktop/dtl/dtl.mjs new frity-ReactComponentContainer $2 ;;
        "-j") node ~/Desktop/dtl/dtl.mjs new joydev-ReactComponentContainer $2 ;;
    esac
}

function srun() {
   google-chrome-beta&
   code&
   sudo ~/Desktop/jVPN.sh&
}

function mcdir() {
    mkdir $1
    cd $1
}

function github() {
    git remote add origin "https://$CREDS_GITHUB_LOGIN:$CREDS_GITHUB_PASSWORD@$1"
    git branch -M master
    git push -u origin master
}

function bootto () {
    help="On new system before use:
    sudo nano /etc/default/grub
    GRUB_DEFAULT=0 => GRUB_DEFAULT=saved
    sudo update-grub
Usage:
    bootto win - booting to windows
    bootto lin - booting to linux"
    case $1 in 
        '--help') echo "$help" ;;
        'lin') sudo grub-reboot 0 && sudo reboot ;;
        'win') sudo grub-reboot 2 && sudo reboot ;;
    esac
}
function windows () {
    help="On new system before use:
    sudo nano /etc/default/grub
    GRUB_DEFAULT=0 => GRUB_DEFAULT=saved
    sudo update-grub
Usage:
    windows - booting to windows"
    if [ "$1" = '--help' ]; then
        echo "$help"
    else
       bootto win
    fi 
}

function windscribe-vpn() {
    case $1 in
        "on") 
            is_windscribe_running=$( windscribe status )
            echo "STATUS: ${is_windscribe_running:0:25}"
            if [[ "${is_windscribe_running:0:25}" == "Windscribe is not running" ]]; then
                sudo windscribe start; windscribe connect
            else
                windscribe connect
            fi
        ;;
        "off") windscribe disconnect ;;
        "info") windscribe account ;;
    esac
}

function vk-vpn() {
    key=$1
    key_prefix="$CREDS_VK_VPN_KEY_PREFIX"
    login="$CREDS_VK_VPN_LOGIN"
    vpn_path='/home/fritylo/Downloads/barbos-100.ovpn'
    ovpn_pass_file='/home/fritylo/vk-vpn-pass.txt'

    echo -e "$login\n$key_prefix$key" > "$ovpn_pass_file"
    sudo openvpn --config "$vpn_path" --auth-user-pass "$ovpn_pass_file"
}

function cbd () {
    # change bookmarked dir
    case $1 in
        "desktop") cd ~/Desktop ;;
        "downloads") cd ~/Downloads ;;
        "localhost") cd /var/www ;;
        "cloud") hdd && cd SWAP/cloud ;;
        "talkme") cd /var/www/talkme-front-end ;;
        "code") cd ~/Code ;;
    esac
}

function rename_any_ext() {
    source_name=$1
    target_name=$2
    for f in "$source_name".*; do
        mv -- "$f" "$target_name.${f#*.}"
    done
}
function raxt() {
   rename_any_ext $1 $2
}
function dupent() {
    # duplicate entity
    cp -r $1 $2
    cd $2
    raxt $1 $2
}

function mm () { 
    # move merge
    SOURCE_DIR=$1
    TARGET_DIR=$2
    sudo find $SOURCE_DIR -name '*' -type f -exec mv -f {} $TARGET_DIR \; 
}

function lh () {
    # localhost manager
    command="$1"
    subcommand="$2"

    case $command in
        --help) 
            cat <<EOHELP
    new {folder_name} {site_url} - create new site in /var/www/{folder_name}, then register site in /etc/hosts, then create new apache config, then open folder in VS Code.
        example: lh new vue_learn vue.learn
    purge {folder_name} {site_url} - remove site, created by \`lh new {folder_name} {site_url}\`
        example: lh purge vue_learn vue.learn
    cd [conf | host] - go to /etc/apache2/sites-enabled
EOHELP
        ;;
        new) 
            folder_name=$2
            site_url=$3

            folder_path="/var/www/$folder_name"

            # Create folder
            sudo mkdir "$folder_path"
            sudo chmod -R 0777 "$folder_path"

            # Update hosts
            echo -e "\n# Site folder: $folder_path\n127.0.0.1\t$site_url" | sudo tee -a /etc/hosts

            # Create apache config
            apache_conf="<VirtualHost *:80>
    # domain of virtual host
    ServerName $site_url
    ServerAlias www.$site_url
    
    # maybe used in sendmail
    ServerAdmin admin@localhost
    # defines base folder, which must be defined after
    DocumentRoot $folder_path
    
    # defining document root folder
    <Directory $folder_path>
        Options Indexes FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>

    # log configuration
    ErrorLog ${APACHE_LOG_DIR}/error.log
    CustomLog ${APACHE_LOG_DIR}/access.log combined

    <IfModule mod_dir.c>
        DirectoryIndex index.php index.pl index.cgi index.html index.xhtml index.htm
    </IfModule>
</VirtualHost>

# vim: syntax=apache ts=4 sw=4 sts=4 sr noet"
            conf_filename="$site_url.conf"
            echo "$apache_conf" | sudo tee "/etc/apache2/sites-available/$conf_filename"
            cd /etc/apache2/sites-enabled
            sudo ln -s "../sites-available/$conf_filename" "$conf_filename"
            sudo apache2ctl restart
            cd -

            # Start VS Code
            code "$folder_path"
        ;;
        purge) 
            folder_name=$2
            site_url=$3

            # Rremove folder
            folder_path="/var/www/$folder_name"
            sudo rm -r "$folder_path"

            # Update hosts, remove old data
            sudo cat /etc/hosts | sed -z "s%\n# Site folder: $folder_path\n127.0.0.1\t$site_url%%g" | sudo tee /etc/hosts

            # Remove apache config
            conf_filename="$site_url.conf"
            sudo rm "/etc/apache2/sites-available/$conf_filename"
            sudo rm "/etc/apache2/sites-enabled/$conf_filename"
            sudo rm "/etc/apache2/sites-available/host.$conf_filename"
            sudo rm "/etc/apache2/sites-enabled/host.$conf_filename"
            sudo apache2ctl restart
        ;;
        cd)
            case $subcommand in
                conf)
                    cd /etc/apache2/sites-enabled
                ;;
                host)
                    cd /var/www
                ;;
            esac
        ;;
    esac
}

function gom() {
   branch=$(git rev-parse --abbrev-ref HEAD)
   git checkout "$1"
   git pull
   git merge --no-ff "$branch"
}

function phpv() {
    local command="$1"
    
    function package-list() {
        ver=$1
        packages=("php$ver" "php$ver-fpm" "php$ver-mysql" "libapache2-mod-php$ver")
    }

    case $command in
        --help) 
            cat <<EOHELP
PHP-FPM version manager for apache2 by @fritylo.
Available commands:

  inst {ver}  install target php-fpm version
              > phpv inst 7.4
  del {ver}   remove target php-fpm version
              > phpv del 7.4
  list        list installed versions
              > phpv list
EOHELP
            ;;
            inst) 
                ver=$2
                package-list $ver
                echo $packages;
                sudo apt-get install $packages -y
            ;;
            del)
                ver=$2
                package-list $ver
                sudo apt-get purge $packages
            ;;
            list)
                dpkg --get-selections | grep -e 'php.*-fpm'
            ;;
    esac

    unset -f package-list
}
