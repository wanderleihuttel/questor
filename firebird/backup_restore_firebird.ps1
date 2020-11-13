<# 
==================================================================================
Script para efetuar Backup/Restore de Banco de Dados Firebird
Versão:   2.1 -  27/08/2020
Autor:    Wanderlei Hüttel
Email:    wanderlei.huttel@gmail.com
Linkedin: https://www.linkedin.com/in/wanderleihuttel/
==================================================================================

----------------------------
Criar um Bot no Telegram
----------------------------
Adicionar o usuário @botfather para a sua conta do telegram ou acessar o endereço https://telegram.me/BotFather e seguir os passos abaixo:
- /newbot - criar um novo bot
- Digitar um nome para o bot. Exemplo: Backup Test Bot
- Digitar um nome de usário para o bot. Precisar terminar com 'bot' Exemplo: (backup_test_bot)

Anotar o token da API (API TOKEN):
Exemplo:
1234567890:AAFd2sDMplKGyoajsPWARnSOwa9EqHiy17U

Enviar uma mensagem para o bot @userinfobot que ele vai retornar o valor do chat_id

Agora basta informar os valores da api_token e chat_id no script:

$api_token="colocar_aqui_a_api_token"
$chat_id="colocar_aqui_o_chat_id"

#>

# Forçar o uso do TLS 1.2
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

#==================================================================================
# FUNÇÃO PARA RETORNAR TAMANHO DE ARQUIVO CORRETAMENTE
#==================================================================================
    Function Format-FileSize() {
        Param ([decimal]$Bytes)
        If ($Bytes -ge 1GB) {[string]::Format("{0:N2}GB ", $Bytes / 1GB)}
        ElseIf ($Bytes -ge 1MB) {[string]::Format("{0:N2}MB ", $Bytes / 1MB)}
        ElseIf ($Bytes -ge 1KB) {[string]::Format("{0:N2}KB ", $Bytes / 1KB)}
        ElseIf ($Bytes -gt 0) {[string]::Format("{0:N2}Bytes", $Bytes)}
        Else {""}
    }


#==================================================================================
# FUNÇÃO PARA RETORNAR DIFERENÇA ENTRE DATAS
#==================================================================================
    Function DateDiff-DateTime() {
        Param ($DateTimeStart, $DateTimeEnd)
        $ts = New-TimeSpan –Start $DateTimeStart –End $DateTimeEnd
        $TotalHora = "{0:hh}:{0:mm}:{0:ss}" -f $ts #.Negate() #Caso fique negativo
        return $TotalHora
    }

    
#==================================================================================
# ALIASES DE PROGRAMAS
#==================================================================================
    Set-Alias -Name gbak -Value "C:\Program Files\Firebird\Firebird_2_5\bin\gbak.exe"


#==================================================================================
# CONFIGURAÇÕES TELEGRAM
#==================================================================================
    $api_token="colocar_aqui_a_api_token"
    $chat_id="colocar_aqui_o_chat_id"
    $url = "https://api.telegram.org/bot${api_token}/sendMessage?chat_id=${chat_id}&text="


#==================================================================================
# DEFINIÇÃO E INICIALIZAÇÃO DE VARIÁVEIS
#==================================================================================
    $timeStartScript  = Get-Date                                                # Obter a data/hora atual
    $timeStartScriptStr  = $timeStartScript.toString('ddMMMyyyy_HHmmss')        # Formata o horário de início do backup para usar no nome do arquivo

    # O diretório raiz do Questor está dividido em 3 subdiretórios (basequente, backup e restore)
    $dirQuestorRaiz      = "C:\Dados\firebird"                                  # Diretório do banco de dados
    
    $dirBackup           = "${dirQuestorRaiz}\backup"                           # Diretório raiz da pasta questor
    $dirRestore          = "${dirQuestorRaiz}\restore"                          # Diretório raiz da pasta questor
    $dirBaseQuestor      = "${dirQuestorRaiz}\basequente"                       # Diretório raiz da pasta questor

    $arqBD               = "basequestor.fdb"                                    # Nome do arquivo da basequente questor
    $arqBD_Log           = "basequestor_log.fdb"                                # Nome do arquivo da basequente questor
    
    $arqBD_Backup        = "basequestor_${timeStartScriptStr}.fbk"              # Nome do arquivo da basequente do backup
    $arqBD_Log_Backup    = "basequestor_log_${timeStartScriptStr}.fbk"          # Nome do arquivo da baselog do backup

    $arqBD_Restore       = "basequestor_${timeStartScriptStr}_nova.fdb"         # Nome do arquivo da basequente de restore
    $arqBD_Log_Restore   = "basequestor_log_${timeStartScriptStr}_nova.fdb"     # Nome do arquivo da baselog de restore

    $arqLogBackup1       = "basequestor_${timeStartScriptStr}.txt"              # Nome do arquivo de log da basesequente de backup
    $arqLogBackup2       = "basequestor_log_${timeStartScriptStr}.txt"          # Nome do arquivo de log da baselog de backup

    $arqLogRestore1      = "basequestor_nova_${timeStartScriptStr}.txt"         # Nome do arquivo de log da basequente de restore
    $arqLogRestore2      = "basequestor_log_nova_${timeStartScriptStr}.txt"     # Nome do arquivo de log da baselog de restore
    
    $arqLogStatus        = "log_status_restore.txt"

    $fbUser              = "sysdba"                                             # Usuário Firebird
    $fbPassword          = "masterkey"                                          # Senha Firebird


    # Exclui arquivos anteriores dos diretorios backup e restore
    Get-ChildItem $dirBackup | 
    Foreach-Object {
        $content = $_.FullName
        Remove-Item $content
    }

    Get-ChildItem $dirRestore | 
    Foreach-Object {
        $content = $_.FullName
        Remove-Item $content
    }


#==================================================================================
# BACKUP DO BANCO FIREBIRD
#==================================================================================
    Write-Host "`n================================================================"
    Write-Host " Backup Firebird Iniciado:   $(${timeStartScript}.toString('dd/MM/yyyy HH:mm:ss'))"
    Write-Host "================================================================"
    $msg  = "===== 💾 Backup/Restore Firebird @???@ =====\n\n" # ✅    

    # Backup Arquivo do Banco 
    Write-Host "`n   ========== Backup BD =========="
    $msg += "========== Backup BD ==========\n"
    $DataHoraInicialTemp  = Get-Date
    #Executa o comando de backup
    gbak -B -se localhost/3050:service_mgr ${dirBaseQuestor}\${arqBD} ${dirBackup}\${arqBD_Backup} -Y ${dirBackup}\${arqLogBackup1} -user ${fbUser} -pass ${fbPassword}
    $DataHoraFinalTemp  = Get-Date
    
    # Mensagens
    $retorno_backup_bd = $?
    $arquivo1 = Get-Item "${dirBackup}\${arqBD_Backup}"
    Write-Host "   Arquivo:  $arqBD"
    Write-Host "   Dump FBK: $(${file1}.name)"
    $msg += "Arquivo=$arqBD\n"
    $msg += "Dump FBK=$($arquivo1.name)\n"
    $msg += "Tamanho=$(Format-FileSize ${file1}.length)\n"
    $msg += "Duração=$(DateDiff-DateTime ${DataHoraInicialTemp} ${DataHoraFinalTemp})\n"
    if($retorno_backup_bd){
        Write-Host "   Status:   Backup OK"
        $msg += "Status=Backup OK\n\n"
    }
    else{
        Write-Host "   Status:   Backup Error"
        $msg += "Status=Backup Error\n\n"
    }
    Write-Host "   Duração:  $(DateDiff-DateTime ${DataHoraInicialTemp} ${DataHoraFinalTemp})`n"
    
    
    # Backup Arquivo do Banco Log 
    Write-Host "   ========== Backup BD_LOG =========="
    $msg += "========== Backup BD_LOG ==========\n"
    $DataHoraInicialTemp  = Get-Date
    
    #Executa o comando de backup
    gbak -B -se localhost/3050:service_mgr $dirBaseQuestor\$arqBD_Log $dirBackup\$arqBD_Log_Backup -Y $dirBackup\$arqLogBackup2 -user $fbUser -pass $fbPassword
    $DataHoraFinalTemp  = Get-Date
    
    # Mensagens
    $retorno_backup_bd_log = $?
    $arquivo2 = Get-Item "${dirBackup}\${arqBD_Log_Backup}"
    Write-Host "   Arquivo:  ${arqBD}"
    Write-Host "   Dump FBK: $(${file2}.name)"
    $msg += "Arquivo=${arqBD_Log}\n"
    $msg += "Dump FBK=$(${file2}.name)\n"
    $msg += "Tamanho=$(Format-FileSize ${file2}.length)\n"
    $msg += "Duração=$(DateDiff-DateTime ${DataHoraInicialTemp} ${DataHoraFinalTemp})\n"
    if($retorno_backup_bd_log){
        Write-Host "   Status:   Backup OK"
        $msg += "Status=Backup OK\n\n"
    }
    else{
        Write-Host "   Status:   Backup Error"
        $msg += "Status=Backup Error\n\n"
    }
    Write-Host "   Duração:  $(DateDiff-DateTime ${DataHoraInicialTemp} ${DataHoraFinalTemp})`n`n"

#==================================================================================
# RESTORE DO BANCO FIREBIRD
#==================================================================================
    $DataHoraInicialTemp  = Get-Date
    Write-Host "================================================================"
    Write-Host " Restore Firebird Iniciado: $(${DataHoraInicialTemp}.toString('dd/MM/yyyy HH:mm:ss'))"
    Write-Host "================================================================"
    
    # Restore Arquivo do Banco 
    Write-Host "`n   ========== Restore BD =========="
    $msg += "========== Restore BD ==========\n"
    $DataHoraInicialTemp  = Get-Date
    
    #Executa o comando de restore
    gbak -C -se localhost/3050:service_mgr ${dirBackup}\${arqBD_Backup} ${dirRestore}\${arqBD_Restore} -Y ${dirRestore}\${arqLogRestore1} -user ${fbUser} -pass ${fbPassword}
    $DataHoraFinalTemp  = Get-Date
    
    # Mensagens
    $retorno_restore_bd = $?
    $arquivo1 = Get-Item "${dirRestore}\${arqBD_Restore}"
    Write-Host "   Dump FBK: ${arqBD_Backup}"
    Write-Host "   Arquivo:  $(${file1}.name)"
    $msg += "Dump FBK=${arqBD_Backup}\n"
    $msg += "Arquivo=${arqBD_Restore}\n"
    $msg += "Tamanho=$(Format-FileSize ${file1}.length)\n"
    $msg += "Duração=$(DateDiff-DateTime ${DataHoraInicialTemp} ${DataHoraFinalTemp})\n"
    if($retorno_restore_bd){
        Write-Host "   Status:   Restore OK"
        $msg += "Status=Restore OK\n\n"
    }
    else{
        Write-Host "   Status:   Restore Error"
        $msg += "Status=Restore OK\n\n"
    }
    Write-Host "   Duração:  $(DateDiff-DateTime ${DataHoraInicialTemp} ${DataHoraFinalTemp})`n"
    
    
    # Restore Arquivo do Banco Log
    Write-Host "   ========== Restore BD_LOG =========="
    $msg += "========== Restore BD_LOG ==========\n"
    $DataHoraInicialTemp  = Get-Date
    
    #Executa o comando de restore
    gbak -C -se localhost/3050:service_mgr ${dirBackup}\${arqBD_Log_Backup} ${dirRestore}\${arqBD_Log_Restore} -Y ${dirRestore}\${arqLogRestore2} -user ${fbUser} -pass ${fbPassword}
    $DataHoraFinalTemp  = Get-Date
    
    # Mensagens
    $retorno_restore_bd_log = $?
    $arquivo2 = Get-Item "${dirRestore}\${arqBD_Log_Restore}"
    Write-Host "   Dump FBK: ${arqBD_Log_Backup}"
    Write-Host "   Arquivo:  $(${file2}.name)"
    $msg += "Arquivo=${arqBD_Log_Restore}\n"
    $msg += "Tamanho=$(Format-FileSize ${file2}.length)\n"
    $msg += "Duração=$(DateDiff-DateTime ${DataHoraInicialTemp} ${DataHoraFinalTemp})\n"
    if($retorno_restore_bd_log){
        Write-Host "   Status:   Restore OK"
        $msg += "Status=Restore OK\n\n"
    }
    else{
        Write-Host "   Status:   Restore Error"
        $msg += "Status=Restore Error\n\n"
    }
    Write-Host "   Duração:  $(DateDiff-DateTime ${DataHoraInicialTemp} ${DataHoraFinalTemp})`n"

    # Caso tenha erro altera para o ícone de errro
    if(${retorno_restore_bd} -and ${retorno_restore_bd_log} -and ${retorno_backup_bd} -and ${retorno_backup_bd_log}){
        $msg = ${msg}.replace("@???@","✅")  # OK
    }
    else{
        $msg = ${msg}.replace("@???@","❌")  # Error
    }

    # Renomear arquivos para minúsculo
    if(${retorno_restore_bd} -and ${retorno_restore_bd_log}){
        $arquivo1 = Get-Item "${dirRestore}\${arqBD_Restore}"
        $arquivo2 = Get-Item "${dirRestore}\${arqBD_Log_Restore}"
        Get-Item $arquivo1 | Rename-Item -NewName { $_.name.ToLower() }
        Get-Item $arquivo2 | Rename-Item -NewName { $_.name.ToLower() }
    }

#==================================================================================
# ENVIO DE MENSAGEM VIA TELEGRAM
#==================================================================================
    $timeFinishScript = Get-Date                            # Obter a data atual
    $msg += "===============================\n"
    $msg += "Backup Iniciado:      $(${timeStartScript}.toString('HH:mm:ss'))\n"
    $msg += "Backup Terminado:     $(${timeFinishScript}.toString('HH:mm:ss'))\n"
    $msg += "Duração Aproximada:   $(DateDiff-DateTime ${timeStartScript} ${timeFinishScript})\n"
    $msg += "===============================\n"
    Write-Host "`n================================================================"
    Write-Host " Tempo Aproximado do Backup:           $(DateDiff-DateTime ${timeStartScript} ${timeFinishScript})"
    Write-Host "================================================================`n"
    
    $msg = ${msg}.replace("\n","`n")
    Write-Output ${msg} | Out-File -Encoding UTF8 ${dirRestore}\${arqLogStatus}
    $msg = Get-Content -path ${dirRestore}\${arqLogStatus} -Raw
    $msg = ${msg}.replace("\n","%0A")
    $url = [System.String]::Concat(${url},${msg})
    $output = (New-Object System.Net.WebClient).DownloadString($url)
    
    Exit 0
