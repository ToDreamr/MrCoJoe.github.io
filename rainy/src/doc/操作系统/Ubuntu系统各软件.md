# Ubuntu操作系统

##### Nginx安装

###### 删除nginx，–purge包括配置文件

```
sudo apt-get --purge remove nginx
```

删除Nginx的相关核心包和

```
sudo apt-get --purge remove nginx
sudo apt-get --purge remove nginx-common
sudo apt-get --purge remove nginx-core
```

查看是否还有Nginx

```
dpkg --get-selections|grep nginxwhich nginx # 不在显示nginx
```

安装Nginx

```
sudo apt-get install nginx
```

## ufw防火墙

开放端口：

```
ufw allow 80/tcp
```

## 建立操作系统的文件路径映射：

```
# 首先安装工具
yum -y install open-vm-tools open-vm-tools-desktop

# 查看共享的目录 此时可以看到，刚才配置的www目录
vmware-hgfsclient

# 创建一个目录, 用于映射关联
mkdir /www
# 此时用 ls /www 查看目录是空的

# 映射共享目录
vmhgfs-fuse .host:/www /www -o subtype=vmhgfs-fuse,allow_other,nonempty
sudo vmhgfs-fuse .host:/dist /usr/share/nginx/dist -o subtype=vmhgfs-fuse,allow_other
# 此时 ls /www 查看目录，已经有东西了，映射成功。

# 可以不用参数，如下
vmhgfs-fuse .host:/www /www
# 注意：这样虽然映射成功，并且，使用 ll /www 查看里面的内容，权限都是最高权限，但是，其他用户却还是无法访问的。
```
