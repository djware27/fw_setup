# fw_setup
Firewall setup script which supports iptables, nftables, ufw and firewalld written in bash 5.2+

## Why I Love Bash

I love **Bash** because it’s **ALGOL**-like. Its simple syntax and powerful control structures feel like an evolution of the clean and structured **ALGOL** language. For anyone who appreciates concise scripting with clarity, Bash delivers that in spades—while still being incredibly flexible and powerful!

## fw_setup
	  
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

## Installation

1. Install dependencies:
    ```bash
    sudo apt update && sudo apt install -y iptables iproute2 rsyslog logrotate
    ```
    For **Red Hat-based** systems:
    ```bash
    sudo dnf install -y iptables iproute rsyslog logrotate
    ```

2. Clone the repository:
    ```bash
    git clone https://github.com/djware27/fw_setup.git
    cd fw_setup
    ```

3. Make the script executable:
    ```bash
    chmod +x firewall_setup.sh
    ```

4. Run the script:
    ```bash
    sudo ./firewall_setup.sh
    ```

## Usage

### **Testing and Verifying Firewall Rules**

To check the applied firewall rules:
```bash
sudo iptables -L -v --line-numbers
```
## Project Goals

The primary goal of this project is to provide a flexible, secure, and automated firewall setup for **Linux-based systems**. The script is designed to help users:

1. **Easily configure and manage firewall rules** using **iptables/nftables**, **UFW**, or **Firewalld**.
2. **Enhance security** by blocking unnecessary ports and services while enabling logging and real-time monitoring.
3. **Simplify firewall automation** with minimal configuration, allowing for easy integration into both test and production environments.
4. **Support multiple Linux distributions**, including **Debian**, **Ubuntu**, **Fedora**, and more.
5. **Provide the option for future AI-driven security and traffic monitoring** to make rule configuration even smarter.
6. **Ensure transparency** and **responsible usage**—guiding users to avoid locking themselves out or breaking their systems.

### Future Goals

1. **Dynamic SSH Port Detection**: Automatically pick up the SSH port from `/etc/sshd_config` or `ssh_config.d`.
2. **Systemd Service Integration**: Create a service to start the firewall and remove the rules when the service is stopped.
3. **Better IPv6 Support**: Implement robust IPv6 firewall rules to ensure the system is secure across both IPv4 and IPv6 traffic.
4. **Documentation**: Provide in-depth documentation on the installation, usage, and customization of the script for different use cases.

### Contributing

Feel free to fork the repository and submit pull requests. Contributions are welcome, especially for new features, bug fixes, and improvements. Please make sure to test your changes before submitting them!
