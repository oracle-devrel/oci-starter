# Install the JVM (jdk or graalvm)
install_java

# Install Tomcat
export TOMCAT_HOME=/opt/tomcat

# Create tomcat user, disable login and give rights
# sudo useradd -s /bin/nologin -g opc -d $TOMCAT_HOME tomcat
sudo groupadd tomcat
sudo useradd -g tomcat -d $TOMCAT_HOME tomcat

# Download Tomcat
sudo dnf install -y wget
cd /tmp
sudo mkdir -p /opt/tomcat

# Set the base URL for Tomcat 11
BASE_URL="https://downloads.apache.org/tomcat/tomcat-11"

# Get the latest version number by parsing the HTML directory listing
LATEST_VERSION=$(curl -s "$BASE_URL/" | grep -oP 'v11\.0\.\d+/' | sort -V | tail -n 1 | tr -d '/v')

# If version was found, build the download URL and fetch the file
if [ -n "$LATEST_VERSION" ]; then
    FILE_NAME="apache-tomcat-$LATEST_VERSION.tar.gz"
    DOWNLOAD_URL="$BASE_URL/v$LATEST_VERSION/bin/$FILE_NAME"
    echo "Downloading $FILE_NAME from $DOWNLOAD_URL ..."
    wget -nv "$DOWNLOAD_URL"
    echo "Download complete."
else
    echo "Could not determine the latest version."
    exit 1
fi
sudo tar -xvf /tmp/apache-tomcat-$LATEST_VERSION.tar.gz -C $TOMCAT_HOME --strip-components=1

# Copy the Application and the start script to $TOMCAT_HOME
sudo cp /home/opc/app/rest/target/starter-1.0.war $TOMCAT_HOME/webapps
sudo mv /home/opc/app/rest/start.sh $TOMCAT_HOME/bin/.
sudo cp /home/opc/compute/tf_env.sh $TOMCAT_HOME/bin/.

sudo chown -R tomcat: $TOMCAT_HOME
sudo sh -c "chmod +x $TOMCAT_HOME/bin/*.sh"
cat > /tmp/tomcat.service << EOF 
[Unit]
Description=Apache Tomcat Web Application Container
Wants=network.target
After=network.target

[Service]
Type=forking

ExecStart=$TOMCAT_HOME/bin/start.sh
ExecStop=$TOMCAT_HOME/bin/shutdown.sh
SuccessExitStatus=143

User=tomcat
Group=tomcat
UMask=0007
RestartSec=10
Restart=always

[Install]
WantedBy=multi-user.target
EOF

sudo cp /tmp/tomcat.service /etc/systemd/system/tomcat.service 

sudo systemctl daemon-reload
sudo systemctl enable tomcat
sudo systemctl start tomcat