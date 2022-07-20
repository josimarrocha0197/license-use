#!/bin/bash
sqlModeAutoFile='/etc/mysql/debian.cnf'
sqlOptions="--defaults-extra-file=${sqlModeAutoFile}"

function separator {
        for i in $(seq 1 95)0; do echo "_"; done | tr '\n' '_'
        echo -e "\n"
}

function lastX {
        if [[ "$1" != "90" && "$1" != "60" && "$1" != 30 ]]; then
                echo -e "Por favor, informe um parâmetro válido (90|60|30) \n"
                exit
        fi
        separator
        echo -e "Valor referência: '$1' dias"
        separator
        parameter=-${1}

	mapfile -t agentList < <(mysql ${sqlOptions} --batch -N futurofone -e 'SELECT 'codigo_agente' as login_agente FROM 'pbx_agente' WHERE 'status_agente'="1" AND 'excluido_agente'="0"')
	mapfile -t agentLogin < <(mysql ${sqlOptions} --batch -N futurofone -e 'SELECT DISTINCT 'agent_cdrqueuelogin' AS agente FROM 'pbx_cdrqueuelogin' WHERE 'time_cdrqueuelogin' BETWEEN DATE_ADD( CURRENT_DATE( ) , INTERVAL '${parameter}' DAY ) AND DATE_ADD( CURRENT_DATE( ) , INTERVAL +1 DAY )')
	
	echo -e "Agentes cadastrados ATIVOS:"
        echo -e "${agentList[@]}" | tr ' ' ','
        echo -e "Quantidade: ${#agentList[@]}"
        separator
        echo -e "Agentes que logaram no painel nos ultimos '$1' dias:"
	echo -e "**Pode conter agentes INATIVOS"
        echo -e "${agentLogin[@]}" | tr ' ' ','
        echo -e "Quantidade: ${#agentLogin[@]}"
	
	mapfile -t commAgentResult < \
                <(comm -23 \
                        <(IFS=$'\n'; echo "${agentList[*]}" | sort) \
                        <(IFS=$'\n'; echo "${agentLogin[*]}" | sort) \
                )
        separator
        echo -e "Agentes ATIVOS que não logaram no painel nos ultimos '$1' dias:"
        echo -e "${commAgentResult[@]}" | tr ' ' ','
	}
lastX $1
separator
