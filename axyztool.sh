#!/bin/bash

#atualizaçãov2

# Função para verificar as dependências necessárias
verificar_dependencias() {
    echo "Verificando dependências..."
    
    local dependencies=("wget" "xdg-open" "curl")

    for dependency in "${dependencies[@]}"; do
        if command -v "$dependency" &>/dev/null; then
            echo "Dependência '$dependency' encontrada."
        else
            echo "Dependência '$dependency' não encontrada. Tentando instalar..."
            if sudo apt-get install -y "$dependency"; then
                echo "Dependência '$dependency' instalada com sucesso."
            else
                echo "Erro ao instalar a dependência '$dependency'."
            fi
        fi
    done

    echo -e "\nTodas as dependências foram verificadas e atualizadas.\n"
    echo "Siga @axyzsec e entre no Discord: https://discord.gg/6PedzWUz59"
}

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
            echo "Vulnerabilidade encontrada na linha:"
            grep -n "$line" <(wget -q -O - "$url")
        done
    else
        echo -e "\nNenhuma vulnerabilidade de XSS encontrada em: $url"
    fi
}

# Função para testar HTML Injection (HTMLi)
testar_html_injection() {
    local url=$1
    local payload="<script>alert('HTML Injection Test')</script>"
    local response=$(wget -qO- --post-data="$payload" "$url" 2>&1)
    
    if [[ "$response" =~ "HTML Injection Test" ]]; then
        echo "Vulnerabilidade de HTML Injection detectada em: $url"
        echo "Vulnerabilidade encontrada na linha:"
        grep -n "$payload" <(wget -q -O - "$url")
    else
        echo "Não foi possível detectar vulnerabilidade de HTML Injection em: $url"
    fi
}

# Função para testar SQL Injection (SQLi)
testar_sql_injection() {
    local url=$1
    local payload="' OR '1'='1"
    local response=$(wget -qO- "$url?$payload" 2>&1)
    
    if [[ "$response" =~ "admin" ]]; then
        echo "Vulnerabilidade de SQL Injection detectada em: $url"

        # Verificando o tipo de SQL Injection
        if [[ "$response" =~ "SQL syntax" ]]; then
            echo "Tipo de SQL Injection: SQL Syntax Error (error de sintaxis)"
            echo "Esta é uma vulnerabilidade de SQL Injection baseada em erros de sintaxe no SQL, o que pode indicar que a consulta injetada foi executada com sucesso."
        elif [[ "$response" =~ "mysqli_fetch_array" ]]; then
            echo "Tipo de SQL Injection: Blind SQL Injection "
            echo "Esta é uma vulnerabilidade de SQL Injection cega, onde o aplicativo não fornece informações úteis na resposta, mas é possível inferir a existência de uma vulnerabilidade com base no comportamento do aplicativo."
        else
            echo "Tipo de SQL Injection: Indeterminado"
            echo "Não foi possível determinar o tipo específico de SQL Injection. Recomenda-se uma análise mais aprofundada."
        fi

        echo "Para explorar essa vulnerabilidade, você pode tentar modificar os parâmetros de consulta para executar comandos SQL maliciosos, como 'UNION SELECT', 'DROP TABLE', entre outros."
        grep -n "$payload" <(wget -q -O - "$url")
    else
        echo "Não foi possível detectar vulnerabilidade de SQL Injection em: $url"
    fi
}


# Função para testar Server-Side Request Forgery (SSRF)
testar_ssrf() {
    local url=$1
    local internal_url="http://localhost"
    local response=$(wget -qO- --header="Host: $internal_url" "$url" 2>&1)
    
    if [[ "$response" =~ "localhost" ]]; then
        echo "Vulnerabilidade de SSRF detectada em: $url"
        echo "Vulnerabilidade encontrada na linha:"
        grep -n "$internal_url" <(wget -q -O - "$url")
    else
        echo "Não foi possível detectar vulnerabilidade de SSRF em: $url"
    fi
}

# Função para verificar vulnerabilidades de Cross-Site Request Forgery (CSRF)
verificar_csrf() {
    local url=$1
    local response=$(curl -s -I "$url" | grep -i "csrf")

    if [ -n "$response" ]; then
        echo "Potencial vulnerabilidade de CSRF detectada em: $url"
    else
        echo "Não foi possível detectar vulnerabilidade de CSRF em: $url"
    fi
}

# Função para verificar cabeçalhos HTTP
verificar_cabecalhos_http() {
    local url=$1
    local response=$(curl -s -I "$url")

    echo "Cabeçalhos HTTP para: $url"
    echo "$response"
}

# Função para exibir o menu principal
exibir_menu() {
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
    echo "                                                                                          "
    echo "AXYZ SCAN - Red Team tool"
    echo "Desenvolvido por axyzsec e N E S Group"
    echo "===================================================="
    echo "                                                                                          "
    echo "1. Fazer scan de sublinks"
    echo "2. Verificar vulnerabilidades de XSS"
    echo "3. Testar HTML Injection (HTMLi)"
    echo "4. Testar SQL Injection (SQLi)"
    echo "5. Testar Server-Side Request Forgery (SSRF)"
    echo "6. Verificar vulnerabilidades de Cross-Site Request Forgery (CSRF)"
    echo "7. Verificar cabeçalhos HTTP"
    echo "8. Verificar dependências"
    echo "9. Abrir Discord"
    echo "0. Sair"
}

# Função principal do programa
main() {
    verificar_dependencias
    
    while true; do
        exibir_menu
        
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
                read -p "Digite o URL para testar HTML Injection: " url_htmli
                echo -e "\nTestando HTML Injection em: $url_htmli"
                testar_html_injection "$url_htmli"
                ;;
            4)
                read -p "Digite o URL para testar SQL Injection: " url_sqli
                echo -e "\nTestando SQL Injection em: $url_sqli"
                testar_sql_injection "$url_sqli"
                ;;
            5)
                read -p "Digite o URL para testar SSRF: " url_ssrf
                echo -e "\nTestando SSRF em: $url_ssrf"
                testar_ssrf "$url_ssrf"
                ;;
            6)
                read -p "Digite o URL para testar CSRF: " url_csrf
                echo -e "\nTestando CSRF em: $url_csrf"
                verificar_csrf "$url_csrf"
                ;;
            7)
                read -p "Digite o URL para verificar cabeçalhos HTTP: " url_http_headers
                echo -e "\nVerificando cabeçalhos HTTP para: $url_http_headers"
                verificar_cabecalhos_http "$url_http_headers"
                ;;
            8)
                verificar_dependencias
                ;;
            9)
                echo -e "\nAbrindo o Discord..."
                xdg-open "https://discord.gg/RCz78XuxWu" || echo "Não foi possível abrir o Discord."
                ;;
            0)
                echo -e "\nEncerrando o programa. Siga @axyzsec no instagram e outras redes sociais!"
                exit 0
                ;;
            *)
                echo -e "\nOpção inválida. Por favor, escolha uma opção válida."
                ;;
        esac
        
        read -p "Pressione Enter para voltar ao menu ou digite 'sair' para encerrar o programa: " continuar
        if [[ "$continuar" == "sair" ]]; then
            echo -e "\nEncerrando o programa. Siga @axyzsec no instagram e outras redes sociais!"
            exit 0
        fi
        clear
    done
}

main
