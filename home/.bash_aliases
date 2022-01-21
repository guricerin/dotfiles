# ファイル操作前に確認する
alias rm='rm -i'
alias mv='mv -i'
alias cp='cp -i'

# Docker
alias dc='docker'
alias dcc='docker compose'

## 全コンテナの停止・削除、全イメージの削除を一括で行う
alias docker-purge='docker stop $(docker ps -q) && docker rmi $(docker images -q) -f'
alias docker-stop-all='docker stop $(docker ps -q)'
alias docker-rmi-all='docker rmi $(docker images -q) -f'
## 全コンテナ強制削除
alias docker-kill-all='docker rm -f $(docker ps -a -q)'
