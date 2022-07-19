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
        parameter=${1}
        parameter=-${parameter}
        mapfile -t extensionCall < <(mysql ${sqlOptions} --batch -N futurofone -e 'SELECT DISTINCT 'src_cdr' AS origem FROM 'pbx_cdr' WHERE 'calldate_cdr' BETWEEN DATE_ADD( CURRENT_DATE( ) , INTERVAL '${parameter}' DAY ) AND DATE_ADD( CURRENT_DATE( ) , INTERVAL +1 DAY ) AND CHAR_LENGTH( 'src_cdr' ) <5 AND 'src_cdr'>99 AND 'direcao_cdr'="saida" AND 'aplicativo_cdr'="Ramal"')
        mapfile -t sipNoRegister < <(asterisk -rx 'sip show peers' | grep UNKNOWN | awk -F"/" '{ print $1 }' | grep -E '^(-?[0-9]{1,})$' | sort -n)
        mapfile -t iaxNoRegister < <(asterisk -rx 'iax2 show peers' | grep UNKNOWN | awk -F"/" '{ print $1 }' | grep -E '^(-?[0-9]{1,})$' | sort -n)

        echo -e "Ramais SIP SEM REGISTRO (agora):"
        echo -e "${sipNoRegister[@]}" | tr ' ' ', ' | sort -n
        echo -e "Quantidade: ${#sipNoRegister[@]} \n"

        echo -e "Ramais IAX SEM REGISTRO (agora):"
        echo -e "${iaxNoRegister[@]}" | tr ' ' ',' | sort -n
        echo -e "Quantidade: ${#iaxNoRegister[@]} \n"

        echo -e "Ramais que realizaram ligações nos ultimos '$1' dias:"
        echo -e "${extensionCall[@]}" | tr ' ' ',' | sort -n
        echo -e "Quantidade: ${#extensionCall[@]} \n"
        separator
        echo -e "Ramais SIP SEM REGISTRO que não fizeram/receberam ligações nos ultimos '$1' dias:"
        mapfile -t commSipResult < \
                <(comm -23 \
                        <(IFS=$'\n'; echo "${sipNoRegister[*]}" | sort) \
                        <(IFS=$'\n'; echo "${extensionCall[*]}" | sort) \
                )
        echo -e "${commSipResult[@]}" | tr ' ' ',' | sort -n

        echo -e "\nRamais IAX SEM REGISTRO que não fizeram/receberam ligações nos ultimos '$1' dias:"
        mapfile -t commIaxResult < \
                <(comm -23 \
                        <(IFS=$'\n'; echo "${iaxNoRegister[*]}" | sort) \
                        <(IFS=$'\n'; echo "${extensionCall[*]}" | sort) \
                )
        echo -e "${commIaxResult[@]}" | tr ' ' ',' | sort -n
        }
lastX $1
separator
