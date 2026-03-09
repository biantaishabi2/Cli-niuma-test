#!/usr/bin/env bash
#
# 统一的测试入口脚本
# 运行所有集成测试并生成汇总报告
#

set -uo pipefail

# 脚本所在目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 测试统计
TOTAL_PASSED=0
TOTAL_FAILED=0
TOTAL_SKIPPED=0
TEST_SUITES=()
SUITE_RESULTS=()

# 输出格式
TAP_OUTPUT=false
VERBOSE=false

# 显示帮助
show_help() {
    cat << EOF
Usage: $(basename "$0") [OPTIONS]

统一的测试入口脚本，运行所有集成测试

OPTIONS:
    -h, --help      显示帮助信息
    -t, --tap       输出 TAP 格式报告
    -v, --verbose   详细输出模式
    -s, --suite     指定运行特定测试套件 (commands|workflows|all)

EXAMPLES:
    $(basename "$0")              # 运行所有测试
    $(basename "$0") --tap        # 输出 TAP 格式
    $(basename "$0") -s commands  # 仅运行命令测试
EOF
}

# 解析参数
SUITE="all"
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_help
            exit 0
            ;;
        -t|--tap)
            TAP_OUTPUT=true
            shift
            ;;
        -v|--verbose)
            VERBOSE=true
            shift
            ;;
        -s|--suite)
            SUITE="$2"
            shift 2
            ;;
        *)
            echo "未知选项: $1"
            show_help
            exit 1
            ;;
    esac
done

# 运行单个测试套件
run_test_suite() {
    local suite_name="$1"
    local suite_script="$2"
    
    if [[ ! -f "$suite_script" ]]; then
        echo -e "${YELLOW}⚠ SKIP${NC}: 测试套件不存在: $suite_script"
        TOTAL_SKIPPED=$((TOTAL_SKIPPED + 1))
        return 0
    fi
    
    if [[ ! -x "$suite_script" ]]; then
        chmod +x "$suite_script"
    fi
    
    echo -e "\n${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}  运行测试套件: $suite_name${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    
    local start_time end_time duration
    start_time=$(date +%s)
    
    local output
    local exit_code=0
    
    if $VERBOSE; then
        "$suite_script" || exit_code=$?
    else
        output=$("$suite_script" 2>&1) || exit_code=$?
        if [[ $exit_code -ne 0 ]]; then
            echo "$output"
        else
            # 只显示摘要
            echo "$output" | grep -E '(PASS|FAIL|通过|失败|测试通过|测试失败)' || true
        fi
    fi
    
    end_time=$(date +%s)
    duration=$((end_time - start_time))
    
    TEST_SUITES+=("$suite_name")
    
    if [[ $exit_code -eq 0 ]]; then
        echo -e "${GREEN}✓ 测试套件通过${NC} (${duration}s)"
        SUITE_RESULTS+=("PASS")
        TOTAL_PASSED=$((TOTAL_PASSED + 1))
    else
        echo -e "${RED}✗ 测试套件失败${NC} (${duration}s)"
        SUITE_RESULTS+=("FAIL")
        TOTAL_FAILED=$((TOTAL_FAILED + 1))
    fi
}

# 输出 TAP 格式报告
output_tap() {
    local total_tests=$((TOTAL_PASSED + TOTAL_FAILED + TOTAL_SKIPPED))
    echo ""
    echo "# TAP 测试报告"
    echo "1..$total_tests"
    
    local i=1
    for suite in "${TEST_SUITES[@]}"; do
        local result="${SUITE_RESULTS[$((i-1))]}"
        if [[ "$result" == "PASS" ]]; then
            echo "ok $i - $suite"
        else
            echo "not ok $i - $suite"
        fi
            i=$((i + 1))
    done
    
    echo "# 总计: $total_tests 个测试套件"
    echo "# 通过: $TOTAL_PASSED"
    echo "# 失败: $TOTAL_FAILED"
    echo "# 跳过: $TOTAL_SKIPPED"
}

# 输出标准格式报告
output_standard_report() {
    echo ""
    echo "========================================"
    echo "           测试汇总报告"
    echo "========================================"
    echo ""
    
    printf "%-30s %s\n" "测试套件" "结果"
    echo "----------------------------------------------"
    
    local i=0
    for suite in "${TEST_SUITES[@]}"; do
        local result="${SUITE_RESULTS[$i]}"
        if [[ "$result" == "PASS" ]]; then
            printf "%-30s ${GREEN}%s${NC}\n" "$suite" "✓ 通过"
        else
            printf "%-30s ${RED}%s${NC}\n" "$suite" "✗ 失败"
        fi
            i=$((i + 1))
    done
    
    echo "----------------------------------------------"
    echo ""
    echo "统计:"
    echo -e "  ${GREEN}通过: $TOTAL_PASSED${NC}"
    echo -e "  ${RED}失败: $TOTAL_FAILED${NC}"
    echo -e "  ${YELLOW}跳过: $TOTAL_SKIPPED${NC}"
    echo ""
}

# 主函数
main() {
    echo "========================================"
    echo "      niuma 集成测试框架"
    echo "========================================"
    echo "开始时间: $(date '+%Y-%m-%d %H:%M:%S')"
    echo "项目根目录: $PROJECT_ROOT"
    echo ""
    
    cd "$PROJECT_ROOT"
    
    # 根据选项运行测试
    case $SUITE in
        commands)
            run_test_suite "CLI命令测试" "$SCRIPT_DIR/integration/test_niuma_commands.sh"
            ;;
        workflows)
            run_test_suite "工作流集成测试" "$SCRIPT_DIR/integration/test_workflow_integration.sh"
            ;;
        all)
            run_test_suite "CLI命令测试" "$SCRIPT_DIR/integration/test_niuma_commands.sh"
            run_test_suite "工作流集成测试" "$SCRIPT_DIR/integration/test_workflow_integration.sh"
            ;;
        *)
            echo -e "${RED}错误: 未知的测试套件: $SUITE${NC}"
            show_help
            exit 1
            ;;
    esac
    
    # 输出报告
    if $TAP_OUTPUT; then
        output_tap
    else
        output_standard_report
    fi
    
    # 最终状态
    echo "========================================"
    if [[ $TOTAL_FAILED -eq 0 ]]; then
        echo -e "${GREEN}所有测试通过!${NC}"
        exit 0
    else
        echo -e "${RED}存在失败的测试套件${NC}"
        exit 1
    fi
}

main "$@"
