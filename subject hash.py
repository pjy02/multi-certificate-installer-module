from cryptography import x509
from cryptography.hazmat.backends import default_backend
import hashlib
import binascii

def get_subject_hash_old(cert_pem: str) -> str:
    # 加载证书
    cert = x509.load_pem_x509_certificate(cert_pem.encode(), default_backend())
    
    # 提取 subject 的 DER 编码
    subject_der = cert.subject.public_bytes()
    
    # 计算 MD5
    md5_digest = hashlib.md5(subject_der).digest()
    
    # 取前4字节（小端序）
    hash_int = int.from_bytes(md5_digest[:4], byteorder="little")
    
    # 转成8位十六进制
    return f"{hash_int:08x}"

# 测试
cert_pem = """证书放这"""

print(get_subject_hash_old(cert_pem))
