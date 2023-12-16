function install_deps() {
   printf "\nInstalling dependecies...\n\n"

   if command -v "imwheel" &> /dev/null; then
      echo "Imwheel already installed!"
   else
      sudo apt-get install imwheel
      echo "Imwheel has been installed!"
   fi

   if [[ -z $(sudo cat /etc/shells | grep xonsh) ]]; then
      echo 'Installing Xonsh...';

      pip3 install 'xonsh[full]' # downloading package
      echo $(which xonsh) | sudo tee -a /etc/shells # register xonsh a available shell
      sudo chsh -s $(which xonsh) # change default shell for root
      chsh -s $(which xonsh) # change default shell for current user

      echo 'Xonsh has been installed!';
   else
      echo 'Xonsh already installed!';
   fi

   if command -v "wp" &> /dev/null; then
      echo "WP-CLI already installed!"
   else
      curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar # downloading binary
      chmod +x wp-cli.phar # allow to execute
      sudo mv wp-cli.phar /usr/local/bin/wp # move to global binaries
      sudo chown $(whoami):root /usr/local/bin/wp

      echo "WP-CLI has been installed!"
   fi

   printf "\nDeps have been installed!\n\n\n"
}
