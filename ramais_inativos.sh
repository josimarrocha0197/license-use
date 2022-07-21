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
function separator {
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

	#array com todos os ramais que fizeram ligacoes nos ultimos x dias (conforme passagem de parametro)        
	mapfile -t extensionCallOut < <(mysql ${sqlOptions} 'SELECT DISTINCT 'src_cdr' AS origem FROM 'pbx_cdr' WHERE 'calldate_cdr' BETWEEN DATE_ADD( CURRENT_DATE( ) , INTERVAL '${parameter}' DAY ) AND DATE_ADD( CURRENT_DATE( ) , INTERVAL +1 DAY ) AND CHAR_LENGTH( 'src_cdr' ) <5 AND 'src_cdr'>99 AND 'direcao_cdr'="saida" AND 'aplicativo_cdr'="Ramal" ORDER BY 'src_cdr' ASC')
	
	#array com todos os ramais que receberam ligacoes nos ultimos x dias (conforme passagem de parametro)
        mapfile -t extensionCallIn < <(mysql ${sqlOptions} 'SELECT DISTINCT 'dst_cdr' AS destino FROM 'pbx_cdr' WHERE 'calldate_cdr' BETWEEN DATE_ADD( CURRENT_DATE( ) , INTERVAL '${parameter}' DAY ) AND DATE_ADD( CURRENT_DATE( ) , INTERVAL +1 DAY ) AND CHAR_LENGTH( 'dst_cdr' ) <5 AND 'dst_cdr'>99 AND 'direcao_cdr'="saida" AND 'aplicativo_cdr'="Ramal" AND 'dialstatus_cdr'="answer" ORDER BY 'dst_cdr' ASC')

	#array com todos os "peers" SIP com status de qualify "UNKNOWN". Considera somente numeros.
	mapfile -t sipNoRegister < <(asterisk -rx 'sip show peers' | grep UNKNOWN | awk -F"/" '{ print $1 }' | grep -E '^(-?[0-9]{1,})$' | sort -n)

	#array com todos os "peers" IAX com status de qualify "UNKNOWN". Considera somente numeros.
        mapfile -t iaxNoRegister < <(asterisk -rx 'iax2 show peers' | grep UNKNOWN | awk -F"/" '{ print $1 }' | grep -E '^(-?[0-9]{1,})$' | sort -n)

	#imprime todos os "peers" SIP com status de qualify "UNKNOWN"
        echo -e "Ramais SIP SEM REGISTRO (agora):"
        echo -e "${sipNoRegister[@]}" | tr ' ' ', '
        echo -e "Quantidade: ${#sipNoRegister[@]} \n"

	#imprime todos os "peers" IAX com status de qualify "UNKNOWN"
        echo -e "Ramais IAX SEM REGISTRO (agora):"
        echo -e "${iaxNoRegister[@]}" | tr ' ' ','
        echo -e "Quantidade: ${#iaxNoRegister[@]} \n"

	#imprime todos os ramais que fizeram ligacoes nos ultimos x dias (conforme passagem de parametro)
        echo -e "Ramais que realizaram ligações nos ultimos '$1' dias:"
        echo -e "${extensionCallOut[@]}" | tr ' ' ','
        echo -e "Quantidade: ${#extensionCallOut[@]} \n"

	separator
	
	#array com os ramais que constam na lista/array de "peers" SIP com status de qualify "UNKNOWN" mas que nao constam na lista/array de ramais que fizeram ligacoes nos ultimos x dias (conforme passagem de parametro)
        mapfile -t commSipResultOut < \
                <(comm -23 \
                        <(IFS=$'\n'; echo "${sipNoRegister[*]}" | sort) \
                        <(IFS=$'\n'; echo "${extensionCallOut[*]}" | sort) \
                )
	#array com os ramais que constam na lista/array de "peers" SIP com status de qualify "UNKNOWN" mas que nao constam na lista/array de ramais que fizeram ou receberam ligacoes nos ultimos x dias (conforme passagem de parametro)
	mapfile -t commSipResultBoth < \
                <(comm -23 \
                        <(IFS=$'\n'; echo "${commSipResultOut[*]}" | sort) \
                        <(IFS=$'\n'; echo "${extensionCallIn[*]}" | sort) \
                )

	#imprime todos os "peers" SIP com status de qualify "UNKNOWN" que nao fizeram & nao receberam ligacoes nos ultimos x dias (conforme passagem de parametro)
        echo -e "Ramais SIP SEM REGISTRO que não fizeram & nao receberam ligações nos ultimos '$1' dias:"
        echo -e "${commSipResultBoth[@]}" | tr ' ' ',' | sort


	#array com os ramais que constam na lista/array de "peers" IAX com status de qualify "UNKNOWN" mas que nao constam na lista/array de ramais que fizeram ligacoes nos ultimos x dias (conforme passagem de parametro)
        mapfile -t commIaxResultOut < \
                <(comm -23 \
                        <(IFS=$'\n'; echo "${iaxNoRegister[*]}" | sort) \
                        <(IFS=$'\n'; echo "${extensionCallOut[*]}" | sort) \
		)

	#array com os ramais que constam na lista/array de "peers" IAX com status de qualify "UNKNOWN" mas que nao constam na lista/array de ramais que fizeram ou receberam ligacoes nos ultimos x dias (conforme passagem de parametro)
        mapfile -t commIaxResultBoth < \
                <(comm -23 \
                        <(IFS=$'\n'; echo "${commIaxResultOut[*]}" | sort) \
                        <(IFS=$'\n'; echo "${extensionCallIn[*]}" | sort) \
		)

	#imprime todos os "peers" IAX com status de qualify "UNKNOWN" que nao fizeram & nao receberam ligacoes nos ultimos x dias (conforme passagem de parametro)
        echo -e "\nRamais IAX SEM REGISTRO que não fizeram/receberam ligações nos ultimos '$1' dias:"
	echo -e "${commIaxResultBoth[@]}" | tr ' ' ','

        }

lastX $1

separator

# FIM
