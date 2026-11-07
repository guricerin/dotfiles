# -------------------------------------------------------------------------------------------
## alias

# ls
Set-Alias -Name "l" -Value Get-ChildItem
Set-Alias -Name "ll" -Value Get-ChildItem
Set-Alias -Name "note" -Value "C:\bin\Notepad++\notepad++.exe"
# git
Set-Alias -Name "g" -Value git
# docker
Set-Alias -Name "dc" -Value docker
Set-Alias -Name "dcc" -Value docker-compose
function Docker-Exec() {
    docker exec -it $args
}
Set-Alias -Name "dce" -Value Docker-Exec

function gs() {
    git status
}

# -------------------------------------------------------------------------------------------
## OSC 7
# カレントディレクトリを OSC 7 で端末に知らせる（WezTerm のタブ名に使う）
# PowerShell の cd はプロセスのカレントディレクトリを変えないため、WezTerm からは見えない
# https://starship.rs/advanced-config/#custom-pre-prompt-and-pre-execution-commands-in-powershell
function Invoke-Starship-PreCommand {
    $loc = $executionContext.SessionState.Path.CurrentLocation
    if ($loc.Provider.Name -eq "FileSystem") {
        $esc = [char]27
        $path = $loc.ProviderPath -replace "\\", "/"
        $host.ui.Write("$esc]7;file://${env:COMPUTERNAME}/${path}$esc\")
    }
}

# -------------------------------------------------------------------------------------------
## starship
# add the end of this file
Invoke-Expression (&starship init powershell)
