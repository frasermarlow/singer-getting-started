![](https://www.stitchdata.com/images/singer-getting-started-guide/singer_logo.gif)

# Singer getting started guide

## Table of contents
### A: Running Singer on AWS EC2

Part 1: [Setting up your AWS EC2 instance](#Introduction)

Part 2: [Setting up the environment](#singer-assumptions)

Part 3: [Installing and running the tap and the target](#six-steps-to-a-happy-tap)

Bonus: [Scheduling using cron](#setting-up-a-tap-replication-schedule-using-cron)

### B: [Running Singer on macOS](#taps-targets-and-python)

------------------------------------------------------

### Introduction

Singer is a framework for creating reliable data flows, to get data from point A to point B. This guide is designed to help anyone new to Singer, and even new to Python, the language most taps are written in, get a Singer tap and Singer target up and running.

As part of this tutorial, we'll show you how to:

1. Set up an Amazon Web Services free-tier virtual server using the EC2 service. You can skip this if you just want to work on your local machine.
2. Set up the right version of Python, along with packages you need so that you can run Singer taps and targets
3. Install a tap and a target and get the data flowing

By the end of this tutorial you'll have a better understanding of Singer and the confidence to configure your own data flows — and who knows, maybe even to build your own taps.

To work your way through this tutorial
* You do not need to be a Python expert or even know much about programming at all.
* You need to be comfortable using the command line to interface with a computer, as we will be using that almost exclusively.
* You should be familiar with networking and connecting to systems via SSH if you want to try the AWS EC2 approach.
* You will need a credit card for authorization purposes, but don’t worry – you don't need to spend a dime to complete this tutorial.

## Part 1: Setting up your AWS EC2 instance
These instructions assume you're working on a Windows machine to manage your EC2 instance.  If you are working on a Mac locally, you will find [specific instructions here](#taps-targets-and-python).

### Why use EC2?

EC2 stands for "Elastic Compute Cloud." It's an AWS service that lets you boot up a virtual computer in the cloud, log in to it using SSH, and run applications using a command-line interface. EC2 instances are stand-alone and free for 12 months for the really small instances. If things fall apart when you're running one you can just terminate an instance and boot up a fresh one in a couple of minutes. (Note that while starting an instance takes only a couple of minutes, the new instance’s IP address may differ from the old one's, so you may need to update your connection details.)

As we mentioned above, you can run Singer on a local Windows or Mac computer as long as you can run Python 3 on your machine, but we like to work with AWS EC2 instances. If you're planning on setting up a data flow for your company, or something that will run on a schedule, then having a stand-alone EC2 virtual machine running the Singer tap has many advantages. EC2 is good for sandboxing, and programs install quickly by virtue of being on the AWS network. On the downside, the free instances are very small, so they run taps very slowly. This said, once your tap is working as you want, you can scale up the instance you're working on – no need to rebuild anything.

### Setting up an EC2 instance

* Head over to the AWS management console (https://aws.amazon.com/console/) and create a free AWS account, or log in if you have one already. You'll need a credit card for this, but Amazon will confirm "We use your payment information to verify your identity and only for usage in excess of the AWS Free Tier Limits. We will not charge you for usage below the AWS Free Tier Limits." This demo should not incur any charges on your credit card.
* Enter a cellphone number for identification purposes.
* Select the "free tier" account
* You will be limited to very small virtual machines. Not to worry, Singer will run just fine, if a bit slowly, on these _micro_ instances.

Once your account is set up, head over to the **[Web Management Console](https://aws.amazon.com/console/)**.  You should see a section called _Build a solution: Get started with simple wizards and automated workflows. Launch a virtual machine with EC2 (2-3 minutes)_.  If you cannot locate that, click on the _Services_ menu item in the page header, and under _Compute_ select _EC2_.

![](https://www.stitchdata.com/images/singer-getting-started-guide/singer-getting-started-guide_2.png)
 
Next, select the type of virtual machine you want to launch. Pick one marked _Free tier eligible_. For this exercise we're selecting **Ubuntu Server 20.04 LTS 64-bit (x86)**. Ubuntu is a popular version of the Linux operating system. 

![](https://www.stitchdata.com/images/singer-getting-started-guide/singer-getting-started-guide_3.png)

On the next screen (_Step 2: Choose an Instance Type_) you will have only one choice: _free tier_ eligible, namely the **t2 micro**. Click _review and launch_.

![](https://www.stitchdata.com/images/singer-getting-started-guide/singer-getting-started-guide_4.png)

Next, set up the **security group** for this server. Security groups contain all the rules for who can access the virtual computer and what protocols they can use. You need to do this only once; if you ever want to set up another virtual machine or scrap and restart the current one, the security groups stay in place.

AWS will give you a default security group called _launch-wizard-1_, which you can rename if you like.  

By default, the security group allows all outbound traffic from the server, but restricts inbound traffic to just SSH traffic on port 22.

![](https://www.stitchdata.com/images/singer-getting-started-guide/singer-getting-started-guide_5.png)
 
Click _launch_ and AWS will ask you to _Select an existing key pair or create a new key pair._  You can think of key pair as the lock that AWS puts on the server to keep it secure and the key that someone needs to access the server. Select _create a new key pair_ in the dropdown, and give it a relevant name.

![](https://www.stitchdata.com/images/singer-getting-started-guide/singer-getting-started-guide_3.jpg)

Click _download Key Pair_ and keep the downloaded key somewhere safe on your computer – if you lose the key to the server, you will no longer be able to access the machine. The key is simply a text file with the file extension _.pem_.  If you open the file in a text editor you can see that it starts with “-----BEGIN RSA PRIVATE KEY-----” and contains a long series of seemingly random characters, which constitute a long and complex password for your server.

Finally, click _Launch Instances_ and AWS will boot up your new machine within a couple of minutes. If you click ‘_view instances_’ or simply return to your AWS Management console, under EC2 you'll see the details of the new instance.

Take note of the public IP address of the machine, because you'll soon be needing it. You'll find it listed under the IPv4 Public IP. The address is likely to change if you terminate this instance and start a new one, or even pause the instance and reboot it later.

![](https://www.stitchdata.com/images/singer-getting-started-guide/singer-getting-started-guide_8.png)
 
Now you can connect to your EC2 instance using SSH.

In Windows, open the command prompt (Start menu, type ‘_cmd_’, and press Enter). In Linux or macOS, open the Terminal application.

At the prompt, enter the following command, replacing the two values `<path-to-pem>` and `<server-ip>` with the values from your systems. `<path-to-pem>` is the file location of the _.pem_ key file you saved. `<server-ip>` is the public IP address of the EC2 machine you're connecting to.

`ssh -i <path-to-pem> -v ubuntu@<server-ip>`

What's going on here? You're instructing your local machine to use the `ssh` command to connect as user "ubuntu" to the computer found at `<server-ip>` using the key file `<path-to-pem>`.

In case you were wondering, the `-i` and the `-v` arguments simply tell SSH that the next item in the command will be the .pem file and the server location respectively. You could equally run the command as 

`ssh -v ubuntu@<server-ip> -i <path-to-pem>`

Here's an example of what the command would look like with those variables plugged in:

`ssh -i C:\Users\myusername\singer-demo\pem\singer-demo.pem -v ubuntu@18.216.66.8`

The first time you connect you'll be presented with a warning message along these lines:

> The authenticity of host '18.216.66.8 (18.216.66.8)' can't be established.  
> ECDSA key fingerprint is SHA256:2y7Vd/v03zQ5vG6q8ejyAPLgDvFYqxYLqhhaS92n+5Y.  
> Are you sure you want to continue connecting (yes/no)? 

This expected, as the secure connection has never been established before. Simply type in ‘_yes_’ and proceed.

**Quick tip for Windows users**: The steps above are great for connecting to your server once. Since you will likely be connecting often, I suggest setting up the command as a shortcut.

![](https://www.stitchdata.com/images/singer-getting-started-guide/singer-getting-started-guide_9.png)

1. Right-click anywhere in File Explorer or the Desktop and select **New** > **Shortcut**.
2. For the location of the item, type in `C:\Windows\System32\cmd.exe /k <the SSH command above>`
	So for example, the location box would contain the following: 
	`C:\Windows\System32\cmd.exe /k ssh -i C:\Users\myusername\singer-demo\pem\singer-demo.pem -v ubuntu@18.216.66.8`
3.	Click Next.
4.	Give the shortcut a name.
5.	Click Finish.
You now have a handy-dandy shortcut on your desktop: ![](https://www.stitchdata.com/images/singer-getting-started-guide/singer-getting-started-guide_10.png)

### Working in Ubuntu

Since we selected Ubuntu Server for our virtual machine, we'll be logged on as the generic user *ubuntu*, and the command prompt will look something like this:

`ubuntu@ip-18-216-66-8:~$`

The tilde (~) indicates that you are in this user’s home directory.

The ubuntu user is a regular user, not the more highly privileged root user for the machine, but it can _act_ as the root user when needed if you prepend the command `sudo` to another command when elevated permissions are required.

In the following sections of this guide, any line that looks like this is a command you can execute from Ubuntu’s command line:

`$ cd ~`

Simply copy and paste the instruction in, without the *$*, which indicates a system prompt. So in the example above, type or copy/paste `cd ~`.

A bit later on we will be using 'virtual environments' - don't worry if that is confusing right now, we will come back to it.  But when we are in a virtual environment the prompt may look like this:  `(tap-autopilot) $`  or even `(target-csv) ubuntu@DESKTOP-CLLCE1R:~$` or somesuch.  The main point is that the command is the part in the instruction that comes after the `$` sign.  The bit before the `$` just gives you context on where that command will be executed.

In the Windows command prompt interface we're using, the '_paste_' function will not work. Once you copy a command from this tutorial, you can instead use the right-mouse button to paste into the command window.

Also in the shell, any characters after the hash character (`#`) is a comment. You'll occasionally see comments those after a command in this guide to add context, but they have no effect in terms of a command.

### Part 2: Setting up the environment

> Note - for those of you comfortable working in Ubuntu, feel free to copy and run the Bash file `ubuntu-singer-setup.sh` found in this repo, and skip to [Installing and running the tap and the target](#six-steps-to-a-happy-tap).

#### Singer assumptions

The Singer documentation makes a few assumptions. First, it assumes that you have a development environment running. Singer depends on a bunch of other programs or modules that you need to install before Singer will work.

Also, the documentation "recommends" using "virtual environments" for running each tap or target. A virtual environment ( or _venv_ for short) is a way of running individual programs in their own little bubbles, calling on their own little subsets of programs. You might have a tap that needs version 3.1 of a module, but a target that's asking for version 4.3. If you try to run them in the same environment you will run into dependency errors. A virtual environment allows for them each to maintain their own set of preferences. This makes configuration a bit more convoluted, but not at all unmanageable.

In truth, using virtual environments is a requirement, not a nice-to-have. Things just will not work if you try to run everything in the same environment. If you are brand new to virtual environments in Python3, check out [this YouTube tutorial](https://www.youtube.com/watch?v=Kg1Yvry_Ydk).

Bearing in mind those considerations, let’s get our environment up to date.

When you start running Ubuntu on a new EC2 instance, you won't have the most recent version of all the Ubuntu commands and utilities, but you can get them by running an update:

`$ sudo apt update && sudo apt upgrade && sudo apt dist-upgrade`

These three sequential commands find all out-of-date packages, download the required updates, and install them. You may be prompted to agree to some updates as they use up some of your "hard drive" space in the cloud. This step takes a little while.

It helps to get Pip (the package installer for Python) up to date as well:

`$ pip install --upgrade pip`

Sometimes, we use Git to install the taps and targets we want to use. Git is a distributed version-control system used to collaborate on and share source code. Git may not yet be installed in your environment, so run:

`$ sudo apt install git`

Eventually, once your tap and target are running, you may want to run your tap on a schedule using the cron utility. To install cron, run:

`$ sudo apt-get install cron`

We need to install some Python development libraries:

`$ sudo apt-get install -y make build-essential libssl-dev zlib1g-dev libbz2-dev libreadline-dev libsqlite3-dev wget curl llvm libncurses5-dev libncursesw5-dev xz-utils tk-dev libffi-dev liblzma-dev python-openssl`

`$ sudo apt-get install -y python3-dev libssl-dev`

And we want to install the Pylint code analysis tool so we can make sure taps and targets are working OK: 

`$ sudo apt install -y pylint`

Then there's Python itself, or more precisely the specific version of Python we need per tap or target. The Ubuntu instance we set up comes preinstalled with Python version 3.8.2. We know this because running the command 

`$ python3 --version`

Returns

> Python 3.8.2

Singer runs on Python 3.5.2, but that specific version can return OpenSSL issues. The issue was fixed in the 3.5.3 release, so it’s a low-risk approach to use that version. But before we do that, we need to deal with the issue of virtual environments.  Again, if you are brand new to virtual environments in Python3, check out [this YouTube tutorial](https://www.youtube.com/watch?v=Kg1Yvry_Ydk).

We need to manage both virtual environments themselves, using a utility called venv, and versions of Python within those environment, using pyenv:

`$ sudo apt-get install -y python3-venv`

`$ curl https://pyenv.run | bash`

As the second installation completes, you'll see a message that says _Load pyenv automatically by adding the following to \~/.bashrc:_ followed by a command.   .bashrc is a hidden file that contains a set of commands that Ubuntu's Bash shell runs on startup. We need to add a few lines to .bashrc — but we're not going to open the file to edit it. Instead, an easy way to do this is to run the following commands, in this order, one at a time:

```
$ echo '' >> ~/.bashrc
$ echo 'export PATH="/home/ubuntu/.pyenv/bin:$PATH"' >> ~/.bashrc
$ echo 'eval "$(pyenv init -)"' >> ~/.bashrc
$ echo 'eval "$(pyenv virtualenv-init -)"' >> ~/.bashrc
$ exec "$SHELL"
```

Each of these `echo` commands appends a new line to the file `.bashrc` by using the `>>` (_append output_) command.

We're getting close to installing Python in a virtual environment! Let’s see what versions we can install. To list all the versions of Python available to us, from 3.5.0 to 3.5.9, run 

`$ pyenv install --list | grep " 3\.[5]"`

We want 3.5.3, so run

`$ pyenv install 3.5.3`

If you like to see all the gory details (or if the install hits an error the first time around) you can use the "verbose" argument:

`$ pyenv install 3.5.3 -v`

Grab a coffee — this will take a while. Once the command completes run 

`$ pyenv versions`

to see the Python versions now available. All being well it will say:

> \* system (set by /home/ubuntu/.pyenv/version)

> 3.5.3

Note that the steps listed above only have to be done once in your development environment, and you don't have to repeat them for each tap.


### Part 3: Installing and running a tap and target

#### Six steps to a happy tap

To install either a tap or a target, follow these steps:

1)	Create a virtual environment for the tap or target
2)	Activate that virtual environment. The command prompt will change to indicate the virtual environment you're operating in.
3)	Specify the version of Python to use in this environment.
4)	Install pip and wheel, which are package managers that allow us in turn to install the tap or target.
5)	Install the tap or target using pip.
6)	Close out of the virtual environment.

Once these steps are complete, we can run the tap or target by calling for it in its virtual environment. 

Here's what these six steps look like in practice. In this example we use _tap-autopilot_, which connects with the [Autopilot](https://www.autopilothq.com/) email automation platform. Swap out `tap-autopilot` in the steps below with your tap’s reference, as found at [https://www.singer.io/](https://www.singer.io/):

```
$ python3 -m venv ~/.virtualenvs/tap-autopilot      	# create a virtual environment specific to this tap
$ source ~/.virtualenvs/tap-autopilot/bin/activate  	# activate the virtual environment
(tap-autopilot) $ pyenv local 3.5.3					# set the local version of Python
(tap-autopilot) $ pip install --upgrade pip wheel			# install wheel
(tap-autopilot) $ pip install tap-autopilot				# install the tap
(tap-autopilot) $ deactivate						# exit the virtual environment
```

There we go — the tap is installed. To run it, we don't call the program directly, but instead call its virtual environment:

`$ ~/.virtualenvs/tap-autopilot/bin/tap-autopilot`

At this point that command won't do anything because we don't have a destination yet. If you try it, you'll get the error:

> tap-autopilot: error: the following arguments are required: -c/--config

To get the data flow working we need a destination for our data (a target), and we need to do a bit of configuration for the tap.  

But first let’s install the target. The steps are similar to those for the tap. In this example we load Autopilot data to .csv format using target-csv:

```
$ python3 -m venv ~/.virtualenvs/target-csv      # create a virtual environment specific to this tap
$ source ~/.virtualenvs/target-csv/bin/activate  # activate the virtual environment
(target-csv) $ pyenv local 3.5.3
(target-csv) $ pip install --upgrade pip wheel
(target-csv) $ pip install target-csv
(target-csv) $ deactivate
```

So now we can invoke the target in its own virtual environment using 

`$ ~/.virtualenvs/target-csv/bin/target-csv`

So let's do a quick manual test of this to make sure all is well with the target.  We are going to manually write a dummy tap output to `stdOut` and push it to the target as follows:

```
printf '{"type":"SCHEMA", "stream":"hello","key_properties":[],"schema":{"type":"object", "properties":{"value":{"type":"string"}}}}\n{"type":"RECORD","stream":"hello","schema":"hello","record":{"value":"world"}}\n' | ~/.virtualenvs/target-csv/bin/target-csv
```
If all goes well you will just the the prompt character back, and it will look as if nothing happened (or maybe you will see the message `INFO Sending version information to singer.io. To disable sending anonymous usage data, set the config parameter "disable_collection" to true`).  But if you check your files ( with `$ ls` ) you should see a new .csv file called something like `hello-20200928T212555.csv`.

If you go and edit the file using (for example) 

`$ nano hello-20200928T212555.csv`

you will see that the file simply has two lines of text that read:

```
value
world
```

Not only does this confirm your target is working as it should, it also gives you a way to manually play around the data.  You can now see how tap output data in JSON gets written to a new .csv file by the target.  So feel free to play around with that command and throw some other data at `target-csv` and see what results you get.

If you don't care too much to know how this works, you can jump to the next heading "Configuring the tap".  But for those of you who are interested, what we just did is write two separate lines to Standard output using the `printf` command.

The first line provided `target-csv` with a record of the [SCHEMA](https://github.com/singer-io/getting-started/blob/master/docs/SPEC.md#schema-message) (or instructions on how our data in the subsequent records will be structured).

`{"type":"SCHEMA", "stream":"hello","key_properties":[],"schema":{"type":"object", "properties":{"value":{"type":"string"}}}}`

and notice that in stdOut we mark the end of the line with `\n`

We then provided tap-csv with a [RECORD](https://github.com/singer-io/getting-started/blob/master/docs/SPEC.md#record-message) that follows the above-mentioned schema:

`{"type":"RECORD","stream":"hello","schema":"hello","record":{"value":"world"}}`

and again, finish the line with `\n`

So we could continue to feed data to target-csv in this fashion with 

`{SCHEMA}\n{RECORD}\n{RECORD}\n{RECORD}...  `

The only other type of message we use in Singer standard is [STATE](https://github.com/singer-io/getting-started/blob/master/docs/SPEC.md#state-message) which tracks where the tap and target last left off so we can neatly pick up on our next run.

So if you are looking to learn more about how taps and targets work, this is a good exercise to manually construct json records and feed them to your target.  If you provide misformed json it will also help you learn the type of error messages you can expect.

#### Configuring the tap

OK. We have a tap and a target installed. Now we need to configure the tap. Each tap can be a bit different, so you should visit the GitHub repo for the tap you're working with and read its README.md file. In our case the repo is at [https://github.com/singer-io/tap-autopilot](https://github.com/singer-io/tap-autopilot). You can find the links for other taps on the Singer website, or by googling "_singer-io tap-name_" – for example "[_singer-io tap-adwords_](https://www.google.com/search?q=singer-io+tap-adwords)."

Create a directory where you can keep configuration files organized. Start in the home directory:

`$ cd ~     # return to the home directory`

This just means ‘change the current active directory to my home directory’.

Now create a directory for the config files:

`$ mkdir tap-autopilot-config  	# make the directory called ‘tap-autopilot-config’`

`$ cd tap-autopilot-config     	#  enter that directory`

Now we can create the files that the tap will use to set the parameters for the data import. The first one, which is required, is the environment variables for the tap, including the API key or access token to use to access the Autopilot instance. Per the tap instructions, create a small file in JSON format called config.json with the following content:

```
{
    "api_key": "your-autopilot-api-token",
    "start_date": "2020-01-01T00:00:00Z"
}
```

Logging into the application, I locate the API key in the Settings section.

![](https://www.stitchdata.com/images/singer-getting-started-guide/singer-getting-started-guide_6.jpg)
 
Use your favorite text editor (nano, for example) to create the file on the EC2 instance

`$ nano config.json`

and paste in (right mouse click) 

```
{
    "api_key": "tH1s1Salot0Fch@ract#rsTh@tL00kL1ke@Pa$$word",
    "start_date": "2020-01-01T00:00:00Z"
}
```

The `start_date` variable tells the Tap the first date from which we want to start the import, so any data created before that date will be ignored.

Next, run the tap in "discovery mode," in which it connects to the source and figures out what data can be retrieved. Running a tap in discovery mode generates a catalog file with all the data that we can pull from the source system. After we generate a catalog file we can tweak it to our purpose. Creating a catalog by using discovery mode is much easier than writing a catalog from scratch. Here's the command:

`$ ~/.virtualenvs/tap-autopilot/bin/tap-autopilot --config ~/tap-autopilot-config/config.json --discover  > ~/tap-autopilot-config/catalog.json`

Let's break that command down:

` ~/.virtualenvs/tap-autopilot/bin/tap-autopilot`	This runs the tap from inside its virtual environment ...
` --config ~/tap-autopilot-config/config.json` 	    ... using the configuration file found at this location ...
` –discover  				`	    ... and runs the tap in discovery mode ...
` > ~/tap-autopilot-config/catalog.json`	    ... and writes the output of that command to a new file in the tap-autopilot-config folder called catalog.json

All being well the command returns the messages:

> INFO Loading Schemas  
> INFO Loading schema for contacts  
> INFO Loading schema for lists  
> INFO Loading schema for smart_segments  
> INFO Loading schema for smart_segments_contacts  

_As an aside, if you work with taps on a regular basis, check out Chris Goddard’s **[Singer Discover Utility](https://github.com/chrisgoddard/singer-discover)** . It's designed to take a Singer-specification JSON catalog file and select which streams and fields to include._

We can check that we now have a catalog.json file in our folder by running:

`$ ls -la`

which should return a directory listing like:

> total 40  
> drwxrwxr-x 2 ubuntu ubuntu  4096 Jun 17 17:32 .  
> drwxr-xr-x 8 ubuntu ubuntu  4096 Jun 17 16:05 ..  
> -rw-rw-r-- 1 ubuntu ubuntu 27189 Jun 17 17:32 catalog.json  
> -rw-rw-r-- 1 ubuntu ubuntu    96 Jun 17 16:08 config.json  

So we now have a small config.json file and a larger catalog.json file, which you can open in your favorite editor or in this collapsable [JSON explorer](http://www.bodurov.com/JsonFormatter/). The Singer documentation can help you understand how catalog files are structured.

One challenge with Singer catalog files is that they often default to loading nothing and expect you to explicitly check off the tables or data types you want, so we need to edit the catalog.json file and select which data streams we want to activate. 

Streams are the sub-categories of data that we want to extract.  So in a CRM system, we migh thave one 'stream' for accounts, one for contacts, one for orders etc.

We select streams to replicate by adding the property `"selected": true` to the stream’s _metadata_ object. For this example, we can browse through the catalog.json file until we find the stream's `metadata` array, then append the `"selected": true`   key/value pair to the metadata object for each stream we want to import:

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

When you're done, save the file and exit the text editor. 

We have one final configuration JSON file to create. The role of the state.json file is to capture at the end of each data run the state of play, so that next time the tap-to-target dataflow runs, it can pick up where it left off.

Each tap handles state a little differently, depending on how the team or individual developing the tap decided to implement things.

In the case of tap-autopilot, we're going to use the state.json file to tell the tap which date we want it to start importing data from. As we did with the `selected` statement in catalog.json, we specify the state for each stream individually.

Open the catalog.json file and search for the key `tap_stream_id`. You'll see that tap-autopilot pulls in four types of data: `contacts`, `lists`, `smart_segments`, and `smart_segments_contacts`.

To select the start date of each of these streams, specify the earliest date to match. Create the file ~/tap-autopilot-config/state.json and specify a start date for each stream:

```
{
	"contacts": "2020-06-18T20:32:05Z",
	"lists": "2020-06-18T20:32:05Z",
	"smart_segments": "2020-06-18T20:32:05Z",
	"smart_segments_contacts": "2020-06-18T20:32:05Z"
}
```

Save the file and exit the editor.

Now return to the home directory:

`$ cd ~`

When you run target-csv, as we're doing, Singer will write all the output files to whatever local directory you're in. (Other targets might write data to a database or a remote destination.) Let's create a directory to hold the exported Autopilot data and change to that directory:

`$ mkdir autopilot-export`
`$ cd autopilot-export`

Now when we run the tap and target, we should get a file that contains all the Autopilot contacts since 2020-06-18 in .csv format.

`$ ~/.virtualenvs/tap-autopilot/bin/tap-autopilot --config ~/tap-autopilot-config/config.json --catalog ~/tap-autopilot-config/catalog.json --properties ~/tap-autopilot-config/catalog.json --state ~/tap-autopilot-config/state.json | ~/.virtualenvs/target-csv/bin/target-csv`

![](https://www.stitchdata.com/images/singer-getting-started-guide/singer-getting-started-guide_7.jpg)

Congratulations — if you made it this far, you have succeeded in getting a Singer tap up and running.  You should see your newly created .csv files in your `autopilot-export` folder by running

`$ ls -la`

## Setting up a tap replication schedule using cron

OK, so you can run the tap manually.  That's great.  Next step is making sure you don't have to get up at 2 AM, log into the server and run the command.  So we are going to schedule the tap to run using *cron*.

If you are not familiar with cron, is a neat tool that simply allows us to set up a schedule at which the server will execute any given command.  The term 'Cron' is simply derived from the Greek word for time (chronos). So you might run the tap daily, weekly or every minute if you like (but there are lots of good reasons *not* to do that, namely cost API limits to name just two). 

And cron is pretty simple to set up.  There are lots of good tutorials online such as [this one](https://www.hostinger.com/tutorials/cron-job).

In its simplist form, we just need to edit our crontab (cron table) file and add a single line that specifies the schedule and the same command we were running manually.  
To do this, first make sure you are not in a `venv` (look at your prompt - if you see your virtual environment in parenthesis at the beginning of the line, just type 'deactivate')

Now open your cron table by typing 

`crontab -e`

You will get a message informing you that `no crontab for ubuntu - using an empty one` - which is fine.
The system will then typically invite you to pick a text editor. Pick the one you like best.
When the crontab file opens, it will give you some instructions (as comments in the file).  Cron will run on the server's clock so bear this in mind when scheduling.

Next we just enter a single line at the end of the crontab file after the comments. cron uses a format for time schedules that may appear unfamiliar but is actually fairly simple. For a full tutorial on how to format cron schedules you can [check out this guide](https://www.hostinger.com/tutorials/cron-job#How-to-Write-Cron-Syntax-Properly).  For now I will stick to a schedule that will run twice a day, everyday.  Using our command above, you would add the following to the end of the crontab file:

`16 */12 * * * ~/.virtualenvs/tap-autopilot/bin/tap-autopilot --config ~/tap-autopilot-config/config.json --catalog ~/tap-autopilot-config/catalog.json --properties ~/tap-autopilot-config/catalog.json --state ~/tap-autopilot-config/state.json | ~/.virtualenvs/target-csv/bin/target-csv`

This will run the tap and export the results to a local .csv file every 12 hours (16 minutes after the hour).  Of course your command might move the data from a remote source to a remote destination, such as a data warehouse.

This is pretty barebones.  Once you have mastered this you might want to put the command in a bash file - called, say `run-my-tap.sh`, and include some other commands and call that instead using 

`16 */12 * * * bash run-my-tap.sh`

This can be useful, for example to [send a slack notification when the run is complete using curl](https://api.slack.com/tutorials/slack-apps-hello-world).

# What's next?

I hope you found this tutorial helpful.  Feel free to fork it and suggest changes if you see things that could be improved.

If you'd like to build your own tap, read [this post by developer Jeff Huth](https://www.stitchdata.com/blog/how-to-build-a-singer-tap-infographic/).

---------------------------------------------------

 
# Running Singer on macOS

#### Taps, targets, and Python

Running Singer taps and targets locally on a Mac requires some setup. For instance, macOS comes with Python 2.7 out of the box, but Singer runs on Python 3.5.2, and separate virtual environments are recommended for each tap and target you use. But don't worry, you don't need much familiarity with Python to get up and running.

To work on Singer, use the macOS Terminal app (Finder > Applications > Terminal). Start by installing Homebrew, a free software package management system that makes it easy to install all the other modules required to run Singer.

`$ /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"`

(Note: Likely your Mac will already have Xcode installed, but if you run into issues installing Homebrew, lack of Xcode will likely be the cause. Xcode can be installed from the macOS App Store.)

While we're at it, we'll install the software testing application Pylint

`$ brew install pylint`

Now we can focus on getting Python itself installed. First check the current version:

`$ python --version`

This would typically return Python 2.7.16, which ships with macOS as of this writing (June 2020). We need to install the more up-to-date Python 3. Before we worry about the specific version we need for Singer, let's install the default Python 3; we'll see how to run programs under different Python versions later.

`$ brew install python  # installs 3.7.7 as of time of writing`

We also need to install pyenv, an application that allows us to manage multiple versions of Python on the same computer:

`$ brew install pyenv`

Using pyenv we can install the required version of Python3 we need. Singer runs on Python 3.5.2, but that specific version can return OpenSSL issues. The issue was fixed in the 3.5.3 release, so it’s a low-risk approach to use that version:

`$ pyenv install 3.5.3`

Next, we're going to install an application that allows us to create virtual environments. You can think of these as containers to run programs in, each container setting up its own set of modules to support the core program. We need to do this because different taps and targets may have different dependencies, and these may conflict from one tap to the next.

`$ pip3 install virtualenv`

Now we have our Python development environment set up, and we can go ahead and download a tap and a target to run. Each time you install a tap or target you should follow these five steps:

1.	Create a new virtual environment.
2.	Activate the virtual environment.
3.	Set the local Python version.
4.	Install the tap or target.
5.	Deactivate the virtual environment.

In this example we'll use _tap-autopilot_, which connects with the [Autopilot](https://www.autopilothq.com/) email automation platform. Swap out `tap-autopilot` in the steps below with your tap’s reference, as found at [https://www.singer.io/](https://www.singer.io/). Note that the command-line prompt changes to _(tap-autopilot)$_ when we activate the virtual environment.

`$ virtualenv -p python3 tap-autopilot`  
`$ source tap-autopilot/bin/activate`  
`(tap-autopilot)$ pyenv local 3.5.3`  
`(tap-autopilot)$ pyenv versions # to confirm install and version assigned`  
`(tap-autopilot)$ pip install tap-autopilot`  
`(tap-autopilot)$ deactivate`  

Repeat this process to install the target that allows us to pipe data to .csv files on our local machine, called ‘target-csv’.

`$ virtualenv -p python3 target-csv`  
`$ source target-csv/bin/activate`  
`(target-csv)$ pyenv local 3.5.3`  
`(target-csv)$ pyenv versions # to confirm install and version assigned`  
`(target-csv)$ pip install target-csv`  
`(target-csv)$ deactivate`  

Now we need to configure the tap and target. Each tap can be a bit different, and I recommend visiting the GitHub repo for the tap you're working with to see the exact details. You can find the link for any tap on the Singer website, or by googling “singer-io tap-name” – for example “singer-io tap-adwords.” In our case the repo is at https://github.com/singer-io/tap-autopilot. 

In most cases, configuring a tap requires three files in JSON format: config.json, catalog.json, and state.json.

config.json holds environment variables such as the API key, integration start date, and any other bespoke variables the tap requires. This is a required file.

catalog.json holds the structure of the data streams that are available for inclusion when we run an import. Most taps allow us to create this file automatically using discovery mode, which we'll talk about in a moment. Editing the file lets us turn streams on or off to specify the data we want.

state.json captures the current state of the data feed – it tracks where we wrap up one import so that we can pick up where we left off on the next run. With some taps, you can also use the state.json file to specify independent start dates for importing different data types.

To keep things organized, let’s create a folder where we can keep our configuration files organized. First make sure you're in the root directory by executing:

`$ cd ~     # return to the home directory`

This just means "change the current active directory to my home folder."

Now let’s create a directory for our config files and change to that directory. You can choose any name you like, but naming it tap-<tap name>-config is a good convention.

`$ mkdir tap-autopilot-config  # make the directory called ‘tap-autopilot-config’`  
`$ cd tap-autopilot-config     # enter that directory`

Now let's create the JSON files that the tap will use to set the parameters for the data import. The first one is config.json, which contains the environment variables for the tap, including the access token we need to use to access the Autopilot instance. As per the tap instructions, create a file in JSON format with the following details:

```
{
    "api_key": "your-autopilot-api-token",
    "start_date": "2020-01-01T00:00:00Z"
}
```
You can find the API key by logging into the application and looking in the Settings section.

![](https://www.stitchdata.com/images/singer-getting-started-guide/singer-getting-started-guide_6.jpg)
 
To create the file, back in the Mac Terminal window open your favorite text editor. We used nano:

`$ nano config.json`

and paste in the Key:

```
{
    "api_key": "tH1s1Salot0Fch@ract#rsTh@tL00kL1ke@Pa$$word",
    "start_date": "2020-05-01T00:00:00Z"
}
```

The `start_date` variable tells the Tap the first date from which we want to start the import, so any data created before that date will be ignored.

Next, run the tap in "discovery mode," in which it connects to the source and figures out what data can be retrieved. Running a tap in discovery mode generates a catalog file with all the data that we can pull from the source system. After we generate a catalog file we can tweak it to our purpose. Creating a catalog by using discovery mode is much easier than writing a catalog from scratch. Here's the command:

`$ ~/.virtualenvs/tap-autopilot/bin/tap-autopilot --config ~/tap-autopilot-config/config.json --discover  > ~/tap-autopilot-config/catalog.json`

Let's break that command down:

` ~/.virtualenvs/tap-autopilot/bin/tap-autopilot`	This runs the tap from inside its virtual environment ...  
` --config ~/tap-autopilot-config/config.json` 	    ... using the configuration file found at this location ...  
` –discover  				`	    ... and runs the tap in discovery mode ...  
` > ~/tap-autopilot-config/catalog.json`	    ... and writes the output of that command to a new file in the tap-autopilot-config folder called catalog.json  

All being well the command returns the messages:

> INFO Loading Schemas  
> INFO Loading schema for contacts  
> INFO Loading schema for lists  
> INFO Loading schema for smart_segments  
> INFO Loading schema for smart_segments_contacts  

_As an aside, if you work with taps on a regular basis, check out Chris Goddard’s **[Singer Discover Utility](https://github.com/chrisgoddard/singer-discover)** . It's designed to take a Singer-specification JSON catalog file and select which streams and fields to include._

We can check that we now have a catalog.json file in our folder by running:

`$ ls -la`

which should return a directory listing like:

> total 40  
> drwxrwxr-x 2 ubuntu ubuntu  4096 Jun 17 17:32 .  
> drwxr-xr-x 8 ubuntu ubuntu  4096 Jun 17 16:05 ..  
> -rw-rw-r-- 1 ubuntu ubuntu 27189 Jun 17 17:32 catalog.json  
> -rw-rw-r-- 1 ubuntu ubuntu    96 Jun 17 16:08 config.json  

So we now have a small config.json file and a larger catalog.json file, which you can open in your favorite editor or in this collapsable [JSON explorer](http://www.bodurov.com/JsonFormatter/). The Singer documentation can help you understand how catalog files are structured.

One challenge with Singer catalog files is that they often default to loading nothing and expect you to explicitly check off the tables or data types you want, so we need to edit the catalog.json file and select which "streams" we want to activate. We do this by adding the property `"selected": true` to the stream’s _metadata_ object. For this example, we can browse through the catalog.json file until we find the stream's `metadata` array, then append the `"selected": true`   key/value pair to the metadata object for each stream we want to import:

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

When you're done, save the file and exit the text editor. 

We have one final configuration JSON file to create. The role of the state.json file is to capture at the end of each data run the state of play, so that next time the tap-to-target dataflow runs, it can pick up where it left off.

Each tap handles state a little differently, depending on how the team or individual developing the tap decided to implement things.

In the case of tap-autopilot, we're going to use the state.json file to tell the tap which date we want it to start importing data from. As we did with the `selected` statement in catalog.json, we specify the state for each stream individually.

Open the catalog.json file and search for the key `tap_stream_id`. You'll see that tap-autopilot pulls in four types of data: `contacts`, `lists`, `smart_segments`, and `smart_segments_contacts`.

To select the start date of each of these streams, specify the earliest date to match. Create the file ~/tap-autopilot-config/state.json and specify a start date for each stream:

```
{
	"contacts": "2020-06-18T20:32:05Z",
	"lists": "2020-06-18T20:32:05Z",
	"smart_segments": "2020-06-18T20:32:05Z",
	"smart_segments_contacts": "2020-06-18T20:32:05Z"
}
```

Save the file and exit the editor.

Now return to the home directory:

`$ cd ~`

When you run target-csv, as we're doing, Singer write all the output files in whatever local directory you're in. (Other targets might write data to a database or a remote destination.) Let's create a directory to hold the exported Autopilot data and change to that directory:

`$ mkdir autopilot-export`  
`$ cd autopilot-export`  

Now when we run the tap and target, we should get a file that contains all the Autopilot contacts since 2020-06-18 in .csv format.

`$ ~/.virtualenvs/tap-autopilot/bin/tap-autopilot --config ~/tap-autopilot-config/config.json --catalog ~/tap-autopilot-config/catalog.json --properties ~/tap-autopilot-config/catalog.json --state ~/tap-autopilot-config/state.json | ~/.virtualenvs/target-csv/bin/target-csv`

![](https://www.stitchdata.com/images/singer-getting-started-guide/singer-getting-started-guide_7.jpg)

Congratulations — if you made it this far, you have succeeded in getting a Singer tap up and running.

If you'd like to build your own tap, read [this post by developer Jeff Huth](https://www.stitchdata.com/blog/how-to-build-a-singer-tap-infographic/).
