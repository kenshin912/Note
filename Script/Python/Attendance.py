import requests,json,sys,re,random,time

LoginPostURL = "http://1.koodpower.cn:8090/seeyon/main.do?method=login"
IndexPageURL = "http://1.koodpower.cn:8090/seeyon/main.do?method=main"
AttBaseURL = "http://1.koodpower.cn:8090/seeyon/ajax.do?method=ajaxAction&managerName=attendanceManager&rnd="
rand = random.randint(11111,99999)
AttPostURL = AttBaseURL + str(rand)
workdata = "managerMethod=savePunchcardData&arguments=%5B%22%22%2C1%5D"
offworkdata = "managerMethod=savePunchcardData&arguments=%5B%22%22%2C2%5D"
header = {"User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/74.0.3729.169 Safari/537.36",}
s = requests.session()
localtime = time.localtime()
h = time.strftime("%H",localtime)

def try_login(username,password):
    PostData = {
        'authorization':'',
        'login.timezone':'GMT+8:00',
        'login_username':username,
        'login_password':password,
        'login_validatePwdStrength':'4',
        'random':'',
        'fontSize':'12',
        'screenWidth':'1920',
        'screenHeight':'1080'
    }
    s.post(LoginPostURL,data = PostData,headers = header)
    Indexpage = s.get(IndexPageURL)
    if re.search(u'670869647114347',Indexpage.text):
        status = True
        print ('Login success!')
    else:
        status = False
        print ('Login failed!')
        sys.exit(1)
    return status

def try_attendance(attposturl,attendancetype):
    if attendancetype == "work":
        res = s.post(attposturl,data = workdata,headers={'Content-Type':'application/x-www-form-urlencoded'})
    else:
        res = s.post(attposturl,data = offworkdata,headers={'Content-Type':'application/x-www-form-urlencoded'})
    return res.text


if __name__== "__main__":
    run = try_login('Username','Password1sHere')
    if int(h) <= 8:
        try_attendance(AttPostURL,"work")
    elif int(h) >=17:
        try_attendance(AttPostURL,"offwork")
    else:
        print ("Wrong Time!")