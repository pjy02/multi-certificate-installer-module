#!/system/bin/sh

exec > /data/local/tmp/multi-cert-installer.log
exec 2>&1

set -x

moddir=${0%/*}

certs_dir="${moddir}/system/etc/security/cacerts"

# 检查证书目录是否存在
if [ ! -d "$certs_dir" ]; then
    echo "certificate directory not found: $certs_dir"
    exit 1
fi

# 检查是否有证书文件
cert_count=$(find "$certs_dir" -name "*.0" -type f | wc -l)
if [ "$cert_count" -eq 0 ]; then
    echo "no certificate files found in $certs_dir"
    exit 1
fi

echo "found $cert_count certificate(s) to install"

set_context() {
    [ "$(getenforce)" = "enforcing" ] || return 0

    default_selinux_context=u:object_r:system_file:s0
    selinux_context=$(ls -zd $1 | awk '{print $1}')

    if [ -n "$selinux_context" ] && [ "$selinux_context" != "?" ]; then
        chcon -r $selinux_context $2
    else
        chcon -r $default_selinux_context $2
    fi
}

# 设置模块证书目录的权限和上下文
chown -r 0:0 "$certs_dir"
set_context /system/etc/security/cacerts "$certs_dir"

# android 14支持 - 处理apex证书存储
if [ -d /apex/com.android.conscrypt/cacerts ]; then
    echo "processing android 14 apex certificate store"
    
    # 创建临时目录
    rm -rf /data/local/tmp/sys-ca-copy
    mkdir -p /data/local/tmp/sys-ca-copy
    mount -t tmpfs tmpfs /data/local/tmp/sys-ca-copy
    
    # 复制系统现有证书
    if [ -d /apex/com.android.conscrypt/cacerts ] && [ "$(ls -a /apex/com.android.conscrypt/cacerts 2>/dev/null)" ]; then
        cp -f /apex/com.android.conscrypt/cacerts/* /data/local/tmp/sys-ca-copy/
        echo "copied existing system certificates"
    fi
    
    # 复制模块中的所有证书
    cp -f "$certs_dir"/* /data/local/tmp/sys-ca-copy/
    echo "copied $cert_count module certificate(s)"
    
    # 设置权限和上下文
    chown -r 0:0 /data/local/tmp/sys-ca-copy
    set_context /apex/com.android.conscrypt/cacerts /data/local/tmp/sys-ca-copy
    
    # 验证证书总数
    total_certs=$(ls -1 /data/local/tmp/sys-ca-copy/*.0 2>/dev/null | wc -l)
    echo "total certificates after merge: $total_certs"
    
    # 挂载目录（只有证书数量合理时才执行）
    if [ "$total_certs" -gt 5 ]; then
        echo "mounting certificate store to apex"
        mount --bind /data/local/tmp/sys-ca-copy /apex/com.android.conscrypt/cacerts
        
        # 为所有zygote进程执行挂载
        for pid in 1 $(pgrep zygote) $(pgrep zygote64); do
            if [ -e "/proc/${pid}/ns/mnt" ]; then
                nsenter --mount=/proc/${pid}/ns/mnt -- \
                    mount --bind /data/local/tmp/sys-ca-copy /apex/com.android.conscrypt/cacerts
                echo "mounted for process $pid"
            fi
        done
        
        echo "successfully mounted certificates for android 14"
    else
        echo "cancelling certificate store replacement due to safety (too few certificates)"
    fi
    
    # 清理临时目录
    umount /data/local/tmp/sys-ca-copy 2>/dev/null
    rm -rf /data/local/tmp/sys-ca-copy
else
    echo "android 14 apex not found, using traditional method"
    
    # 传统android版本的证书处理
    # 证书文件会通过magisk的模块机制自动挂载到/system/etc/security/cacerts
    echo "certificates will be installed via magisk module system"
fi

echo "multi-certificate installation completed successfully"