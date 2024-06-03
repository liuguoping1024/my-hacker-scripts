#!/usr/bin/python3

import sys
import os

repos = [
    'https://github.com/home-assistant/core.git'
]

def print_help():
    print("Usage: ")
    print("repo init: 下载全部代码")
    print("repo sync: 同步本地全部代码")

def git_clone():
 
    for repo in repos:
        print('Begin to clone source: ', repo)
        command = "git clone " + repo
        os.system(command)
    return


def git_sync():
    local = os.getcwd()
    dirs = os.listdir(local)
    for item in dirs:
        path = os.path.join(local, item)
        if os.path.isfile(path):
            continue;

        print(path)
        os.chdir(path)
        os.system("git pull")        
        os.chdir(local)
    
    return

def main():
    if(len(sys.argv) < 2):
        print_help()
        return
    
    cmd = sys.argv[1]

    if cmd == "init":
        git_clone()
        return
    
    if cmd == "sync":
        git_sync()
        return

    print_help()
    return

# main function
if __name__ == '__main__':
    main()


