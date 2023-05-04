# Hands-on EFS-01 : How to Create EFS & Attach the EFS to the multiple EC2 Linux Instances

## Outline

- Part 1 - Prep(EC2 SecGrp, EFS SecGrp, EC2 Linux Instance)

- Part 2 - Creating EFS

- Part 3 - Attach the EFS to the multiple EC2 Linux instances


## Part 1 - Prep (EC2 SecGrp, EFS SecGrp, EC2 Linux Instance)

### Step 1 - Create EC2 SecGrp:

- Open the Amazon EC2 console at https://console.aws.amazon.com/ec2/.

- Choose the Security Groups on left-hand menu

- Click the `Create Security Group`.

```text
Security Group Name  : EC2 SecGrp
Description          : EC2 SecGrp
VPC                  : Default VPC
Inbound Rules:
    - Type: SSH ----> Source: Anywhere
Outbound Rules: Keep it as default
Tag:
    - Key   : Name
      Value : EC2 SecGrp
```

### Step 2 - Create EFS SecGrp:

- Click the `Create Security Group`.

```text
Security Group Name  : EFS SecGrp
Description          : EFS SecGrp
VPC                  : Default VPC
Inbound Rules:
    - Type: NFS ----> Port: 2049 ------>Source: sg-EC2 SecGrp
Outbound Rules: Keep it as default
Tag:
    - Key   : Name
      Value : EFS SecGrp
```

### Step 3 - Create EC2 :

- Configure First Instance in N.Virginia

```text
AMI             : Amazon Linux 2023
Instance Type   : t2.micro
Network         : default
Subnet          : default
Security Group  : EC2 SecGrp
Tag             :
    Key         : Name
    Value       : EC2-1
```

- Configure Second Instance in N.Virginia

```text
AMI             : Amazon Linux 2023
Instance Type   : t2.micro
Network         : default
Subnet          : default
Security Group  : EC2 SecGrp
Tag             :
    Key         : Name
    Value       : EC2-2
```

## Part 2 - Creating EFS

Open the Amazon EFS console at https://console.aws.amazon.com/efs/.

- Click "Create File System" 

- Click "Customize" 
```text
General:
Name                    : FirstEFS
Storage class           : Standart
Automatic backups       : Uncheck "Enable automatic backups"
Lifecycle management    : Select "None"
Encryption              : Enable encryption of data at rest
```
```text
Performance settings:
Keep default settings
```

- Click "Next"
```text
Network: 
Virtual Private Cloud (VPC) : Default VPC (Keep default)
Mount targets               : 
  - Clear "default sg" from all AZ
  - Add "EFS SecGrp" to all AZ
```
- Show that you can only add one mount point for each AZ though it has multiple subnets (for example custom VPC) 
- Click "Next"

```text

File system policy - optional:
Keep default settings.
```
- Click "Next"
```text

Review and create:
Review settings
```
- Click "Create"


## Part 3 - Attach the EFS to the multiple EC2 Linux instances

### STEP-1: Configure the EC2-1 instance


- Go EC2 console

- Connect to EC2-1 with SSH.
```text
ssh -i .....pem ec2-user@..................
```
- Update the installed packages and package cache on your instance.

```text
sudo yum update -y
```
- Change the hostname 

```text
sudo hostnamectl set-hostname First
```

- type "bash" to see new hostname.

```text
bash
```

- Install the "Amazon-efs-utils Package" on Amazon Linux

```text
sudo yum install -y amazon-efs-utils
```

- Create Mounting point 

```text
sudo mkdir efs
```

- Go to the EFS console and click  on "FirstEFS" . Then click "Attach" button seen top of the "EFS" page.

- On the pop up window, copy the script seen under "Using the EFS mount helper" option: "sudo mount -t efs -o tls fs-60d485e2:/ efs"

- Turn back to the terminal and mount EFS using the "EFS mount helper" to the "efs" mounting point

```text
sudo mount -t efs -o tls fs-xxxxxx:/ efs
```
- Check the "efs" folder
```text
ls
```
- Go the "efs" folder and create a new file with Nano editor.

```text
cd efs
sudo nano example.txt
```
- Write something, save and exit;
```text
"hello from first EC2-1"
CTRL X+Y
```

- check the example.txt

```text
cat example.txt
```
### STEP-2: Configure the EC2-2 instance


-  Connect to EC2-2 with SSH.
```text
ssh -i .....pem ec2-user@..................
```
- Update the installed packages and package cache on your instance.

```text
sudo yum update -y
```
- Change the hostname 

```text
sudo hostnamectl set-hostname Second
```
- type "bash" to see new hostname.

```text
bash
```
- Install the "Amazon-efs-utils Package" on Amazon Linux

```text
sudo yum install -y amazon-efs-utils
```

- Create Mounting point 

```text
sudo mkdir efs
```

- Go to the EFS console and click  on "FirstEFS" . Then click "Attach" button seen top of the "EFS" page.

- On the pop up window, copy the script seen under "Using the EFS mount helper" option: "sudo mount -t efs -o tls fs-60d485e2:/ efs"

- Turn back to the terminal and mount EFS using the "EFS mount helper" to the "efs" mounting point

```text
sudo mount -t efs -o tls fs-xxxxxxx:/ efs
```
- Check the "efs" folder
```text
ls
```
- Check the example.txt. Show that you can also reach the same file.

```text
cat example.txt
```

- Add something example.txt

```text
sudo nano example.txt
"hello from first EC2-2"
CTRL X+Y
```
- Check the example.txt

```text
cat example.txt

"hello from first EC2-1"
"hello from first EC2-2"
```
- Connect from EC2-1 to the "efs" and show the example.txt:


```text
cd efs
cat example.txt

"hello from first EC2-1"
"hello from first EC2-2"
```

***Don't forget to edit fstab to mount efs on reboot!!!***

#### Setting up Automatic Mounting using /etc/fstab with the EFS Mount Helper

Your EC2 instance is now mounted to the EFS file system.
However, you'll notice that if you reboot your instance(EC2-1 & EC2-2), the file system does not remount to your instance.
We can use the `/etc/fstab` file with EFS mount helper to automatically remount the file system.
The `/etc/fstab` file contains information about file systems that should be mounted during instance booting.

1.  Run the following command to open the `/etc/fstab` file in the nano editor.  
    
    ```
    sudo nano /etc/fstab
    
    ```
    
2.  On a new line, paste in the following (remember to use the file system ID):  
    
    ```
    fs-xxxxxx:/ /home/ec2-user/efs efs tls,_netdev
    
    ```
    
3.  Save the changes to the file.
    
4.  Let's test the new entry to see if everything was setup correctly.  
    
    ```
    sudo mount -fav
    
    ```
    All done! We now have the EC2 instance remounting the file system on reboot.



### STEP-3: Configure the EC2-3 instance with EFS while Launching

- Go to the EC2 console and click "Launch Instance"

- Configure third Instance in N.Virginia

```text
AMI             : Amazon Linux 2023
Instance Type   : t2.micro
Network         : Edit >>>>> Choose one of the default subnets
Configure Storage : Advanced

  File systems  >>>> Edit >>>Add file system-------> FirstEFS 
  (Note down the mnt point "/mnt/efs/fs1")
Security Group  : EC2 SecGrp
Tag             :
    Key         : Name
    Value       : EC2-3
```
- Connect to EC2-3 with SSH

- Change the hostname 

```text
sudo hostnamectl set-hostname Third
```

```text
ssh -i .....pem ec2-user@..................
```
- Go to the directory of mount target 
```text
cd /mnt/efs/fs1/
```
- Show the example.txt:

```text
cd efs
cat example.txt

"hello from first EC2-1"
"hello from first EC2-2"
```
 - Add something example.txt

```text
sudo nano example.txt
"hello from first EC2-3"
CTRL X+Y
```
- Check the example.txt

```text
cat example.txt

"hello from first EC2-1"
"hello from first EC2-2"
"hello from first EC2-3"
```

- Terminate instances and delete file system from console.
