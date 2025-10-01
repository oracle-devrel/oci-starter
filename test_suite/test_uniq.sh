SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
cd $SCRIPT_DIR
export TEST_HOME=$SCRIPT_DIR/test_group_all

echo "Removed duplicate entries in errors_rerun.sh"

cp $TEST_HOME/errors_rerun.sh /tmp/errors_rerun.sh
cat /tmp/errors_rerun.sh | sort | uniq > $TEST_HOME/errors_rerun.sh 
echo "---- Uniq Errors ----"
cat $TEST_HOME/errors_rerun.sh 
