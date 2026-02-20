#!/bin/bash
# 故意失败的 gate 脚本，用于测试 gate retry + PR review 机制
echo "FAIL: intentional gate failure for testing"
echo "Test assertion error: expected 'success' got 'failure'"
exit 1
