# 本人工作专用

定期更新

主要工作思路：

1、创建实际工作目录和文件
2、复制文件
3、创建deb

工作目录允许用户修改或者重建，例如/lib/systemd/system/hubv3.service


# 清除全部工作痕迹
./build.sh --clean

用户创建不同的deb时，互不干扰

# 重建
./build.sh --rebuild

删除工作目录内的数据，重建，一般用户数据全乱了

rebuild时，本目录内的部分文件，复制到工作目录

./build.sh

编译deb，

一般如果工作目录内的文件，如果已经存在的话，不会用本目录内的文件覆盖， 便于编辑，直到rebuild指令

