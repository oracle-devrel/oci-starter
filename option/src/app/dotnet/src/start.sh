#!/bin/bash
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
cd $SCRIPT_DIR
export PATH=$HOME/.dotnet:$PATH
export DB_USER="##DB_USER##"
export DB_PASSWORD="##DB_PASSWORD##"
export DB_URL="##DB_URL##"
dotnet run
