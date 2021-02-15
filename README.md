# BKG's Open Source NTRIP Caster Running Under Docker

This repository contains the BKG NTRIP caster set up to run under docker.

NTRIP was invented by the German organisation Bundesamt für Kartographieund Geodäsie (BKG) - 
in English, the Federal Agency for Cartography and Geodesy. 
It's used to transmit corrections from a GNSS base station
to a GNSS rover over the Internet.
(GNSS is the general term for what we often call GPS.)
Recently base stations and rovers have become much cheaper
and you can buy a complete system for less than $1,000.

Your caster softtware has to run on a server with a well-known name.
If you have your own network of Windows machines
and you know how to configure them,
you may be able to get the caster working on one of those.
Here I assume that you are going to set it up on a server on the Internet with a proper domain name.
Nowadays, that's fairly cheap,
and it's one less machine to manage.
(I use a Digital Ocean droplet that costs me $5 per month.)

BKG's caster implements NTRIP Version 1.
It's free and open source.
NTRIP is now at Version 2.
BKG has a version 2 caster, but it's not free or open source.

Docker provides a ready-made predictable environment in which you can build and run software.
The steps to build and run a docker application are the same regardless of your operating system.

Until docker came along,
installing software like this could be a nightmarish mess,
because the environment provided by every computer was
different and unpredictable - Windows 7, Windows 10, Ubuntu Linux, Red hat Linux
or whatever,
and usually with different optional software installed.

When docker runs an application, it creates a stripped-down
Linux environment
within whichever operating system your computer is actually running.
This irons out most of the gotchas and makes success much more likely.

Each docker application is encapsulated in its own environment,
which also reduces problems caused by hidden interactions.
Two applications can only communicate through well understood interfaces.

This does mean that to put a solution together you may have to learn a few new skills,
which is a cost,
but most people find that the benefits of using docker far outweigh this.

This document explains what NTRIP is,
how to set up a suitable environment
for your caster,
how to build and run it and how to manage it once it's running.

I should also say at the beginning that
you don't necessarily need your own NTRIP caster.
There are a number already available that you might use instead.

If you do need to run your own caster,
read on.

## Configuration Files

BKG's original build and installation instructions are
[here](https://github.com/goblimey/ntripcaster/blob/master/ntripcaster/README.txt)
They include some manual steps,
to be followed once the software is built.
Docker uses completely automated builds,
so I've reworked things to allow this.
With this version of the caster,
you start by producing a couple of configuration files
and the rest of the process is automatic.

You just need to set up
two configuration files called sourcetable.dat and ntripcaster.conf.
The distribution includes an example of each file.

There's a copy of BKG's documentation
[here](https://github.com/goblimey/ntripcaster/blob/master/ntripcaster/conf/NtripSourcetable.doc).
It may make more sense if you look at the example configuration files while you are reading it.

The important part is this:

"Go to the configuration directory and rename "sourcetable.dat.dist" and
"ntripcaster.conf.dist" to "sourcetable.dat" and "ntripcaster.conf".
Edit both files according to your needs. For details about "sourcetable.dat"
see file "NtripSourcetable.doc". In the configuration file "ntripcaster.conf"
you have to specify the name of the machine the server is running on
(no IP adress!!) and you can adapt other settings, like the listening ports,
the server limits and the access control."

### sourcetable.dat

Copy the example file:

```
$ cp sourcetable.dat.dist sourcetable.dat
```

and edit sourcetable.dat to suit your needs.

BKG's instructions say:
"Whatever the content of your "sourcetable.dat" finally might be,
it is recommended
to include the following line in that configuration file:
CAS;rtcm-ntrip.org;2101;NtripInfoCaster;BKG;0;DEU;50.12;8.69;http://www.rtcm-ntrip.org/home".

That line is already in the example source table file
so you can just leave it.

Apart from that first line,
sourcetable.dat defines your mountpoints.
You need one for each base station.
I have one base station.
It's on the roof of my shed
in Leatherhead in the UK.
I call my mountpoint "uk_leatherhead".

Each line of sourcetable.dat is a list of fields separate by semicolons.  Mine looks like this:

```
CAS;rtcm-ntrip.org;2101;NtripInfoCaster;BKG;0;DEU;50.12;8.69;http://www.rtcm-ntrip.org/home
STR;uk_leatherhead;Leatherhead;RTCM 3.0;;;;;GBR;51.29;-0.32;1;0;sNTRIP;none;N;N;0;;
```

Field 1 of the second line is "STR" which says that it's defining a mountpoint.

Field 2 "uk_leatherhead" is the name of my mountpoint.

Field 3 "Leatherhead" is the nearest town to my base station.

GBR is the three-letter code for the UK.
You can find the two and three letter code for your country
[here](https://www.iban.com/country-codes).

"51.29;-0.32" gives the longitude and latitude of my base station.
If you don't know that,
you can use "0.00;0.00".

### ntripcaster.conf

Copy the example file:

```
$cp ntripcaster.conf.dist ntripcaster.conf
```

and edit ntripcaster.conf to suit your needs.
The other file defines all sorts of things,
including the user names and password used to access the mountpoints.

There's a password for the base stations.
All base stations use the same password.
There's no facility to specify a user name,
so your base station can use any user name.

There is a separate set of usernames and passords for each mountpoint
which the rovers need to supply when they connect.

The lines you need to change are scattered through the file:

```
rp_email casteradmin@ifag.de       # substitute your email address
server_url http://caster.ifag.de   # substitute http://your.domain.name
```

```
encoder_password sesam01           # Password for base stations.  Choose something more secure.
```

```
server_name igs.ifag.de             # substitute your.domain.name

```
  
The last few lines of the file specify the user names and passwords.
You need one line for each of the mountpoints you specified in sourcetable.dat. 
The rovers use these to access the mountpoints.
For example:

```
/uk_leatherhead:user1:password1,user2:password2
```
creates user names "user1" and "user2" whic a rover can use to connect to that mountpoint.

In this file, the mountpoint names must start with "/"
(but not in sourcetable.dat).

You don't need to create usernames and passwords:

```
/uk_leatherhead
```
creates a public mountpoint - any rover can connect to it.

The mountpoint names are case sensitive -
"MY_MOUNTPOINT", "My_Mountpoint" and "my_mountpoint" are all different names.

## Quick Instructions For Building

These instructions are for those readers
who are familiar with concepts such as docker,
remote management of computers,
domain names, virtual private servers and so on.
If you are not one of those people,
continue to the next section.

Run these commands on your server:

```
git clone git://github.com/goblimey/ntripcaster.git
cd ntripcaster/ntripcaster/conf
cp ntripcaster.conf.dist.in ntripcaster.conf
```

Edit your configuration files as explained above.

Move back to the top level of the project and build your docker image:

```
cd ../..
sudo docker build . -t ntripcaster
```

The build will take a little while and at the end you should see something like this:

```
Step 11/11 : CMD /usr/local/ntripcaster/bin/ntripcaster
 ---> Running in a13e5bbd3545
Removing intermediate container a13e5bbd3545
 ---> fc4f331c1db4
Successfully built fc4f331c1db4
Successfully tagged ntripcaster:latest
```
Run it like so:

```
sudo docker run -p2101:2101 ntripcaster >/dev/null 2>&1 &
```
The caster runs on port 2101.
The -p option publishes that port and makes it available to the outside world
on the same port of the VPS.

">/dev/null" connects the docker command's standard output channel to a special file that just discards anything
written to it.
"2>&1" connects the standard error channel to whatever the standard output channel is connected to.
That means that the docker image will run quietly,
without sending anything to the console.
The "&" at the end of the command runs it in the background,
so you get another prompt and you can issue more commands.
The caster will survive you ending the ssh session
that you used to start it.
It will run until something goes wrong and it dies,
or until it's forcibly shut down.

For a quick check that it's working,
use curl to fetch the home page:

    curl http://localhost:2101/

(That's http, NOT https.)

That request should produce a copy of the source table.
This tests that the caster is running and that it has found its configuration files.

If that works,
and you have curl installed,
you can run a similar test from your local computer
to check that it works across the Internet:

    curl http://my.domain.name:2101/

That should produce the same result.
If the first test worked and this one doesn't,
the most likely explanation is that you haven't arranged with your VPS provider
to open up port 2101 to tcp traffic.

(You could try the same test with a web browser,
but modern versions of chrome have gone all https
and it doesn't seem to like http requests anymore.)

### The Log File

The caster creates a log file as it runs,
which you can use to debug problems.
To see the log have to know the ID of the docker container
which is running the caster:
```
sudo docker ps
```
That produces a list of running docker containers, something like:
```
CONTAINER ID  IMAGE        COMMAND                CREATED        STATUS       PORTS     NAMES
a5666adfd5d5  68b1841290ef "/bin/sh -c /usr/loc…" 2 minutes ago  Up 2 minutes 2101/tcp  happy_bassi
```
So docker is running one image, the caster. Its container ID is a5666adfd5d5.

BKG's original installation instructions say
that to run the caster you should change directory to
/usr/local/ntripcaster/bin
and run the program from there.
It will then pick up the configuration files from
/usr/local/ntripcaster/conf and write a log file
in /usr/local/ntripcaster/logs.

Not quite.
We saw earlier that it's picking up the configuration,
but if we look in the logs directory,
it's empty:

    docker exec -it {container_id} ls /usr/local/ntripcaster/logs

The ls command produces nothing, because there's nothing in there.
The log is actually in the bin directory,
because that was the current directory when we started the caster:

    docker exec -it {container_id} ls /usr/local/ntripcaster/bin
    
    ntripcaster  ntripcaster.log

You can track what's written to the log using the tail command.
The -f option makes tail run forever,
displaying new lines as they arrive:

    docker exec -it {container_id} tail -f /usr/local/ntripcaster/bin/ntripcaster.log

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

If you connect a base station, the source value will increase by one.
If you connect a rover, the client value will increase by one.

Use ctrl/c to stop the tail command.


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
Most receiver have some kind of "fixed" mode,
where they assume that they are stationary.
The result depends on the device and on how long you leave it taking averages.
You can achieve maybe 1m accuracy this way.

Dual-band GNSS Receivers are now available that can analyse
two signals coming from the same satellite on different frequencies
to get an even more acurate position -
typically within half a metre.

Apart from using GNSS to find the base station's position,
you can use traditional surveying techniques
and then simply tell the base station its position.

A base station that knows its position accurately,
it
can send corrections to a nearby rover.
Essentially the base station says "I know I'm here.
The signal from satellite X says that I'm there,
so it's wrong by this much."
It sends out a stream of correction messages for each satellite that it can see.
If the rover is close enough and can see the same satellites,
it can use these data to correct the signals that it's receiving
and get a better fix.
If the rover is within about 10 Km of the base station
and the base station knows its position perfectly,
the rover can find its position within 2 cm.

If the base station's notion of its position is slightly wrong,
the rover's position will be wrong by the same amount.
Imagine you move the rover around a site,
measure the positions of various features and draw a map.
Each position on the map will always be inaccurate by about 2 cm.
Also, if the base station's notion of its position is half a metre to the North of where it really is,
the whole map will be shifted by half a metre to the North.

The Radio Technical Commission for Maritime Services (RTCM) produced a standard
protocol for the corrections over a radio link.
so a base station from one manufacturer can send corrections
to a rover from another manufactuer.
This is called the RTCM protocol.
It's currently at version 3.

RTCM over radio is used for all sorts of purposes
including small drones.
The drone contains a GNSS rover sending position information to its flight controller.
The base station sits on the ground in a fixed position,
sending GNSS corrections to the rover.
The two are connected via Long Range (LoRa) radio.
The operator can pre-program the drone to follow a path
around a site,
avoiding obstacles.
This works well when the base station is in a prominent position
and the rover is high in the air,
so the two have line of site between them.

If the rover is closer to the ground,
for example in a hand-held tracker,
feature such as buildings, trees and hedges can interfere
with the radio connection and make it very flaky.
To provide a better alternative,
the Bundesamt für Kartographieund Geodäsie (BKG) defined
the Network Transport of Rtcm via Internet Protocol (NTRIP)
which replaces the radio link with an HTTP connection over the Internet.

You can buy a base station off the shelf that sends corrections using NTRIP,
and a rover that can receive and use them.
Recently,
the base stations have become much cheaper,
and you can buy a complete system for less than $1,000.
It's also much easier than it used to be to get an Internet connection -
any smart phone can provide one.
The smart phone can also provide a display
for the rover,
reducing the cost.

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

A client (a rover) sends a series of HTTP requests
to the caster
and gets back corrections from a mountpoint (a base station) in response.
Since it matters how far apart the base station and rover are,
the protocol includes a facility for the rover to find its nearest mountpoint.

To use NTRIP,
the rover must be connected to the Internet.
While I was working on this project
I did my testing using
an Emlid Reach M+ as a hand-held rover,
connected to my iPad over Bluetooth
and using its Internet connection.
The Reach is designed to work within a drone.
As a hand-held rover
it's a bit of a lashup,
and I don't recommend it,
but technically it worked quite well.

For more professional applications such as surveying,
companies such as Trimble and Leica
sell hand-held GNSS devices that
can receive corrections from an NTRIP caster.
Obviously they would like you to use their correction service,
but you don't have to.
Trimble recently launched a budget product called the [Catalyst](https://geospatial.trimble.com/catalyst),
which competes on price with my Reach device
and looks much nicer.  

## Getting a Domain and Server
To run the caster, you need a server with a well-known name.
You can achieve that by buying an Internet domain.
Strictly you don't buy a domain.
You rent it from a domain registrar,
so you have to pay regularly to keep it going.

You can obtain a domain from various domain registrars such as
[namecheap](https://www.namecheap.com/)
or [ionos](https://www.ionos.co.uk/domains/domain-names?ac=OM.UK.UKo42K356180T7073a&gclid=CjwKCAjwzJjrBRBvEiwA867byhd5ynLOIbN-A4a2-9cpfmQS4pAvJj4gE6oRjs_5HSW2STzu9oYgiBoCUFUQAvD_BwE&gclsrc=aw.ds).
There are many others.
I mention those two
because their initial registration fees and their subsequent
renewal fees are both reasonable.
When choosing a registrar,
always check the renewal fees.
Beware of introductory offers
that cost you a lot more later.

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
so you can choose how much processor power it has and how much it costs.
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

Each network service on a computer runs on a numbered port,
for example, a web server will usually run its http service on port 80
and its https service on port 443. 
The NTRIP caster runs on port 2101.
For security reasons
many VPS suppliers
stop access to ports by default.
You have to ensure that port 2101 is open for tcp access.
You may need to ask the tech support people how to do this. 

## Connecting to Your VPS
Once your VPS is set up and
responding to your domain name,
you need to connect to it
from whatever computer you normally use.
These instructions assume that 
you are running MS Windows on your local machine
(because most people do)
and that your VPS is running
the Linux operation system
(because that's also what most people do).
If you are running Windows on your VPS,
the procedure to connect will be similar but different.
You need to
consult your VPS supplier about that.
The docker commands will be the same.

There are various ways to connect to your VPS.
The ssh command is probably the most common.
Your Windows machine can't do that out of the box,
you need to install some software.
My suggestion is
[git for windows](https://gitforwindows.org/).
Once you've installed that,
go to your start menu and run Git Bash.
That starts a command window and you can run ssh in that.

To connect to your VPS you need your user name and your domain name.
If your user name is "user" and your domain is "my.domain.name",
connect like so:

    ssh user@my.domain.name

When you set up your VPS you may have been asked
to create a public/private key pair.
They are files in the .ssh directory in your home directory on your local machine.
If the machine you are connecting from has
your private key installed and the machine you are connecting to
has your public key installed,
you don't need a password.

If you didn't create keys,
you will be asked for your password when you connect to your VPS.
That means you can connect to it from any computer,
but so can anybody else who can guess your password.
If you created a key pair,
your VPS should be set up so that
it's only possible to connect from a computer that holds a copy of the private key. 
(So now would be a very good time to make a backup copy of your key pair
on a memory stick.)

Logging in with a key pair means that you don't have to remember yet another password.
That's not just convenient,
it's also much more secure.
Your VPS supplier should have arranged that
it's not possible for anybody to log in over the network using a password.

To see why, once you are connected to your VPS, try this:

    tail -100 /var/log/auth.log
    
It shows the recent log of attempted logins.
If you haven't tried this before, the result is quite scary.
This is what I got:

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
people all round the world trying every few seconds
to connect to my VPS
by guessing user names and passwords.
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
You can see which IP address they are coming in from,
but they are probably using somebody else's computer that they've already compromised.

If you allow connection by user name and password,
it's just a question of time before
somebody makes a correct guess and gets in.
That would be bad.
They can use your VPS for all sorts of nefarious purposes,
for which you could be blamed.

Prevent this by configuring your VPS to refuse logins over the network
using a password.
Consult your VPS supplier about how to do that.
Keep a safe copy of your keys,
otherwise you could lock yourself out as well as the hackers.

That's the security sermon over.  Now let's build an NTRIP caster.

## Installing the Caster
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
I'm going to add sudo to all commands that need it,
and you can just copy and paste them into your git bash window.

(Concerning pasting,
you can't use the usual Windows shortcut ctrl/v to paste into the ssh window.
Right click and a small menu appears with a paste option.)

First, install docker on your VPS.
How you do that depends on which version of Linux you are running
on your VPS.
For Ubuntu, it's:

    sudo apt install docker.io
    
The Docker service needs to be set up to run when your VPS machine starts up:

    sudo systemctl start docker
    
    sudo systemctl enable docker

Next fetch my caster project:

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
Within that, there's a directory called conf.
You need to create files in there
as explained in the earlier section
Configuration Files.

    cd ntripcaster/conf
    cp sourcetable.dat.dist sourcetable.dat
    cp ntripcaster.conf.dist.in ntripcaster.conf

If you are not familiar with Linux, use the editor nano:

    nano sourcetable.dat

While you are in nano,
move around the file using the arrow keys.
The mouse doesn't work.
When you have finished editing the file,
use ctrl/o to write your changes and ctrl/x to exit.

Once you've created those two configuration files,
you can use docker to build your caster.
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

The directives in the Dockerfile
automate a build process which is similar to the steps described by
BKG's original installation instructions shown above.


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

    $ curl http://localhost:2101/
    
That should produce something like this:

    SOURCETABLE 200 OK
    Server: NTRIP NtripCaster 0.1.5/1.0
    Content-Type: text/plain
    Content-Length: 483
    
    CAS;rtcm-ntrip.org;2101;NtripInfoCaster;BKG;0;DEU;50.12;8.69;http://www.rtcm-ntrip.org/home
    STR;uk_leatherhead;Leatherhead;RTCM 3.0;;;;;GBR;51.29;-0.32;1;0;sNTRIP;none;N;N;0;;
    ENDSOURCETABLE

which is the contents of your sourcetable.dat,
preceded by some HTTP header lines.

Meanwhile,
your first git bash windows should still be displaying the server log.
Each request for the source table produces an exra line:

    Kicking unknown 1 [172.17.0.1] [Sourcetable transferred], connected for 0 seconds

This is good.
It shows that your caster is running
and has found its conf directory
and the files in it,
so it's a sign that 
everything is knitted together properly.

If your Git Bash tool supports curl,
you can try the same from your local machine,
connecting over the Internet.
Start another Git Bash
window.
Don't connect it to your VPS, just run this command,
which will run locally and connect to your VPS across the Internet:

    curl http://my.domain.name:2101/

(substituting your domain name)

It should produce the same result.
if not,
the obvious explanation is that
port 2101 on your VPS
is not open for tcp requests.

You could try the same test by typing that request URL
into the address bar of your web browser,
but they are beginning to support https only,
and this request is http, so it may not work.

Now you can shut down the server.  First you must find the ID of the running container,
as described above (in the section on the log file).

To avoid confusion:  to start the server use docker run and specify the image ID.
Once it's running, refer to it using its container ID, not its image ID.

When the container stops,
the Linux image that was running
and any files in it are destroyed,
The advantage of that is that you don't have to do any tidying yourself.
The disadvantage is that if something goes wrong and the caster crashes,
the container dies and
all evidence vanishes with it.

You can set up the docker image so that things like the server log file survive.
Read the docker manual to find out how.

When you use docker,
there's also all sorts of tidying you have to do -
removing old image files and containers.
Again, you need to read the manual,

Whenever you change anything in the project, you need to run the docker build again.
That will produce a new image with a different ID.

When you started the docker image earlier,
it tied up your git bash window.
To avoid that, start the image using this magic:

    sudo docker run {image_id} >/dev/null 2>&1 &

(substituting your image ID)

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
and if you know its container ID you can run commands in it.
For example, if the container id is f473f0749fd0,
this will run the ps command in the container,
which shows you what programs are running there:

    docker exec -tt f473f0749fd0 ps -aef
    
    UID        PID  PPID  C STIME TTY          TIME CMD
    root         1     0  0 16:35 ?        00:00:00 /bin/sh -c ./ntripcaster
    root         6     1  0 16:35 ?        00:00:00 ./ntripcaster
    root         9     0 22 16:50 pts/0    00:00:00 ps -aef

The running programs include the ps that you are running to see this output.

More potential confusion:

    docker ps

is a docker command that lists the running containers.

     ps -aef

is a linux command that lists the running programs.
The two commands do similar jobs and one is named after the other.

When we start the caster running,
it produces a log file within the docker image.
When it started,
the current directory was /usr/local/ntripcaster/bin,
so the log file is in there.
We can see it using the ls command:

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
(and any user name).
The rover will need the user name and password for the mountpoint
that it's going to use.

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

The software is built using the make command.
There is a file called makefile in each directory that tells make what to do.

The configure command runs another command automake
which creates each makefile from a template
called makefile.in and the settings in makefile.am. 

To automate the manual configuration step,
I edited Makefile.am and Makefile.in
in the conf directory.
The etc_DATA setting controls the files that are copied
from that directory when the software is installed.
The original contains:

    etc_DATA = ntripcaster.conf.dist sourcetable.dat.dist
    
so only those two files are copied.

In my version that becomes

    etc_DATA = ntripcaster.conf.dist sourcetable.dat.dist ntripcaster.conf sourcetable.dat

Now when docker runs "make install",
it copies four files from the conf directory rather than two.

So you just have to create ntripcaster.conf and sourcetable.dat
and then run docker.
It runs configure, which runs automake to create the makefiles,
then it runs make to build and install the software.

Actually, what's supposed to happen is that the template Makefile.in is
edited by automake based on the settings in Makefile.am,
so it should only be necessary to change makefile.am.
I think what's happened is that somebody has run configure
and then committed the result,
so I've inherited a Makefile.in that is not the original version.
Ah well,
that's the fun world of open-source software for you.

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
