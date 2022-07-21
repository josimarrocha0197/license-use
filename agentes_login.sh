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
function lastX() {
	
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

	#array com todos os agentes cadastrados, somente ativos e "nao excluidos"
	mapfile -t agentList < <(mysql ${sqlOptions}' SELECT 'codigo_agente' as login_agente FROM 'pbx_agente' WHERE 'status_agente'="1" AND 'excluido_agente'="0"')

	#array com todos os agentes que fizeram login nos ultimos x dias (conforme passagem de parametro)
	mapfile -t agentLogin < <(mysql ${sqlOptions}' SELECT DISTINCT 'agent_cdrqueuelogin' AS agente FROM 'pbx_cdrqueuelogin' WHERE 'time_cdrqueuelogin' BETWEEN DATE_ADD( CURRENT_DATE( ) , INTERVAL '${parameter}' DAY ) AND DATE_ADD( CURRENT_DATE( ) , INTERVAL +1 DAY )')
	
	#imprime todos agentes ativos e "nao excluidos" cadastrados e a quantidade
	echo -e "Agentes cadastrados ATIVOS:"
        echo -e "${agentList[@]}" | tr ' ' ','
        echo -e "Quantidade: ${#agentList[@]}"

        separator

	#imprime todos os agentes que logaram no painel nos ultimos x dias (conforme passagem de parametro)
        echo -e "Agentes que logaram no painel nos ultimos '$1' dias:"
	echo -e "**Pode conter agentes INATIVOS"
        echo -e "${agentLogin[@]}" | tr ' ' ','
        echo -e "Quantidade: ${#agentLogin[@]}"
	
	#compara a lista/array de agentes ativos e "nao excluidos" com a lista/array de agentes que fizeram login nos ultimos x dias (conforme passagem de parametro), e armazena na variavel os agentes ativos e "nao excluidos" que nao constam na lista/array de agentes que logaram nos ultimos x dias (conforme passagem de parametro) 
	mapfile -t commAgentResult < \
                <(comm -23 \
                        <(IFS=$'\n'; echo "${agentList[*]}" | sort) \
                        <(IFS=$'\n'; echo "${agentLogin[*]}" | sort) \
                )
        
	separator
	
	#imprime os agentes ativos e "nao excluidos" que nao logaram no painel nos ultimos x dias (conforme passagem de parametro)
        echo -e "Agentes ATIVOS que não logaram no painel nos ultimos '$1' dias:"
        echo -e "${commAgentResult[@]}" | tr ' ' ','
	}

lastX $1

separator

# FIM
