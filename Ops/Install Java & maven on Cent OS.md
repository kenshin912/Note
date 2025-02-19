# Install Java & maven on Cent OS

### Install Java

```bash
tar zxvf jdk-8u261-linux-x64.tar.gz
mv jdk1.8.0_261 /usr/local/java
vim /etc/profile
```

```bash
export JAVA_HOME=/usr/local/java
export JRE_HOME=${JAVA_HOME}/jre
export CLASSPATH=.:${JAVA_HOME}/lib:${JRE_HOME}/lib
export PATH=${JAVA_HOME}/bin:$PATH
```

```bash
source /etc/profile
ln -s /usr/local/java/bin/java /usr/bin/java
java -version

java version "1.8.0_261"
Java(TM) SE Runtime Environment (build 1.8.0_261-b12)
Java HotSpot(TM) 64-Bit Server VM (build 25.261-b12, mixed mode)
```



### Install Maven

```bash
tar zxvf apache-maven-3.6.3-bin.tar.gz
mv apache-maven-3.6.3 /usr/local/maven
vim /etc/profile
```

```bash
export MAVEN_HOME=/usr/local/maven
export MAVEN_HOME
export PATH=$PATH:$MAVEN_HOME/bin
```

```bash
source /etc/profile
mvn -version

Apache Maven 3.6.3 (cecedd343002696d0abb50b32b541b8a6ba2883f)
Maven home: /usr/local/maven
Java version: 1.8.0_261, vendor: Oracle Corporation, runtime: /usr/local/java/jre
Default locale: en_US, platform encoding: UTF-8
OS name: "linux", version: "4.18.0-193.19.1.el8_2.x86_64", arch: "amd64", family: "unix"
```

