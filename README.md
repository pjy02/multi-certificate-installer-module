# 多证书安装器模块

## 概述
本模块专为 Android 系统设计，能够将 `system/etc/security/cacerts` 目录下的所有证书文件批量安装至系统证书存储区，实现系统级证书信任。特别适用于企业内部证书部署、移动应用开发测试等需要自定义 CA 证书的场景。

## 功能特点

- **批量证书安装**: 自动安装 `system/etc/security/cacerts` 目录中的所有 `.0` 证书文件
- **Android 14 支持**: 完全支持 Android 14 APEX 证书存储机制
- **安全检查**: 包含证书数量验证，防止意外覆盖系统证书
- **SELinux 兼容性**: 正确处理 Android 安全策略
- **详细日志记录**: 提供完整的安装日志用于调试

## 使用方法

1. 将证书文件（`.0` 格式）放入模块的 `system/etc/security/cacerts/` 目录中
2. 证书文件名应该是证书的哈希值（例如 `9a389b53.0`）
3. 在 Magisk Manager 中安装模块
4. 重启设备

## 证书文件要求

- 证书文件必须为 `.0` 格式
- 证书文件名应与证书哈希值对应
- 证书必须是 PEM 格式的 X.509 证书
- 支持同时安装多个证书文件

## 兼容性

- 支持 Android 10 及以上版本
- 完全兼容 Android 14 APEX 证书存储
- 需要 Magisk v20.4+

## 日志文件

安装日志保存到 `/data/local/tmp/multi-cert-installer.log`

## 安全说明

- 模块会验证证书总数，仅在数量合理时才执行安装
- 支持传统 Android 版本和 Android 14 APEX 证书存储
- 正确处理 SELinux 上下文和文件权限

## 故障排除

1. 如果证书未安装，请检查日志文件 `/data/local/tmp/multi-cert-installer.log`
2. 确保证书文件格式正确（`.0` 扩展名，PEM 格式）
3. 确保设备已正确安装 Magisk 并具有 root 权限
4. 重启设备并检查证书是否已安装

## 技术细节

模块通过以下方式工作：
1. 扫描 `system/etc/security/cacerts` 目录中的所有 `.0` 文件
2. 对于 Android 14+：使用 APEX 证书存储挂载机制
3. 对于传统 Android 版本：使用 Magisk 的标准模块挂载机制
4. 自动处理 SELinux 上下文和文件权限
5. 为所有相关进程执行证书存储挂载