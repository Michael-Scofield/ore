#!/bin/bash

# 默认值
THREADS=4
FEE=50

# 解析命令行参数
for i in "$@"
do
case $i in
    --id=*)
    IDJSON="${i#*=}"
    shift # past argument=value
    ;;
    --threads=*)
    THREADS="${i#*=}"
    shift # past argument with value
    ;;
    --fee=*)
    FEE="${i#*=}"
    shift # past argument with value
    ;;
    *)
    # unknown option
    ;;
esac
done

# 检查是否提供了IDJSON
if [ -z "$IDJSON" ]; then
    echo "ID not provided. Use --id=[your_id] to specify the ID."
    exit 1
fi

# 检查操作系统并选择安装方式
OS_INFO=$(uname -a)
if [[ $OS_INFO == *"opencloudos"* ]]; then
    INSTALL_CMD="yum install -y"
else
    INSTALL_CMD="apt update && apt install -y"
fi

# 安装 Rust 和 Solana
echo "Installing Rust and Solana..."
curl https://sh.rustup.rs -sSf | sh -s -- -y
source $HOME/.cargo/env
$INSTALL_CMD cargo
sh -c "$(curl -sSfL https://release.solana.com/v1.18.4/install)"

# 安装 ore-cli
echo "Installing ore-cli..."
cargo install ore-cli

# 更新 PATH 并使其立即生效
export PATH="/root/.local/share/solana/install/active_release/bin:$PATH"
export PATH="$HOME/.local/share/solana/install/active_release/bin:$PATH"
export PATH="$HOME/.cargo/bin:$PATH"
source ~/.bashrc

# 创建密钥文件
echo "Creating keypair file..."
mkdir -p ~/.config/solana
echo "$IDJSON" > ~/.config/solana/id.json
# 生效
solana config set --keypair /root/.config/solana/id.json
# 执行 ore 命令
echo "Executing ore command..."
nohup ore --rpc https://rpc.shyft.to?api_key=Tm7pl8NWxWWyLzOB --keypair ~/.config/solana/id.json --priority-fee $FEE mine --threads $THREADS > ore_output.log 2>&1 &
