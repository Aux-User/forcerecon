# forcerecon
This script scans the network for live hosts and identifies their open ports, services and vulnerabilities. Each host is then checked for weak passwords via brute force attack and the scan results saved in a report.    

This script was written as part of my Penetration Testing module that I took for class.   
Below a short summary of what the script does while more details are available in the project documentation - [ProjDoc-PT.pdf](https://github.com/Aux-User/forcerecon/blob/main/ProjDoc-PT.pdf)    

The script executes as follows:
- Prompts user to specify a user list and password list for the password testing phase later.
- Alternatively, a password list may be generated on the spot with crunch
- Network is scanned using nmap to generate a list of hosts
- Each host is
  - Scanned with nmap for:
    - Open ports
    - Services
    - OS
    - Potential vulnerabilities
  - Subject to a password strength check using a brute force attack with hydra
- After all hosts have been tested, a tone is played to let the user know that the run is concluded.
- A report is generated and the user may choose to view the details of the scan on a single machine or the whole network.

**Addtional files in repository**    
pilotauth.lst and pilotroster.lst are the files containing login credentials used for the brute force attack recorded in the documentation.
