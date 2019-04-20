RHCSA评分脚本:
	教学环境下，在真机解压，server开机时执行./rht-checkcsa.py。按两下回车即可。


Functions:
	Input(1):         check_all        完整测试(测试所有项)
	Input(ENTER):     check_no_user    部分测试(不包含用户密码的验证)
	!!!测试用户密码采用expect方式，比较慢，不建议使用

Files：
 	rht-checkcsa.py --> 主文件 
	.checkcsa 		--> 检测脚本

ISSUE:
1、网络配置检查标准（命令配置），手工写文件的会失败 
2、主机名必须修改，默认配置会检查失败(手工修改配置文件或者使用命令).
3、用户权限，必须先添加组（先添加的组号为1001，这里检查组号），再添加用户.
4、如果检查用户口令，请不要做其他操作（采用expect方式，输入无关内容可能导致检测失败）.

Versions:
2.0	基本功能完成.
2.1	增加颜色显示(正确:绿色，错误:红色),调整check_stu_f()、check_str()、check_tar()逻辑，检测到一个文件不符合就报错(不再列出所有不符合条件的文件).
2.2	增加tar包压缩方式检测，必须能够使用tar jxf 命令解压.
2.3	调整判断机制，/etc/gshadow不在时，去判断/etc/gshadow-(配置ldapuser0后会导致/etc/gshadow 消失，导致用户组检测失败,但会产生 /etc/gshadow-)
2.4	修复find文件时只提示扣分，但未进行统计。
2.5     支持vmware虚拟机 f0_rh254



