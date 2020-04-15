import requests,re,os,time
from bs4 import BeautifulSoup
from multiprocessing import Pool
from multiprocessing.dummy import Pool as ThreadPool
#from tomorrow import threads

class umeiSpider:
    def __init__(self):
        s = requests.session() # 建立会话,会话中共享 Session/Cookies
        s.headers = {"User-Agent":"Mozilla/5.0 (Macintosh; Intel Mac OS X 10_13_6) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/74.0.3325.181 Safari/537.36"}
        self.s = s
        self.proxies = {}
        self.base_url = 'https://umei.fun/posts/'
        self.base_path = 'C://umei'
        self.count = 0

    def open_url(self,url):
        try:
            response = self.s.get(url,proxies=self.proxies,timeout=30)
            if response.status_code == 200:
                return response.text
            return None
        except Exception:
            return None

    def parse_data(self,html):
        #url = self.base_url + str(Number)
        #html = self.open_url(url)
        pattern = r'[a-zA-z]+://[^\s]*datahost.trade[^\s]*'
        imgs = re.findall(pattern,html)
        soup = BeautifulSoup(html,features="html.parser")
        array = re.split(r'[-|：\s]\s*',soup.title.string)
        org,desc,model = array[0],array[1]+array[2],array[5]
        return imgs,org,desc,model

    def save_files(self,imglist,save_path):
        #imglist,org,desc,model = self.parse_data(startNum)
        #save_path = os.path.join(self.base_path,org,model,desc)
        i = 0
        #pool = ThreadPool(5)
        for each in imglist:
            file = self.s.get(each[:-1:],timeout=30)
        #file = pool.map(self.open_url,imglist)
            if file.status_code == 200:
                os.makedirs(save_path,exist_ok=True)
                with open(save_path + '/%s.jpeg'%i,'wb') as f:
                    print ('Downloading file:' + save_path + '/%s.jpeg'%i)
                    f.write(file.content)
                    i +=1
                    f.close()
            else:
                print ('Ignore invalid files!')

    def main(self,startNum,stopNum):
        for i in range(startNum,stopNum):
            print ('Serial Number:' + str(i))
            url = self.base_url + str(i)
            html = self.open_url(url)
            if html is None:
                i +=1
                print ('Invalid URL: ' + url)
            else:
                imglist,org,desc,model = self.parse_data(html)
                save_path = os.path.join(self.base_path,org,model,desc)
                self.save_files(imglist,save_path)
                print ('Current Serial download completed!')

if __name__ == "__main__":
    result = umeiSpider()
    result.main(500,1000)