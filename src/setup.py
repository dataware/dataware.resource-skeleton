from setuptools import setup

setup(
    name='dataware-resource',
    version='0.1dev',
    packages=['dataware'],
    license='MIT license',
    long_description=open('README.txt').read(),
    include_package_data=True,
    #install_requires=[
#	"bottle == 0.11.4",
#	"MySQL-python == 1.2.3",
#	"gevent == 0.13.8",
 #   ],
    install_requires=[
	"bottle",
	"MYSQL-python",
	"gevent",
	"sqlparse"
    ]
)

