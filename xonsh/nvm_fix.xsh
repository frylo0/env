def _nvm_fix():
    $NVM_SYMLINK_CURRENT = "true"
    $NVM_DIR = f"{$HOME}/.nvm"
    source-bash --suppress-skip-message f"{$NVM_DIR}/nvm.sh"  # This loads nvm
    $PATH.insert(0, f"{$NVM_DIR}/current/bin")

_nvm_fix()