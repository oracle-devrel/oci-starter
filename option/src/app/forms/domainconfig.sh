
# touch /u01/oracle/.frm_config/msg/.in_progress
cd /u01/oracle/.frm_config/scripts 
# nohup /u01/oracle/middleware/Oracle_Home/oracle_common/common/bin/wlst.sh /u01/oracle/.frm_config/scripts/wlst/domainconfig.py >  /tmp/provision.log 2>&1 &

cd /u01/oracle/.frm_config/scripts
sed -i.bak utils.sh -e "s/clean_up_exit[ ]*$/# clean_up_exit/g"
sed -i.bak provision.sh -e "s/clean_up_exit[ ]*$/# clean_up_exit/g"
cd wlst
sed -i.bak domainconfig.py -e "s/delete_file_if_exists/# delete_file_if_exists/g"

# Start the bootstrap
# It works only if .autosetup.ini and json exist
sudo /u01/oracle/.frm_config/bootstrap.sh
