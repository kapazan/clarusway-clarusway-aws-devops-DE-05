# Hands-on CW-01 : Setting Cloudwatch Alarm Events, and Logging

Purpose of the this hands-on training is to create Dashboard, Cloudwatch Alarm, configure Events option and set Logging up.

## Learning Outcomes

At the end of the this hands-on training, students will be able to;

- create Cloudwatch Dashboard.

- settings Cloudwatch metrics.

- create an Alarm.

- create an Events.

- configure Logging with Agent.


## Outline

- Part 1 - Prep - Launching an Instance

- Part 2 - Creating a Cloudwatch dashboard

- Part 3 - Creating an Alarm

- Part 4 - Creating an Events with Lambda

- Part 5 - Configure Logging with Agent 

## Part 1 - Prep - Launching an Instance

STEP 1 : Create a EC2

- Go to EC2 menu using AWS console

- Launch an Instance
- Configuration of instance.

```text
AMI             : Amazon Linux 2023
Instance Type   : t2.micro
Configure Instance Details:
  - Monitoring ---> Check "Enable CloudWatch detailed monitoring"
Tag             :
    Key         : Name
    Value       : Cloudwatch_Instance
Security Group ---> Allows ssh, http to anywhere
```
- Set user data.

```bash
#! /bin/bash

dnf update -y
dnf install nginx -y
cd /usr/share/nginx/html
chmod o+w /usr/share/nginx/html
rm index.html
wget https://raw.githubusercontent.com/awsdevopsteam/route-53/master/index.html
wget https://raw.githubusercontent.com/awsdevopsteam/route-53/master/ken.jpg
systemctl enable nginx
systemctl start nginx 
```

## Part 2 - Creating a Cloudwatch dashboard

- Go to the Cloudwatch Service from AWS console.

- Select Dashboards from left hand pane

- Click "Create Dashboard"
```
Dashboard Name: Clarusway_Dashboard
```

- Select a widget type to configure as "Line"  ---> Next

- Select "Metrics"  ----> Tap configure button

- Select "EC2" as a metrics

- Select "Per-instance" metrics

- Select "Cloudwatch_Instance", "CPUUtilization"  ---> Click "create widget"

- Show EC2 CPUUtilization Metrics.

## Part 3 - Create an Alarm.

- Select Alarms on left hand pane

- click "Create Alarm"

- Click "Select metric"

- Select EC2 ---> Per-Instance Metrics ---> "CPUUtilization" ---> Select metric

```bash
Metric      : change "period" to 1 minute and keep remaining as default
Conditions  : 
  - Treshold Type                 : Static
  - Whenever CPUUtilization is... : Greater
  - than...                       : 60
```

- click next

```bash
Notification:
  - Alarm state trigger : In alarm
  - Select an SNS topic : 
    - Create new topic
      - Create a new topic: Clarus-alarm
      - Email endpoints that will receive the notification: <your email address>
    - create topic

EC2 action
  - Alarm state trigger
    - In alarm ---> Select "Stop Instance"
```

- click next

- Alarm Name  : My First Cloudwatch Alarm
  Description : My First Cloudwatch Alarm

- click next --- > review and click create alarm

- go to email box and confirm the e-mail sent by AWS SNS

- go to the terminal and connect EC2 instance via ssh

- install and run the stress tool:

```bash
sudo dnf install stress -y
stress --cpu 80 --timeout 20000
```
- Go to dashboard and check the EC2 metrics

- you will receive a alarm message to your email and this message trigger to stop your EC2 Instance.

- go to EC2 instance list and show the stopped instance

- restart this instance.

### Part 4 - CloudWatch Events with Lambda

#### Step 1: Create Role

- Go to IAM console a create Policy named "start-stop-instance" including these json script seen below:

```text 
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "logs:CreateLogGroup",
                "logs:CreateLogStream",
                "logs:PutLogEvents"
            ],
            "Resource": "arn:aws:logs:*:*:*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "ec2:Start*",
                "ec2:Stop*"
            ],
            "Resource": "*"
        }
    ]
}

```
- than create a IAM Role that will be used in Lambda Function 

- Click Roles on left hand pane

- click create role

- select Lambda ---> click next permission

- select newly created Policy named "start-stop-instance"  ---> Next

- Add tags ---> Next

- Review
	- Role Name :start-stop-instance
  - Role Description: start-stop-instance

- click create role

#### Step 2: Creating Stop Lambda Functions

- Go to Lambda Service on AWS Console

- Functions ----> Create Lambda function
```text
1. Select Author from scratch
  Name: Stop_Instance
  Runtime: Python 3.10
  Role: 
    Existing Role: "start-stop instance"
  Click 'Create function'
```

- Configuration of Function Code

- In the sub-menu of configuration go to the "Function code section" and paste code seen below

```python
import boto3
region = 'us-east-1'
instances = ['i-02c107da60f5dad15']#DON'T FORGET TO CHANGE ME
ec2 = boto3.client('ec2', region_name=region)

def lambda_handler(event, context):
    ec2.stop_instances(InstanceIds=instances)
    print('stopped your instances: ' + str(instances))

```
- Don't forget to change Instance ID in the Code. 

- Click "DEPLOY" button


#### Step 3 Testing your function - Create test event

Click 'Test' button and opening page Configure test events
```
Select: Create new test event
Event template: Hello World
Event name: teststop
Input test event as;

{}

Click 'Create'
Click 'Test'
```
You will see the message Execution result: 

- Than check the EC2 instance that it it stopped. 

#### Step 4: Creating Start Lambda Functions

- Go to Lambda Service on AWS Console

- Functions ----> Create Lambda function
```text
1. Select Author from scratch
  Name: Start_Instance
  Runtime: Python 3.10
  Role: 
    Existing Role: "start-stop-instance"
  Click 'Create function'
```

- Configuration of Function Code

- In the sub-menu of configuration go to the "Function code section" and paste code seen below

```python
import boto3
region = 'us-east-1'
instances = ['i-02c107da60f5dad15']
ec2 = boto3.client('ec2', region_name=region)

def lambda_handler(event, context):
    ec2.start_instances(InstanceIds=instances)
    print('started your instances: ' + str(instances))
```

- Don't forget to change Instance ID in the Code. 

- Click "DEPLOY" button

#### Step 5 Testing your function - Create test event

Click 'Test' button and opening page Configure test events
```
Select: Create new test event
Event template: Hello World
Event name: teststart
Input test event as;

{}

Click 'Create'
Click 'Test'
```
You will see the message Execution result: 

- Than check the EC2 instance that it will be restarted thanks to the Lambda 

#### Step 6 Creating Stop-Cloudwatch Event

- Go to the CloudWatch Console and from left hand menu under the Event sub-section
- Click on "Amazon EventBridgeGo" 
Event Bus -------> Default(keep it as is)
Rules     -------> Create Rule 
Click on "Create Rule"
```
- Name                   : cw_event_stop
- Description - optional : cw_event_stop
- Event Bus              : Default(keep it as is)
- Rule type              : "Schedule"
```
- Click on Next

- Define schedule

```text
- Sample event     :  Keep it as is
- Schedule pattern : A fine-grained schedule 
                    Cron expression: 45 19 ? * MON-FRI * 
                    Note: (- Explain the cron parameters. 
                           - Choose Local Time 
                           - Change cron expression according to session time to be triggered within 3 minutes.)

```

- Click on "Next: "

- Select the Target parameters:

```text
Targets: 
- AWS service
- Select Target: Lambda Function
                   - Function: Stop_Instance

```
- Click on "Next "
- Click "Configure Details"
- Click "Create Rule."

Show the Instance state that Event is gonna stop instance. 

#### Step 7 Creating Start-Cloudwatch Event

- Go to the CloudWatch Console and from left hand menu under the Event sub-section
- Click on "Amazon EventBridgeGo" 
Event Bus -------> Default(keep it as is)
Rules     -------> Create Rule 
Click on "Create Rule"
```
- Name                   : cw_event_start
- Description - optional : cw_event_start
- Event Bus              : Default(keep it as is)
- Rule type              : "Schedule"
```
- Click on Next

- Define schedule

```text
- Sample event     :  Keep it as is
- Schedule pattern : A fine-grained schedule 
                    Cron expression: 50 19 ? * MON-FRI * 
                    Note: (- Explain the cron parameters. 
                           - Choose Local Time 
                           - Change cron expression according to session time to be triggered within 3 minutes.)

```

- Click on "Next: "

- Select the Target parameters:

```text
Targets: 
- AWS service
- Select Target: Lambda Function
                   - Function: Start_Instance

```
- Click on "Next "
- Click "Configure Details"
- Click "Create Rule."

- Show the Instance state that Event is gonna start instance. 

### Part 5 - Configure Logging with Agent 

STEP 1 : Create second EC2 Instance

- Go to EC2 menu using AWS console

- Launch an Instance
- Configuration of instance.

```text
AMI             : Amazon Linux 2023
Instance Type   : t2.micro
Tag             :
    Key         : Name
    Value       : Cloudwatch_Log
Security Group ---> Allows ssh, http to anywhere
```
- Set user data.

```bash
#! /bin/bash

dnf update -y
dnf install nginx -y
cd /usr/share/nginx/html
chmod o+w /usr/share/nginx/html
rm index.html
wget https://raw.githubusercontent.com/awsdevopsteam/route-53/master/index.html
wget https://raw.githubusercontent.com/awsdevopsteam/route-53/master/ken.jpg
systemctl enable nginx
systemctl start nginx 
```

STEP 2 : Create IAM role

- Go to IAM role on AWS console

- Click Roles on left hand pane

- click create role

- select EC2 ---> click next permission

- select "CloudWatchLogsFullAccess"  ---> Next

- Add tags ---> Next

- Review
	- Role Name : Claruscloudwatchlog  
  - Role Description: Clarusway Cloudwatch EC2 logs access role

- click create role

- Go to instance named "Cloudwatch_Log" ---> Actions ---> Security ---> Modify IAM role ---> Attach "CloudWatchLogsFullAccess" role ---> Apply

STEP 3:  Install and Configure the CloudWatch Logs Agent

- Go to the terminal and connect to the Instance named "Cloudwatch_Log"

- Install cloudwatch log agent:
```bash
sudo dnf install amazon-cloudwatch-agent -y
```
- Enable it:
```bash
sudo systemctl enable amazon-cloudwatch-agent
```
- Use config wizard to create the config file:
```bash
sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-config-wizard
```
- You have many options here like creating custom metrics and saving the config file to SSM but for the sake of this handson 
we'll just configure it for the nginx logs.

- Configure as seen below:

```bash
On which OS are you planning to use the agent?
1. linux
2. windows
3. darwin
default choice: [1]: 1

Are you using EC2 or On-Premises hosts?
1. EC2
2. On-Premises
default choice: [1]: 1

Which user are you planning to run the agent?
1. root
2. cwagent
3. others
default choice: [1]: 1

Do you want to turn on StatsD daemon?
1. yes
2. no
default choice: [1]: 2

Do you want to monitor metrics from CollectD? WARNING: CollectD must be installed or the Agent will fail to start
1. yes
2. no
default choice: [1]: 2

Do you want to monitor any host metrics? e.g. CPU, memory, etc.
1. yes
2. no
default choice: [1]: 2

Do you have any existing CloudWatch Log Agent configuration file to import for migration?
1. yes
2. no
default choice: [2]: 2

Do you want to monitor any log files?
1. yes
2. no
default choice: [1]: 1

Log file path: 
/var/log/nginx/access.log

Log group name:
default choice: [access.log]: Enter

Log stream name:
default choice: [{instance_id}]: Enter

Log Group Retention in days: 2

Do you want to specify any additional log files to monitor?
1. yes
2. no
default choice: [1]: 1

Log file path:
/var/log/nginx/error.log

Log group name:
default choice: [error.log]: Enter

Log stream name:
default choice: [{instance_id}]: Enter

Log Group Retention in days: 2

Do you want to specify any additional log files to monitor?
1. yes
2. no
default choice: [1]: 2

Do you want to store the config in the SSM parameter store?
1. yes
2. no
default choice: [1]: 2
```

- Start the agent using the config file:
```bash
sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -s -c file:/opt/aws/amazon-cloudwatch-agent/bin/config.json
```

STEP 4: Get the logs

- Go to the EC2 instance, grab the public IP address and paste it to the browser. Logs should be sent to the cloudwatch logs.

- Go to the Cloudwatch and select Log groups. 

- Select the created log groups named "access.log" and "error.log" ---> Show the created "log streams".

