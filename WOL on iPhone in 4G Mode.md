#### Use WOL on iPhone in 4G Mode

#### iPhone Setting
 * Search "WOL" in AppStore & Download App

 * Input Extenal IP Addr & Your Computer MAC Addr.

#### Gateway Setting
 * NAT Setting -> VirtualServer
 * Random Extenal Port => 9 Port (udp) to your computer static IP Addr

#### Computer Setting
 * "This PC" -> "Manage" -> "Device Manager" -> "Network Adapters" 
 * Choose your network card , right click -> " Properties" -> "Advanced"
 * "Shutdown Wake-On-Lan":"Enabled" , "Wake on Magic Packet":"Enabled"
 * Enable WOL in BIOS Setting

 ### JUST Do it
 