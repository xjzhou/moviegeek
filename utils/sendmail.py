#!/usr/bin/python
# -*- coding: UTF-8 -*-

import sys, getopt
import argparse
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
from email.header import Header
from email.utils import formataddr
import smtplib

def sending(receivers,subject,content,attach):
    sender = 'jumpserver@idongjia.cn'
    password = 'aS7WSGwEJBtwh4re'
    message = MIMEMultipart()
    #message['From'] = Header("数据组", 'utf-8')
    #message['To'] =  Header("拍卖", 'utf-8')
    message['From'] = formataddr(["数据组",sender])

    message['To'] = formataddr(["数据组成员",receivers])

    message['Subject'] = Header(subject, 'utf-8')

    message.attach(MIMEText(content+u'\n\n\n超级无敌通知系统2018.04.18','plain', 'utf-8'))
    if attach is not None:
        print (attach)
        att1 = MIMEText(open(attach, 'rb').read(), 'base64', 'utf-8')
        att1["Content-Type"] = 'application/octet-stream'
        att1["Content-Disposition"] = 'attachment; '+'filename='+attach
        message.attach(att1)
    try:
        server=smtplib.SMTP_SSL("smtp.exmail.qq.com", 465)
        server.login(sender, password)
        server.sendmail(sender,receivers,message.as_string())
        print ("邮件发送成功")
    except smtplib.SMTPException:
        print ("Error: 无法发送邮件")

def main(argv):
    parser = argparse.ArgumentParser()
    parser.add_argument('--target', '-T',
                        type=str, 
                        help='mail_to_those_target_adresss:   --target a@qq.com b@qq.com',
                        nargs='+',
                        default=['shuju@idongjia.cn'])
    parser.add_argument('--subject','-S',
                            type=str,
                            help='the subject of the mail',
                            nargs=1,
                            default=['job_failed'])

    parser.add_argument('--content','-C',
                            type=str,
                            help='content for the mail',
                            nargs=1,
                            default=[''])

    parser.add_argument('--attach','-A',
                                type=str,
                                help='attachment for the mail:   --attach /data/myfile.txt',
                                nargs=1,
                                default=[None])

    args = parser.parse_args()
    print (args.target,args.subject,args.attach,args.content)

    sending(args.target,args.subject[0],args.content[0],args.attach[0])



if __name__ == "__main__":
   main(sys.argv[1:])
