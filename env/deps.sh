function install_deps() {
   printf "\nInstalling dependecies...\n\n"

   sudo apt-get install imwheel

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

   printf "\nDeps have been installed!\n\n\n"
}
