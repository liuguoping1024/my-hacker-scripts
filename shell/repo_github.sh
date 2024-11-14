#!/bin/bash

# 遍历当前目录下的所有子目录
for dir in */ ; do
    # 检查是否存在merge_upstream.sh脚本
    if [[ -f "$dir/merge_upstream.sh" ]]; then
        echo "执行 $dir/merge_upstream.sh ..."
        # 进入子目录并执行脚本
        (cd "$dir" && bash merge_upstream.sh)
    else
        echo "$dir 中没有 merge_upstream.sh，跳过。"
    fi
done


