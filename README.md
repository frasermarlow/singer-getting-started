# Singer: Getting Started Guide (for real beginners)

## Table of Contents
### A: Running Singer on AWS EC2 (using a PC)

Part 1: [Setting up your AWS EC2 instance](#Introduction)

Part 2: [Setting up the environment](#singer-assumptions)

Part 3: [Installing, and then running the tap and the target](#six-steps-to-a-happy-tap)

### B: [Running Singer on Mac OS](#taps-targets-and-python)

------------------------------------------------------

### Context:

This guide is aimed at people interested in using [the Singer.io framework](https://singer.io) for building data flows.  It is **a beginner level guide**.  The main instructions for using Singer can be found in the [official 'getting started' guide](https://github.com/singer-io/getting-started)

### Introduction

Singer.io is a great framework for creating reliable data flows, to get data from point A to point B.  But if you are not an experienced data engineer or software developer, it is easy to hit a few stumbling blocks early in the process.  These teething issues are enough to make most data scientists or data analysts give up on Singer and go look for a more consumer-friendly solution (which is what [Stitch Data Loader](https://www.stitchdata.com/) is all about.) 

But don’t give up just yet.  The goal of this guide is to help those of you who – like me – are new to Singer. You may even be new to Python in general.  
The steps below will help you get a Singer Tap and a Singer Target up and running.

The Singer documentation assumes a lot of familiarity with Python environments and versions, so I am going to slow things down a touch and walk you through the set-up of the environment in a bit more detail.

As part of this tutorial, I will show you how to:

1. Set up an Amazon Web Services free tier virtual server using the EC2 service (You can skip this if you just want to work on your local machine, the next two steps would be the same there).
2. Set up the right version of Python along with the other packages needed so that you can run Singer Taps and Targets
3. Install a Tap and a Target and get the data flowing

> Note that there is a separate tutorial for those just looking to [work with Singer on their local MacOS machine](#taps-targets-and-python)

I hope that by the end of this tutorial you will have a better understanding and familiarity with Singer and the confidence to move forward in configuring your own dataflows, and who knows, maybe even building your own Taps.

So how much expertise is required to work your way through this tutorial?  Let me try and set the bar for you:
* You do not need to be a Python expert or even know much about programming at all.
* You need to be comfortable using the command line to interface with a computer, we will be using that almost exclusively.
* Familiarity with networking and connecting via SSH is a plus if you are going to try the AWS EC2 approach, but if not I recommend running on your local machine.
* You will need a credit card for authorization purposes, but don’t worry – you don’t need to spend a dime to complete this tutorial.

## Part 1: Setting up your AWS EC2 instance.
These instructions assume you are working on a PC to manage your EC2 instance, but you could equally follow along on a Mac.

### Why use EC2?

As mentioned above, you can run Singer on a local PC or Mac.  As long as you can run Python 3 on your machine (and connect to the internet!) you should be able to skip this set-up and move on to the next section if you like to [work with Singer on their local MacOS machine](#taps-targets-and-python). But personally I like to work with AWS EC2 instances.  EC2 stands for ‘_Amazon Elastic Compute Cloud_’ and is a service where you can boot up a remote virtual computer, log into it using SSH and run applications using the Shell command line interface.

EC2 instances are stand-alone, free for 12 months (for the really small instances) and if things fall apart you can just terminate an instance and boot up a fresh one in a couple of minutes.  In fact, in writing this tutorial I terminated my EC2 instance several times and just rebooted a new one.  (Note that the new server’s IP address may well change when you create a new instance, and you will need to update your connection details.)

If you are planning on setting up a data flow for your company, or something that will run on a schedule, then having a stand-alone EC2 virtual machine run the Singer Tap has many advantages.  It is good for sandboxing, and networking is fast by virtue of being on the AWS network.  On the downside, the free instances are very small, so they will run Taps _very slowly_.  This said, once your Tap is working as wanted, you can just scale up the EC2 instance with a single click – no need to go and rebuild everything a second time.

### Setting up an EC2 instance:

* Head over to the AWS management console ( https://aws.amazon.com/console/ ) and create a free AWS account or log in if you have one already.  You will need a credit card for this, but Amazon will confirm “_We use your payment information to verify your identity and only for usage in excess of the AWS Free Tier Limits. We will not charge you for usage below the AWS Free Tier Limits._” – this demo should not incur any charges on your credit card.
* Enter a cellphone number for identification purposes.
* Select the ‘free tier’ account
* You will be limited to very small virtual machines.  Not to worry, Singer will run just fine, if not a bit slowly, on these ‘_micro_’ instances.

Once your account is set up head over to the **[Web Management Console](https://aws.amazon.com/console/)**.  You should see a section called _“Build a solution: Get started with simple wizards and automated workflows. Launch a virtual machine with EC2 (2-3 minutes)”_.  If you cannot locate that just click on the ‘_Services_’ menu item in the page header, then select ‘_EC2_’ under ‘_Compute_’.

![](https://www.stitchdata.com/images/singer-getting-started-guide/singer-getting-started-guide_2.png)
 
You will now be asked to select the type of virtual machine you want to launch.  Just make sure you pick one marked “_Free tier eligible_”.  For this exercise I am selecting an **Ubuntu Server 20.04 LTS 64-bit (x86)**.

![](https://www.stitchdata.com/images/singer-getting-started-guide/singer-getting-started-guide_3.png)

On the next screen (“_Step 2: Choose an Instance Type_”) you will only have one choice that is ‘_free tier_’ eligible, namely the **t2 micro**.  From here, just click ‘_review and launch_’.

![](https://www.stitchdata.com/images/singer-getting-started-guide/singer-getting-started-guide_4.png)

Next, we need to set up the **security group** for this server.  Security groups contain all the rules for who can access this virtual computer, and what protocols they can use.  This may seem like another painful step in setting things up, but you only need to do this once.  If you ever want to set up another virtual machine or scrap and restart the current one, the security groups stay in place.

AWS will give you a default security group called ‘_launch-wizard-1_’ which you can rename if you like.  

By default, the security group will allow all outbound traffic from the server, but will restrict inbound traffic to just SSH traffic on port 22.

![](https://www.stitchdata.com/images/singer-getting-started-guide/singer-getting-started-guide_5.png)
 
Click ‘_launch_’ and AWS will ask you to “_Select an existing key pair or create a new key pair._”.  A key pair is a set of two ‘_keys_’ – you can think of these as the lock that AWS will put on the server to keep it secure, and the key that we need to access the server.  Select ‘_create a new key pair_’ in the dropdown, and give it a relevant name.

![](https://www.stitchdata.com/images/singer-getting-started-guide/singer-getting-started-guide_3.jpg)

Then click ‘_download Key Pair_’ and keep the downloaded Key somewhere safe on your computer – if you lose the key to the server, you will no longer be able to access the machine.  As you will see the ‘_Key_’ is simply a text file with the file extension ‘_.pem_’.  If you open the file itself in a text editor you will see that it  starts with “-----BEGIN RSA PRIVATE KEY-----” and is followed by a long series of seemingly random characters, which constitute a long and very complex password for your server.

You can now finally click ‘_Launch Instances_’ and AWS will boot up your brand new machine.

After a couple of minutes, your instance will be up and running – if you click ‘_view instances_’ or simply return to your AWS Management console, under EC2 you will see the details of the new instance you launched.

Here, take a note of the public IP of the machine, we will soon be needing that.  You will find it listed under the IPv4 Public IP:  This address is likely to change if you ever terminate this instance and start a new one, or even pause the instance and reboot it later.

![](https://www.stitchdata.com/images/singer-getting-started-guide/singer-getting-started-guide_8.png)
 
#### Connect to AWS EC2 using SSH

Now it is time to connect to your new EC2 instance. For this we will use SSH (Secure SHell is a secure networking protocol for connecting to a remote computer.)

In Windows open the command prompt (Start menu, type ‘_cmd_’ and press enter).  A primer for [using SSH on Mac can be found here](https://osxtips.net/how-to-use-ssh-on-mac/).

Here you need to create the following command replacing the two values `<path-to-pem>` and `<server-ip>`

`ssh -i <path-to-pem> -v ubuntu@<server-ip>`

So what is going on here?  In essence, you are instructing windows to use `ssh` to connect as user ‘ubuntu’ to the computer found at `<server-ip>`  using the Key file `<path-to-pem>`

So where do we get these two variables?  Well `<path-to-pem>` is the file location of the _.pem_ key file we saved.  You may have simply saved it in your ‘_downloads_’ folder, but it’s usually a good idea to save it somewhere specific on your computer.

`<server-ip>` is the public IP of the EC2 machine you are connecting to.  This is the IP we took note of earlier.

In case you were wondering, the ‘-I’ and the ‘-v’ simply tell SSH that the next item in the command will be the .pem file and the server location respectively.  So you could equally run the command as 

`ssh -v ubuntu@<server-ip> -i <path-to-pem>`

Here is an example of what the command would look like with those variables plugged in:

`ssh -i C:\Users\myusername\singer-demo\pem\singer-demo.pem -v ubuntu@123.987.65.4`

The first time you connect you will be presented with a warning message along these lines:

> The authenticity of host '18.216.66.8 (18.216.66.8)' can't be established.  
> ECDSA key fingerprint is SHA256:2y7Vd/v03zQ5vG6q8ejyAPLgDvFYqxYLqhhaS92n+5Y.  
> Are you sure you want to continue connecting (yes/no)? 

This is what we expect, as the secure connection has never been established before.  Simply type in ‘_yes_’ and proceed.

**Quick tip on PC**:  The steps above are great for connecting to your server once.  Since you will likely be connecting often, I suggest setting this up as a shortcut.

![](https://www.stitchdata.com/images/singer-getting-started-guide/singer-getting-started-guide_9.png)

1. Right-click anywhere in File Explorer or the Desktop and select **New** > **Shortcut**.
2. For the location of the item, type in `C:\Windows\System32\cmd.exe /k <the SSH command above>`
	So for example, the ‘location’ box would contain the following: 
	`C:\Windows\System32\cmd.exe /k ssh -i C:\Users\myusername\singer-demo\pem\singer-demo.pem -v ubuntu@123.987.65.4`
3.	Click Next.
4.	Give the shortcut a name.
5.	Click Finish
You will now have a handy-dandy shortcut on your desktop: ![](https://www.stitchdata.com/images/singer-getting-started-guide/singer-getting-started-guide_10.png)

**Shortcut on Mac** Details for doing the same on Mac can be found here: [Create quick-access ssh shortcuts](http://hints.macworld.com/article.php?story=20060810042411590)

### Working in Ubuntu

Ubuntu is a version of the Linux operating system.  It is widely used and well supported.  If you are new to using Ubuntu, welcome.  In the default set up (such as the one we walked through above) you will be logged on as the generic user called ‘*ubuntu*’.  This is why you will see prompt look something like this:

`ubuntu@ip-123-31-11-123:~$`

which is basically <user>@<computer>:<current-directory>

The tilde (`~`) indicates that you are in this user’s home directory.

Ubuntu is just a regular user, not the root user for the machine but can _act_ as the root user when needed.  This is why we will prepend the word ‘_sudo_’ to many commands, when elevated permissions are required.

In the sections below, the following apply:
Any line that looks like this:

`$ cd ~`

is a command you can execute in Ubuntu’s command line.  Simply copy and paste the instruction in to the command line, without the ‘$’ – so in the example above just type or copy/paste ‘ cd~ ’

In the Windows command prompt interface we are using, ‘paste’ does not work.  Once you copy a command from this tutorial, you can typically use the right-hand mouse button to paste into the command window.

Also in BASH, anything after the hash character (`#`) is a comment.  I will occasionally add those after a command to add context.

### Part 2: Setting up the environment.
#### Singer assumptions
There are a few assumptions in the official Singer documentation that we need to tackle.

First, there is an assumption that you already have a fully featured development environment running.  Singer depends on a bunch of other programs or modules that we need to install before Singer will work on our machine.

The second thing to tackle is this: the documentation ‘recommends’ using what are called ‘virtual environments’ for running each tap or target.  A virtual environment ( or ‘_venv_’ for short) is a way of running individual programs in their own little bubble, calling on their own little subset of programs.  So you might have a Tap that needs version 3.1 of a module, but the Target is asking for version 4.3.  The virtual environment allows for them each to maintain their own set of preferences.

In truth, using virtual environments is a requirement, not a nice to have.  Things just will not work if you try to run everything in the same environment.  To run Singer we need to use **virtual environments**.  Let me explain what those are quickly.

When a program runs in Python (or any other operating system) it calls on a bunch of other programs.  Each one of these individual programs is individually managed and upgraded.  So at one point in time, using a specific combination of these modules, a developer got the core program to work.

But if any one of these modules is on a different version on your machine you will run into the dreaded dependency errors.
To protect from that we create a virtual environment.  All programs operating in that virtual environment will call on a specific set of versions for any required module.

So for example, we might ask Singer to run the import Tap for Chargebee in one environment and push the data up to Google BigQuery using target-bigquery in a different environment.  This makes things a bit more convoluted, but not at all unmanageable.  You will get used to it quickly. It’s not as complicated as it sounds… bear with me.

So first, let’s get things up to date:

When you install a new EC2 instance you are not necessarily getting the most recent version of things, so let’s run an update.

`$ sudo apt-get update && sudo apt-get upgrade && sudo apt-get dist-upgrade`

(Note that here I am executing three sequential commands, but using `&&` to put them on a single command line)

This will find all out of date packages, download the required updates and then install them.  You may need to agree to some installs as they will use up some of your ‘hard drive’ on the cloud.  This sequence of steps may take a little while.

Sometimes, we use Git to install the Taps and Targets we want to use, and Git may not yet be installed in your environment, so let’s do that now:

`$ sudo apt install git`

Once your tap and target are running you will want to run it on a schedule.  For this we use Cron.  So let’s install that while we are at it:

`$ sudo apt-get install cron`

Again, you might find it is already on your system, in which case you are all set.

Finally, let’s run 

`$ sudo apt install -y pylint`

This installs a code analysis tool we will use to make sure taps and targets are working OK.

Now, let us set up Python

Most computers will come with Python pre-installed.  It is a very popular programming language.  The Ubuntu instance we set up above for example comes preinstalled with version 3.8.2.  We know this because running the command 

`$ python3 --version`

Returns the following:

> Python 3.8.2

Singer runs on Python 3.5.2, but I have found that installing that specific version returns OpenSSL issues.  The issue was fixed in the 3.5.3 release, so it’s a low risk approach to go with that incremental version.

But in addition to Python we are going to need the development libraries, so let us install those first:

`$ sudo apt-get install -y make build-essential libssl-dev zlib1g-dev libbz2-dev libreadline-dev libsqlite3-dev wget curl llvm libncurses5-dev libncursesw5-dev xz-utils tk-dev libffi-dev liblzma-dev python-openssl`

`$ sudo apt-get install -y python3-dev libssl-dev`

**OK, NOW can we install python?**

Sure.  Well no.  Not yet. We need to now deal with that second issue - the **virtual environments**.

Let’s install the module that allows us to manage versions of Python and these virtual environments.  Virtual environments are managed with ‘venv’ whereas Python _versions_ are managed with ‘pyenv’. Pyenv is a collection of shell scripts and not installable with **pip** so we use this instead:

`$ sudo apt-get install -y python3-venv`

`$ curl https://pyenv.run | bash`

As the second installation completes, you will see a message that says “_Load pyenv automatically by adding the following to \~/.bashrc:_”  … followed by a command.   ‘_bashrc_’ is a set of commands that Bash will run on startup.  It's a hidden file on the Ubuntu system so the file name has a period in front of it.  So we need to edit this file (\~/.bashrc) to add a few lines.  Here we are not going to open the file to edit it.  Instead, an easy way to do that is to run the following commands, in this order, one at a time:

```
$ echo '' >> ~/.bashrc
$ echo 'export PATH="/home/ubuntu/.pyenv/bin:$PATH"' >> ~/.bashrc
$ echo 'eval "$(pyenv init -)"' >> ~/.bashrc
$ echo 'eval "$(pyenv virtualenv-init -)"' >> ~/.bashrc
$ exec "$SHELL"
```

Each one of these lines will append a new line to the file `.bashrc` by using the `>>` (_append output_) command.


I promise we are getting close to installing Python in a virtual environment!

Let’s see what versions we can install.  Run this command: 

`$ pyenv install --list | grep " 3\.[5]"`

This will list all the versions of Python available to us, from 3.5.0 to 3.5.9.  As mentioned earlier, we are going to go with 3.5.3.  In order to run this in the virtual environment we need to have it available to us as an alternate version, so here goes – let’s install Python.

`$ pyenv install 3.5.3`

If you like to see all the gory details (or if the install hits an error the first time around) you can use this tweak to see all the details:

`$ pyenv install 3.5.3 -v`

Go grab a coffee - this will take a while.  Once this is complete run 

`$ pyenv versions`

And you will see the Python versions now available to us.  All being well it will say:

> \* system (set by /home/ubuntu/.pyenv/version)

> 3.5.3


### Part 3: Installing, and then running the tap and the target
#### Six steps to a happy tap
In order to install either a Tap or a Target, we follow these steps:

1)	Create a virtual environment for the Tap or Target
2)	Activate that virtual environment.  You will notice the command prompt changes to indicate the virtual environment you are operating in.
3)	Specify the version of Python we will use in this environment
4)	Install ‘pip’ and ‘wheel’ which are package managers that will allow us in turn to install the Tap or Target.
5)	Install the Tap or Target using pip
6)	Close out of the virtual environment.

Once these steps are complete, we will be in a position to run the Tap or Target by calling for it in its virtual environment. 

So here are what these six steps look like in practice. In this example I am going to use `_tap-autopilot_` which is an email automation platform.  Depending on the tap you select, you will have to swap out tap-autopilot in the steps below with your Tap’s reference as found at [https://www.singer.io/](https://www.singer.io/):

```
$ python3 -m venv ~/.virtualenvs/tap-autopilot      	# create a virtual environment specific to this tap
$ source ~/.virtualenvs/tap-autopilot/bin/activate  	# activate the virtual environment
$ pyenv local 3.5.3					# set the local version of Python
$ pip install --upgrade pip wheel			# install Wheel
$ pip install tap-autopilot				# install the Tap
$ deactivate						# exit the virtual environment
```

There we go.  The tap is installed.  Now to run it, we would not call the program directly, but call it’s virtual environment as follows:

`$ ~/.virtualenvs/tap-autopilot/bin/tap-autopilot`

Of course, right now that command won’t do anything as we don’t have a destination yet. If you try it, you will get the error:

> tap-autopilot: error: the following arguments are required: -c/--config

To get the data flow working we need both a destination for our data (known as a ‘target’), as well as a bit of configuration for the Tap.  Let’s install the Target first as the steps are very similar as for the Tap.  In this example I am going to export my Autopilot data to .csv format using target-csv.  We will simply repeat steps 1 to 6 above.

```
$ python3 -m venv ~/.virtualenvs/target-csv      # create a virtual environment specific to this tap
$ source ~/.virtualenvs/target-csv/bin/activate  # activate the virtual environment
$ pyenv local 3.5.3
$ pip install --upgrade pip wheel
$ pip install target-csv
$ deactivate
```

So we now have a Tap and a Target installed.  Now we need to configure the Tap.  Each Tap can be a bit different, and I recommend visiting the Github repo for the tap you are working with.  In my case that would be [https://github.com/singer-io/tap-autopilot](https://github.com/singer-io/tap-autopilot) - but you can find the link for your specific Tap on the Singer.io website, or by googling “_singer-io tap-name_” – for example “[_singer-io tap-adwords_](https://www.google.com/search?q=singer-io+tap-adwords)”.


Let’s create a folder where we can keep our configuration files organized.  First let us just make sure you are in the root directory, so just run this:

`$ cd ~     # return to the home directory`

This just means ‘change the current active directory to my home folder’.

Now let’s create a folder for our config files.  You can pick whichever folder name you like.

`$ mkdir tap-autopilot-config  	# make the directory called ‘tap-autopilot-config’`

`$ cd tap-autopilot-config     	#  enter that directory`

In this folder we are going to create several files that the tap will use to set the parameters for the data import.  The first one (which is required) is the environment variables for the Tap, namely what access token to use to access my Autopilot instance.  As per the tap instructions, we will need to create a small file in JSON format called ‘config.json’ with the following details:

```
{
    "api_key": "your-autopilot-api-token",
    "start_date": "2020-01-01T00:00:00Z"
}
```

Logging into the application, I locate the API key in the Settings section.

![](https://www.stitchdata.com/images/singer-getting-started-guide/singer-getting-started-guide_6.jpg)
 
Now to create the file, back on the EC2 instance we use ‘nano’ (the text editor) to create the file:

`$ nano config.json`

and paste in (right mouse click) 

```
{
    "api_key": "tH1s1Salot0Fch@ract#rsTh@tL00kL1ke@Pa$$word",
    "start_date": "2020-05-01T00:00:00Z"
}
```

The next step is to run the Tap in ‘_discovery mode_’.  What this means is that we are going to ask the Tap to connect to its source and figure out what data can be retrieved.  This will allow us to generate a ‘_catalog_’ file with all the data that we can pull from – in this case – the Autopilot system.  
Once this catalog file is generated, we can tweak it to our purpose.  Using ‘_discovery_’ is much easier than trying to write our catalog from scratch.  So here is the command for doing this:

`$ ~/.virtualenvs/tap-autopilot/bin/tap-autopilot --config ~/tap-autopilot-config/config.json --discover  > ~/tap-autopilot-config/catalog.json`

Let me break that command down a bit for you:

` ~/.virtualenvs/tap-autopilot/bin/tap-autopilot`	This runs the Tap from inside its virtual environment…
` --config ~/tap-autopilot-config/config.json` 	… using the configuration file found at this location…
` –discover  				`	… and runs the Tap in ;discover’ mode
` > ~/tap-autopilot-config/catalog.json`		… and write the output of that command to a new file in the ‘tap-autopilot-config’ folder called ‘catalog.json’

All being well this command will result in the following message:

> INFO Loading Schemas  
> INFO Loading schema for contacts  
> INFO Loading schema for lists  
> INFO Loading schema for smart_segments  
> INFO Loading schema for smart_segments_contacts  

_As an aside, if you work with Taps on a regular basis, check out Chris Goddard’s ‘**Singer Discover Utility**’ found here: [https://github.com/chrisgoddard/singer-discover](https://github.com/chrisgoddard/singer-discover). It is designed to take a Singer-specification JSON catalog file and select which streams and fields to include._

So that all looks good. We can check that we now have a ‘_catalog.json_’ file in our folder by running:

`$ ls -la`

And this will return the following:

> total 40  
> drwxrwxr-x 2 ubuntu ubuntu  4096 Jun 17 17:32 .  
> drwxr-xr-x 8 ubuntu ubuntu  4096 Jun 17 16:05 ..  
> -rw-rw-r-- 1 ubuntu ubuntu 27189 Jun 17 17:32 catalog.json  
> -rw-rw-r-- 1 ubuntu ubuntu    96 Jun 17 16:08 config.json  

So we now have a small config.json file and a larger catalog.json file. You can explore the catalog with 

`$ nano catalog.json`

If you want to explore how these catalog files are structured , I would recommend the Singer.io docs as well as the JSON explorer found at [http://www.bodurov.com/JsonFormatter/](http://www.bodurov.com/JsonFormatter/)

There is one challenge with Singer catalog files – they often default to loading nothing and let you explicitly check off the tables or data types you want.
Referring to the Singer documentation pertaining to the catalog,  we need to edit the catalog.json file and pick out which ‘streams’ we want to activate.  We do this by adding the property `“selected”: true` to the stream’s ‘_metadata_’ object:

In my case I browse through the catalog.json file until I find the steam’s ‘metadata’ array and I append the "selected": true   key/value pair to the metadata object for each stream I want to import:

```
"metadata": [
                {
                    "breadcrumb": [],
                    "metadata": {
                        "inclusion": "available",
                        "selected": true,
                        "table-key-properties": [
                            "contact_id"
                        ]
                    }
                }, 
```

This done, exit the text editor with Cntl+X (answer ‘Y’ to save your changes). 

We have one final configuration JSON file to create, and that is the ‘state’ file.  In essence the role of the ‘state’ file is to capture at the end of each data run the state of play, so that next time the tap-to-target dataflow runs, it can pick up where it left off.

The thing is each tap will handle the ‘state’ a little bit differently, depending on how the team or individual developing the tap decided to implement things.

In the case of tap-autopilot I am going to use the state.json file to tell the tap which date I want it to start importing data from.  Like the ‘select’ statement in catalog.json, is done for each ‘stream’ individually.

Examining the catalog.json file, if you search for the key ‘tap_stream_id’ you will see that tap-autopilot pulls in four types of data: "_contacts_","_lists_","_smart_segments_", and "*smart_segments_contacts*".

So to select the start date of each of these streams, we can specify the earliest date to match as follows.  Create the file with 

`$ nano ~/tap-autopilot-config/state.json`

And specify a start date for each stream as follows:

```
{
	"contacts": "2020-06-18T20:32:05Z",
	"lists": "2020-06-18T20:32:05Z",
	"smart_segments": "2020-06-18T20:32:05Z",
	"smart_segments_contacts": "2020-06-18T20:32:05Z"
}
```

Exit the text editor (Cntl+X) and confirm the changes should be saved.

Now, let’s go back to our home directory:

`$ cd ~`

When we run the Tap and Target, it will drop all the output files in whatever local folder I am in.  This is true because I am using target-csv but of course you might be setting up a Target that pushed data back up to a database or a remote destination.  In that case you will need to follow the configuration steps for that Destination. 

But for now I am going to create a new folder to hold my exported Autopilot data:

`$ mkdir autopilot-export`

`$ cd autopilot-export`

Now when I run the Tap and Target, I will get an output of all the Autopilot contacts since 2020-06-18 in .csv format.

`$ ~/.virtualenvs/tap-autopilot/bin/tap-autopilot --config ~/tap-autopilot-config/config.json --catalog ~/tap-autopilot-config/catalog.json --properties ~/tap-autopilot-config/catalog.json --state ~/tap-autopilot-config/state.json | ~/.virtualenvs/target-csv/bin/target-csv`

![](https://www.stitchdata.com/images/singer-getting-started-guide/singer-getting-started-guide_7.jpg)

Congratulations.  If you made it this far, you have succeeded in getting a Singer Tap up and running.

### Additional resources:

* If you would like to build your own Tap I recommend [this article by Jeff Huth at Bytecode](https://www.stitchdata.com/blog/how-to-build-a-singer-tap-infographic/)
* If you work with Taps on a regular basis, check out Chris Goddard’s ‘[Singer Discover Utility](https://github.com/chrisgoddard/singer-discover)’. It is designed to take a Singer-specification JSON catalog file and select which streams and fields to include.
* If you want to explore JSON file structures, [Vladimir Bodurov's JsonFormatter](http://www.bodurov.com/JsonFormatter/) is a quick and useful tool.

---------------------------------------------------

 
# Running Singer on Mac OS
#### Taps, Targets and Python

Running Taps and Targets locally on a Mac is probably the most common scenario for testing and development, but getting Singer to work does require some set up.

For instance, Mac OS X comes with Python 2.7 out of the box, but Singer runs on Python 3.5. and separate virtual environments are recommended for each Tap and Target you use.  But don’t worry, you do not need much familiarity with Python to get up and running.  The following guide should get you there.

To work on Singer, we are going to use the Mac Terminal which comes with Mac OS by default.

So let’s start by opening the command line Terminal (Finder > Applications > Terminal)

First, we install Homebrew, the free software package management system which makes it easy to install all the other modules required to run Singer.

`$ /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"`

(Note: Likely your Mac will already have Xcode installed, but if you run into issues installing Homebrew, that will likely be the cause. Xcode can be installed from the Apple Mac store.)

While we are at it, we will install the software testing application PyLint

`$ brew install pylint`

With these in place, we can now focus on getting Python itself installed.  First let’s check on the current version:

`$ python --version`

This would typically return Python 2.7.16 that ships with MacOS (as of June 2020).  So we need to install the more up-to-date Python3.  Before we worry about the specific version we need for Singer, let’s install the default Python3 on your machine – don’t worry, we will be able to run programs under different Python versions later.

`$ brew install python  # installs 3.7.7 as of time of writing`

So now we have Python3 running, we will install an application that allows us to manage multiple versions of Python on the same computer, called PyEnv:

`$ brew install pyenv`

And using PyEnv we can now install the required version of Python3 we need, namely 3.5.3:

`$ pyenv install 3.5.3`

Great.  Next we are going to install an application that allows us to create ‘virtual environments’.  You can think of these as containers to run a program in, each container setting up its own set of modules to support the core program.  This is important because different taps or targets may have different dependencies to run smoothly, and these may conflict from one tap to the next.

`$ pip3 install virtualenv`

Now we have things set up, and we can go ahead and download a Tap and a Target for us to run.  Each time you install an integration, you will follow these same five steps:
1.	Create a new virtual environment
2.	Activate the virtual environment
3.	Set the local Python version
4.	Install the Tap or Target
5.	Deactivate the virtual environment

So here are the commands for those five steps for installing the tap I will be using, namely ‘tap-autopilot’.  Note that the command line prompt changes to _(tap-autopilot)$_ when we activate the virtual environment.

`$ virtualenv -p python3 tap-autopilot`
`$ source tap-autopilot/bin/activate`
`(tap-autopilot)$ pyenv local 3.5.3`
`(tap-autopilot)$ pyenv versions # to confirm install and version assigned`
`(tap-autopilot)$ pip install tap-autopilot`
`(tap-autopilot)$ deactivate`

We repeat these same five steps for each tap or Target we install.  So let’s repeat this process for installing the Target which allows us to pipe data to .csv files on our local machine, called ‘target-csv’

`$ virtualenv -p python3 target-csv`
`$ source target-csv /bin/activate`
`(target-csv)$ pyenv local 3.5.3`
`(target-csv)$ pyenv versions # to confirm install and version assigned`
`(target-csv)$ pip install tap-autopilot`
`(target-csv)$ deactivate`

With these installed, we now need to configure the Tap.  Each Tap can be a bit different, and I recommend visiting the Github repo for the tap you are working with for the exact details. In my case that would be https://github.com/singer-io/tap-autopilot - but you can find the link for your specific Tap on the Singer.io website, or by googling “singer-io tap-name” – for example “singer-io tap-adwords”.

In the context of this tutorial, note that ‘target-csv’ does not need any configuration, but most other Targets will, as they will require connection details to your data destination, such as a database or remote folder.

In most cases, configuring a Tap requires 3 files in JSON format:  **config.json**, **catalog.json**, and **state.json**.

**config.json** : This file holds the environment variables such as the API key, integration start date and any other bespoke variables the tap requires.  This is always a required file.

**catalog.json** : This file holds the structure of the data streams that are available for inclusion when we run an import.  Most taps allow us to create this file automatically using ‘discovery’ mode.  Once the file is created we can then turn streams on or off to specify the data we want.

**state.json** : This file captures the current state of the data feed – so it tracks where we wrap up one import so that we can pick up where we left off on the next run.  With some Taps, we can also use the state.json file to specify independent start dates for importing different data types.

To keep things organized, let’s create a folder where we can keep our configuration files organized.  First let us just make sure you are in the root directory, so just run this:

`$ cd ~     # return to the home directory`

This just means ‘change the current active directory to my home folder’.
Now let’s create a folder for our config files.  You can pick whichever folder name you like but naming it tap-<tap name>-config is a good convention.

`$ mkdir tap-autopilot-config  # make the directory called ‘tap-autopilot-config’`
`$ cd tap-autopilot-config     #  enter that directory`

In this folder we are going to create the JSON files that the Tap will use to set the parameters for the data import.  The first one (which is required) is the environment variables for the Tap, namely what access token to use to access my Autopilot instance.  As per the tap instructions, we will need to create a small file in JSON format called ‘*config.json*’ with the following details:
```
{
    "api_key": "your-autopilot-api-token",
    "start_date": "2020-01-01T00:00:00Z"
}
```
Logging into the application, I locate the API key in the Settings section.

![](https://www.stitchdata.com/images/singer-getting-started-guide/singer-getting-started-guide_6.jpg)
 
Now to create the file, back in the Mac Terminal window we use ‘nano’ (the text editor) to create the file:

`$ nano config.json`

and paste in the Key:

```
{
    "api_key": "tH1s1Salot0Fch@ract#rsTh@tL00kL1ke@Pa$$word",
    "start_date": "2020-05-01T00:00:00Z"
}
```

The next step is to run the Tap in ‘*discovery mode*’.  

What this means is that we are going to ask the Tap to connect to its source and figure out what data can be retrieved (some Taps hard-wire this structure, so don’t always stay up to date when the source data changes). 

*Discovery mode* will allow us to generate a ‘*catalog*’ file with all the data that we can pull from – in this case – the Autopilot system.  Once this *catalog.json* file is generated, we can tweak it to our purpose.  Using ‘*discovery*’ is much easier than trying to write our catalog from scratch.  So here is the command for doing this:

`$  ~/tap-autopilot/bin/tap-autopilot --config ~/tap-autopilot-config/config.json --discover  > ~/tap-autopilot-config/catalog.json`

Let me break that command down a bit for you:

`~/tap-autopilot/bin/tap-autopilot`	This runs the Tap from inside its virtual environment…
 `--config ~/tap-autopilot-config/config.json` 	… using the configuration file found at this location…
`–discover`  					… and runs the Tap in ;discover’ mode
`\> ~/tap-autopilot-config/catalog.json`		… and write the output of that command to a new file in the ‘*tap-autopilot-config*’ folder called ‘*catalog.json*’

All being well this command will result in the following message:

>INFO Loading Schemas  
>INFO Loading schema for contacts  
>INFO Loading schema for lists  
>INFO Loading schema for smart_segments  
>INFO Loading schema for smart_segments_contacts  

As an aside, if you work with Taps on a regular basis, check out Chris Goddard’s ‘[Singer Discover Utility](https://github.com/chrisgoddard/singer-discover)’ . It is designed to take a Singer-specification JSON catalog file and select which streams and fields to include.

So that all looks good. We can check that we now have a ‘catalog.json’ file in our folder by running:
`$ ls -la`
And this will return the following:

> total 40  
> drwxrwxr-x 2 ___________ ___________  4096 Jun 17 17:32 .  
> drwxr-xr-x 8 ___________ ___________  4096 Jun 17 16:05 ..  
> -rw-rw-r-- 1 ___________ ___________ 27189 Jun 17 17:32 catalog.json  
> -rw-rw-r-- 1 ___________ ___________    96 Jun 17 16:08 config.json  

So we now have a small config.json file and a larger catalog.json file. You can explore the catalog with
 
`$ nano catalog.json`

If you want to explore how these catalog files are structured , I would recommend the Singer.io docs as well as the JSON explorer found at http://www.bodurov.com/JsonFormatter/ 

There is one challenge with Singer catalog files – they often default to loading nothing and let you *explicitly* check off the tables or data types you want.

Referring to the Singer documentation pertaining to the catalog,  we need to edit the catalog.json file and pick out which ‘_streams_’ we want to activate.  

We do this by adding the property `“selected”: true ` to the stream’s ‘_metadata_’ object:

In my case I browse through the *catalog.json* file until I find the steam’s ‘*metadata*’ array and I append the `"selected": true`   key/value pair to the metadata object for each stream I want to import:

```
"metadata": [
                {
                    "breadcrumb": [],
                    "metadata": {
                        "inclusion": "available",
                        "selected": true,
                        "table-key-properties": [
                            "contact_id"
                        ]
                    }
                }, 
```

This done, exit the text editor with Cntl+X (answer ‘Y’ to save your changes). 

We have one final configuration JSON file to create, and that is the ‘*state*’ file.  In essence the role of the ‘*state*’ file is to capture at the end of each data run the state of play, so that next time the tap-to-target dataflow runs, it can pick up where it left off.

The thing is each tap will handle the ‘state’ a little bit differently, depending on how the team or individual developing the tap decided to implement things.

In the case of **tap-autopilot** I am going to use the *state.json* file to tell the tap which date I want it to start importing data from. Like the ‘*select*' statement in *catalog.json*, is done for each ‘*stream*’ individually.
Examining the *catalog.json* file, if you search for the key ‘*tap_stream_id*’ you will see that tap-autopilot pulls in four types of data: "*contacts*","*lists*","*smart_segments*", and "*smart_segments_contacts*".

So to manage the start date of each of these streams, we can specify the earliest date to match as follows.  Create the file with 

`$ nano ~/tap-autopilot-config/state.json`

And specify a start date for each stream as follows:

```
{
	"contacts": "2020-06-18T20:32:05Z",
	"lists": "2020-06-18T20:32:05Z",
	"smart_segments": "2020-06-18T20:32:05Z",
	"smart_segments_contacts": "2020-06-18T20:32:05Z"
}
```

Exit the text editor (Cntl+X) and confirm the changes should be saved.
Now, let’s go back to our home directory:

`$ cd ~`

When we run the Tap and Target, it will drop all the output files in whatever local folder I am in.  This is true because I am using target-csv but of course you might be setting up a Target that pushed data back up to a database or a remote destination.  In that case you will need to follow the configuration steps for that Destination. 

But for now I am going to create a new folder to hold my exported Autopilot data:

`$ mkdir autopilot-export`
`$ cd autopilot-export`

Now when I run the Tap and Target, I will get an output of all the Autopilot contacts since 2020-06-18 in .csv format.

`$ ~/tap-autopilot/bin/tap-autopilot --config ~/tap-autopilot-config/config.json --catalog ~/tap-autopilot-config/catalog.json --properties ~/tap-autopilot-config/catalog.json --state ~/tap-autopilot-config/state.json | ~/.virtualenvs/target-csv/bin/target-csv`

 Congratulations.  If you made it this far, you have succeeded in getting a Singer Tap up and running on MacOS.
