#requires -version 7
# Windows 用のセットアップ。setup.sh と同じく、ファイルごとのシムリンクを $env:UserProfile に作成する
# - home/ からは windows/common-files.txt に書いたものだけ、windows/home/ からは全部をリンクする
# - シムリンクの作成には開発者モードが必要
Param(
  [Alias("n")][switch]$DryRun = $false,
  [Alias("y")][switch]$Yes = $false
)
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

Set-Variable -Name DOTFILES_HOME -Option Constant -Value (Join-Path $PSScriptRoot "home")
Set-Variable -Name WINDOWS_HOME -Option Constant -Value (Join-Path $PSScriptRoot "windows" "home")
Set-Variable -Name COMMON_FILES -Option Constant -Value (Join-Path $PSScriptRoot "windows" "common-files.txt")

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

function PrintSuccess($message) {
  Write-Host "  [o] $message" -ForegroundColor Green
}

function PrintExpected($message) {
  Write-Host "  [?] $message" -ForegroundColor Blue
}

# home/ 配下のパスが common-files.txt のどれかに当てはまるか。末尾が / の行はディレクトリ配下すべてに当てはまる
function IsCommonFile($relPath, $patterns) {
  foreach ($pattern in $patterns) {
    if ($pattern.EndsWith("/")) {
      if ($relPath.StartsWith($pattern)) { return $true }
    }
    elseif ($relPath -eq $pattern) {
      return $true
    }
  }
  return $false
}

# リンク元とリンク先の組を返す
function DotFilePairs() {
  $patterns = Get-Content -LiteralPath $COMMON_FILES |
  ForEach-Object { $_.Trim() } |
  Where-Object { $_ -ne "" -and !$_.StartsWith("#") }

  $pairs = @()
  Get-ChildItem -LiteralPath $DOTFILES_HOME -File -Force -Recurse | ForEach-Object {
    $rel = [IO.Path]::GetRelativePath($DOTFILES_HOME, $_.FullName).Replace("\", "/")
    if (IsCommonFile -relPath $rel -patterns $patterns) {
      $pairs += [PSCustomObject]@{ Rel = $rel; Src = $_.FullName }
    }
  }
  Get-ChildItem -LiteralPath $WINDOWS_HOME -File -Force -Recurse | ForEach-Object {
    $rel = [IO.Path]::GetRelativePath($WINDOWS_HOME, $_.FullName).Replace("\", "/")
    $pairs += [PSCustomObject]@{ Rel = $rel; Src = $_.FullName }
  }

  # home/ と windows/home/ の両方に同じパスがあると、どちらを張るか決められない
  $dups = $pairs | Group-Object -Property Rel | Where-Object { $_.Count -gt 1 }
  if ($dups) {
    $dups | ForEach-Object { PrintError -message "home/ と windows/home/ の両方にある: $($_.Name)" }
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
    PrintSuccess -message "$dst -> $src"
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
  Write-Host "apply`n"
  BuildSymlinks -pairs $pairs
}

Main
