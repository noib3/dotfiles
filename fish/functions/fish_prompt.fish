function fish_prompt
    powerline-shell --shell bare $status
end
# function fish_prompt --description "Write out the prompt"
#   set -l normal (set_color normal)

#   # Color the prompt differently when we're root
#   set -l color_cwd $fish_color_cwd
#   set -l prefix
#   set -l suffix "\$"

#   # If we're running via SSH, change the host color.
#   set -l color_host $fish_color_host
#   if set -q SSH_TTY
#       set color_host $fish_color_host_remote
#   end

#   echo -n -s \
#     (set_color $fish_color_user) "$USER" \
#     $normal @ \
#     (set_color $color_host) (prompt_hostname) \
#     " " \
#     (set_color --bold $color_cwd) (prompt_pwd) \
#     $normal (fish_vcs_prompt) " " $suffix " "
# end
