#!/usr/bin/python
#coding=utf-8

import itchat
import os

@itchat.msg_register('Text')

def text_reply(msg):
	if u'power' in msg['Text'] or u'poweron' in msg['Text']:
		os.system("/usr/bin/wol 14:DD:A9:56:10:13")
		return u'Power on your computer...'
	elif u'mstsc' in msg['Text'] or u'ssh' in msg['Text']:
		return u'36.33.216.86:55555'
	else:
		return u'i cant do other things now...'
	
itchat.auto_login(hotReload=True)
itchat.auto_login(True, enableCmdQR=2)
itchat.run()
