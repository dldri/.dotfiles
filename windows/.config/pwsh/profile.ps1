# Add this to your pwsh $PROFILE
#
# Touch function
function touch {New-Item "$args" -ItemType File}

# oh-my-posh
# using catppuccin-mocha theme
oh-my-posh init pwsh --config "$env:POSH_THEMES_PATH/catppuccin_mocha.omp.json" | Invoke-Expression

# Set vim alias to run nvim
Set-Alias -Name vim -Value nvim

# zoxide setup
Invoke-Expression (& { (zoxide init powershell | Out-String) })
