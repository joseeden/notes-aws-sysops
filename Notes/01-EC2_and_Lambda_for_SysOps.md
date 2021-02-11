<!-- 2021-01-27 06:03:44 -->

# 01 - EC2 and Lambda for SysOps #
________________________________________________

<p align=center>
    <img src="../Images/ec2-for-sysops.png" width=600>
</p>

The focus of these note will be on EC2 from the SysOps perspective:

- Operations
- Troubleshooting
- Instance Types
- Launch Modes
- AMI
- CloudWatch

It is also assumed that you have prior knowledge or some basics of Amazon Web Services. The  AWS Console UI changes from time to time so the images that you may see in my notes might not be the same with what you see on your console.

This document is broken down into these sections:

1.  [Changing Instance Type](#changing-instance-type)
2.  [EC2 Placement Groups](#ec2-placement-groups-csp)
3.  [Shutdown Behavior and Termination Protection](#shutdown-behavior-and-termination-protection)
4.  [EC2 Launch Issues](#ec2-launch-issues)
5.  [EC2 SSH Issues](#ec2-ssh-issues)
6.  [EC2 Instance Launch Types](#ec2-launch-types)
7.  [Spot Instances and Spot Fleet](#spot-instances-and-spot-fleet)
8.  [EC2 Instance Types - Deep Dive](#ec2-instance-types-deep-dive)
9.  [EC2 AMIs](#ec2-amis)
10. [Cross-account AMI Copy](#cross-account-ami-copy)
11. [Elastic IPs](#elastic-ips)
12. [CloudWatch Metrics for EC2](#cloudwatch-metrics-for-ec2)
13. [Custom CloudWatch Metrics](#custom-cloudwatch-metrics-for-ec2)
14. [CloudWatch Logs for EC2](#cloudwatch-logs-for-ec2)
15. [Unified CloudWatch Agent](#unified-cloudwatch-agent)
16. [AWS Lambda](#aws-lambda)

________________________________________________

## CHANGING INSTANCE TYPE ##

This is a commonly done in SysOps. Notes to remember are:

- can only be done on EBS-backed instances
- you need to stop the instance before changing the instance type
- from instance settings, click **Change Instance Type** 
- we can upsize and downsize
- on some instances, we have an option to tick **EBS Optimized**
- once changed, restart instance
- the public ip may change when you reboot an instance

Before restarting instance, I have t2.micro:

    [ec2-user@ip-172-31-27-248 ~]$ free -m
                  total        used        free      shared  buff/cache   available
    Mem:            983          75         506           0         401         770
    Swap:             0           0           0

After changing to the a bigger one - t2.small:

    [ec2-user@ip-172-31-27-248 ~]$ free -m
                  total        used        free      shared  buff/cache   available
    Mem:           1991          76        1730           0         183        1776
    Swap:             0           0           0

________________________________________________

## EC2 PLACEMENT GROUPS - CSP ##

These are used to control EC2 Placement strategy within the AWS infrastructure.

- no direct interaction with hardware
- we just let AWS know how we want our instances to be 'arranged'
- three EC2 placement group options:

1.  **Cluster**
    - same rack, same AZ
    - Instances are grouped together in 1 Availability Zone.
    - low latency - 10 Gbps BW 
    - high performance, but high risk
    - if rack fails, all instances fial at the same time
    - for applications that needs to complete fast

        ![](../Images/ec2-cluster.png)

2.  **Spread**
    - span across multiple AZ
    - instances are spread across different hardware
    - limit of **7** instances **per AZ per group**
    - for **max availability**
    - for critical applications

        ![](../Images/ec2-spread.png)

3.  **Partition**
    - similar with spread
    - spread on different partitions on different racks within an AZ
    - risk of failures can be isolated by partitions
    - up to **100 instances per group**
    - used for big data applications (Hadoop, Cassandra, Kafka)

        ![](../Images/ec2-partition.png)


To use Placement Groups, create the **Placement group** under **Network and Security** first and then when you're configuring instance details during instance creation, choose your Placement group.

![](../Images/ec2-pg-1.png)

________________________________________________

## SHUTDOWN BEHAVIOR AND TERMINATION PROTECTION ##

You can enable termination protection and shutdown behavior during instance creation or while its running.

**SHUTDOWN BEHAVIOR**
This is how the instance will react when shutdown from OS, not on AWS Console or API. There are two options here:
- Stopped (default)
- Terminated

Note that the CLI Attribute is **InstanceInitiatedShutdownBehavior**

**TERMINATION PROTECTION**
Protection against accidental termination in AWS Console or CLI.
- **Shutdown Behavior > Termination Protection**
- If SB=Terminate, then it'll terminate instance regardless if TP is enabled.

![](../Images/sbtp.png)

________________________________________________

## EC2 LAUNCH ISSUES ##

**InstanceLimitExceededError**
This means you have reached max number of running On-demand instances per region. The limits are counted in vCPU.

 - Max vCPU per region: 32
 - Either launch instance i another region or open support ticket to AWS to increase limit on your region.

You can view current limit in your region through the EC2 console.

![](../Images/ec2-limits.png)

<br>

**InsufficientInstanceCapacity**
This means AWS doesn't have much On-demand capacity in the particular AZ to which instance is launched.

- wait for a few minutes before requesting again
- break down requests into smaller ones.
- request for a different instance type and then resize later.

<br>

**Instance Terminates Immediately**
You are able to start instance but it went from pending to terminated immediately.

- EBS limit is reached
- EBS volume is corrupt
- root EBS volume is encrypted and you don't have access to KMS key for decryption.
- instance store-backed AMI is missing a part.

To see how the instance was terminated abruptly, you can select Settings icon at the upper right of the EC2 console to show **State Transition**.

![](../Images/state-transition.png)

![](../Images/state-transition-2.png)

(The [AWS Documentation](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/troubleshooting-launch.html) has a whole section discussing about instance launch issues. You can also view per-region [EC2 service quotas](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-resource-limits.html).

________________________________________________

## EC2 SSH ISSUES ##

**Unprotected Private Key File Error**
This means the private key file in your Linux machines doesn't have the necessary permissions. Make sure to set the .pem file to allow read permission - chmod 400

**Hostkey not found Error**
Username used in logging via SSH to the instance is not found.
You'll usually get a **permission denied** message.

**Connection Timeout**
This is usually caused by security groups not configured correctly.
It's also possible that CPU load is high that the instance cannot reply back.
________________________________________________

## EC2 LAUNCH TYPES ##

1.  **On-demand Instances** 
    - used for short workload and uninterrupted workloads
    - pay for what you use (billing per second, after the first minute)
    - highest cost, but no upfrontpayment
    - no long-term commitment

2.  **Reserved Instance** 
    - Minimum of **1 year**
    - up to **75% discount** compared to On-demand
    - upfront payment for long-term commitment
    - reservation can be 1 or 3 years        
    - recommended for steady usage, example is database
    - three types of reserved instances (RI):

        - **Standard Reserved Instances**
          Specific instance type for long workloads
        - **Convertible RI** 
            Can convert to other instance types 
        - **Scheduled RI** 
            Reserving instances in a specific schedule
    
        <img src="../Images/ec2-ri.png">

3.  **Spot Instance** 
    - short workloads, you can lose instances any time.
    - up to **90% discount** compared to On-demand
    - most cost-efficient but less reliable, you can *'lose'* instances any time
    - if current spot price is higher than your max price, you lose the instance
    - **max price** - how much you're willing to pay for the spot instance
    - **current spot price** - bidding price or market price
    - not recommended for critical applications or database
    - for workloads resilient to interruptions or failures
        - batch jobs
        - data analysis
        - image processing
        - any job that can be re-tried
    - **Suggested:** RI + On-demand + Spot
    - Use RI for baseline capacity with predictable usage
    - Use Spot or On-demand for jobs with unpredictable workload

4.  **Dedicated Instances**
    - no other customer will share your hardware.
    - may share with other instance under the same account
    - no control on instanc eplacement
    - no control on underlying hardware

5.  **Dedicated Host** 
    - Entire physical EC2 server is dedicated to you
    - Full control of EC2 instance placement
    - Full control on sockets/physical cores
    - **3 year** period reservation, more expensive
    - For companies with strong regulatory and compliance needs
    - For software with BYOL licensing model
    - **BYOL** - Bring Your Own License

    <br>

    Below is comparison between dedicated hosts vs. dedicated instances

<p align=center>
    <img src="../Images/ec2-dedicated-2.png" width=500>
</p>

You can set instance launch types during creation of instance

<img src="../Images/ec2-instance-type.png" width=700>

#### INTERRUPTION BEHAVIOR ####
You can set what will happen to your spot instance when it is terminated and reclaimed by AWS.
- terminate / delete
- stop instance (you can then re-assign workload or change instance type)

#### PERSISTENT REQUEST ####
When you have a persistent spot request, you'll automatically have another spot instance created when the current instance is terminated by AWS. 

Note that if you terminate your own instance, it will just go through the same cycle - AWS checks if spot request is still valid and if it is, it will launch a new instance. To fully stop an instance from going through the persistent request cycle:

1.  Spot request must be in either of these states:
    - **open**
    - **active**
    - **disabled state**
2.  Cancelling a spot request does not terminate the instance
3.  You must first cancel the spot request
4.  then delete the instances

<p align=center>
    <img src="../Images/persistent-request.png" width=300>
</p>

To configure persistent request and interruption behavior

![](../Images/prib.png)
________________________________________________

## SPOT INSTANCES AND SPOT FLEET ##

**SPOT INSTANCES**
You can define a max spot price and get the instance while **current spot price < max price you're willing to pay**.

- spot prices are quite stable for periods of time
- but it will be projected as changing from the exam's perspective
- you define the max spot price you're willing to pay in a **spot request** 
- the hourly spot price varies based on **offer** and **capacity**
- AWS gives **2 minutes period** before fully reclaiming spot instance
- if you don't want the instances to be reclaimed, you can use Spot Block

**SPOT BLOCK**
You can *block* spot instances for a specified period of time without interruptions.
- 1 to 6 hours
- this is pretty rare since AWS can still reclaim the instance

**SPOT REQUEST**
This contains the following details
- Max price you're willing to pay
- Desired number of instances
- Launch specifications
- Validity - from and to
- Request-type:
    - **One-time**
        As soon as your request is fulfilled and spot instances are launched, the spot request is deleted.

    - **Persistent**
        Spot request will keep fulfilling the desired number of instance during it's period. This meant automatically creating another instance when current number of instance goes beyond the desired number. Cancelling persistent requests are discussed [here](#persistent-request)

**SPOT FLEET**
It is a set of mixed type of instances - Spot + On-demand
- Builds target capacity based on price constraints
- Can have multiple launch pools to choose from
- Automatically does the 'mix-and-match' based on your budget
- You can define your strategies:
    
    - **lowestprice**
        - Launching instances from pool with the lowest price
        - cost optimization
        - short workloads

    - **diversified**
        - Launched instances are distributed across pools
        - great for availability
        - longer workloads

    - **capacityOptimized**
        - Instances are chosen from pool with optimal capacity
________________________________________________

<!-- 2021-01-28 03:06:15 -->

## EC2 INSTANCE TYPES - DEEP DIVE ##

There are a lot of available EC2 instance types but these are the ones we can focus on for the exam:

| Types | Use Cases |
| :-: | :- |
| **R** | needs a lot of RAM, e.g. in-memory cache |
| **C** | needs good CPU, e.g. compute, databases |
| **M** | somewhere in the middle, e.g. balanced apps, web app, general |
| **I** | needs good local I/O, e.g. instance storage, databases |
| **G** | applications that need GPU, video-rendering, ML |
| **T2/T3** | burstable (up to a capacity) |
| **T2/T3 Unli** | Unlimited burst |

You can check out more information in this [comparison page.](ec2instances.info)
________________________________________________________________

#### BURSTABLE INsTANCES (T2/T3) ####

Overall performance of EC2 instance is good, but for situations where the machine processes something unexpected - like a load spike, CPU can **burst out**, basically boosting power.
- During burst, CPU is good
- Burst credits are also used
- If credits are all used up, CPU becomes *BAD*.
- You accumulate burst credits when CPU is not bursting
- The larger the instance type, the larger the burst, the faster you accumulate
- If your load constantly burst, you may need to move to a different isntance type

You can check out some comparison on the CPU credits here:

![](../Images/cpu-credits.png)
________________________________________________________________

#### T2/T3 UNLIMITED ####

Unlimited burst credit balance
- you dont lose performance, but you may need to watch your expenses
- costs could go high if you don't monitor your usage

You can read more about burstable instances on the linkes below:
- [Unlimited mode for burstable performance instances](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/burstable-performance-instances-unlimited-mode.html)
- [Work with burstable performance instances](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/burstable-performance-instances-how-to.html)

________________________________________________________________

## EC2 AMIs ##

There are many available base images on AWS and these images can be customized at runtime through the **User data**.
- Red Hat
- Ubuntu
- Fedora
- Windows

To create our own image, we could use **customized Amazon Machine Images**.
- when we need pre-installed packages
- faster boot time, faster deploy when autoscaling
- control over the security and maintenance of AMI
- Active Directory (AD) Integration
- you can also use available AMIs from the AWS Marketplace
- you can also sell your own in the AWS Marketplace
- AMIs are stored in your **S3 Bucket**.
- Pricing is based on S3 Bucket space being used by the AMI
- Do not use AMIs that you don't trust

Note that **AMIs are REGION-SPECIFIC**, but you can copy it to another region.

#### SAMPLE LAB ####

1.  Launch an instance, and then copy the script below and paste on the **User data** field during instance creation.

    ```bash
    #!/bin/bash

    # Installs httpd
    sudo yum update -y
    sudo yum install -y httpd
    sudo systemctl enable httpd
    sudo systemctl start httpd

    # creates sample testpage
    echo 'Ephesians 3:20!' > /var/www/html/index.html
    ```

2.  Log in to instance once it's running and check if httpd is installed and running. Also check if the testpage was created

        systemctl status httpd
        cat /var/www/html/index.html

3.  Get the instance public IP and open the site inside your browser. You should see something like this.

    ![](../Images/sample-lab-ami.png)

4.  Create an AMI from this instance right-clicking on the instance and then selecting **Actions > Images and Templates > Create Image**

    ![](../Images/sample-lab-ami-2.png)

5.  Fill-in **image name** and then hit **Create Image** at the bottom.

    ![](../Images/sample-lab-ami-3.png)

6.  You can now view your AMI from the **AMIs** console. Select your AMI and then click **Actions > Launch**. Configure the instance and launch.

    ![](../Images/sample-lab-ami-4.png)

7.  Going back to the EC2 Main page, you should now see the second instance. Copy it's public ip and access it through your browser. You should see the same testpage.

    ![](../Images/sample-lab-ami-4.png)

________________________________________________________________

## CROSS-ACCOUNT AMI COPY ##

Note that you can share your AMI with another AWS account
- you are still the owner of that shared AMI
- if AMI is copied to another region, they become the owner of that AMI copy.
- to prevent others from making a copy of your AMI, don't give them:

    - read access to the EBS volume (EBS-backed instance)
    - read access to the associated S3 bucket (Instance store-backed AMI )

- You can't copy an encrypted AMI shared from another account
- if snapshot/key is shared, copy the snapshot and encrypt it with your own key
- you can't copy an AMI with an associated **billingProduct** shared from another account
- instead, you can launch an instance from that AMI and then create an AMI from your instance.
________________________________________________________________

## ELASTIC IPs ##

Fixed public IP which you can own, as logn as you don't delete it.
- can only be attached to **one instance at a time**
- can be re-mapped across instances
- you only pay for it **when you don't use it**
- release elastic IP when not in use to prevent costs
- **Max** of **5 Elastic IPs** - you can request AWS to increase that

**WHY USE AN ELASTIC IP?**

- To mask a failure from the outside - elastic IPs can be immediately re-mapped to another instance

**OVERALL**

- use elastic IPs **only when needed**
- you can use a random public ip and register a DNS name to it
- use a Load Balancer with a statis hostname

________________________________________________________________

## CLOUDWATCH METRICS FOR EC2 ##

AWS provides and pushes these metrics for you.
- **Basic Monitoring** - metrics collected at 5 minutes interval
- **Detailed Monitoring** - metrics collected at 1 minute interval
- The metrics include

    - **Status Check** 
        - Instance Status - checks EC2 VM
        - System Status - checks hardware
    - **Network Check** - Network In/out
    - **Disk Check** - Read/Write (only for instance store)
    - **CPU Check** - CPU utilization + Credit usage

You can also have your own **custom metrics**.

- **Basic Resolution** - 1 minute resolution
- **High Resolution** - up to 1 second resolution

For custom metrics, make sure your EC2 instance role has necessary IAM permissions.

**NOTE:** RAM is for user's custom metrics, it is not provided by AWS.
________________________________________________________________

## CUSTOM CLOUDWATCH METRICS FOR EC2 ##

Sample custom metrics can include
- RAM
- swap usage
- any custom metric for your application

**SAMPLE LAB**

1.  Download a script from [AWS Documentation page](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/mon-scripts.html).
2.  Push the RAM as a custom metric.


<code>*EDEN: I was supposed to do this lab but the scripts have been deprecated by AWS. You can now use CLOUDWATCH AGENT to collect metrics and logs. You can read more about it [here](https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/Install-CloudWatch-Agent.html)*</code>

________________________________________________________________

## CLOUDWATCH LOGS FOR EC2 ##

EC2 instance will not send any logs **by default** to CloudWatch. To do this, we must install a **CloudWatch Agent** on the instance.
- make sure IAM permissions are correct
- EC2 instance and on-prem servers can both be setup with CloudWatch Agent


#### PRACTICE LAB ###

To install the older CloudWatch Logs Agent on our EC2 instance, we'll be following this [page.](https://docs.aws.amazon.com/AmazonCloudWatch/latest/logs/QuickStartEC2Instance.html)

1.  **Configure Your IAM Role or User for CloudWatch Logs**

    - Go to IAM > Roles > Create Role > EC2.
    - Then on search bar, look for **CloudWatchFullAccess**.
    - Hit next until you reach last page.
    - Put a role name and a brief description.

    ![](../Images/cw-logs-agent-1.png)

    ![](../Images/cw-logs-agent-2.png)

    - Once you've created the role, attach it to your running EC2 instances
    - select instance then **Actions > Security > Modify IAM Role**

        ![](../Images/cw-logs-agent-2-5.png)

2.  **Install and Configure CloudWatch Logs on an Existing Amazon EC2 Instance**
    - since I currently have 2 instances running, I'll use the command below to install CloudWatch Logs on both:
        
            sudo yum install -y awslogs

        ![](../Images/cw-logs-agent-3.png)

3.  **Edit the /etc/awslogs/awslogs.conf file to configure the logs to track**
    - we can leave this on default for now
    - if you want to read more, you can check the official [AWS Quick Start](https://docs.aws.amazon.com/AmazonCloudWatch/latest/logs/QuickStartEC2Instance.html)
    - we'll just see the important details in that file
    - note that the only file that will be sent to CloudWatch is the **/var/log/messages**

    ```bash
    [ec2-user@ip-172-31-29-157 ~]$ tail -5 /etc/awslogs/awslogs.conf 
    file = /var/log/messages
    buffer_duration = 5000
    log_stream_name = {instance_id}
    initial_position = start_of_file
    log_group_name = /var/log/messages
    ```

4.  **By default, the /etc/awslogs/awscli.conf points to the us-east-1 region. To push your logs to a different region, edit the awscli.conf file and specify that region.**
    
    - Note that I'm on ap-southeast-1 region
        
    ```bash
    sudo sed -i "s/us-east-1/ap-southeast-1/" /etc/awslogs/awscli.conf
    ```

5.  **If you are running Amazon Linux 2, enable and start the awslogs service with the following command.**

    ```bash
    sudo systemctl enable awslogsd
    sudo systemctl start awslogsd
    sudo systemctl status awslogsd
    ```

6.  **The logs should now start streaming to CloudWatch.**
    - You might need to wait for a bit to see the logs

        ![](../Images/cw-logs-agent-4.png)

_____________________________________________________________

<code>EDEN: I was not initially seeing the /var/log/messages in the Log Groups in the CloudWatch console even after a couple of minutes have passed already.</code>

<code>So I checked online and saw this [article](https://aws.amazon.com/premiumsupport/knowledge-center/push-log-data-cloudwatch-awslogs/) on how to troubleshoot when log groups doesn't appear in the CloudWatch console. It suggested to check */var/log/awslogs.log* and I sure did saw an error which was preventing the logs from being pushed to CloudWatch. It was a **NoCredentialsError: Unable to locate credentials**.</code>

<code>Turns out I forgot to attach the IAM role I just created to the EC2 instances. After attaching the role and then restarting the awslogsd service in both instances, I checked the */var/log/awslogs.log* once again to see if the error is still there.</code>

<code>What I saw in the file was a bunch of JSON-formatted text - success.
I refreshed the CloudWatch console and the /var/log/messages log group is now there.</code>
____________________________________________________

<!-- 2021-02-01 05:38:59 -->

## UNIFIED CLOUDWATCH AGENT ##

Agent that does metrics and logs at the same time.
- collect more system-level metrics from EC2 instances across operating systems
- metrics can include in-guest metrics
- collect system-level metrics from on-premise servers
- retrieve custom metrics from applications or services using **StatsD** and **collectd** protocols
- you can download/install agent manually or use SSM

For this one, we'll do a sample laba dn we'll be utilizing a role that has **CloudWatchAgentAdminPolicy** attached.

This policy allows us to collect logs and send custom metrics into CloudWatch. It has also the *SSM:GetParameter* and *SSM:PutParameter* which allows us to fetch and push configuration from/to SSM.

The main purpose of the **Unified CloduWatch Agent** is to have a stored parameter** which can always be pulled by your isntances to run the agent.

**SAMPLE LAB**

1.  Create a role with **CloudWatchAgentAdminPolicy** attached.

    ![](../Images/cw-ucwa-1.JPG)
    ![](../Images/cw-ucwa-2.png)

2.  Create an instance and attach the newly created role.
3.  Connect to the instance and install a simple Apche web server.
    Enable and start httpd.

    ```bash
    sudo yum install -y httpd
    sudo systemctl enable httpd
    sudo systemctl start httpd
    sudo systemctl status httpd
    ```
4.  Create a simple index.html file.

    ```bash
    echo 'Hello from the Other side!' > /var/www/html/index.html
    ```
5.  Copy the public DNS of the instanc eand open it in a browser. You should see something like this.

    ![](../Images/cw-ucwa-3.png)

6.  We will be using two logs for the httpd service. We will be streamign both of these logs to CloudWatch.

    ```bash
    [root@ip-172-31-47-113 ec2-user]# ll /var/log/httpd/
    total 8
    -rw-r--r-- 1 root root 733 Jan 31 22:04 access_log
    -rw-r--r-- 1 root root 967 Jan 31 22:01 error_log
    ```

7. Next step is to setup the CloudWatch Unified Agent on the instance. We start with downloading the rpm file.

    ```bash
    wget https://s3.amazonaws.com/amazoncloudwatch-agent/amazon_linux/amd64/latest/amazon-cloudwatch-agent.rpm
    ```

8. Install the CloudWatch Agent on the instance.

    ```bash
    sudo rpm -U ./amazon-cloudwatch-agent.rpm
    ```

9.  Run the wizard which will do the agent configuration setup for us.

    ```bash
    sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-config-wizard
    ```

    Note that you'll ne prompted to answer questions. Use the number corresponding to the answers below.

    | Questions | Answers |
    |:- | :- |
    | On which OS are you planning to use the agent? | linux |
    | Are you using EC2 or On-Premises hosts? | EC2 |
    | Which user are you planning to run the agent? | root |
    | Do you want to turn on StatsD daemon? | Yes |
    | Which port do you want StatsD daemon to listen to? | 8125 |
    | What is the collect interval for StatsD daemon? | 10s |
    | What is the aggregation interval for metrics collected by StatsD daemon? | 60s |
    | Do you want to monitor metrics from CollectD? | Yes |
    | Do you want to monitor any host metrics? e.g. CPU, memory, etc. | Yes |
    | Do you want to monitor cpu metrics per core? Additional CloudWatch charges may apply. | Yes |
    | Do you want to add ec2 dimensions (ImageId, InstanceId, InstanceType, AutoScalingGroupName) into all of your metrics if the info is available? | Yes |
    | Would you like to collect your metrics at high resolution (sub-minute resolution)? This enables sub-minute resolution for all metrics, but you can customize for specific metrics in the output json file. | 60s |
    | Which default metrics config do you want? | Basic |

    After answering the first set of questions, you'll be shown the current configuration:

    ```bash
    Current config as follows:
    {
            "agent": {
                    "metrics_collection_interval": 60,
                    "run_as_user": "root"
            },
            "metrics": {
                    "append_dimensions": {
                            "AutoScalingGroupName": "${aws:AutoScalingGroupName}",
                            "ImageId": "${aws:ImageId}",
                            "InstanceId": "${aws:InstanceId}",
                            "InstanceType": "${aws:InstanceType}"
                    },
                    "metrics_collected": {
                            "collectd": {
                                    "metrics_aggregation_interval": 60
                            },
                            "disk": {
                                    "measurement": [
                                            "used_percent"
                                    ],
                                    "metrics_collection_interval": 60,
                                    "resources": [
                                            "*"
                                    ]
                            },
                            "mem": {
                                    "measurement": [
                                            "mem_used_percent"
                                    ],
                                    "metrics_collection_interval": 60
                            },
                            "statsd": {
                                    "metrics_aggregation_interval": 60,
                                    "metrics_collection_interval": 10,
                                    "service_address": ":8125"
                            }
                    }
            }
    }
    ```

    You'll then be ask with a second set of questions. Use the number corresponding to the answers below.

    | Questions | Answers |
    | :- | :- |
    | Are you satisfied with the above config? Note: it can be manually customized after the wizard completes to add additional items. | Yes |
    | Do you have any existing CloudWatch Log Agent (http://docs.aws.amazon.com/AmazonCloudWatch/latest/logs/AgentReference.html) configuration file to import for migration?<br>(This is used if you have an existing agent on the instance that you want to import. In our case, it's our first time installing the agent so we'll just choose No) | No |
    | Do you want to monitor any log files?<br>(This will be the two files that we want to stream to CloudWatch) | Yes |
    | Log file path | /var/log/httpd/access_log |
    | Log group name | [access_log] |
    | Log stream name | [{instance_id}] |
    | Do you want to specify any additional log files to monitor? | /var/log/httpd/error_log |
    | Log group name | [error_log] |
    | Log stream name | [{instance_id}] |
    | Do you want to specify any additional log files to monitor? | No | 

    You'll again be shown the current configurations.

    ```bash
    Saved config file to /opt/aws/amazon-cloudwatch-agent/bin/config.json successfully.      
    Current config as follows:
    {
            "agent": {
                    "metrics_collection_interval": 60,
                    "run_as_user": "root"
            },
            "logs": {
                    "logs_collected": {
                            "files": {
                                    "collect_list": [
                                            {
                                                    "file_path": "/var/log/httpd/access_log",                                                "log_group_name": "access_log",
                                                    "log_stream_name": "{instance_id}"       
                                            },
                                            {
                                                    "file_path": "/var/log/httpd/error_log", 
                                                    "log_group_name": "error_log",
                                                    "log_stream_name": "{instance_id}"       
                                            }
                                    ]
                            }
                    }
            },
            "metrics": {
                    "append_dimensions": {
                            "AutoScalingGroupName": "${aws:AutoScalingGroupName}",
                            "ImageId": "${aws:ImageId}",
                            "InstanceId": "${aws:InstanceId}",
                            "InstanceType": "${aws:InstanceType}"
                    },
                    "metrics_collected": {
                            "collectd": {
                                    "metrics_aggregation_interval": 60
                            },
                            "disk": {
                                    "measurement": [
                                            "used_percent"
                                    ],
                                    "metrics_collection_interval": 60,
                                    "resources": [
                                            "*"
                                    ]
                            },
                            "mem": {
                                    "measurement": [
                                            "mem_used_percent"
                                    ],
                                    "metrics_collection_interval": 60
                            },
                            "statsd": {
                                    "metrics_aggregation_interval": 60,
                                    "metrics_collection_interval": 10,
                                    "service_address": ":8125"
                            }
                    }
            }
    }
    Please check the above content of the config.
    The config file is also located at /opt/aws/amazon-cloudwatch-agent/bin/config.json.     
    Edit it manually if needed.
    ```

    Note that the configuration can be modified anytime by editing the **/opt/aws/amazon-cloudwatch-agent/bin/config.json** file

    This will be followed by a final set fo questions.

    | Questions  | Answers | 
    | :- | :- |
    | Do you want to store the config in the SSM parameter store? | yes |
    | What parameter store name do you want to use to store your config? (Use 'AmazonCloudWatch-' prefix if you use our managed AWS policy) | [AmazonCloudWatch-linux] |
    | Which region do you want to store the config in the parameter store?<br>(This will depend on the region where your isntance is.) | [ap-southeast-1] |
    | Which AWS credential should be used to send json config to parameter store? | From SDK | 

    once everythign is good, you should see a successful confirmation after the last question.

    ```bash
    Successfully put config to parameter store AmazonCloudWatch-linux.
    Program exits now.
    ```

10. We now proceed to **AWS Systems Manager(SSM) > Parameter Store**. Click the one created earlier - **AmazonCloudWatch-Linux**. This can now server as a parameter configuration which can be used when you create another instance and you want to install CloudWatch Unified Agent onto it as well.

    ![](../Images/ssm.png)

11. To ensure the process will not fail, we'll have to first create the **/usr/share/collectd/types.db** file

    ```bash
    mkdir -p mkdir -p /usr/share/collectd/
    touch /usr/share/collectd/types.db
    ```

12. To start the agent, we have two options

    ```bash
    # Option 1 - boot CloudWatch agent from an ssm configuration-parameter-store name
    sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -c ssm:<insert-parameter-store-name-here> -s

    # Option 2 - directly boot it from a file in a file path
    sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -c file:<insert-configuration-file-path-here> -s
    
    ```

    For our lab, we will use the first option

    ```bash
    sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -c ssm:AmazonCloudWatch-linux -s
    ```

13. We should now be seeing the CloudWatch logs and metrics in CloudWatch. Go to **CloudWatch > Log groups**.

    ![](../Images/cw-ssm-1.png)

________________________________________________________

#### WHAT ARE THE METRICS THAT BE COLLECTED BY THE CLOUDWATCH AGENT? ####

You can see a complete listing of the metrics that can collected by the CloudWatch agent in the [AWS Documentation page](https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/metrics-collected-by-CloudWatch-agent.html). These are just a few of them:

- cpu_time_active
- cpu_time_guest
- cpu_time_guest_nice
- swap_free
- swap_used
- swap_used_percent

________________________________________________________

## AWS Lambda ##

AWS Lambda is one of AWS' **serverless** products - this means you don't manage the underlying infrastructure
- **event-driven** where code runs in response to events
- Lambda runs functions
- you just upload code, code gets executed when triggered
- code can be triggered by CLI, SDK, or through a schedule
- Lambda scales by concurrently executing functions up to your **default limit: 1000**

<img src="../Images/lambda.png" width=700>

In addition, you also need to know about Lambda:

- **max execution time: 15 minutes**
- you get billed by amount of time your function runs and the amount of memory you allocate to your function
- this means you can't have a code running past 15 minutes
- you can configure your functions to access resources inside of a VPC


### AWS Lambda - Concurrency ###

<img src="../Images/lambda-2.png" width=700>


### AWS Lambda - VPC ###

You can connect your Lambda function to your VPC through an **Elastic Network Interface (ENI)**. Lambda configures the ENI, you just have to give it your VPC configuration.
- Lambda is a public service so it can access the internet
- however, if Lambda is connected to a VPC, it routes data through the VPC
- this means you'll need a NAT gateway or internet gateway to go out the VPC

<img src="../Images/lambda-3.png" width=700>


### AWS Lambda - On a schedule ###

You can also configure Lambda to run on a schedule using **CloudWatch Events.**

<img src="../Images/lambda-4.png" width=700>

________________________________________________________
