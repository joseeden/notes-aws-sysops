
# 06 - EBS and EFS #
_________________________________________

This note will dive in to the available storage options for EC2, EBS and EFS, but from a SysOps perspective. 

![](../Images/06-preview.png)

The main concepts that we'll focus on are:
- Performance
- Troubleshooting
- Operations
- Monitoring

This note is broken down into these sections:

1.  [EBS Overview](#ebs-overview)
2.  [EBS Volume Types](#ebs-volume-types)
3.  [EBS Volume Burst](#ebs-volume-burst)
4.  [EBS Computing Throughput](#ebs-computing-throughout)
5.  [EBS Operation Volume Resizing](#ebs-operation-volume-resizing)
6.  [EBS Operation Snapshots](#ebs-operation-snapshots)
7.  [EBS Operation Volume Migration](#ebs-operation-volume-migration)
8.  [EBS Operation Volume Encryption](#ebs-operation-volume-encryption)
9.  [EBS vs. Instance Store](#ebs-vs-instance-store)
10. [EBS for SysOps](#ebs-for-sysops)
11. [EBS Raid Configurations](#ebs-raid-configurations)
12. [CloudWatch and EBS](#cloudwatch-and-ebs)
13. [EFS Overview](#efs-overview)
______________________________________________

## EBS OVERVIEW ##

