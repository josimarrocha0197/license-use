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

	mapfile -t extensionAll < <(mysql ${sqlOptions} --batch -N futurofone -e 'SELECT 'numero_ramal' FROM 'pbx_ramal'')
	mapfile -t extensionLogin < <(mysql ${sqlOptions} --batch -N futurofone -e 'SELECT DISTINCT 'ramal_cdrqueuelogin' AS ramal FROM 'pbx_cdrqueuelogin' WHERE 'time_cdrqueuelogin' BETWEEN DATE_ADD( CURRENT_DATE( ) , INTERVAL '${parameter}' DAY ) AND DATE_ADD( CURRENT_DATE( ) , INTERVAL +1 DAY )' | grep -v NULL)

	echo -e "Ramais do cliente:"
	echo -e "${extensionAll[@]}" | tr ' ' ','
	echo -e "Quantidade: ${#extensionAll[@]}"
	separator
	echo -e "Ramais que logaram no painel nos ultimos '$1' dias:"
	echo -e "**Pode conter ramais INATIVOS"
	echo -e "${extensionLogin[@]}" | tr ' ' ','
	echo -e "Quantidade: ${#extensionLogin[@]}"
	
	mapfile -t commExtensionResult < \
                <(comm -23 \
                        <(IFS=$'\n'; echo "${extensionAll[*]}" | sort) \
                        <(IFS=$'\n'; echo "${extensionLogin[*]}" | sort) \
                )		
	separator
	echo -e "Ramais que não logaram no painel nos ultimos '$1' dias:"
	echo -e "${commExtensionResult[@]}" | tr ' ' ','
	}
lastX $1
separator
