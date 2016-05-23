---
layout: posts
title: "Security Group Auditing"
date: 2016-05-22
---

In this script we will query all of our domain controllers for security events in the security log.

## Prerequisites
* You need permissions to do PowerShell remoting, and query your domain controller event logs
* You need to turn on appropriate event log autditing for your domain controllers.
* If you want to send the output through email, you also need an smtp server.

## Script Output
This script produces an HTML email.

![screen shot of result email](../img/gsga-small.png)

## The Code
See the full <a href="https://github.com/ajhstn/ajhstn.github.io/blob/master/ps/Get-SecurityGroupAuditing.ps">code</a> on GitHub.