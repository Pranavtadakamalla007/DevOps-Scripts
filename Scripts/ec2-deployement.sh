#!/bin/bash

# Function for error handling
error_exit() {
    echo "$1" 1>&2
    exit 1
}

# Log message
echo "Starting deployment steps on EC2 instance..."

# Variables
jar_file_name="BGCCHECK-0.0.1-SNAPSHOT.jar"
jar_directory="/home/ec2-user"
log_file="$jar_directory/bgc.log"
java_port=8080 # Adjust this if your application uses a different port

# Declare associative array of instances
declare -A instances
instances=(
    ["UAT-Branch_InstanceID"]="$(UAT_EC2InstanceID)"
    ["UAT-Branch_PublicIP"]="$(UAT_EC2PublicIP)"
    ["QA-Branch_InstanceID"]="$(Test_EC2InstanceID)"
    ["QA-Branch_PublicIP"]="$(Test_EC2PublicIP)"
    ["Pre-master_InstanceID"]="$(Master_EC2InstanceID)"
    ["Pre-master_PublicIP"]="$(Master_EC2PublicIP)"
    ["DEV-Branch_InstanceID"]="$(Dev_EC2InstanceID)"
    ["DEV-Branch_PublicIP"]="$(Dev_EC2PublicIP)"
)

# Debugging: Print all available instances
echo "Available instances:"
for key in "${!instances[@]}"; do
    echo "$key: ${instances[$key]}"
done

# Get the branch name from the system variable
branch_name="$(Build.SourceBranchName)"

# Debugging: Print the branch name
echo "Detected branch name: '$branch_name'"

# Check if branch name matches one of the known environments
if [[ -n "${instances[${branch_name}_PublicIP]}" ]]; then
    ec2_instance_ip="${instances[${branch_name}_PublicIP]}"
    identity_file_path="$(BGCTrureFace.secureFilePath)"

    # Ensure Java is installed and deploy the JAR
    ssh -o StrictHostKeyChecking=no -i "$identity_file_path" ec2-user@"$ec2_instance_ip" << EOF
# Ensure Java is installed
if ! java -version &>/dev/null; then
    echo "Java not found. Installing Java..."
    sudo yum install -y java-17-amazon-corretto || exit 1
    echo "Java installed successfully."
else
    echo "Java is already installed."
fi

# List contents of the target directory
echo "Listing contents of $HOME:"
ls -l "$HOME"

# Check if the JAR file exists
if [ ! -f "$jar_directory/$jar_file_name" ]; then
    echo "Error: JAR file $jar_file_name does not exist in $jar_directory"
    exit 1
fi

# Ensure the JAR has executable permissions
chmod +x "$jar_directory/$jar_file_name" || exit 1
echo "Executable permissions added to $jar_file_name"

# Check for any process using the port
port_in_use=\$(sudo netstat -tuln | grep ":$java_port")
if [ -n "\$port_in_use" ]; then
    echo "Port $java_port is in use. Killing the process..."
    pid=\$(sudo lsof -t -i:$java_port)
    sudo kill -9 \$pid || exit 1
    echo "Killed process using port $java_port"
else
    echo "Port $java_port is free."
fi

# Directly check for the JAR file without modification time check
if [ -f "$jar_directory/$jar_file_name" ]; then
    echo "Found $jar_file_name in $jar_directory"

    # Attempt to find and kill the existing process
    pid=\$(pgrep -f "$jar_file_name")
    if [ -n "\$pid" ]; then
        kill -9 \$pid
        echo "Killed the existing process running $jar_file_name (PID: \$pid)"
    else
        echo "No process found running $jar_file_name"
    fi

    # Start the new JAR
    nohup java -jar "$jar_directory/$jar_file_name" > "$log_file" 2>&1 &
    if [ \$? -eq 0 ]; then
        echo "Started $jar_file_name successfully"
    else
        echo "Failed to start $jar_file_name"
        exit 1
    fi

    # Ensure the process is running
    new_pid=\$(pgrep -f "$jar_file_name")
    if [ -n "\$new_pid" ]; then
        echo "$jar_file_name is now running with PID: \$new_pid"
        echo "You can monitor the logs using: tail -f $log_file"
    else
        echo "Failed to start $jar_file_name"
        exit 1
    fi
else
    echo "Error: $jar_file_name does not exist in $jar_directory"
    exit 1
fi

echo "Deployment completed successfully!"
EOF

else
    error_exit "Branch name '${branch_name}' does not match any known environment"
fi
