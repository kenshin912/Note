## Walle 代码 bug fix record

`/opt/walle_home/walle/service/deployer.py`

```py
def cleanup_local(self):
		# clean local package
	  command = 'ls -t ./ | grep "^{project_id}_" | tail -n +2 | xargs rm -rf'.format(project_id=self.project_info['id'])
		with self.localhost.cd(self.local_codebase):
				result = self.localhost.local(command, wenv=self.config())
```



`/opt/walle_home/walle/service/git/repo.py`

```py

import shutil

     def init(self, url):
         # 创建目录
         if not os.path.exists(self.path):
             os.makedirs(self.path)
         # git clone
         if self.is_git_dir():
             return self.pull()
         else:
             # The following line code from github.(https://github.com/meolu/walle-web/issues/896)
             # if not git directory , delete it and read it again.
             # modify by yuan @ Aug.6.2021 11:53
             shutil.rmtree(self.path)
             return self.clone(url)
```

