#requires -version 7
# Windows 用のセットアップ。setup.sh と同じく、ファイルごとのシムリンクを $env:UserProfile に作成する
# - home-common/（macOS・Linux と共通）と home-windows/（Windows でだけ使う）の全部をリンクする
# - シムリンクの作成には開発者モードが必要
Param(
  [Alias("n")][switch]$DryRun = $false,
  [Alias("y")][switch]$Yes = $false
)
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# https://patorjk.com/software/taag/#p=display&f=Efti%20Wall&t=dotfiles
Set-Variable -Name LOGO -Option Constant -Value @'

        ...       #   ___                          _          .      .      _     _         |"|
   o,*,(o o)      #  <_*_>         ()_()         _|_|_      .  .:::.      o' \,=./ `o      _|_|_       `  _ ,  '
  8(o o)(_)Ooo    #  (o o)         (o o)         (o o)        :(o o):  .     (o o)         (o o)      -  (o)o)  -
ooO-(_)---Ooo-----8---(_)--Ooo-ooO--`o'--Ooo-ooO--(_)--Ooo-ooO--(_)--Ooo-ooO--(_)--Ooo-ooO--(_)--Ooo--ooO'(_)--Ooo-

'@

Set-Variable -Name DOTFILES_HOMES -Option Constant -Value @(
  (Join-Path $PSScriptRoot "home-common"),
  (Join-Path $PSScriptRoot "home-windows")
)

function IsDeveloperMode() {
  $res = Get-ItemPropertyValue registry::HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock -Name AllowDevelopmentWithoutDevLicense -ErrorAction SilentlyContinue
  return $res -eq 1
}

function PrintError($message) {
  Write-Host "  [x] $message" -ForegroundColor Red
}

function PrintWarn($message) {
  Write-Host "  [!] $message" -ForegroundColor Yellow
}

function PrintExpected($message) {
  Write-Host "  [?] $message" -ForegroundColor Blue
}

# リンク元とリンク先の組を返す
function DotFilePairs() {
  $pairs = @()
  foreach ($dir in $DOTFILES_HOMES) {
    Get-ChildItem -LiteralPath $dir -File -Force -Recurse | ForEach-Object {
      $rel = [IO.Path]::GetRelativePath($dir, $_.FullName).Replace("\", "/")
      $pairs += [PSCustomObject]@{ Rel = $rel; Src = $_.FullName }
    }
  }

  # home-common/ と home-windows/ の両方に同じパスがあると、どちらを張るか決められない
  $dups = $pairs | Group-Object -Property Rel | Where-Object { $_.Count -gt 1 }
  if ($dups) {
    $dups | ForEach-Object { PrintError -message "home-common/ と home-windows/ の両方にある: $($_.Name)" }
    exit 1
  }

  return $pairs | ForEach-Object {
    [PSCustomObject]@{ Src = $_.Src; Dst = Join-Path $env:UserProfile $_.Rel }
  }
}

function PrintExpectation($pairs) {
  $pairs | ForEach-Object { PrintExpected -message "$($_.Dst) -> $($_.Src)" }
}

function ConfirmApply() {
  if ($Yes) {
    return
  }
  $answer = Read-Host "続けますか？ [y/N]"
  if ($answer -notin @("y", "Y", "yes", "YES")) {
    Write-Host "中止しました"
    exit 1
  }
}

function BuildSymlinks($pairs) {
  $pairs | ForEach-Object {
    $src = $_.Src
    $dst = $_.Dst
    $parent = Split-Path -Path $dst -Parent
    if (!(Test-Path -LiteralPath $parent)) {
      New-Item -ItemType Directory -Path $parent -Force > $null
    }
    $item = Get-Item -LiteralPath $dst -Force -ErrorAction SilentlyContinue
    if ($item) {
      # シムリンクでない実ファイルは、setup.sh と同じく .bak に退避する
      if (!$item.LinkType) {
        Copy-Item -LiteralPath $dst -Destination "$dst.bak" -Force
      }
      Remove-Item -LiteralPath $dst -Force
    }
    New-Item -ItemType SymbolicLink -Path $dst -Value $src > $null
  }
}

function Main() {
  if (!$IsWindows) {
    PrintError -message "Windows で実行してください。macOS・Linux では setup.sh を使います"
    exit 1
  }

  $pairs = DotFilePairs
  if ($DryRun) {
    Write-Host "dry-run`n"
    if (!(IsDeveloperMode)) {
      PrintWarn -message "シムリンクの作成には開発者モードが必要です"
    }
    PrintExpectation -pairs $pairs
    return
  }

  if (!(IsDeveloperMode)) {
    PrintError -message "シムリンクの作成には開発者モードが必要です"
    exit 1
  }
  PrintExpectation -pairs $pairs
  Write-Host
  ConfirmApply
  Write-Host $LOGO
  Write-Host "apply`n"
  BuildSymlinks -pairs $pairs
  Write-Host "`n ようこそ、$env:UserName の世界へ。`n そして、あなたの帰還に感謝します。"
}

Main
