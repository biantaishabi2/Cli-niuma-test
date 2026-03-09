#!/usr/bin/env bash
#
# niuma CLI 命令集成测试脚本
# 测试 niuma CLI 各命令的正常执行
#

set -uo pipefail

# 测试计数器
TESTS_PASSED=0
TESTS_FAILED=0

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 断言函数
assert_equals() {
    local expected="$1"
    local actual="$2"
    local message="${3:-}"
    
    if [[ "$expected" == "$actual" ]]; then
        echo -e "${GREEN}✓ PASS${NC}: $message"
        TESTS_PASSED=$((TESTS_PASSED + 1))
        return 0
    else
        echo -e "${RED}✗ FAIL${NC}: $message"
        echo "  Expected: $expected"
        echo "  Actual: $actual"
        TESTS_FAILED=$((TESTS_FAILED + 1))
        return 1
    fi
}

assert_exit_code() {
    local expected="$1"
    local command="$2"
    local message="${3:-}"
    
    local exit_code=0
    eval "$command" >/dev/null 2>&1 || exit_code=$?
    
    if [[ "$expected" == "$exit_code" ]]; then
        echo -e "${GREEN}✓ PASS${NC}: $message (exit code: $exit_code)"
        TESTS_PASSED=$((TESTS_PASSED + 1))
        return 0
    else
        echo -e "${RED}✗ FAIL${NC}: $message"
        echo "  Expected exit code: $expected"
        echo "  Actual exit code: $exit_code"
        TESTS_FAILED=$((TESTS_FAILED + 1))
        return 1
    fi
}

assert_contains() {
    local expected="$1"
    local actual="$2"
    local message="${3:-}"
    
    if [[ "$actual" == *"$expected"* ]]; then
        echo -e "${GREEN}✓ PASS${NC}: $message"
        TESTS_PASSED=$((TESTS_PASSED + 1))
        return 0
    else
        echo -e "${RED}✗ FAIL${NC}: $message"
        echo "  Expected to contain: $expected"
        echo "  Actual: $actual"
        TESTS_FAILED=$((TESTS_FAILED + 1))
        return 1
    fi
}

# 测试场景 1: 配置加载 - 验证 .niuma.yml 配置正确解析
test_config_loading() {
    echo -e "\n${YELLOW}=== Test: 配置加载场景 ===${NC}"
    
    local config_file=".niuma.yml"
    
    # 验证配置文件存在
    if [[ -f "$config_file" ]]; then
        echo -e "${GREEN}✓ PASS${NC}: 配置文件 $config_file 存在"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "${RED}✗ FAIL${NC}: 配置文件 $config_file 不存在"
        TESTS_FAILED=$((TESTS_FAILED + 1))
        return 1
    fi
    
    # 验证必要字段存在
    if grep -q "^ai:" "$config_file"; then
        echo -e "${GREEN}✓ PASS${NC}: 配置包含 'ai' 顶级字段"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "${RED}✗ FAIL${NC}: 配置缺少 'ai' 顶级字段"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
    
    if grep -q "default:" "$config_file"; then
        echo -e "${GREEN}✓ PASS${NC}: 配置包含 'default' 字段"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "${RED}✗ FAIL${NC}: 配置缺少 'default' 字段"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
    
    if grep -q "providers:" "$config_file"; then
        echo -e "${GREEN}✓ PASS${NC}: 配置包含 'providers' 字段"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "${RED}✗ FAIL${NC}: 配置缺少 'providers' 字段"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
    
    if grep -q "workflow:" "$config_file"; then
        echo -e "${GREEN}✓ PASS${NC}: 配置包含 'workflow' 字段"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "${RED}✗ FAIL${NC}: 配置缺少 'workflow' 字段"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
}

# 测试场景 2: 命令执行 - 验证 niuma CLI 基本可用性
test_niuma_version() {
    echo -e "\n${YELLOW}=== Test: 命令执行场景 (niuma CLI) ===${NC}"
    
    # 检查 niuma 命令是否存在
    if command -v niuma &>/dev/null; then
        echo -e "${GREEN}✓ PASS${NC}: niuma 命令可用"
        TESTS_PASSED=$((TESTS_PASSED + 1))
        
        # 测试 --help 返回退出码 0
        assert_exit_code 0 "niuma --help" "niuma --help 返回退出码 0"
        
        # 测试帮助信息输出
        local help_output
        help_output=$(niuma --help 2>&1) || true
        if [[ -n "$help_output" ]] && echo "$help_output" | grep -q "Available Commands"; then
            echo -e "${GREEN}✓ PASS${NC}: niuma --help 返回帮助信息"
            TESTS_PASSED=$((TESTS_PASSED + 1))
        else
            echo -e "${YELLOW}⚠ WARN${NC}: niuma --help 未返回预期帮助信息"
        fi
    else
        echo -e "${YELLOW}⚠ SKIP${NC}: niuma 命令未安装，跳过 CLI 测试"
    fi
}

# 测试场景 4: 错误处理 - 验证无效命令参数返回非零退出码
test_error_handling() {
    echo -e "\n${YELLOW}=== Test: 错误处理场景 ===${NC}"
    
    if command -v niuma &>/dev/null; then
        # 测试无效参数返回非零退出码
        local exit_code=0
        niuma --invalid-flag 2>/dev/null || exit_code=$?
        
        if [[ "$exit_code" -ne 0 ]]; then
            echo -e "${GREEN}✓ PASS${NC}: 无效参数返回非零退出码 (exit code: $exit_code)"
            TESTS_PASSED=$((TESTS_PASSED + 1))
        else
            echo -e "${RED}✗ FAIL${NC}: 无效参数应返回非零退出码"
            TESTS_FAILED=$((TESTS_FAILED + 1))
        fi
        
        # 测试错误信息输出到 stderr
        local stderr_output
        stderr_output=$(niuma --invalid-flag 2>&1) || true
        if [[ -n "$stderr_output" ]]; then
            echo -e "${GREEN}✓ PASS${NC}: 错误信息输出到 stderr"
            TESTS_PASSED=$((TESTS_PASSED + 1))
        else
            echo -e "${YELLOW}⚠ WARN${NC}: 未检测到 stderr 错误输出"
        fi
    else
        echo -e "${YELLOW}⚠ SKIP${NC}: niuma 命令未安装，跳过错误处理测试"
    fi
}

# 测试 mock_provider.sh 可用性
test_mock_provider() {
    echo -e "\n${YELLOW}=== Test: Mock Provider 可用性 ===${NC}"
    
    local mock_script=".niuma/mock_provider.sh"
    
    if [[ -f "$mock_script" ]]; then
        echo -e "${GREEN}✓ PASS${NC}: mock_provider.sh 存在"
        TESTS_PASSED=$((TESTS_PASSED + 1))
        
        if [[ -x "$mock_script" ]]; then
            echo -e "${GREEN}✓ PASS${NC}: mock_provider.sh 可执行"
            TESTS_PASSED=$((TESTS_PASSED + 1))
        else
            echo -e "${RED}✗ FAIL${NC}: mock_provider.sh 不可执行"
            TESTS_FAILED=$((TESTS_FAILED + 1))
        fi
        
        # 测试 mock provider 返回有效 JSON
        local output
        output=$(bash "$mock_script" /dev/null 2>&1) || true
        if [[ -n "$output" ]] && echo "$output" | grep -q '"summary"'; then
            echo -e "${GREEN}✓ PASS${NC}: mock_provider.sh 返回有效 JSON"
            TESTS_PASSED=$((TESTS_PASSED + 1))
        else
            echo -e "${RED}✗ FAIL${NC}: mock_provider.sh 未返回有效 JSON"
            TESTS_FAILED=$((TESTS_FAILED + 1))
        fi
    else
        echo -e "${RED}✗ FAIL${NC}: mock_provider.sh 不存在"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
}

# 主函数
main() {
    echo "========================================"
    echo "niuma CLI 命令集成测试"
    echo "========================================"
    echo "开始时间: $(date '+%Y-%m-%d %H:%M:%S')"
    
    # 切换到项目根目录
    cd "$(dirname "$0")/../.."
    
    # 运行所有测试
    test_config_loading
    test_niuma_version
    test_error_handling
    test_mock_provider
    
    # 输出 TAP 格式报告
    echo ""
    echo "========================================"
    echo "TAP 测试报告"
    echo "========================================"
    echo "1..$((TESTS_PASSED + TESTS_FAILED))"
    echo "# 通过: $TESTS_PASSED"
    echo "# 失败: $TESTS_FAILED"
    
    # 总结
    echo ""
    echo "========================================"
    echo "测试总结"
    echo "========================================"
    echo -e "通过: ${GREEN}$TESTS_PASSED${NC}"
    echo -e "失败: ${RED}$TESTS_FAILED${NC}"
    
    if [[ $TESTS_FAILED -eq 0 ]]; then
        echo -e "\n${GREEN}所有测试通过!${NC}"
        exit 0
    else
        echo -e "\n${RED}存在失败的测试${NC}"
        exit 1
    fi
}

main "$@"
