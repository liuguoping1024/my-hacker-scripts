import argparse
import json
import os
import subprocess
from pathlib import Path

parser = argparse.ArgumentParser()
parser.add_argument('--home', default="/var/lib/homeassistant/homeassistant", help='Default: /var/lib/homeassistant/homeassistant')
args = parser.parse_args()

def check_device_file(file_path):
    my_file = Path(file_path)
    if not my_file.exists():
        print(file_path + " is not exist")
        return
    dev_file = open(file_path, "r+", encoding='utf-8')
    json_string = dev_file.read()
    dev_file.close()

    body = json.loads(json_string)
    if 'deleted_devices' in body['data']:
        body['data']['deleted_devices'] = []

    dev_file = open(file_path, "w+", encoding='utf-8')
    dev_file.write(json.dumps(body, indent=2))
    dev_file.close()

    print(file_path + " validate success")
    return


def check_entity_file(file_path):
    my_file = Path(file_path)
    if not my_file.exists():
        print(file_path + " is not exist")
        return
    entity_file = open(file_path, "r+", encoding='utf-8')
    json_string = entity_file.read()
    entity_file.close()

    body = json.loads(json_string)
    if 'deleted_entities' in body['data']:
        body['data']['deleted_entities'] = []

    entity_file = open(file_path, "w+", encoding='utf-8')
    entity_file.write(json.dumps(body, indent=2))
    entity_file.close()

    print(file_path + " validate success")
    return

def main_run(dir):
    if not dir.endswith(os.sep):
        dir += os.sep
    dir += '.storage' + os.sep

    device_file = dir + 'core.device_registry'
    entity_file = dir + 'core.entity_registry'

    check_device_file(device_file)
    check_entity_file(entity_file)

    return
