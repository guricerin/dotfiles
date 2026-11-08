# -------------------------------------------------------------------------------------------
## alias

Set-Alias -Name "note" -Value "C:\bin\Notepad++\notepad++.exe"

# -------------------------------------------------------------------------------------------
## abbr
# fish の abbr、home-unix/.zshrc の zsh-abbr と同じく、略語を元のコマンドに展開する
# スペースか Enter を押したときに、コマンドの位置（行頭か、; | & の直後）の略語を展開する
$global:Abbr = @{
    l  = 'ls'
    g  = 'git'
    gs = 'git status'
    f  = 'fzf'
}

function global:Expand-Abbr {
    $line = $null
    $cursor = $null
    [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$line, [ref]$cursor)
    $before = $line.Substring(0, $cursor)
    if ($before -match '(?:^|[;|&])\s*([^\s;|&]+)$' -and $global:Abbr.ContainsKey($Matches[1])) {
        $word = $Matches[1]
        [Microsoft.PowerShell.PSConsoleReadLine]::Replace($cursor - $word.Length, $word.Length, $global:Abbr[$word])
    }
}

Set-PSReadLineKeyHandler -Key Spacebar -BriefDescription "abbr-expand-space" -Description "略語を展開してからスペースを入れる" -ScriptBlock {
    Expand-Abbr
    [Microsoft.PowerShell.PSConsoleReadLine]::Insert(' ')
}

Set-PSReadLineKeyHandler -Key Enter -BriefDescription "abbr-expand-enter" -Description "略語を展開してから実行する" -ScriptBlock {
    Expand-Abbr
    [Microsoft.PowerShell.PSConsoleReadLine]::AcceptLine()
}

# -------------------------------------------------------------------------------------------
## Ctrl + G で リポジトリ移動
# home-unix/.zshrc の ghq-fzf-cd と同じ動き。ghq と fzf がないときは割り当てない
if ((Get-Command ghq -ErrorAction SilentlyContinue) -and (Get-Command fzf -ErrorAction SilentlyContinue)) {
    Set-PSReadLineKeyHandler -Chord Ctrl+g -BriefDescription "ghq-fzf-cd" -Description "ghq のリポジトリを fzf で選んで移動する" -ScriptBlock {
        $dir = ghq list --full-path | fzf
        if ($dir) {
            Set-Location $dir
        }
        # 移動先をプロンプト（starship）に反映する
        [Microsoft.PowerShell.PSConsoleReadLine]::InvokePrompt()
    }
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
