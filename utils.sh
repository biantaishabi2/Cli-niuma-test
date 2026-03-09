#!/bin/bash
# 读取 config.json 的 app_name
APP_NAME=$(cat config.json | grep app_name | cut -d'"' -f4)
echo "App: $APP_NAME"
