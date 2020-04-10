# ------------------------- ZSH CONFIG FILE -------------------------

mod_dir=~/.config/zsh/modules
#for module in $(/bin/ls -A $mod_dir); do source $mod_dir/$module; done

source $mod_dir/shell-options.zsh
source $mod_dir/PATH.zsh
source $mod_dir/export_vars.zsh
source $mod_dir/colors.zsh
source $mod_dir/vimode.zsh
source $mod_dir/prompt.zsh
source $mod_dir/tab_autocomplete.zsh
source $mod_dir/key_bindings.zsh
source $mod_dir/aliases.zsh
source $mod_dir/transmission.zsh
source $mod_dir/custom_clear.zsh

# brew install zsh-syntax-highlighting
source /usr/local/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# brew install zsh-autosuggestions
source /usr/local/share/zsh-autosuggestions/zsh-autosuggestions.zsh

# git clone https://github.com/kutsan/zsh-system-clipboard /usr/local/share/zsh-system-clipboard
source /usr/local/share/zsh-system-clipboard/zsh-system-clipboard.zsh

# git clone https://github.com/hlissner/zsh-autopair /usr/local/share/zsh-autopair
source /usr/local/share/zsh-autopair/autopair.zsh
