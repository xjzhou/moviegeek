#!/opt/anaconda3/bin/python
# _*_ coding: utf-8 -*-

import argparse
import logger

def main():

    logger.info('[START]')

    parser = argparse.ArgumentParser()
    parser.add_argument("input", help="输入文件路径")
    parser.add_argument("output", help="输出文件路径")

    args = parser.parse_args()

    print(args)

    print(type(args))

    print(args.input)

    logger.info('[END]')


if __name__ == '__main__':
    main()

