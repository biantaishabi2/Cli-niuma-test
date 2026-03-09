# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

## [Unreleased]

## [1.0.0] - 2026-03-09

### L0 - 基础配置与初始化

#### Added
- **config.json** - 创建项目配置文件 (#571)
  - 配置项：`app_name` (niuma-test)、`version` (1.0.0)、`debug` (false)
  
- **auto_merge_test.txt** - 创建自动合并测试文件 (#577)
  - 初始内容：`auto-merge L0 test`

### L1 - 工具脚本与扩展

#### Added
- **utils.sh** - 创建 Bash 工具脚本 (#572)
  - 功能：读取 config.json 中的 `app_name` 并输出
  - 用法：`bash utils.sh`

#### Changed
- **auto_merge_test.txt** - 追加 L1 测试内容 (#578)
  - 新增内容：`auto-merge L1 appended`

## 版本说明

- **L0 (Level 0)**: 基础配置层，包含项目核心配置文件
- **L1 (Level 1)**: 工具扩展层，添加实用脚本和文件扩展
- **L2 (Level 2)**: 文档完善层，创建项目文档（CHANGELOG.md）
