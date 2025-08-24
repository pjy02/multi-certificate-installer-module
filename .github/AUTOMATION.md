# GitHub Actions 自动化发布指南

## 概述
本项目配置了两个GitHub Actions工作流，用于自动化打包和发布到GitHub Releases。

## 工作流文件

### 1. 基础版 - `release.yml`
**功能：**
- 自动检测版本标签并打包
- 创建GitHub Release
- 上传zip文件

**触发方式：**
```bash
# 推送版本标签
git tag v1.1
git push origin v1.1
```

### 2. 高级版 - `release-advanced.yml`
**功能：**
- 自动版本号管理
- 自动更新module.prop中的版本信息
- 生成update.json文件
- 支持手动触发发布
- 自动版本号递增

**注意：** 需要GitHub Actions有写入权限

**触发方式：**

#### 方式一：标签触发（推荐）
```bash
# 推送版本标签
git tag v1.2.0
git push origin v1.2.0
```

#### 方式二：手动触发
1. 进入GitHub仓库的Actions页面
2. 选择"Advanced Auto Release"工作流
3. 点击"Run workflow"
4. 填写版本号和其他参数

### 3. 简化版 - `release-simple.yml` (推荐)
**功能：**
- 自动检测版本标签并打包
- 创建GitHub Release
- 上传zip文件和update.json
- 显示版本更新信息（需要手动更新）

**优势：**
- 不需要写入权限
- 更稳定的执行
- 适合大多数使用场景

**触发方式：**
```bash
# 推送版本标签
git tag v1.3.0
git push origin v1.3.0
```

## 使用步骤

### 1. 首次设置

#### 启用GitHub Actions
1. 进入GitHub仓库设置
2. 点击"Actions"选项卡
3. 选择"Allow all actions and reusable workflows"
4. 保存设置

#### 配置仓库权限
**对于简化版工作流（推荐）：**
- 保持默认权限设置即可
- 不需要特殊权限配置

**对于高级版工作流：**
1. 进入仓库设置 > Actions > General
2. 确保"Workflow permissions"设置为"Read and write permissions"
3. 确保"Allow GitHub Actions to create and approve pull requests"已启用

> 💡 **推荐使用简化版工作流** `release-simple.yml`，它不需要特殊权限，更稳定可靠。

### 2. 准备发布

#### 更新README.md（可选）
确保README.md包含最新的功能说明和更新日志。

#### 检查module.prop
确保module.prop中的版本信息正确：
```ini
id=multi-cert-installer
name=多证书安装器
version=v1.0
versionCode=1
author=自定义
description=将system/etc/security/cacerts目录中的所有CA证书安装到系统证书存储中。
updateJson=https://example.com/multi-cert-installer.json
```

### 3. 执行发布

#### 使用基础版工作流
```bash
# 创建版本标签
git tag v1.1.0

# 推送标签（自动触发发布）
git push origin v1.1.0
```

#### 使用高级版工作流
```bash
# 创建版本标签
git tag v1.2.0

# 推送标签（自动触发完整发布流程）
git push origin v1.2.0
```

### 4. 验证发布
1. 进入GitHub仓库的Releases页面
2. 检查新创建的Release
3. 确认zip文件和update.json已正确上传
4. 测试下载链接是否正常

## 高级功能

### 自动版本管理
高级版工作流会自动：
- 递增versionCode
- 更新module.prop中的版本信息
- 生成update.json文件
- 提交版本更新到仓库

### update.json格式
```json
{
  "version": "v1.2.0",
  "versionCode": "3",
  "zipUrl": "https://github.com/username/repo/releases/download/v1.2.0/multi-certificate-installer-v1.2.0.zip",
  "changelog": "自动发布版本 v1.2.0",
  "releaseDate": "2024-01-15T10:30:00Z"
}
```

### 手动触发参数
- **version**: 发布版本号（如v1.1.0）
- **bump_type**: 版本递增类型（patch/minor/major）

## 故障排除

### 常见问题

#### 1. 工作流执行失败
**检查项：**
- GitHub Actions是否已启用
- 仓库权限是否正确配置
- 工作流文件语法是否正确

**解决方案：**
```bash
# 检查工作流语法
github action workflows

# 查看执行日志
# 进入GitHub仓库Actions页面查看详细日志
```

#### 2. 权限错误
**错误信息：**
```
Permission to [repository].git denied to github-actions[bot]
fatal: unable to access 'https://github.com/[repository]/': The requested URL returned error: 403
```

**原因分析：**
- GitHub Actions默认没有写入权限
- 高级版工作流尝试推送更改到仓库

**解决方案：**

**方案一：使用简化版工作流（推荐）**
1. 切换到 `release-simple.yml` 工作流
2. 手动更新module.prop版本信息
3. 使用setup-automation.ps1脚本自动更新

**方案二：配置写入权限**
1. 进入仓库设置 > Actions > General
2. 设置"Workflow permissions"为"Read and write permissions"
3. 确保"Allow GitHub Actions to create and approve pull requests"已启用
4. 重新运行工作流

**方案三：手动流程**
1. 运行setup-automation.ps1脚本更新版本
2. 手动推送更改到仓库
3. 创建标签触发发布

#### 3. 标签推送失败
**解决方案：**
```bash
# 确保本地标签已创建
git tag -l

# 强制推送标签（如需要）
git push origin v1.1.0 --force
```

### 调试技巧

#### 本地测试工作流
```bash
# 安装GitHub CLI（如果未安装）
# 下载地址：https://cli.github.com/

# 本地测试工作流
gh workflow list
gh workflow run release-advanced.yml -f version=v1.1.0
```

#### 查看工作流状态
```bash
# 查看所有工作流
gh workflow list

# 查看特定工作流运行状态
gh run list --workflow=release-advanced.yml

# 查看运行日志
gh run view <run-id> --log
```

## 最佳实践

### 版本号规范
- 使用语义化版本号：v主版本号.次版本号.修订号
- 例如：v1.0.0, v1.0.1, v1.1.0, v2.0.0

### 发布前检查清单
- [ ] README.md已更新
- [ ] module.prop版本信息正确
- [ ] 所有功能测试通过
- [ ] 证书目录结构正确
- [ ] 工作流文件语法正确
- [ ] 选择合适的工作流（推荐使用简化版）
- [ ] 权限配置正确（如使用高级版）

### 发布后验证
- [ ] Release创建成功
- [ ] zip文件可正常下载
- [ ] update.json生成正确
- [ ] 下载链接有效
- [ ] 版本号正确递增
- [ ] 检查工作流执行日志无错误

## 联系支持
如果遇到问题，请：
1. 检查GitHub Actions执行日志
2. 查看本指南的故障排除部分
3. 在仓库Issues中创建问题报告