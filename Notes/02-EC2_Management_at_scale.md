<!-- 2021-02-01 08:26:28 -->

# 02 - EC2 Management at scale #
______________________________________________

<p align=center>
    <img src="../Images/02-preview.png">
</p>

This section will focus on two topics that are important for the AWS SysOps exam: **SSM and Opsworks**. By the end of this notes, you'll be able to answer the following questions:

- How to manage an EC2 instance fleet and on-premise servers?
- How to apply patches at scale?
- How to run automations?
- How to store parameters?
- How to use Chef and Puppet?

This note will be broken down into the following sections:

1.  [Systems Manager Overview](#aws-systems-manager-overview)
2.  [EC2 Instances with SSM Agent](#lab-ec2-instances-with-ssm-agent)
3.  [AWS Tags and Resource Groups](#aws-tags-and-resource-groups)
4.  [SSM Documents and Run Command](#ssm-documents-and-run-command)
5.  [SSM Inventory and Patches](#ssm-inventory-and-patches)
6.  [SSM Secure Shell]()
7.  [What if I lose my EC2 SSH Key?]()
8.  [SSM Parameter Store Overview]()
9.  [AWS Opsworks Overview]()
______________________________________________

## AWS SYSTEMS MANAGER OVERVIEW ##

This helps you manage your EC2 instances and on-premise systems at scale.

- Get operational insight about the state of your infrastructure
- Detect problems and **automated patches** for enhanced compliance
- Works both for Windows and Linux OS
- Integrated with **CloudWatch Metrics/dashboard** and **AWS Config**
- Free service

Main features:

- Resource Groups
- Insights
    - Insight Dashboard
    - Inventory
    - Compliance
- **Parameter Store**
- Action
    - automation (shutting down ec2,etc.)
    - **Run command**
    - **Session Manager**
    - **Patch Manager**
    - Maintenance Windows
    - State Manager

<p align=center>
    <img src="../Images/ssm-10.png">
</p>

**HOW SYSTEMS MANAGER WORKS**
The SSM agent must first be installed on our EC2 instances which will then report to the SSM service.
- agent is installed by default for Amazon Linux AMI and some Ubuntu AMI
- if instance can't talk to  SSM service, most likely an issue with the SSM Agent

<p align=center>
    <img src="../Images/ssm-11.png" width=500>
</p>

___________________________________________________

### LAB - EC2 INSTANCES WITH SSM AGENT ###

We will setting up 3 instances with SSM agent. We will use Amazon Linux AMI since it comes pre-built with the SSM agent

1.  Create a role with attached **AmazonEC2RoleforSSM** - this is the default policy.

    ![](../Images/ssm-12.png) 

2.  Create three instances and attach the newly created role.
    For the security gruop, create a new one and remove any rule attached to it.

3.  Go to **Systems Manager > Managed instances**. You should see the three newly created instances there.

    ![](../Images/ssm-13.png)

___________________________________________________

## AWS TAGS AND RESOURCE GROUPS ##

**AWS TAGS**
Key-value pairs that can be attached to different AWS resources (but mostly used in EC2).
- free-naming convention
- can be used for resource-grouping, cost-allocation, automation
- better to have many tags than few!

**RESOURCE GROUPS**
Create, view, or manage logical groups of resources using the tags
- can be based on 
    - application
    - layers of application task
    - prod vs. dev environments
- this can be done thru SSM
- region-specific - you'll need to create different RG per region
- works with EC2, S3 Lambda, DynamoDB

___________________________________________________

### LAB - TAGS AND RESOURCE GROUPS ###

We'll use the same three instances from the last lab.

1.  Create tags for each instance. Go to **EC2 > Select instance > Actions > Instance Settings > Manage Tags**. use the value below for each instance.

    | Instance | Tags | Value |
    | --- | --- | --- |
    | Instance 1 | Name | eden-dev-svr |
    | | Environment | dev | 
    | | Team | anaheim |
    | Instance 2 | Name | eden-prod-svr |
    | | Environment | prod | 
    | | Team | anaheim |
    | Instance 1 | Name | eden-dev2-svr |
    | | Environment | dev | 
    | | Team | orlando |

2.  The **Resource groups** can be initially be accessed at the top of the UI console but it has been changed for the new update. You can read more in the [AWS Documentation](https://docs.aws.amazon.com/ARG/latest/userguide/welcome.html). To access RG, go to **Services > Management and Governance > Resource Groups and Tag Editors**

3.  In the Resource Groups console, click **Create a resource group**.
    You will then be given two options to use:

    - Tag based
    - CloudFormation stack based

    Since we did the tags manually, we'll select **tag-based**.
    
    ![](../Images/rg-1.png)
    
    For the **Grouping-criteria**, type instances and select EC2 instances.
    For the **Tags**, we want to select just the instances with Environment=dev.

    ![](../Images/rg-2.png)

    At the bottom, you can see a preview of the **Group Resources**.
    You can also provide a **Group Name** and **Group Description**.

    ![](../Images/rg-5.png)

    When you're done, hit **Create group**.

4.  Create another one for prod instances and another one for Anaheim instances. Follow the same steps in number 3. You should see all three resource groups in **Saved Resource Groups**.

    ![](../Images/rg-6.png)

    We can now apply OS patching, automations, and the sorts on the instances based on these groups.

______________________________________________________________

## SSM DOCUMENTS AND RUN COMMAND ##

**SSM DOCUMENTS**
You can define parameters and actions in the SSM Documents.
- can be in JSON or YAML format
- wide number of documents are available in AWS
- it can be applied to:
    - patch manager
    - state manager
    - automation
    - parameter store
    - run command
    - to execute a document, we use the **run command**

To see all the available documents, go to **Systems Manager > Documents**.

**RUN COMMAND**
You can execute a document or a script using the *run command*.
- you can run command across multiple instances(using RGs)
- you can use **Rate Control/Error Control**
- integrated with IAM and CloudTrail
- no need to SSH to run a command
- results can be printed in the console

______________________________________________________________

### LAB - SSM DOCUMENTS AND RUN COMMAND ###

We'll be using the same lab all throughout this section. For this one, we we will be using the SSM Documents to install an Apache server on all three instances.

1.  Recall that there is no inbound rule on the security group we created for this lab - **SSM-Managed-Instances**. Edit the security group to allow HTTP/HTTPS.

    ![](../Images/ssm-14.png)

2. Go to **Systems Manager > Documents > Create command or session**. You can use the details below.

    | Section | Value | 
    | --- | --- |
    | Name | Install-configure-apache |
    | Content | YAML |

    For the actual YAML code, you can use the [install-apache.yaml](../install-apache.yaml) below. Click **Create document** once you're done.

    ```YAML
    ---
        schemaVersion: '2.2'
        description: YAML file to install Apache on the instances
        parameters:
            Message:
                type: "String"
                description: "Welcome Message"
                default: "Hello from the Other Side!"
        mainSteps:
        -
            action: aws:runShellScript
            name: configureApache
            inputs:
                runCommand:
                - 'sudo yum update -y'
                - 'sudo yum install -y httpd'
                - 'sudo systemctl start httpd'
                - 'sudo systemctl enable httpd'
                - 'echo  "{{Message}} from $(hostname -f)" > /var/www/html/index.html'
    ```

3.  To use the SSM Document we just created, fo to **Run Command > Run a command**. On the search bar, type in **Owner: Owned by me** and then select the document you created.

    ![](../Images/ssm-doc-1.png)

4.  Scroll down on the **Command parameters** section. We can change this to another value. For this one, we'll set it to "*To infinity and beyond!*".

    ![](../Images/ssm-doc-2.png)

    On the **Target** section, we can specify instance tags or manually select instances. For this we'll just select all three instances.

    ![](../Images/ssm-doc-3.png)

5.  Scroll further below. We can see the **RATE CONTROL** - this specifies how many isntances at a time in which to execute the task. This means that if our value is **3**, we can run the command for 3 instances at a time.

    **ERROR THRESHOLD** - stop the task after the task fails on a specific number of percentages or targets.

    ![](../Images/ssm-doc-4.png)

    On the **Output** section, we can choose to have the output to be written on an S3 bucket. For now we'll disable it.
    
    ![](../Images/ssm-doc-5.png)

    We can also have the output sent to CloudWatch. You can use **customRunCommand** on the **Log group name** field.

6.  Once you're done, hit **Run** at the bottom to run the task. You should see the same:

    ![](../Images/ssm-doc-6.png)

    Click refresh icon. All three instances should now show as *Succeeded*.

    ![](../Images/ssm-doc-7.png)

7.  Go to **CloudWatch > Log Groups** and then select the log we created - **customRunCommand**

    ![](../Images/ssm-doc-8.png)

    ![](Images/ssm-doc-9.png)

8.  You can also see the logs in Systems Manager. Go to **Systems Manager > Run command > select an instance > see the output at the bottom**

9.  To verify, copy the public DNS of each instance and open it in a browser. You should see the index.html with the message we edited earlier - *"To infinity and beyond!"*

    ![](../Images/ssm-doc-10.png)

_________________________________________________________

## SSM INVENTORY AND PATCHES ##