# Install the CloudWatch Agent on Windows

# Download:
https://s3.amazonaws.com/amazoncloudwatch-agent/windows/amd64/latest/amazon-cloudwatch-agent.msi

# Change to download directory and execute the following:
msiexec /i amazon-cloudwatch-agent.msi

# Run the following command in PowerShell
& "C:\Program Files\Amazon\AmazonCloudWatchAgent\amazon-cloudwatch-agent-ctl.ps1" -a fetch-config -m ec2 -s -c file:"C:\Program Files\Amazon\AmazonCloudWatchAgent\config.json"