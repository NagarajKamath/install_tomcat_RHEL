#!/bin/bash

# Function to check if a service is running
check_service_status() {
    systemctl is-active --quiet "$1"
}

# Function to enable manager and host manager in context.xml
enable_manager_hostmanager() {
    local context_file=$1
    if ! grep -q '<Context' "$context_file"; then
        echo "Adding manager/host-manager configuration to $context_file"
        sudo cat /home/ec2-user/artisantek-2024/context.txt > $context_file 
    else
        echo "Manager/host-manager already configured in $context_file"
    fi
}

# Check if Java is installed
if ! java -version 2>&1 | grep -q "11.0.23"; then
    echo "Installing Java 11..."
    sudo yum install java-11-openjdk-devel -y
else
    echo "Java 11 is already installed."
fi

# Check if Tomcat is installed
if [ ! -d "/opt/tomcat" ]; then
    echo "Tomcat is not installed. Installing Tomcat..."
    
    sudo useradd -m -U -d /opt/tomcat -s /bin/false tomcat
    sudo yum install wget -y
    cd /tmp
    wget https://archive.apache.org/dist/tomcat/tomcat-9/v9.0.89/bin/apache-tomcat-9.0.89.tar.gz
    sudo tar xf /tmp/apache-tomcat-9.0.89.tar.gz -C /opt/tomcat --strip-components=1
    sudo chown -R tomcat: /opt/tomcat
    sudo chmod -R 755 /opt/tomcat

    # Prompt for port selection
    read -p "Enter port for Tomcat (8080 or 9050): " port
    if [[ "$port" != "8080" && "$port" != "9050" ]]; then
        echo "Invalid port. Defaulting to 8080."
        port=8080
    fi

    sudo sed -i "s/port=\"8080\"/port=\"$port\"/" /opt/tomcat/conf/server.xml

    # Add service configuration
    sudo cat /home/ec2-user/artisantek-2024/tomcat.service | sudo tee /etc/systemd/system/tomcat.service &> /dev/null
    sudo cat /home/ec2-user/artisantek-2024/tomcat-users.txt | sudo tee /opt/tomcat/conf/tomcat-users.xml &> /dev/null

    # Enable manager and host manager
    enable_manager_hostmanager /opt/tomcat/webapps/manager/META-INF/context.xml
    enable_manager_hostmanager /opt/tomcat/webapps/host-manager/META-INF/context.xml

    sudo systemctl daemon-reload
    sudo systemctl start tomcat
    sudo systemctl enable tomcat
else
    echo "Tomcat is already installed."

    # Enable manager and host manager if not enabled
    enable_manager_hostmanager /opt/tomcat/webapps/manager/META-INF/context.xml
    enable_manager_hostmanager /opt/tomcat/webapps/host-manager/META-INF/context.xml

    # Check if Tomcat is running
    if ! check_service_status tomcat; then
        echo "Tomcat is not running. Attempting to restart..."
        sudo systemctl restart tomcat
        if ! check_service_status tomcat; then
            echo "Failed to restart Tomcat. Please check the logs for more details."
            sudo journalctl -u tomcat --since "5 minutes ago"
            exit 1
        fi
    else
        echo "Tomcat is running."
    fi
fi
