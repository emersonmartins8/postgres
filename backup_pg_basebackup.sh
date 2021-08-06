#Script: Backup físico do PostgreSQL com o binário pg_basebackup
#Diretório : Necessário um mount point dedicado para os backups do PostgreSQL /backup
#
#Backup Details
#
#
backup_dir=/backup
retention_duration=7
export PGPASSWORD=""
export PGPORT="5432"
echo -e "\n\nBackup Status: $(date +"%d-%m-%y")" >> $backup_dir/Status.log
echo -e "-----------------------" >> $backup_dir/Status.log
echo -e "\nStart Time: $(date)\n" >> $backup_dir/Status.log
/usr/lib/postgresql/9.6/bin/pg_basebackup -U postgres  -w -D $backup_dir/PostgreSQL_Base_Backup_$(date +"%d-%m-%y") -l "`date`" -P -F tar -z -R &>> $backup_dir/Status.log
echo -e "\nEnd Time: $(date)" >> $backup_dir/Status.log

#Auto Deletion for Backups
#Value 7 for retention_duration will keep 8 days backups

find $backup_dir/PostgreSQL_Base_Backup* -type d -mtime +$retention_duration -exec rm -rv {} \;