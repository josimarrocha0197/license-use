#!/bin/bash
sqlModeAutoFile='/etc/mysql/debian.cnf'
sqlOptions="--defaults-extra-file=${sqlModeAutoFile}"

echo -e "######################################################################################################################## \n"

function lastX {
        if [[ "$1" != "90" && "$1" != "60" && "$1" != 30 ]]; then
                echo -e "Por favor, informe um parâmetro válido (90|60|30) \n"
                exit
        fi

        echo -e "Valor referência: $1 dias \n"
        parameter=${1}
        parameter=-${parameter}
        mapfile -t extensionCall < <(mysql ${sqlOptions} --batch -N futurofone -e 'SELECT DISTINCT 'src_cdr' AS origem FROM 'pbx_cdr' WHERE 'calldate_cdr' BETWEEN DATE_ADD( CURRENT_DATE( ) , INTERVAL '${parameter}' DAY ) AND DATE_ADD( CURRENT_DATE( ) , INTERVAL +1 DAY ) AND CHAR_LENGTH( 'src_cdr' ) <5 AND 'src_cdr'>99 AND 'direcao_cdr'="saida" AND 'aplicativo_cdr'="Ramal"')
        mapfile -t sipNoRegister < <(asterisk -rx 'sip show peers' | grep UNKNOWN | awk -F"/" '{ print $1 }' | grep -E '^(-?[0-9]{1,})$' | sort -n)
        mapfile -t iaxNoRegister < <(asterisk -rx 'iax2 show peers' | grep UNKNOWN | awk -F"/" '{ print $1 }' | grep -E '^(-?[0-9]{1,})$' | sort -n)

        echo -e "Ramais SIP SEM REGISTRO: ${sipNoRegister[@]}"
        echo -e "Quantidade: ${#sipNoRegister[@]} \n"

        echo -e "Ramais IAX SEM REGISTRO: ${iaxNoRegister[@]}"
        echo -e "Quantidade: ${#iaxNoRegister[@]} \n"

        echo -e "Ramais que realizaram ligações: ${extensionCall[@]}"
        echo -e "Quantidade: ${#extensionCall[@]} \n"

        echo -e "Comparando as informações obtidas... \n"
        echo -e "________________________________________________________________________________________________________________________ \n"

        echo -e "Ramais SIP SEM REGISTRO que não fizeram ligações: "
        mapfile -t commSipResult < \
                <(comm -23 \
                        <(IFS=$'\n'; echo "${sipNoRegister[*]}" | sort) \
                        <(IFS=$'\n'; echo "${extensionCall[*]}" | sort) \
                )
        echo -e "${commSipResult[@]} \n"

        echo -e "Ramais IAX SEM REGISTRO que não fizeram ligações: "
        mapfile -t commIaxResult < \
                <(comm -23 \
                        <(IFS=$'\n'; echo "${iaxNoRegister[*]}" | sort) \
                        <(IFS=$'\n'; echo "${extensionCall[*]}" | sort) \
                )
        echo -e "${commIaxResult[@]} \n"
        }

lastX $1
