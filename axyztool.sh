#!/bin/bash

# Função para encontrar sublinks em uma página
encontrar_sublinks() {
    local url=$1
    local sublinks=()
    local link
    local sublink
    local base_url=$(echo "$url" | sed 's/[^/]*$//')

    # Faz o download do conteúdo da página e procura por links
    wget -q -O - "$url" | \
        grep -o '<a [^>]*href=['"'"'"][^"'"'"']*['"'"'"]' | \
        sed -e 's/<a href=["'"'"']//' -e 's/["'"'"']$//' | \
        while read -r link; do
            sublink=$(echo "$link" | grep -E '^(http|https)://' || echo "$base_url$link")
            echo "$sublink"
        done
}

# Função para verificar vulnerabilidades de injeção de scripts (XSS)
verificar_xss() {
    local url=$1
    local response=$(wget --server-response -q -O - "$url" 2>&1)
    local status_code=$(echo "$response" | awk '/^  HTTP/{print $2}')
    
    if [ "$status_code" == "200" ]; then
        echo -e "Status: \e[31m$status_code\e[0m - OK"
    else
        echo -e "Status: \e[31m$status_code\e[0m - Error"
    fi

    local xss_vulnerabilidades=$(echo "$response" | grep -i -E '<script|<img|onerror|javascript:')
    
    if [ -n "$xss_vulnerabilidades" ]; then
        echo -e "\nPotenciais vulnerabilidades de XSS encontradas em: $url"
        echo "$xss_vulnerabilidades" | while IFS= read -r line; do
            echo "$line" | sed 's/^/  /'
        done
    else
        echo -e "\nNenhuma vulnerabilidade de XSS encontrada em: $url"
    fi
}

# Função principal do programa
main() {
    clear
    echo " ________     ___    ___ ___    ___ ________          ________  ________  ________  ________      "
    echo "|\   __  \   |\  \  /  /|\  \  /  /|\_____  \        |\   ____\|\   ____\|\   __  \|\   ___  \    "
    echo "\ \  \|\  \  \ \  \/  / | \  \/  / /\|___/  /|       \ \  \___|\ \  \___|\ \  \|\  \ \  \\ \  \   "
    echo " \ \   __  \  \ \    / / \ \    / /     /  / /        \ \_____  \ \  \    \ \   __  \ \  \\ \  \  "
    echo "  \ \  \ \  \  /     \/   \/  /  /     /  /_/__        \|____|\  \ \  \____\ \  \ \  \ \  \\ \  \ "
    echo "   \ \__\ \__\/  /\   \ __/  / /      |\________\        ____\_\  \ \_______\ \__\ \__\ \__\\ \__\ "
    echo "    \|__|\|__/__/ /\ __\\___/ /        \|_______|       |\_________\|_______|\|__|\|__|\|__| \|__| "
    echo "             |__|/ \|__\|___|/                          \|_________|                              "
    echo "                     \______/                                                         "
    echo "===================================================="
    echo "AXYZ SCAN - Red Team tool"
    echo "Desenvolvido por axyzsec e N E S Group"
    
    while true; do
        echo -e "\nMenu:"
        echo "1. Fazer scan de sublinks"
        echo "2. Verificar vulnerabilidades de XSS"
        echo "3. Abrir Discord"
        echo "4. Sair"
        
        read -p "Escolha uma opção: " escolha
        
        case $escolha in
            1)
                read -p "Digite o site-alvo para escanear sublinks: " site_alvo
                echo -e "\nScanning target: $site_alvo\n"
                sublinks=$(encontrar_sublinks "$site_alvo")
                echo "Sublinks encontrados:"
                for sublink in "${sublinks[@]}"; do
                    echo "$sublink"
                done
                ;;
            2)
                read -p "Digite o URL para verificar vulnerabilidades de XSS: " url_xss
                echo -e "\nVerificando vulnerabilidades de XSS em: $url_xss"
                verificar_xss "$url_xss"
                ;;
            3)
                echo -e "\nAbrindo o Discord..."
                xdg-open "https://discord.gg/RCz78XuxWu" || echo "Não foi possível abrir o Discord."
                ;;
            4)
                echo -e "\nEncerrando o programa. Siga @axyzsec no instagram e outras redes sociais!"
                exit 0
                ;;
            *)
                echo -e "\nOpção inválida. Por favor, escolha uma opção válida."
                ;;
        esac
    done
}

main
