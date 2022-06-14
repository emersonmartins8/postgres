#!/bin/bash
# Script..................: backup_mysql_database.sh
# Autor...................: Emerson Martins (DBA) 
# Finalidade..............: Backup e Checagem de Integridade - Ambiente Simples, OLPT e GIS
# Tipo....................: Backup Lógico - Dump
# Distribuicao............: Debian, Ubuntu, CentOs  

# Variaveis de Ambiente
DATA=`date +%Y-%m-%d-%H-%M`
HostName=`hostname`
LOG=$PastaBackup/log_backup_$DATA.log
AdmMySQL=usuarioMySQL
PassMySQL=senha
PastaBackup=/backup/dumps
number_of_days=2

find $PastaBackup -name "*.sql" -mtime +$number_of_days -type f -exec rm -rf {} \;

echo "---- Inicio do Backup ------- " > $LOG
# Verifica existencia da pasta de backup e cria

if [ ! -d $PastaBackup ]; then
      echo  >> $LOG
      echo "Pasta de Backup inexiste!!!" >> $LOG
      mkdir -p $PastaBackup
      if [ "$?" != "0" ]; then
          echo "A Pasta de Backup nao pode ser criada, saindo do Backup" >> $LOG
          exit 1
      fi
      echo  >> $LOG
      echo "Pasta Criada" >> $LOG
fi
 
# Desabilitado - Não recomendado para bases grandes
# Verificar a integridade do banco e corrige
# caso haja algum problema
echo " -----------------------------------------------------------------------------" >> $LOG
echo " Inicio das copias de Backup - Servidor $HostName - $DATA " >> $LOG
echo " -----------------------------------------------------------------------------" >> $LOG
##echo -n "Veriricando a Integridade do Banco de Dados..." >> $LOG
##echo >> $LOG
##sleep 1
##mysqlcheck -A -e -u $AdmMySQL -p$PassMySQL --auto-repair >> $LOG
##echo >> $LOG
##echo "Checagem Finalizada!!! " >> $LOG
echo "-----------" >> $LOG
echo -n "Inicio dos Backups..." >> $LOG
echo " -----------------------------------------------------------------------------" >> $LOG
echo -n "Lista de Databases:" >> $LOG
echo >> $LOG
mysql -u $AdmMySQL -p$PassMySQL -e "show databases;" >> $LOG
echo  >> $LOG

echo -n "Fazendo Backup das Bases ..."  >> $LOG
sleep 1
echo  >> $LOG
mysql -u $AdmMySQL -p$PassMySQL -e "show databases;" > /tmp/databases.txt
linhas_file=`cat /tmp/databases.txt | wc -l`
databases=`echo $(($linhas_file-1))`
tail -n $databases /tmp/databases.txt > /tmp/databases_backup.txt
databases_backup=`cat /tmp/databases_backup.txt`

for dbase in $databases_backup; do
	## Incluir aqui os bancos que nao serao necessarios efetuar backup seguindo o padrao abaixo 	
	## ************* Descomentar estas linhas caso queira excluir alguns bancos de dados ****** #####
	##if [ "$dbase" != "information_schema" ] && [ "$dbase" != "performance_schema" ]  && [ "$dbase" != "mysql" ] && [ "$dbase" != "information_schema" ]; then
     	   echo >> $LOG
     	   echo "Fazendo backup do Database $dbase..." >> $LOG
     	   echo >> $LOG
     		mysqlpump -u $AdmMySQL -p$PassMySQL  $dbase --default-parallelism=8 | gzip -c  > $PastaBackup/$dbase-$DATA.sql.tgz
           tail -n 5 $PastBackup/$dbase-$DATA.sql >> $LOG
     	   echo "---------------------------" >> $LOG
     	   echo dbase >> $LOG
        ##fi
done
echo " -----------------------------------------------------------------------------" >> $LOG
#echo >> $LOG
#echo -n "Apagando backups e logs anteriores " >> $LOG

find $PastaBackup/  -name "*.tgz" -daystart -mtime +$number_of_days -type f -exec rm -f {} \;
#find $PastaBackup/  -name "*.log" -daystart -mtime +$number_of_days -type f -exec rm -f {} \;

ls -lart $PastaBackup > /tmp/lista_backups.txt

echo " -----------------------------------------------------------------------------" >> $LOG
echo >> $LOG
echo -n "Lista de Backups disponíveis em disco " >> $LOG
cat  /tmp/lista_backups.txt >> $LOG

echo "Backup Finalizado" >> $LOG
