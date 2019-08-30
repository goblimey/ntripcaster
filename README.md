# BKG's Open Source NTRIP Caster Running Under Docker

This repository contains the BKG NTRIP caster set up to run under docker.

Docker provides a ready-made predictable environment in which you can build and run software.
The steps to buid and run a docker application are the same regardless of your operating system.

This document explains how to create a server that can run the caster,
how to build and run the caster and how to manage it.
It also explains what an NTRIP caster is.

As explained below,
you don't necessarily need your own NTRIP caster.
There are a number already available that you could use.
If you do need to run your own,
read on.

## Domain and Server
To run the caster, you need a server on the Internet with a well-known IP address.
That means you need to own an Internet domain.
You can obtain one from various domain registrars such as
[namecheap](https://www.namecheap.com/)
or [ionos](https://www.ionos.co.uk/domains/domain-names?ac=OM.UK.UKo42K356180T7073a&gclid=CjwKCAjwzJjrBRBvEiwA867byhd5ynLOIbN-A4a2-9cpfmQS4pAvJj4gE6oRjs_5HSW2STzu9oYgiBoCUFUQAvD_BwE&gclsrc=aw.ds).

You don't actually buy a domain.
You rent it from a domain registrar,
so you have to pay regularly to keep it going.
I mention those two registrars
because the initial registration and the subsequent
renewal fees are both reasonable.
When choosing a registrar,
always check the renewal fees.

Once you have your domain name,
you need a computer on the Internet
that answers to it.
You can rent a Virtual Private Server (VPS)
rather than running your own machine.
You may be able to find a VPS supplier that can also handle your domain registration.

Amazon Web Services is one of the best-known VPS suppliers,
but they can be expensive.
[Digital Ocean](https://www.digitalocean.com/)
offer a VPS called a droplet that you can rent for $5 per month.
In the UK,
[Mythic Beasts](https://www.mythic-beasts.com/servers/virtual) offer a configurable VPS,
so you can choose how much processor power it has.

The more powerful your VPS,
the more you pay,
but you don't need much computer power to run an NTRIP caster.
The main issue is network bandwidth.
Messages pass between your base station
and your caster
and between your
rover and your caster.
You need enough bandwidth to handle that traffic.  

When you rent the VPS you can choose what
operating system it runs.
These instruction assume that you are running Linux rather than
Microsoft Windows on your VPS.
It's more secure and more reliable.

Once you've hired your domain and your VPS,
you need to configure the VPS
to answer to the domain name.
How to do that varies according to the two suppliers.
Your VPS supplier's tech support people should be able to explain how to do it.

(That's another reason for using one of the better-known domain registrars such as ionos or namecheap.
The techies at the VPS company should know what to do.)

Each service on a server runs on a numbered port.
The caster runs on port 2101.
For security reasons
many VPS suppliers
stop access to ports by default.
You have to open the port for tcp access.
You may need to ask the tech support people how to do this. 

## Installing the Caster
Once your VPS is set up and
responding to your domain name,
you need to connect to it
from whatever computer you normally use.
The rest of these instructions assume that 
you are running MS Windows on your local machine
(because most people do)
and that your VPS is running
the Linux operation system.
If you are running Windows on it,
the procedure to connect will be similar but different.
You need to
consult your VPS supplier about that.
The docker commands will be the same.

There are various ways to connect to a VPS.
The ssh command is probably the most common.
If your local machine
runs Microsoft Widows
you need to install some software to get an ssh command.
You don't have that out of the box.
You can get one by installing [git for windows](https://gitforwindows.org/).
Once you've installed that,
run Git Bash,
which starts a command window.
You can run ssh in that.

To connect to your VPS you need a user name and password.
You also need your domain name.

When you set up your VPS you may have been asked
to create a public/private key pair.
They are files in the .ssh directory in your home directory on your local machine.
If the computer you are connecting from has
your private key file and the computer you are connecting to
has your public key file,
you don't need a password.

If you didn't create a key pair,
you will be asked for your password when you connect to your VPS,
so you can connect that way from any computer,
but so can anybody else who can guess your password.
If you created a key pair,
your VPS should be set up so that
it's only possible to connect from a computer that holds a copy of the private key.
That's less convenient but much more secure.

If your user name is "user" and your domain is "my.domain.name",
connect to your VPS like so:

    ssh user@my.domain.name

(Now would be a very good time to make a backup copy of your key pair
on a memory stick.)

Once you have connected from your git bash window to your VPS,
you are running commands 
in that window on the VPS,
NOT on your local machine.
Type ctrl/d or the exit command to end the session
and get back to your local machine.

To reinforce my point about other people logging in,
once you are connected, type this command:

    tail -100 /var/log/auth.log
    
This is what I got when I did this:

```
Aug 29 09:31:31 audolatry sshd[24565]: Received disconnect from 122.195.200.148 port 14902:11:  [preauth]
Aug 29 09:31:31 audolatry sshd[24565]: Disconnected from authenticating user root 122.195.200.148 port 14902 [preauth]
Aug 29 09:31:36 audolatry sshd[24567]: Received disconnect from 222.186.15.101 port 58740:11:  [preauth]
Aug 29 09:31:36 audolatry sshd[24567]: Disconnected from authenticating user root 222.186.15.101 port 58740 [preauth]
Aug 29 09:31:37 audolatry sshd[24569]: Received disconnect from 222.186.42.117 port 51976:11:  [preauth]
Aug 29 09:31:37 audolatry sshd[24569]: Disconnected from authenticating user root 222.186.42.117 port 51976 [preauth]
Aug 29 09:32:06 audolatry sshd[24571]: Invfrom the git bash windowalid user rabbitmq from 180.240.229.254 port 40846
Aug 29 09:32:07 audolatry sshd[24571]: Received disconnect from 180.240.229.254 port 40846:11: Bye Bye [preauth]
Aug 29 09:32:07 audolatry sshd[24571]: Disconnected from invalid user rabbitmq 180.240.229.254 port 40846 [preauth]
Aug 29 09:35:30 audolatry sshd[24576]: Received disconnect from 122.195.200.148 port 42495:11:  [preauth]
Aug 29 09:35:30 audolatry sshd[24576]: Disconnected from authenticating user root 122.195.200.148 port 42495 [preauth]
Aug 29 09:38:31 audolatry sshd[24578]: Received disconnect from 36.156.24.43 port 51260:11:  [preauth]
Aug 29 09:38:31 audolatry sshd[24578]: Disconnected from authenticating user root 36.156.24.43 port 51260 [preauth]
Aug 29 09:47:41 audolatry sshd[24582]: Received disconnect from 183.131.82.99 port 17573:11:  [preauth]
Aug 29 09:47:41 audolatry sshd[24582]: Disconnected from authenticating user root 183.131.82.99 port 17573 [preauth]
Aug 29 09:52:41 audolatry sshd[24586]: Received disconnect from 222.186.30.111 port 48306:11:  [preauth]
Aug 29 09:52:41 audolatry sshd[24586]: Disconnected from authenticating user root 222.186.30.111 port 48306 [preauth]
Aug 29 09:55:04 audolatry sshd[24589]: Received disconnect from 183.131.82.99 port 45178:11:  [preauth]
Aug 29 09:55:04 audolatry sshd[24589]: Disconnected from authenticating user root 183.131.82.99 port 45178 [preauth]
Aug 29 09:57:22 audolatry sshd[24592]: Invalid user fsc from 80.211.171.195 port 35560
Aug 29 09:57:22 audolatry sshd[24592]: Received disconnect from 80.211.171.195 port 35560:11: Bye Bye [preauth]
Aug 29 09:57:22 audolatry sshd[24592]: Disconnected from invalid user fsc 80.211.171.195 port 35560 [preauth]
Aug 29 09:57:54 audolatry sshd[24594]: Accepted publickey for root from xxx.xxx.xxx.xxx port 50986 ssh2: RSA SHA256:FheBvetqJo0CCYC3ghFpdnvVJwzXYEXxwwUavFgugXs
Aug 29 09:57:54 audolatry sshd[24594]: pam_unix(sshd:session): session opened for user root by (uid=0)
Aug 29 09:57:54 audolatry systemd-logind[814]: New session 2383 of user root.
Aug 29 09:59:45 audolatry sshd[24722]: Received disconnect from 36.156.24.79 port 47652:11:  [preauth]
Aug 29 09:59:45 audolatry sshd[24722]: Disconnected from authenticating user root 36.156.24.79 port 47652 [preauth]
Aug 29 10:01:11 audolatry sshd[24732]: Received disconnect from 222.186.15.110 port 50693:11:  [preauth]
Aug 29 10:01:11 audolatry sshd[24732]: Disconnected from authenticating user root 222.186.15.110 port 50693 [preauth]
Aug 29 10:03:48 audolatry sshd[28383]: Connection closed by authenticating user root 69.16.201.246 port 56496 [preauth]
Aug 29 10:06:24 audolatry sshd[28387]: Received disconnect from 222.186.30.111 port 24240:11:  [preauth]
Aug 29 10:06:24 audolatry sshd[28387]: Disconnected from authenticating user root 222.186.30.111 port 24240 [preauth]
Aug 29 10:06:24 audolatry sshd[28389]: Received disconnect from 49.88.112.80 port 23981:11:  [preauth]
Aug 29 10:06:24 audolatry sshd[28389]: Disconnected from authenticating user root 49.88.112.80 port 23981 [preauth]
Aug 29 10:08:50 audolatry sshd[28392]: Received disconnect from 183.131.82.99 port 64115:11:  [preauth]
Aug 29 10:08:50 audolatry sshd[28392]: Disconnected from authenticating user root 183.131.82.99 port 64115 [preauth]
Aug 29 10:12:54 audolatry sshd[28397]: error: maximum authentication attempts exceeded for root from 202.104.174.163 port 40946 ssh2 [preauth]
Aug 29 10:12:54 audolatry sshd[28397]: Disconnecting authenticating user root 202.104.174.163 port 40946: Too many authentication failures [preauth]
Aug 29 10:16:22 audolatry sshd[28401]: Connection closed by authenticating user root 78.97.92.249 port 54430 [preauth]
Aug 29 10:17:01 audolatry CRON[28403]: pam_unix(cron:session): session opened for user root by (uid=0)
Aug 29 10:17:01 audolatry CRON[28403]: pam_unix(cron:session): session closed for user root
Aug 29 10:20:08 audolatry sshd[28407]: Received disconnect from 122.195.200.148 port 10224:11:  [preauth]
Aug 29 10:20:08 audolatry sshd[28407]: Disconnected from authenticating user root 122.195.200.148 port 10224 [preauth]
Aug 29 10:21:35 audolatry sshd[28410]: Connection closed by authenticating user git 78.97.92.249 port 41622 [preauth]
Aug 29 10:22:29 audolatry sshd[28412]: Connection reset by 49.88.112.85 port 13845 [preauth]
```

The line that says "Accepted publickey for root" is me connecting using my key.
The rest show other
people all round the world trying to connect by guessing user names and passwords.
Ths will have started as soon as my domain was created
and announced.
One tried connecting as the user root, another tried as the user rabbtmq,
another as fsc, and so on.
Those user names are standard and exist on lots of servers.
The hackers run software that guesses a password,
tries to connect,
guesses another password,
tries to connect
and so on.
It goes on all day and all night as long as your VPS is running.
It probably costs the attackers nothing to do this
because they are stealing time on somebody else's computer to do it.

If you allow connection by user name and password,
somebody will eventually make a correct guess and get in.
That would be bad.
Prevent this by configuring your VPS to only allow lgins over the network
using keys.
Consult your VPS supplier about how to do that.
Keep a safe copy of your keys,
otherwise you could lock yourself out as well as the hackers.

Security sermon over.  Now let's build an NTRIP caster.

First, install docker on your VPS.
How you do that depends on which operating system you are running.

Another small complication.
There's a user called root that has special privileges.
You need them to install things.
Your VPS supplier may set things up so that you log in
using another user that doesn't have those privileges.
If so,
you can get the extra privileges by putting "sudo" at the start of any command.
Forcing you to use sudo is safer because those privileges also allow you to make disastrous mistakes.
Having to start each dangerous command with "sudo" is a reminder to be careful.
Using docker makes things even safer,
because it automates all of the dangerous operations. 

You can also add the sudo if you are root.
It only wastes time,
it doesn't do any harm.
I'm going to use sudo for all commands that need the privilege,
and you can just copy and paste them into your git bash window.

(Concerning pasting,
you can't use the usual Windows shortcut ctrl/v to paste into the ssh window.
Right click and a small menu appears with a paste option.)


For Ubuntu Linux, install docker like so:

    sudo apt-get install docker.io

Fetch my caster project:

    git clone git://github.com/goblimey/ntripcaster.git
    cd ntripcaster
    ls

    Dockerfile  LICENSE  README.md  ntripcaster

That creates a directory called ntripcaster
and moves into it.
(You don't need any privilege to do that,
so you don't need sudo.)
The "ls" command lists the contents of the directory.
It contains four files including Dockerfile and another directory,
also called ntripcaster.

That subdirectory contains the materal to build the caster,
including a file
README.txt containing BKG's original installation instructions.
This is an extract,
which describes the steps that the docker build process has to mimic:

```
To install the NtripCaster do the following:
- unzip the software in a separate directory
- run "./configure" (if you do not want the server to be installed in
"/usr/local/ntripcaster" specify the desired path with "./configure --prefix=<path>")
- run "make"
- run "make install"

After that, the server files will be in "/usr/local/ntripcaster", binaries will
be in "/usr/local/ntripcaster/bin", configuration files in
"/usr/local/ntripcaster/conf", logs in "/usr/local/ntripcaster/logs" and
templates in "/usr/local/ntripcaster/templates" (or in your desired path
correspondingly).

Go to the configuration directory and rename "sourcetable.dat.dist" and
"ntripcaster.conf.dist" to "sourcetable.dat" and "ntripcaster.conf".
Edit both files according to your needs. For details about "sourcetable.dat"
see file "NtripSourcetable.doc". In the configuration file "ntripcaster.conf"
you have to specify the name of the machine the server is running on
(no IP adress!!) and you can adapt other settings, like the listening ports,
the server limits and the access control.
```

Those instructions include some tweaks that
you have to do manually after you've built
and installed the caster.
That's not easy to do
with docker,
so I've made some changes to the setup files
to do it automatically.

Within the directory ntripcaster there is
a directory called conf.
It contains a file
ntripcaster.conf.dist.in.
Before you build the caster.
you need to copy that file
and edit it to fit your environment:

    cd ntripcaster/conf
    cp ntripcaster.conf.dist.in ntripcaster.conf

If you are not familiar with Linux,
use the editor nano.
While you are in nano,
move around the file using the arrow keys.
The mouse doesn't work.
When you have finished editing the file,
use ctrl/o to write your changes and ctrl/x to exit.

    nano ntripcaster.conf

You need to change these lines:

```
rp_email casteradmin@ifag.de       # substitute your email address
server_url http://caster.ifag.de   # substitute http://your.domain.name
```

A few lines later:

```
encoder_password sesam01           # choose a more secure password
```

further down the file:

```
server_name igs.ifag.de             # substitute your.domain.name

```
  
The last two lines of the file are:

```
/BUCU0:user1:password1,user2:password2
/PADO0
```

Those lines define your mountpoints and the user names and passwords that can access them.
Create a mountpoint for your base station.
The name must start with "/".
In the example they are in upper case.
They don't have to be
but whatever you choose,
you must remember to use the same case when configuring your rover -
bucu0, Bucu0 and BUCU0 are all different names.

The second mountpoint in the example has no username list,
so it's public -
anybody can connect their rover to it
without a user name and password.
It's much more secure to require rovers to log in.

Those are all the changes you need to make to ntripcaster.conf.
To get out of the nano editor, type ctrl/o to write the changes and ctrl/x to exit.

Now you can build your caster.
The Dockerfile in the top level directory of your project looks something like this:

```
FROM ubuntu:18.04

COPY ntripcaster /ntripcaster

WORKDIR /ntripcaster

RUN apt-get update && apt-get install build-essential --assume-yes

RUN ./configure

RUN make install

EXPOSE 2101

WORKDIR /usr/local/ntripcaster/bin

CMD ./ntripcaster
```

When docker runs, it creates a Linux environment on your computer
within whichever operating system it's actually running.
it uses that to build an image,
which will later be run in a similar Linux environment.
The directives in the Dockerfile
automate a process which is similar to the steps described by
BKG's original installation instructions shown above,

FROM defines which version of Linux docker will run, in this case Ubuntu 18.4.
Check the website for Linux distribution you are using
and choose the latest stable version.
For Ubuntu, that's [this page](https://ubuntu.com/#download).
Choose the LTS version.

The top level directory of your project contains the Dockerfile and
a directory ntripcaster.
The COPY copies the contents of that directory into a workspace.

WORKDIR sets the current directory to that workspace.

The version of Linux that docker creates is very minimal
and it doesn't contain any software build tools.
The first RUN installs what's needed.
The second one uses them to configure the caster for this Linux environment
and the third one uses the make tool to build and install
the caster.

When the caster runs, it accepts network connections on port 2101.
The EXPOSE allows the rest of the system to access that port.

The next directive WORKDIR sets the working directory when the docker image is run.

Finally, RUN runs a command when the docker image is started.
It runs the caster.
 
You are currently in the directory ntripcaster/ntripcaster/conf.
Move back to the top level directory of your project
(the one that contains Dockerfile)
and build your image: 

    cd ../..
    sudo docker build .

Note the "." in the docker command.
That means "the current directory".
Docker looks in the given directory for a file called Dockerfile
and obeys the directives in it. 

That should produce output showing what it's doing.
It will take a few minutes.
If all goes well,
the last line should be something like:

    Successfully built 68b1841290ef

which means that it's built a docker image called
68b1841290ef.

You get a different image name each time you do this.

Run the image like so:

    sudo docker run -p2101:2101 68b1841290ef

The -p connects port 2101 of the docker image to port 2101 of the host machine,
in this case, your VPS.
As I said earlier, you need to check that network connections are allowed
on this port.
 
Running the image will produce something like:

	NtripCaster Version 0.1.5 Initializing...
	NtripCaster comes with NO WARRANTY, to the extent permitted by law.
	You may redistribute copies of NtripCaster under the terms of the
	GNU General Public License.
	For more information about these matters, see the file named COPYING.
	Starting thread engine...
	[28/Aug/2019:15:21:56] Using stdout as NtripCaster logging window
	[28/Aug/2019:15:21:56] Starting main connection handler...
	[28/Aug/2019:15:21:56] NtripCaster Version 0.1.5 Starting..
	[28/Aug/2019:15:21:56] Listening on port 2101...
	[28/Aug/2019:15:21:56] Using (your domain name) as servername...
	[28/Aug/2019:15:21:56] Server limits: 100 clients, 100 clients per source, 40 sources
	[28/Aug/2019:15:21:56] Starting Calender Thread...
	[28/Aug/2019:15:21:56] Bandwidth:0.000000KB/s Sources:0 Clients:0
 
The "docker run" ties up your git bash window.
Start another and use ssh to connect to your VPS as before.

An NTRIP server responds to http requests.
Using the curl command you can send a request
to the server for its home page and see the result:

    $ curl localhost:2101/
    
That should produce something like this:

    SOURCETABLE 200 OK
    Server: NTRIP NtripCaster 0.1.5/1.0
    Content-Type: text/plain
    Content-Length: 519
    
    CAS;www.euref-ip.net;2101;EUREF-IP;BKG;0;DEU;50.12;8.69;http://www.euref-ip.net/home
    CAS;rtcm-ntrip.org;2101;NtripInfoCaster;BKG;0;DEU;50.12;8.69;http://www.rtcm-ntrip.org/home
    NET;EUREF;EUREF;B;N;http://www.epncb.oma.be/euref_IP;http://www.epncb.oma.be/euref_IP;http://igs.ifag.de/index_ntrip_reg.htm;none
    NET;IGS;BKG;B;N;http://igscb.jpl.nasa.gov/;none;http://igs.ifag.de/index_ntrip_reg.htm;none
    STR;BUCU0;Bucharest;RTCM 2.0;1(1),3(60),16(60);0;GPS;EUREF;ROU;44.46;26.12;0;0;Ashtech Z-XII3;none;B;N;520;TU Bucharest
    ENDSOURCETABLE

Now check that the caster is receiving connections over the Internet.
Back on your local computer,
type this into the address bar of your web browser:

    http://your.domain.name:2101/

where your.domain.name is the domain name that you are using.

DO NOT type this into the Google search box.
That won't work.
Type it into the address bar at the top of the browser.

You should see the same result as the previous test.

This is good.
It shows that your caster is running.
The sourcetable that's returned is a copy of the one in the conf directory,
which gives you some confidence that everything is knitted together propery.

If the first test works and the second one doesn't,
then port 2101 is not open on your VPS.

Your first git bash windows should still be displaying the server log.
Each request for the source table produces an exra line:

    Kicking unknown 1 [172.17.0.1] [Sourcetable transferred], connected for 0 seconds

Now you can shut down the server.  First you must find the ID of the running image:

    sudo docker ps

That produces a list something like:
    
    CONTAINER ID  IMAGE        COMMAND                CREATED        STATUS       PORTS     NAMES
    a5666adfd5d5  68b1841290ef "/bin/sh -c /usr/loc…" 2 minutes ago  Up 2 minutes 2101/tcp  happy_bassi

So docker is running one image, the caster.  Its container ID is a5666adfd5d5.
Stop that container like so:

    sudo docker stop a5666adfd5d5

That stops the container.
Any files in it are destroyed,
The advantage of that is that you don't have to do any tidying yourself.
The disadvantage is that if something goes wrong and the caster crashes,
the container dies and
all evidence vanishes with it.

You can set up the docker image so that things like the server log file survive.
Read the docker manual to find out how.

To avoid confusion:  to start the server use docker run and specify the image ID.
Once it's running, refer to it using its container ID, not its image ID.
The container lasts as long as you are running the image.
The image lasts until you delete it.

Whenever you change anything in the project, you need to run the docker build again.
That will produce a new image with a different ID.

To avoid tying up your git bash window, start the image like so:

    sudo docker run {image_id} >/dev/null 2>&1 &

">/dev/null" connects the command's standard output to a special file that just discards anything
written to it.
"2>&1" connects the standard error channel to whatever the standard output channel is connected to.
That means that the docker image will run quietly.
The "&" at the end of the command runs it in the background,
so you get another prompt and you can issue more commands.
The caster will run until something goes wrong and it dies,
or until it's shut down.

If you run "docker ps" again,
you will see that the container ID is different.
Running a docker image creates a new container.

If something goes wrong, we need to find out what happened
by looking at the log.

The docker container is a complete separate Linux environment
and if you know its container ID you can run commands in it:

    sudo docker ps

    CONTAINER ID  IMAGE        COMMAND                CREATED         STATUS          PORTS      NAMES
    f473f0749fd0  ca624f5eea74 "/bin/sh -c /usr/loc…" 10 minutes ago  Up 10 minutes   8000/tcp   determined_curie

My container is f473f0749fd0

The ps command shows you what programs are running in the container:

    docker exec -tt f473f0749fd0 ps -aef

    UID        PID  PPID  C STIME TTY          TIME CMD
    root         1     0  0 16:35 ?        00:00:00 /bin/sh -c ./ntripcaster
    root         6     1  0 16:35 ?        00:00:00 ./ntripcaster
    root         9     0 22 16:50 pts/0    00:00:00 ps -aef

The running programs include the ps that you are running to see this output.

Going back to the original installation instructions that I quoted earlier,
they say that to run the caster you should change directory to
/usr/local/ntripcaster/bin
and run the program from there.
It will pick up the configuration files from
/usr/local/ntripcaster/conf and write a log file
in /usr/local/ntripcaster/bin:

Not quite.
We saw earlier that it's picking up the configuration,
but if we look in the logs directory,
it's empty:

    docker exec -it f473f0749fd0 ls /usr/local/ntripcaster/logs

The ls command produces nothing, because there's nothing in there.
The log is in the bin directory,
because that was the current directory when we started the caster:

    root@audolatry:/home/simon/ntripcaster# docker exec -it f473f0749fd0 ls /usr/local/ntripcaster/bin
    
    ntripcaster  ntripcaster.log

You can track what's written to the log using the tail command.
The -f option makes tail run forever,
displaying new lines as they arrive:

    docker exec -it 80d5bc1e5b57 tail -f /usr/local/ntripcaster/bin/ntripcaster.log

    [29/Aug/2019:16:55:26] [1:Calendar Thread] Bandwidth:0.000000KB/s Sources:0 Clients:0
    [29/Aug/2019:16:56:26] [1:Calendar Thread] Bandwidth:0.000000KB/s Sources:0 Clients:0
    [29/Aug/2019:16:57:26] [1:Calendar Thread] Bandwidth:0.000000KB/s Sources:0 Clients:0
    [29/Aug/2019:16:58:26] [1:Calendar Thread] Bandwidth:0.000000KB/s Sources:0 Clients:0
    [29/Aug/2019:16:59:26] [1:Calendar Thread] Bandwidth:0.000000KB/s Sources:0 Clients:0
    [29/Aug/2019:17:00:26] [1:Calendar Thread] Bandwidth:0.000000KB/s Sources:0 Clients:0
    [29/Aug/2019:17:01:26] [1:Calendar Thread] Bandwidth:0.000000KB/s Sources:0 Clients:0
    [29/Aug/2019:17:02:26] [1:Calendar Thread] Bandwidth:0.000000KB/s Sources:0 Clients:0
    [29/Aug/2019:17:03:26] [1:Calendar Thread] Bandwidth:0.000000KB/s Sources:0 Clients:0
    [29/Aug/2019:17:04:26] [1:Calendar Thread] Bandwidth:0.000000KB/s Sources:0 Clients:0

Use ctrl/c to stop the tail command.

If nothing bad happens,
the caster will run until
the VPS is shut down.
Your VPS supplier will shut it down occasionally.
They should warn you if they do that,
but you will have to start caster again
using docker run.

You can configure the VPS to run a command whenever it starts.
Unfortunately, how to do that depends on what version of Linux you are running on your VPS.
(Not to be confused with the version that you specified in the Dockerfile.)

I'm running Ubuntu on my VPS, and a Google search led me to https://askubuntu.com/questions/814/how-to-run-scripts-on-start-up.
The relevent part is "The upstart system will execute all scripts from which it finds a configuration in directory /etc/init. These scripts will run during system startup (or in response to certain events, e.g., a shutdown request) and so are the place to run commands that do not interact with the user; all servers are started using this mechanism."

## Configuring Your Base Station and Rover
Configuring your base station and your rover depends on what you are using.
Read the manuals.
You will need to supply the information
that you set up in the ntripserver.conf configuration file.
Both will need
the server URL, port (2101),
and mountpoint name.
The base station should use the encoder password
(and I'm guessing, any user name).
The rover will need the user name and password for the mountpoint.

When any of your devices connect to the caster,
you should see some activity in the caster's log
on your VPS.


## Tweaks to The Original Source Code From BKG
The caster is free software
originally written in C by BKG and distributed by them.
I would have preferred to use that as my starting point,
but when the time came,
I couldn't find it.
Instead I used a copy on github:
https://github.com/nunojpg/ntripcaster.

There are a huge number of ready-made projects out there
written in C and C++ that you can download, build and run.
The procedure tends to be:

    ./configure
    make install

If you can automate the whole process,
including any configuration tweaks,
you can use docker to build the project and run the result.
This section may be useful if you want to do that.

This caster implements NTRIP version 1.
BKG went on to define NTRIP version 2.
They sell a version that implements that,
but there is no free version
as far as I know.

To automate the manual configuration step,
I edited Makefile.am and Makefile.in
in the conf directory.
These are used by the initial configuration phase
to create Makefile.
That controls what the "make install" command does during
the installation phase.
The etc_DATA setting controls the files that are copied:

    etc_DATA = ntripcaster.conf.dist sourcetable.dat.dist
    
becomes

    etc_DATA = ntripcaster.conf.dist sourcetable.dat.dist ntripcaster.conf sourcetable.dat

This sets up the Makefle so that when you run "make install",
it copies four files from the conf directory rather than two.
This allows you to set up ntripcaster.conf and sourcetable.dat
as you need before you build the project.

Theoretically, Makefile.in is derived from Makefile.am
when you run ./configure
so I'm not sure why it's necessary to edit both files,
but it is.

## NTRIP Basics
There are a lot of acronyms in this field.
I'll start by unpicking some of them.

A Global Navigation Satellite System (GNSS) is a network of satellites 
that allows a receiver on the Earth to find its positon accurately.
The first and best-known was the 
Global Positioning System (GPS),
originally created by the American military for missile guidance.
GNSS systems now include
the European Galileo, the Russian GLONASS and the Chinese Baidou.
Each has its own network of satellites
(known as a "constellation").
Many satellite navigation receivers
are capable of picking up signals from all these systems and making use of any of them.

A moving receiver (for example a hand-held device, or in a car, a boat or an aircraft)
that can see enough satellites can find its position reasonably accurately,
typically to within three or four metres.

If the receiver knows that it's in a fixed position
it can do better by repeatedly finding its position and averaging the results.
Dual-band GNSS Receivers are now available that can analyse
two signals coming from the same satellite on different frequencies
to get an even more acurate position.

A base station that knows its position accurately,
it
can send corrections to a nearby rover.

Essentially the base station says "I know I'm here.
The signal from satellite X says that I'm there,
so it's wrong by this much."
It sends a stream of correction messages to the rover,
which uses them to correct the position that it's receiving
from the same satellite.

Apart from using GNSS to find the base station's position,
the operator can use traditional surveying techniques
and then configure the base station accordingly.
The more accurately the position is set,
the more accurate the rover's position will be.

If the rover is within about 10 Km of the base station
and the base station knows its position perfectly,
the rover can find its position within 2 cm.
If the base station position is wrong by, say, 5 cm in one direction,
then each corrected position that the rover produces will be shifted by
5cm in the same direction.

The Radio Technical Commission for Maritime Services (RTCM) produced a standard
protocol for the corrections over a radio link.
so a base station from one manufacturer can send corrections
to a rover from another manufactuer.
This is called the RTCM protocol.
It's currenty at ersion 3.

Radio connections can be a bit flaky
and these days it's much easier than it used to be to get Internet access.
The Network Transport of Rtcm via Internet Protocol (NTRIP)
replaces the radio link with a connection over the Internet
using HTTP.
NTRIP was invented by the German 
Bundesamt für Kartographieund Geodäsie (BKG) -
in English, the Federal Agency for Cartography and Geodesy.
You can buy a base station off the shelf that sends corrections using NTRIP,
and a rover that can receive and use them.
Recently,
the base stations have become much cheaper,
and you can buy a complete system for less than $1,000.

For a device to find a target device
on the Internet,
the target needs a well-known address.
To avoid every base station
needing one of those, NTRIP uses three components,
a caster, a server and a client.

The caster broadcasts the data coming from one or more base stations.
Each base station is represented in the caster by a mountpoint.
All other components communicate via the caster,
so only it needs a well-known address. 

Each base station sends a series of HTTP requests to the caster,
containing correction data in RTCM messages.

The software to do this is called an NTRIP server.
Crucially, it doesn't need a well-known Internet address.
My base base station is currently in a shed in my back garden,
connecting to a caster via my home broadband service. 

A cient (the rover) sends a series of HTTP requests
to the caster
and gets back corrections from a mountpoint (base station) in response.
Since it matters how far apart the base station and rover are,
the protocol includes a facility for the rover to find its nearest mountpoint.

To use NTRIP,
the rover must be connected to the Internet.
This can be done via a mobile phone and a Bluetooth link.

## Commercial NTRIP services
A number of GNSS devices can send and receive NTRIP corrections,
notable manufacturers include Emlid; U-Blox; Trimble and Leica.

There are also a number of sources of NTRIP correction data.
Trimble and Leica both provide these across the world
for their own devices and others,
but their services are expensive
(hundreds of dollars per month).
For somebody like a sureveyor working in the Oil and Gas sector,
this makes a lot of sense:
wherever you are in the world,
your rover will receive some sort of correction data,
making it more accurate than it would be otherwise.
In places like Western Europe,
it wlll be accurate to within a few centimetres.

For a surveyor working for a small local government authority,
or a field archaeologist,
those services may be too expensive,
and running their own base station is more feasible.
Even better,
they might be able to use somebody else's base station
and only need buy a $300 rover.

There are free NTRIP services such as the International GNSS Service (IGS).
and rtk2go.com,
provided by snip.com,
a company that makes and sells commercial NTRIP software.
The free services are very limited,
with just a few base stations scattered over large distances.
For example, my nearest IGS mountpoint is at Herstmonceaux.
If I lived in Brighton or Eastbourne,
that would be great,
but I don't.
I'm about 60 Km away.
The corrections are useful at that distance,
but running my own base station is better.

The rtk2go.com NTRIP service allows you to connect your own base station and share its corrections with other people.
Unfortunately,
a lot of the base station owners (in the UK at least) seem to switch them off when they are not using them.
All the ones near me are only on occasionally.
Also, the service is only free now while it's in beta test.
The owners say that they plan to charge for it eventually.

## NTRIP on a Budget
In the past,
GNSS devices that could produce NTRIP corrections were expensive,
but recently that's changed.

Emlid sell a ready-made device the Reach RS+ for $800.
You can buy that,
connect it to a caster,
and it will provide corrections to your rover.
Emlid's Rover,
the Reach M+, costs about $300 including antenna.
Without corrections, it's accurate to about 4 m,
with them,
to 2 cm.

In 2019, U-Blox launched the ZED-F9P,
a dual-band chip which can be used in a base station or rover.
As a rover
it can find its position to within half a metre
witout a correction source.
With suitable corrections, to 2cm.

Sparkfun sell a version of the U-Blox chip mounted on a circuit board.
It can be connected to a Raspberry Pi to produce an complete base station.
No electronics knowledge or soldering needed.
