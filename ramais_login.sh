#!/bin/bash
################################################################################
# Escallo: agentes_login.sh
#
# @author Josimar Rocha <josimar@futurotec.com.br>
# @version 20220721
################################################################################

# Configuracoes basicas do script
myVersion="20220721"

# Configuracoes para consulta no banco de dados
sqlModeAutoFile='/etc/mysql/debian.cnf'
dataBase=futurofone
sqlOptions="--defaults-extra-file=${sqlModeAutoFile} --batch -N ${dataBase} -e"

# Imprime caracteres unica e exclusivamente para organizar a saida dos valores apresentados
function separator() {
        for i in $(seq 1 95)0; do echo "_"; done | tr '\n' '_'
        echo -e "\n"
}


# Realiza as operacoes necessárias e apresenta os valores obtidos
# @param ${1} tempo de referencia para consulta
function lastX {

	#Verifica se o valor passado como parametro esta dentro do intervalo esperado. Caso contrário, imprime as orientações de uso
        if [[ "$1" != "90" && "$1" != "60" && "$1" != 30 ]]; then
                echo -e "Por favor, informe um parâmetro válido (90|60|30) \n"
                exit
        fi

        separator

	#imprime o valor de referencia passado como parametro e a data atual do servidor
        echo -e "Versao do script: '$myVersion'"
        echo -e "Valor referência: '$1' dias"
        echo -e "Data de referência: `date`"

	separator

	#adiciona "-" (negativo) ao valor passado como parametro e armazena em uma nova variavel. Necessario para definir o "intervalo" da consulta, que deve ser negativo
        parameter=-${1}
	
	#array com todos os ramais cadastrados
        mapfile -t extensionAll < <(mysql ${sqlOptions} 'SELECT 'numero_ramal' FROM 'pbx_ramal' ORDER BY 'numero_ramal' ASC')

	#array com todos os ramais cadastrados, somente do tipo PA CE ou PA SE
        mapfile -t extensionAllPa < <(mysql ${sqlOptions} 'SELECT 'numero_ramal' FROM 'pbx_ramal' WHERE 'tipo_ramal'="2" OR 'tipo_ramal'="5" ORDER BY 'numero_ramal' ASC')

	#array com todos os ramais que foram usados para login nos ultimos x dias (conforme passagem de parametro)
        mapfile -t extensionLogin < <(mysql ${sqlOptions} 'SELECT DISTINCT 'ramal_cdrqueuelogin' AS ramal FROM 'pbx_cdrqueuelogin' WHERE 'time_cdrqueuelogin' BETWEEN DATE_ADD( CURRENT_DATE( ) , INTERVAL '${parameter}' DAY ) AND DATE_ADD( CURRENT_DATE( ) , INTERVAL +1 DAY ) ORDER BY 'ramal_cdrqueuelogin' ASC' | grep -v NULL)

	#imprime todos os ramais cadastrados
        echo -e "Ramais do cliente:"
        echo -e "${extensionAll[@]}" | tr ' ' ','
        echo -e "Quantidade: ${#extensionAll[@]}"

        separator

	#imprime todos os ramais que foram usados para login nos ultimos x dias (conforme passagem de parametro)
        echo -e "Ramais que logaram no painel nos ultimos '$1' dias:"
        echo -e "**Pode conter ramais INATIVOS"
        echo -e "${extensionLogin[@]}" | tr ' ' ','
        echo -e "Quantidade: ${#extensionLogin[@]}"

	separator

	#compara a lista/array contenado todos os ramais cadastrados com a lista/array contendo todos os ramais que foram usados para login nos ultimos x dias (conforme passagem de parametro), e armazena os ramais cadastrados que nao constam na lista/array de ramais que foram usados para login nos ultimos x dias (conforme passagem de parametro)
        mapfile -t commExtensionResult < \
                <(comm -23 \
                        <(IFS=$'\n'; echo "${extensionAll[*]}" | sort) \
                        <(IFS=$'\n'; echo "${extensionLogin[*]}" | sort) \
                )

	#imprime os ramais cadastrados que foram usados para login nos ultimos x dias (conforme passagem de parametro)
        echo -e "Ramais que não logaram no painel nos ultimos '$1' dias:"
        echo -e "${commExtensionResult[@]}" | tr ' ' ','

	separator 

	#compara a lista/array contenado todos os ramais cadastrados do tipo PACE ou PASE com a lista/array contendo todos os ramais que foram usados para login nos ultimos x dias (conforme passagem de parametro), e armazena os ramais cadastrados que nao constam na lista/array de ramais que foram usados para login nos ultimos x dias (conforme passagem de parametro)
        mapfile -t commExtensionResultPa < \
                <(comm -23 \
                        <(IFS=$'\n'; echo "${extensionAllPa[*]}" | sort) \
                        <(IFS=$'\n'; echo "${extensionLogin[*]}" | sort) \
                )
        
	#imprime os ramais cadastrados que foram usados para login nos ultimos x dias (conforme passagem de parametro), somente do tipo PA CE ou PA SE
	echo -e "Ramais do tipo PA que não logaram no painel nos ultimos '$1' dias:"
        echo -e "${commExtensionResultPa[@]}" | tr ' ' ','
        }

lastX $1

separator

# FIM
