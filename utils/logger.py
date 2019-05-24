# coding: utf-8

import logging
import logging.handlers
from logging import *
import datetime
import sys

# logging初始化工作
logging.basicConfig()
logger = logging.getLogger()
logger.setLevel(logging.INFO)

'''
TimedRotatingFileHandler(filename [,when [,interval [,backupCount]]])

- when 是一个字符串的定义如下：
    'S': Seconds
    'M': Minutes
    'H': Hours
    'D': Days
    'W': Week day (0=Monday)
    'MIDNIGHT': Roll over at midnight

- interval 是指等待多少个单位when的时间后，Logger会自动重建文件，当然，这个文件的创建
取决于filename+suffix，若这个文件跟之前的文件有重名，则会自动覆盖掉以前的文件，所以
有些情况suffix要定义的不能因为when而重复。

- backupCount 是保留日志个数。默认的0是不会自动删除掉日志。若设10，则在文件的创建过程中
库会判断是否有超过这个10，若超过，则会从最先创建的开始删除
'''

rht = logging.handlers.TimedRotatingFileHandler("/data/xjzhou/moviegeek/logs/logger", 'D', 1, 10)
rht.suffix = "%Y%m%d%H%M"


'''
    fmt = logging.Formatter("%(asctime)s \
    %(pathname)s \
    %(filename)s \
    %(funcName)s \
    %(lineno)s \
    %(levelname)s \
    : %(message)s", \
    "%Y-%m-%d %H:%M:%S")
'''

fmt = logging.Formatter("[%(asctime)s] [%(levelname)s] \
%(filename)s:%(funcName)s:%(lineno)d \
: %(message)s", \
"%Y-%m-%d %H:%M:%S")

rht.setFormatter(fmt)

# !!!
logger.addHandler(rht)

def quick_start_log(log_fn=None, mode=None, level=logging.DEBUG, \
                    format='%(asctime)s|%(name)s|%(levelname)s| %(message)s'):
    '''
    simplest basicConfig wrapper, open log file and return default log handler
    '''

    if log_fn is None:
        now = datetime.datetime.now()
        ts = now.strftime('%Y-%m-%d_%H%M%S')
        log_fn = '%s.%s.log' % (sys.argv[0], ts)

    if mode is None:
        mode = 'w'

    logging.basicConfig(level=level,
                        format=format,
                        filename=log_fn,
                        filemode=mode)

    logger = logging.getLogger('main')
    if mode.lower() == 'a':
        logger.info('---=== START ===---')

    return logger

if __name__ == '__main__':
    log = quick_start_log()
    log.info('message')
    log.fatal('exit')
