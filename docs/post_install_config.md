
markdown

```
# 安装后配置指南
 
## 1. 基础配置
首次进入 WSL 后，设置 root 密码：
​```bash
sudo passwd root
```

## 2. 网络配置

如果需要使用代理，在 WSL 中执行：

bash

```
export ALL_PROXY="http://<代理地址>:<端口>"
```

## 3. 性能优化

在 Windows 用户目录下创建 `.wslconfig` 文件，示例配置：

ini

```
[wsl2]
memory=4GB
processors=2
localhostForwarding=true
nestedVirtualization=true
[experimental]
autoMemoryReclaim=true
sparseVhd=true
```

修改后执行 `wsl --shutdown` 生效。

## 4. 终端优化

推荐安装 Windows Terminal 获得更好的命令行体验。



```
---
 
### <a id="docsresourcesmd"></a> 12. `docs/resources.md`
​```markdown
# 参考资源与命令速查表
 
## 官方文档
- [Microsoft 官方 WSL 文档](https://learn.microsoft.com/zh-cn/windows/wsl/)
- [Ubuntu for WSL 官方镜像](https://ubuntu.com/wsl)
 
## 常用命令速查表
| 命令 | 功能 |
|------|------|
| `wsl --status` | 查看 WSL 状态 |
| `wsl --list --verbose` | 列出已安装分发版本信息 |
| `wsl --export <分发名> <文件名.tar>` | 备份分发系统 |
| `wsl --import <分发名> <安装路径> <备份文件.tar>` | 恢复分发系统 |
| `wsl --shutdown` | 关闭所有 WSL 实例 |
| `wsl --unregister <分发名>` | 删除指定分发系统 |
| `wsl --update` | 更新 WSL 内核版本 |
```