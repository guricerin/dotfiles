# Windows で使うツールを入れる。macOS・Linux の scripts/depends.sh にあたる

@(
  "Microsoft.PowerShell" # PowerShell Core
  "Git.Git"              # Claude Code は hook と Bash ツールを Git Bash で動かす
  "GitHub.cli"
  "Starship.Starship"
  "jqlang.jq"            # Claude Code の hook（assign-pr-to-me.sh）で使う
  "astral-sh.uv"         # Claude Code の hook（check-skill-md.py）を uv run で動かす
  "Gitleaks.Gitleaks"
) | ForEach-Object {
  Write-Host "Installing $_"
  winget install -e --id $_
}

# winget にないもの
@(
  "ghq"
) | ForEach-Object {
  Write-Host "Installing $_"
  scoop install $_
}

# Python 製の CLI ツール。~/.local/bin に入る
@(
  "pre-commit" # グローバルの pre-commit フック（~/.config/git/hooks/pre-commit）で使う
) | ForEach-Object {
  Write-Host "Installing $_"
  uv tool install $_
}
