@echo off
set timestamp=%date:~-4%%date:~3,2%%date:~0,2%_%time:~0,2%%time:~3,2%%time:~6,2%
set timestamp=%timestamp: =0%
git add .
git commit -m "BACKUP AUTO: %timestamp%"
git tag backup-%timestamp%
echo ? Backup criado: backup-%timestamp%
