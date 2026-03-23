# -*- coding: utf-8 -*-
"""修复 TJA 解析器 - 移除 FileAccess.file_exists() 检查"""

import re

file_path = r'C:\Users\15013\Projects\AgentWorkspace\projects\TaikoLine\src\parser\tja_parser.gd'

with open(file_path, 'r', encoding='utf-8') as f:
    lines = f.readlines()

# 查找并删除相关行
new_lines = []
skip_until_open = False
i = 0
while i < len(lines):
    line = lines[i]
    
    # 查找 "# 检查文件是否存在"
    if '# 检查文件是否存在' in line:
        # 跳过接下来的 4 行（if 语句和 return）
        i += 1  # 跳过 if not FileAccess.file_exists
        i += 1  # 跳过 result.success = false
        i += 1  # 跳过 result.error = ...
        i += 1  # 跳过 return result
        i += 1  # 跳过空行
        # 替换下一行的注释
        if i < len(lines) and '# 直接尝试打开文件' in lines[i]:
            new_lines.append('\t# 直接尝试打开文件（避免 FileAccess.file_exists() 对 res:// 路径下非导入文件的误判）\n')
            new_lines.append('\t# 使用 FileAccess.open() 直接打开文件，更可靠\n')
            i += 1
        continue
    
    new_lines.append(line)
    i += 1

with open(file_path, 'w', encoding='utf-8') as f:
    f.writelines(new_lines)

print("修改成功！")

# 验证修改
with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()
    if 'FileAccess.file_exists' in content:
        print("警告：文件中仍然存在 FileAccess.file_exists")
    else:
        print("验证通过：FileAccess.file_exists 已移除")
