sudo useradd -m -d /opt/tomcat -U -s /bin/false tomcat
sudo apt update -y &> /dev/null
sudo apt install openjdk-17-jdk -y &> /dev/null
sudo update-alternatives --set java /usr/lib/jvm/java-17-openjdk-amd64/bin/java
export JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64
export JRE_HOME=$JAVA_HOME
java -version
cd /tmp
wget https://dlcdn.apache.org/tomcat/tomcat-10/v10.1.26/bin/apache-tomcat-10.1.26.tar.gz &> /dev/null
sudo tar xzvf apache-tomcat-10*tar.gz -C /opt/tomcat --strip-components=1 &> /dev/null
sudo chown -R tomcat:tomcat /opt/tomcat/
sudo chmod -R u+x /opt/tomcat/bin
sudo cp "$original_dir/startup.sh" /opt/tomcat/bin/startup.sh
sudo chown -R tomcat:tomcat /opt/tomcat/logs &> /dev/null
sudo cp "$original_dir/tomcat.service" /etc/systemd/system/tomcat.service
sudo cp "$original_dir/tomcat-users.txt" /opt/tomcat/conf/tomcat-users.xml
# Enable manager and host manager
sudo mkdir -p /opt/tomcat/webapps/manager/META-INF
sudo mkdir -p /opt/tomcat/webapps/host-manager/META-INF
sudo cp "$original_dir/context.txt" /opt/tomcat/webapps/manager/META-INF/context.xml
sudo cp "$original_dir/context.txt" /opt/tomcat/webapps/host-manager/META-INF/context.xml

sudo systemctl daemon-reload
sudo systemctl start tomcat 
sudo systemctl enable tomcat &> /dev/null
echo ""
echo "Tomcat installed! Also manager and Host manager activated!"
