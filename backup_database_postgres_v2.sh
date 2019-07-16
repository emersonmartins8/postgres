#!/bin/bash
# -----------------------------------------------------------------------------------------------------------------
# Instituto de Tecnologia do Estado de Alagoas - ITEC.
#
# Rotina..................: Backup via Dump
# Script..................: backup_database_postgres.sh 
# Autor...................: Emerson Martins - DBA 
# Finalidade..............: Backup Postgres - Ambiente Sistemas
# Tipo....................: Generico - Todas as bases exceto [template0,template1 e postgres]
# Distribuicao............: [CentOs,Debian,Ubuntu e derivados]
#

# Checa se todos os parametros foram passados
#
if [ "$1" = "" ]; then
   echo " "
   echo "Por favor, use a sintax abaixo: "
   echo "Onde:"
   echo "   Parametros     : 1 - Compactado Sim(S), Nao (N) "
  # echo "   Tipo do backup : 2 - DUMP, EXPDP "
  # echo "   Versao DB      : 3 - 8x, 9x, 10x"
  # echo "   Backup Diario  : 4 - (S)im / (N)ao "
  # echo "   Dados/Estrutura: 5 - (D)ados / (E)strutura "
  # echo "   ORACLE_HOME    : 6 - Em caso de testes, informe o ORACLE_HOME"
   echo " "
   echo "Exemplo        : sh /home/usuario/backup_database_postgres.sh S "
   echo " " 
   exit
fi 

#Variaveis de Ambiente Fixas
#Diretorio de Backup
backup_dir="/backup/"
#Formato de data do arquivo de Log
#backup_date=`date +%d-%m-%Y`
#Formato de data e hora backup/log
backup_date=$(date +"%d-%m-%Y_%H_%M_%S")
#Diretório  do Log do backup
backup_log="/backup/"
# Tempo de Retencao -  
# Numero de dias que voce manterar os backups
number_of_days=3
# Utilizará compactacao S/N
compactado=$1

databases=`/usr/lib/postgresql/9.6/bin/psql -l -t | cut -d'|' -f1 | sed -e 's/ //g' -e '/^$/d'`

for i in $databases; do
  if [ "$i" != "template0" ] && [ "$i" != "template1" ]  && [ "$i" != "postgres" ] && [ "$i" != "test" ]; then
    echo Dumping $i to $backup_dir$i\_$backup_date
	
	if [ "$1" = "S" ]; then 
   		/usr/lib/postgresql/9.6/bin/pg_dump -Upostgres  --format plain --inserts  $i > $backup_dir$i\_$backup_date.sql
    		tar -cjf $backup_dir$i\_$backup_date.tar.bz2 $backup_dir$i\_$backup_date.sql
    		rm -f $backup_dir$i\_$backup_date.sql
	else
   		/usr/lib/postgresql/9.6/bin/pg_dump -Upostgres  --format plain --inserts  $i > $backup_dir$i\_$backup_date.sql
	fi
 
 fi
done
find $backup_dir -type f -prune -mtime +$number_of_days -exec rm -f {} \;

