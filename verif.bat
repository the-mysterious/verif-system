@echo off
echo Execution en tant que administrateur...

:: Vérifier s'il s'agit d'une élévation avec privilèges déjà enregistrés
>nul 2>&1 "%SYSTEMROOT%\system32\cacls.exe" "%SYSTEMROOT%\system32\config\system"

:: Si l'erreur de cacls est 0 (pas d'erreur), alors nous avons déjà les privilèges administratifs.
if '%errorlevel%' == '0' goto :continue

:: Sinon, exécuter en tant qu'administrateur
echo Set UAC = CreateObject^("Shell.Application"^) > "%temp%\getadmin.vbs"
echo UAC.ShellExecute "%~s0", "", "", "runas", 1 >> "%temp%\getadmin.vbs"
"%temp%\getadmin.vbs"
exit /B

:continue
echo Execution en tant que administrateur reussie.

setlocal enabledelayedexpansion
title  Vérification Système Windows
color 0A

:menu
cls

title VÉRIFICATION SYSTÈME WINDOWS
echo [1] Vérification fichiers système (SFC)
echo [2] Réparation image Windows (DISM)
echo [3] Vérification complète (SFC + DISM)
echo [4] Voir rapport détaillé (CBS.log)
echo [0] Quitter
echo.
set /p choix="Votre choix : "

if "%choix%"=="1" goto sfc_only
if "%choix%"=="2" goto dism_only
if "%choix%"=="3" goto full_check
if "%choix%"=="4" goto voir_log
if "%choix%"=="0" goto fin
goto menu

:: ─────────────────────────────────────────────
:sfc_only
cls
echo [*] Lancement de SFC /scannow...
echo     (Administrateur requis - peut prendre quelques minutes)
echo.
sfc /scannow
goto analyse_sfc

:: ─────────────────────────────────────────────
:dism_only
cls
echo [*] Réparation de l'image Windows avec DISM...
echo.
DISM /Online /Cleanup-Image /RestoreHealth
goto analyse_dism

:: ─────────────────────────────────────────────
:full_check
cls
echo [1/2] DISM - Réparation image Windows...
echo.
DISM /Online /Cleanup-Image /RestoreHealth
echo.
echo [2/2] SFC - Vérification des fichiers système...
echo.
sfc /scannow
goto analyse_sfc

:: ─────────────────────────────────────────────
:analyse_sfc
echo.

echo [ANALYSE DES RÉSULTATS SFC]

:: Lecture du log CBS pour détecter les problèmes
findstr /c:"cannot repair" /c:"found corrupt" "%windir%\Logs\CBS\CBS.log" >nul 2>&1
if %errorlevel%==0 (
    color 0C
    echo.
    echo  ❌ PROBLÈME DÉTECTÉ !
    echo     Des fichiers corrompus ont été trouvés et n'ont
    echo     PAS pu être réparés automatiquement.
    echo.
    echo  ➡  Conseil : Lancez d'abord DISM /RestoreHealth
    echo     puis relancez SFC /scannow.
    echo.
) else (
    findstr /c:"repaired successfully" "%windir%\Logs\CBS\CBS.log" >nul 2>&1
    if %errorlevel%==0 (
        color 0E
        echo.
        echo  ⚠  Des fichiers corrompus ont été RÉPARÉS avec succès.
        echo     Votre système est maintenant corrigé.
        echo     Un redémarrage est recommandé.
        echo.
    ) else (
        color 0A
        echo.
        echo  ✅ Aucun problème détecté !
        echo     Tous les fichiers système sont intacts.
        echo.
    )
)

echo  📄 Log complet : %windir%\Logs\CBS\CBS.log
echo --------------------------------------------------
pause
color 0A
goto menu

:: ─────────────────────────────────────────────
:analyse_dism
echo.
echo ----------------------------------------------
echo [ANALYSE DES RÉSULTATS DISM]
echo ----------------------------------------------
if %errorlevel%==0 (
    color 0A
    echo  ✅ Image Windows OK ou réparée avec succès.
) else (
    color 0C
    echo  ❌ DISM n'a pas pu réparer l'image.
    echo     Vérifiez votre connexion internet ou
    echo     utilisez un ISO Windows comme source.
)
echo ----------------------------------------------
pause
color 0A
goto menu

:: ─────────────────────────────────────────────
:voir_log
cls
echo [*] Ouverture du rapport CBS.log (50 dernières lignes)...
echo.
powershell -command "Get-Content '%windir%\Logs\CBS\CBS.log' -Tail 50"
echo.
pause
goto menu

:: ─────────────────────────────────────────────
:fin
cls
echo Au revoir !
timeout /t 2 >nul
exit