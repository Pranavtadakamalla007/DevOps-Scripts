#!/bin/bash

# Function for error handling
error_exit() {
    echo "$1" 1>&2
    exit 1
}

# Log message
echo "Transferring JAR file to EC2 instance..."

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
    artifact_directory="$(System.ArtifactsDirectory)/target"
    jar_file_name="BGCCHECK-0.0.1-SNAPSHOT.jar"

    # Check if the identity file exists
    if [[ -f "$identity_file_path" ]]; then
        chmod 400 "$identity_file_path" || error_exit "Failed to change permissions on $identity_file_path"

        # List files in the artifact directory for debugging
        echo "Listing contents of artifact directory:"
        ls -l "$artifact_directory"

        # Execute SCP command to transfer the JAR file directly to /home/ec2-user
        echo "Executing SCP command to transfer JAR file..."
        scp -o StrictHostKeyChecking=no -i "$identity_file_path" "$artifact_directory/$jar_file_name" ec2-user@"$ec2_instance_ip":/home/ec2-user/ || error_exit "SCP transfer failed"

        echo "JAR file transferred successfully!"

        # Check the contents of /home/ec2-user on the EC2 instance
        echo "Checking contents of /home/ec2-user on the EC2 instance..."
        ssh -o StrictHostKeyChecking=no -i "$identity_file_path" ec2-user@"$ec2_instance_ip" "ls -l /home/ec2-user/"
    else
        error_exit "Identity file $identity_file_path not found"
    fi
else
    error_exit "Branch name '${branch_name}' does not match any known environment"
fi
