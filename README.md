LDWin
=====

## Link Discovery Client for Windows
Chris Hall 2010-2013 - [chall32.blogspot.com]

<p align="center"> 
<img src="https://github.com/chall32/LDWin/blob/master/LDWin.png?raw=true" alt="LDWin is a Link Discovery Protocol Client for Windows"/>
</p>

### What is Link Discovery?
Link discovery is the process of ascertaining information from directly connected networking devices, such as network switches.  This can be helpful when diagnosing suspected network connectivity issues.

LDWin supports the following methods of link discovery:

+   [CDP] - Cisco Discovery Protocol
+   [LLDP] - Link Layer Discovery Protocol

LDWin is based on [WinCDP] also by Chris Hall

### Why?
Lets face it.  We have all been there: "where does this network cable / uplink / port go?"

Until now, it has been a matter of looking up cable numbers in databases, fiddling about in the back of server and network racks or worst case - manually tracing cables down the backs of server racks, under the computer room or office floor, in overhead cable trays etc etc...

There must be a better way to tell where a network cable goes to without having to go to all that trouble every time.  VMware ESXi has Link discovery built in. Why not also have link discovery in Windows?

### How to Use
**You must have administrative rights to run this program**

1.   Start the program
2.   From the "Network Connection:" drop down, select the network adaptor over which you wish to obtain network link information
3.   Click "Get Link Data"
4.   LDWin will then listen on the selected network adaptor for link protocol announcements.  It may take up to 60 seconds to receive an announcement
5.   Once an announcement has been received, the received information will be displayed in the results section
6.   Use the "Save Link Data" button to save the received information into a text file

NOTE: A valid TCP/IP address is not required to receive valid link information.

### What's New?
***See the [changelog] for what's new in the most recent release.***


### [Click here to download latest version](https://github.com/chall32/LDWin/blob/master/LDWin.exe?raw=true)

[changelog]: https://github.com/chall32/LDWin/blob/master/ChangeLog.txt
[chall32.blogspot.com]: http://chall32.blogspot.com
[CDP]:http://en.wikipedia.org/wiki/Cisco_Discovery_Protocol
[LLDP]:http://en.wikipedia.org/wiki/Link_Layer_Discovery_Protocol
[WinCDP]:http://github.com/chall32/WinCDP