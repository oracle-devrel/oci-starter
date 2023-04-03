#!/bin/bash
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
cd $SCRIPT_DIR

echo "WARNING"
echo 
echo "This will destroy all the resources in all subdirectories."
echo 
if [ "$1" != "--auto-approve" ]; then
  read -p "Do you want to proceed? (yes/no) " yn

  case $yn in 
  	yes ) echo Deleting;;
	no ) echo Exiting...;
		exit;;
	* ) echo Invalid response;
		exit 1;;
  esac
fi

for d in */ ; do
    if [ "$d" != "group_common/" ]; then
      echo "-- DESTROY_GROUP - $d ---------------------------------"
      cd $d
      ./destroy.sh --auto-approve
      cd $SCRIPT_DIR
    fi
done

cd group_common
./destroy.sh --auto-approve
