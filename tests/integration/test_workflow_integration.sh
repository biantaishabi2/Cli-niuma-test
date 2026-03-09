#!/usr/bin/env bash
#
# GitHub Actions 工作流集成测试
# 验证 GitHub Actions 工作流的配置正确性
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

# 检查 YAML 语法（使用 Python 的 yaml 模块或 yq 如果可用）
check_yaml_syntax() {
    local file="$1"
    
    # 优先使用 Python 的 yaml 模块
    if command -v python3 &>/dev/null; then
        python3 -c "import yaml; yaml.safe_load(open('$file'))" 2>/dev/null
        return $?
    elif command -v python &>/dev/null; then
        python -c "import yaml; yaml.safe_load(open('$file'))" 2>/dev/null
        return $?
    elif command -v yq &>/dev/null; then
        yq '.' "$file" >/dev/null 2>&1
        return $?
    else
        # 退而求其次：检查基本的 YAML 结构
        if grep -q '^name:' "$file" && grep -q '^on:' "$file"; then
            return 0
        fi
        return 1
    fi
}

# 验证工作流文件结构
validate_workflow_structure() {
    local file="$1"
    local issues=()
    
    # 检查必需字段
    if ! grep -q '^name:' "$file"; then
        issues+=("缺少 'name' 字段")
    fi
    
    if ! grep -q '^on:' "$file" && ! grep -q '^"on":' "$file"; then
        issues+=("缺少 'on' 触发器字段")
    fi
    
    if ! grep -q 'jobs:' "$file"; then
        issues+=("缺少 'jobs' 字段")
    fi
    
    if [[ ${#issues[@]} -eq 0 ]]; then
        return 0
    else
        printf '%s\n' "${issues[@]}"
        return 1
    fi
}

# 测试场景 3: 工作流验证 - 验证所有 YAML 文件语法正确
test_workflow_yaml_syntax() {
    echo -e "\n${YELLOW}=== Test: 工作流 YAML 语法验证 ===${NC}"
    
    local workflows_dir=".github/workflows"
    local yaml_count=0
    local valid_count=0
    
    if [[ ! -d "$workflows_dir" ]]; then
        echo -e "${RED}✗ FAIL${NC}: 工作流目录 $workflows_dir 不存在"
        TESTS_FAILED=$((TESTS_FAILED + 1))
        return 1
    fi
    
    echo "扫描目录: $workflows_dir"
    
    for yaml_file in "$workflows_dir"/*.yml "$workflows_dir"/*.yaml; do
        # 处理没有匹配文件的情况
        [[ -e "$yaml_file" ]] || continue
        
        yaml_count=$((yaml_count + 1))
        local basename_file
        basename_file=$(basename "$yaml_file")
        
        # 检查 YAML 语法
        if check_yaml_syntax "$yaml_file"; then
            echo -e "${GREEN}✓ PASS${NC}: $basename_file - YAML 语法有效"
            valid_count=$((valid_count + 1))
        else
            echo -e "${RED}✗ FAIL${NC}: $basename_file - YAML 语法错误"
            TESTS_FAILED=$((TESTS_FAILED + 1))
            continue
        fi
        
        # 验证工作流结构
        local structure_issues
        structure_issues=$(validate_workflow_structure "$yaml_file" 2>&1) || true
        if [[ -z "$structure_issues" ]]; then
            echo -e "${GREEN}✓ PASS${NC}: $basename_file - 工作流结构有效"
            TESTS_PASSED=$((TESTS_PASSED + 1))
        else
            echo -e "${RED}✗ FAIL${NC}: $basename_file - 工作流结构问题:"
            echo "$structure_issues" | sed 's/^/  /'
            TESTS_FAILED=$((TESTS_FAILED + 1))
        fi
    done
    
    if [[ $yaml_count -eq 0 ]]; then
        echo -e "${YELLOW}⚠ WARN${NC}: 未找到 YAML 工作流文件"
    else
        echo -e "\n总计: $yaml_count 个 YAML 文件, $valid_count 个语法有效"
        if [[ $valid_count -eq $yaml_count ]]; then
            TESTS_PASSED=$((TESTS_PASSED + 1))
        fi
    fi
}

# 测试工作流间的依赖关系
test_workflow_dependencies() {
    echo -e "\n${YELLOW}=== Test: 工作流依赖关系验证 ===${NC}"
    
    local workflows_dir=".github/workflows"
    local reusable_workflow_count=0
    
    # 检查是否有可重用工作流引用
    for yaml_file in "$workflows_dir"/*.yml "$workflows_dir"/*.yaml; do
        [[ -e "$yaml_file" ]] || continue
        
        if grep -q 'uses:' "$yaml_file"; then
            reusable_workflow_count=$((reusable_workflow_count + 1))
            local basename_file
            basename_file=$(basename "$yaml_file")
            
            # 提取 uses 引用并验证格式
            local uses_lines
            uses_lines=$(grep 'uses:' "$yaml_file" | sed 's/.*uses:\s*//' | tr -d '[:space:]')
            
            local valid_refs=0
            while IFS= read -r ref; do
                [[ -z "$ref" ]] && continue
                
                # 验证 uses 引用格式: owner/repo/path@ref
                if [[ "$ref" =~ ^[a-zA-Z0-9_-]+/[a-zA-Z0-9_-]+/.+@.+$ ]]; then
                    valid_refs=$((valid_refs + 1))
                fi
            done <<< "$uses_lines"
            
            if [[ $valid_refs -gt 0 ]]; then
                echo -e "${GREEN}✓ PASS${NC}: $basename_file - 包含 $valid_refs 个有效可重用工作流引用"
                TESTS_PASSED=$((TESTS_PASSED + 1))
            fi
        fi
    done
    
    if [[ $reusable_workflow_count -eq 0 ]]; then
        echo -e "${YELLOW}⚠ INFO${NC}: 未检测到可重用工作流引用"
    fi
}

# 测试配置文件验证
test_config_files() {
    echo -e "\n${YELLOW}=== Test: 配置文件验证 ===${NC}"
    
    # 验证 .niuma.yml
    if [[ -f ".niuma.yml" ]]; then
        if check_yaml_syntax ".niuma.yml"; then
            echo -e "${GREEN}✓ PASS${NC}: .niuma.yml YAML 语法有效"
            TESTS_PASSED=$((TESTS_PASSED + 1))
        else
            echo -e "${RED}✗ FAIL${NC}: .niuma.yml YAML 语法错误"
            TESTS_FAILED=$((TESTS_FAILED + 1))
        fi
    fi
    
    # 验证 .niuma/ 目录下的 YAML 文件
    if [[ -d ".niuma" ]]; then
        for yaml_file in .niuma/*.yml .niuma/*.yaml; do
            [[ -e "$yaml_file" ]] || continue
            
            local basename_file
            basename_file=$(basename "$yaml_file")
            
            if check_yaml_syntax "$yaml_file"; then
                echo -e "${GREEN}✓ PASS${NC}: $yaml_file YAML 语法有效"
                TESTS_PASSED=$((TESTS_PASSED + 1))
            else
                echo -e "${RED}✗ FAIL${NC}: $yaml_file YAML 语法错误"
                TESTS_FAILED=$((TESTS_FAILED + 1))
            fi
        done
    fi
}

# 测试 GitHub Actions 特定验证
test_github_actions_specific() {
    echo -e "\n${YELLOW}=== Test: GitHub Actions 特定验证 ===${NC}"
    
    local workflows_dir=".github/workflows"
    
    for yaml_file in "$workflows_dir"/*.yml "$workflows_dir"/*.yaml; do
        [[ -e "$yaml_file" ]] || continue
        
        local basename_file
        basename_file=$(basename "$yaml_file")
        local passed=0
        
        # 检查 permissions 设置（安全最佳实践）
        if grep -q 'permissions:' "$yaml_file"; then
            echo -e "${GREEN}✓ PASS${NC}: $basename_file - 包含权限配置"
            ((passed++))
        else
            echo -e "${YELLOW}⚠ WARN${NC}: $basename_file - 缺少权限配置（permissions）"
        fi
        
        # 检查是否有 job 定义
        if grep -q 'jobs:' "$yaml_file"; then
            local job_count
            job_count=$(grep -c '^  [a-zA-Z_-]*:' "$yaml_file" 2>/dev/null || echo 0)
            echo -e "${GREEN}✓ PASS${NC}: $basename_file - 包含 job 定义"
            ((passed++))
        fi
        
        if [[ $passed -gt 0 ]]; then
            TESTS_PASSED=$((TESTS_PASSED + 1))
        fi
    done
}

# 主函数
main() {
    echo "========================================"
    echo "GitHub Actions 工作流集成测试"
    echo "========================================"
    echo "开始时间: $(date '+%Y-%m-%d %H:%M:%S')"
    
    # 切换到项目根目录
    cd "$(dirname "$0")/../.."
    
    # 运行所有测试
    test_workflow_yaml_syntax
    test_workflow_dependencies
    test_config_files
    test_github_actions_specific
    
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
