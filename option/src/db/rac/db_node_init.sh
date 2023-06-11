export INSTANCE1=${PREFIX}1
export INSTANCE2=${PREFIX}2
export PDB=PDB1

echo PREFIX=$PREFIX
echo INSTANCE1=$INSTANCE1
echo INSTANCE2=$INSTANCE2
echo ORACLE_UNQNAME=$ORACLE_UNQNAME

# Wait that instance1 is up
while true ; do
  echo "Waiting..."
  srvctl status instance -instance ${INSTANCE1} -db ${ORACLE_UNQNAME} > /tmp/instance_status.txt
  result=$(grep -nE 'is running' /tmp/instance_status.txt) # -n shows line number
  echo "DEBUG: Result found is $result"
  if [ ! -z "$result" ] ; then
    echo "COMPLETE!"
    break;
  fi
  sleep 5
  date
done


srvctl add service -db ${ORACLE_UNQNAME} -service jbasic -pdb $PDB -preferred ${INSTANCE1} -available ${INSTANCE2} -failover_restore AUTO -commit_outcome TRUE -failovertype AUTO -replay_init_time 600 -retention 86400 -notification TRUE -drain_timeout 300 -stopoption IMMEDIATE -role PRIMARY
srvctl start service -db ${ORACLE_UNQNAME} -service jbasic
srvctl status service -db ${ORACLE_UNQNAME} -service jbasic

srvctl add service -db ${ORACLE_UNQNAME} -service jtac -pdb $PDB -preferred ${INSTANCE1} -available ${INSTANCE2} -failover_restore AUTO -commit_outcome TRUE -failovertype AUTO -replay_init_time 600 -retention 86400 -notification TRUE -drain_timeout 300 -stopoption IMMEDIATE -role PRIMARY
srvctl start service -db ${ORACLE_UNQNAME} -service jtac
srvctl status service -db ${ORACLE_UNQNAME} -service jtac

srvctl add service -db ${ORACLE_UNQNAME} -service jac -pdb $PDB -preferred ${INSTANCE1} -available ${INSTANCE2} -failover_restore LEVEL1 -commit_outcome TRUE -failovertype TRANSACTION -session_state dynamic -replay_init_time 600 -retention 86400 -notification TRUE -drain_timeout 300 -stopoption IMMEDIATE -role PRIMARY
srvctl start service -db ${ORACLE_UNQNAME} -service jac
srvctl status service -db ${ORACLE_UNQNAME} -service jac

srvctl add service -db ${ORACLE_UNQNAME} -service jtaf -pdb $PDB -preferred ${INSTANCE1} -available ${INSTANCE2} -failover_restore LEVEL1 -commit_outcome TRUE -failovertype SELECT -notification TRUE -drain_timeout 300 -stopoption TRANSACTIONAL -role PRIMARY
srvctl start service -db ${ORACLE_UNQNAME} -service jtaf
srvctl status service -db ${ORACLE_UNQNAME} -service jtaf