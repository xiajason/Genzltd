#!/bin/bash
# DAO Genie 智能合约部署脚本

echo "=== DAO Genie 智能合约部署 ==="

# 检查Hardhat是否安装
if ! command -v npx hardhat &> /dev/null; then
    echo "❌ Hardhat未安装，请先安装依赖"
    exit 1
fi

# 编译智能合约
echo "🔨 编译智能合约..."
npx hardhat compile

# 启动本地测试网络
echo "🌐 启动本地测试网络..."
npx hardhat node &
HARDHAT_PID=$!

# 等待网络启动
sleep 5

# 部署合约
echo "🚀 部署DAO Genie合约..."
npx hardhat run scripts/deploy.js --network localhost

# 更新环境变量中的合约地址
echo "📝 更新合约地址配置..."
# 这里需要从部署输出中获取合约地址并更新.env.local

echo "✅ 智能合约部署完成！"
echo "💡 请手动更新.env.local中的NEXT_PUBLIC_CONTRACT_ADDRESS"

# 停止测试网络
kill $HARDHAT_PID
