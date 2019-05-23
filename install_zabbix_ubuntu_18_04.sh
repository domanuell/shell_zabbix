#!/bin/bash
#
# Script para facilicar a instalação do software Zabbix versão 4.2
#
# Requisitos Ubuntu server 18.04 LTS
# Não é possível instalar em outro SO, script especifco para versão 18.04 do Ubuntu Server.
#
# Uso: install_zabbix_ubuntu_18.04.sh [ instalar ]
#
# Versão 1.0: Realiza o instalação do software Zabbix completa na versão do Ubuntu 18.04.2 LTS.
#
# Abril 2019, Evandro José Zipf

# Caminho no sistema operacional do php.ini
PHPFILE=/etc/php/7.2/apache2/php.ini

# Modificar conforme seu ambiente os parâmetros de banco de dados
SENHA="zabbix";
SENHAROOT="senharoot";
NOMEBANCO="zabbix";
USUARIODB="zabbix";


# Se não passar nenhum arqgumento, mostra mensagem de ajuda
[ "$1" ] || {
	echo
	echo "Uso: ./install_zabbix_ubuntu_18_04 [ instalar ]"
	echo
	echo " instalar - Instalar Zabbix no Ubuntu 18.04"
	echo
	exit 0
}

# Função para pegar a distribuição Linux utilizada
pega_nome_distro(){

	DISTRO=DESCONHECIDA
	grep "Ubuntu 18.04" /etc/issue > /dev/null 2>&1 && DISTRO=UBUNTU
	echo $DISTRO

}

# Pega a versão do sistema operacional
DISTRO=$(pega_nome_distro)

# Se não for UBUNTU 18.04 termina o script
if [ "$DISTRO" != "UBUNTU" ];
	
	then
		echo "Seu SO não é compatível com esse script."
		exit 0;
	fi


	# Informa o usúario se deseja continuar a instalar o Zabbix
	echo "Ao continuar você irá instalar o Zabbix na versão 4.2. Deseja continuar (s/n)?"
	read resposta

# verifica resposta do usuário
if [ "$resposta" != "s" ]; 
	
	then
		echo "Instalação finalizada";
		exit 0; 
	fi


case "$1" in

	instalar)
				# Desenha a barra de progresso na tela
				echo -ne '\033c'
				echo -n '[.................................................] 0%'
				passo='#####'

				# Laço de 10 em 10 até no máximo 100
				for i in {10..100..10}; do
					sleep 1
					pos=$((i/2-5)) # calcula a posição atual da barra
					echo -ne '\033[G' # vai para o começo da linha
					echo -ne "\033[${pos}C" # vai para a posição atual da barra
					echo -n "$passo"
					echo -ne '\033[53G' # vai para a posição da porcentagem
					echo -n "$i" # mostra a porcentagem

					if [ "$i" -eq 10 ] ; 
					then
						# Download do pacote para ubuntu no site oficial do Zabbix
						echo -ne '\033[57G'
						echo -n "Download dos pacotes Aguarde....."
						wget -q https://repo.zabbix.com/zabbix/4.2/ubuntu/pool/main/z/zabbix-release/zabbix-release_4.2-1%2Bbionic_all.deb
						sleep 2
					fi

					if [ "$i" -eq 50 ] ;
					then
		   			    echo -ne '\033[57G'
				      	# Instalando pacote zabbbix-realease para Ubuntu 18.04
				      	echo -n "Instalando pacotes.. Aguarde.."
				      	dpkg -i zabbix-release_4.2-1+bionic_all.deb >/dev/null
				      	
				      	sleep 1
	    		    fi

				    if [ "$i" -eq 70 ] ;
				    then
      					
				      	# Atualizando repositório
				      	apt-get -q=2 update
				      					      	
				      	# Instalação dos pacotes necessários para o Zabbix
				      	apt-get -q=2 install mysql-server zabbix-server-mysql \
				      	php7.2 php7.2-mysql php7.2-bcmath php7.2-gd \
				      	php7.2-mbstring php7.2-xml php7.2-gettext php7.2-ldap -y >&/dev/null	
				      	sleep 1
											
				    fi


				    if [ "$i" -eq 80 ] ;
				    then

				    	echo -ne '\033[57G'
				        # Instalando pacote zabbbix-realease para Ubuntu 18.04
				        echo -n "Criando banco de dados........."

				      	# Enviando credenciais para um arquivo temporário Zabbix
				      	echo "$USUARIODB" >> tempnoto.txt
				      	echo "$SENHA" >> tempnoto.txt

				      	# Enviando credenciais root para arquivo temporário
				      	echo "root" >> tempnotoadm.txt
				      	echo "$SENHAROOT" >> tempnotoadm.txt

				      	# Criando o banco de dados para Zabbix
						echo "create database $NOMEBANCO character set utf8;" | mysql --login-path=tempnoto.txt
						echo "GRANT ALL PRIVILEGES ON $NOMEBANCO.* TO $USUARIODB@localhost IDENTIFIED BY '$SENHA' WITH GRANT OPTION;" | mysql --login-path=tempnoto.txt
						
						# Populando o banco de dados para o Zabbix
						cd /usr/share/doc/zabbix-server-mysql
						zcat create.sql.gz | mysql --login-path=tempnoto.txt $NOMEBANCO

						sleep 2
								   				      					      	
				      	# Realizando backup do arquivo de configuração
				      	cp $PHPFILE $PHPFILE.ori.$$

				      	# Configurando o php.ini
						sed -i 's/max_execution_time/\;max_execution_time/g' $PHPFILE;
						echo 'max_execution_time=300'>> $PHPFILE;
						
						sed -i 's/max_input_time/\;max_input_time/g' $PHPFILE;
						echo 'max_input_time=300' >> $PHPFILE;
						
						sed -i 's/date.timezone/\;date.timezone/g' $PHPFILE;
						echo 'date.timezone=America/Sao_Paulo' >> $PHPFILE;

						sed -i 's/post_max_size/\;post_max_size/g' $PHPFILE;
						echo 'post_max_size=16M' >> $PHPFILE;

						echo "DBPassword=$SENHA" >> /etc/zabbix/zabbix_server.conf
			      	
				    fi

				    if [ "$i" -eq 90 ] ;
				    then
				      	
				      	echo -ne '\033[57G'
				      	# Instalação Frontend
				      	echo -n "Instalando Frontend..................."
						apt-get -q=2 install zabbix-frontend-php -y >&/dev/null;
				      	
				      	# reiniciando serviços
				      	service apache2 restart;
				      	systemctl -q enable zabbix-server;

				      	# ativando Zabbix Server
				      	service zabbix-server start

				      	sleep 1
				    fi

				    if [ "$i" -eq 100 ] ;
				    then
				      	echo -ne '\033[57G'
				      	echo -n "Instalação finalizada com sucesso....."
				      	echo
				      	sleep 1
				    fi  
				  done
			;;
		  *)
		# Qualquer outra opção é erro
		echo "Opção inválida $1"
		exit 1
	;;
esac


		# removendo arquivos temporários
		rm -f tempnoto.txt tempnotoadm.txt

