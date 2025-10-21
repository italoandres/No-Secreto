@echo off
echo Instalando Firebase CLI...
npm install -g firebase-tools

echo Fazendo login no Firebase...
firebase login

echo Fazendo deploy dos indices...
firebase deploy --only firestore:indexes

pause