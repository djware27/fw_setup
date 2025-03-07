# fw_setup
Firewall setup script which supports iptables, nftables, ufw and firewalld written in bash 5.2+

fw_setup.sh will check which firewall you have installed and use that to generate the ALLOW rules based on the ports it finds
open using a ss scan.  It will generate rules for both netid: tcp & udp.  It also creates a safety rule for ssh using a default port
of 22.  You can change which port your ssh server is listening on in the script.  

It has been tested on Debian 12, Ubuntu 24.10 and Fedora KDE 41.

Status is BETA, so don't put this on a production server.

Here are the required dependencies for running the firewall automation script:

Required Dependencies
	1.	iptables (or nftables, ufw, firewalld if preferred)
	•	For managing the firewall rules.
	2.	ss (or netstat if ss is unavailable)
	•	To scan open ports and check listening services.
	3.	rsyslogd
	•	For logging firewall activity.
	4.	logrotate
	•	To prevent logs from growing too large.
	5.	Ansible (for automation)
	•	If you plan to automate the setup or updates of firewall rules.

How to Install Dependencies

For Debian-based systems:

sudo apt update && sudo apt install -y iptables iproute2 rsyslog logrotate

For Red Hat-based systems:

sudo dnf install -y iptables iproute rsyslog logrotate

For Arch-based systems:

sudo pacman -S iptables iproute2 rsyslog logrotate

Once these dependencies are installed, you’re good to go! Let me know if you need more help. 🚀🔥
