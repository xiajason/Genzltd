#!/bin/bash

# 构建微信小程序脚本
# 用于生成微信开发者工具可导入的项目文件

echo "🚀 开始构建微信小程序版本..."

# 进入前端目录
cd /Users/szjason72/zervi-basic/basic/frontend-taro

# 检查是否已安装依赖
if [ ! -d "node_modules" ]; then
    echo "📦 安装依赖..."
    npm install
fi

# 构建微信小程序版本
echo "🔨 构建微信小程序..."
npm run build:weapp

# 检查构建结果
if [ -d "dist" ]; then
    echo "✅ 构建成功！"
    
           # 复制sitemap.json文件
       if [ -f "src/sitemap.json" ]; then
           cp src/sitemap.json dist/
           echo "📄 已复制sitemap.json文件"
       fi

       # 创建project.miniapp.json文件
       echo "📄 创建project.miniapp.json文件..."
       cat > dist/project.miniapp.json << 'EOF'
{
  "miniprogramRoot": "./",
  "projectname": "jobfirst-unified",
  "description": "JobFirst统一前端项目",
  "appid": "wx4d4cc8bf367e7c2b",
  "setting": {
    "urlCheck": false,
    "es6": true,
    "enhance": true,
    "postcss": true,
    "preloadBackgroundData": false,
    "minified": false,
    "newFeature": false,
    "coverView": true,
    "nodeModules": false,
    "autoAudits": false,
    "showShadowRootInWxmlPanel": true,
    "scopeDataCheck": false,
    "uglifyFileName": false,
    "checkInvalidKey": true,
    "checkSiteMap": true,
    "uploadWithSourceMap": true,
    "compileHotReLoad": true,
    "lazyloadPlaceholderEnable": false,
    "useMultiFrameRuntime": true,
    "useApiHook": true,
    "useApiHostProcess": true,
    "babelSetting": {
      "ignore": [],
      "disablePlugins": [],
      "outputPath": ""
    },
    "enableEngineNative": false,
    "useIsolateContext": true,
    "userConfirmedBundleSwitch": false,
    "packNpmManually": false,
    "packNpmRelationList": [],
    "minifyWXSS": true,
    "disableUseStrict": false,
    "minifyWXML": true,
    "showES6CompileOption": false,
    "useCompilerPlugins": false
  },
  "compileType": "miniprogram",
  "libVersion": "2.27.3",
  "condition": {}
}
EOF
       echo "✅ 已创建project.miniapp.json文件"

       # 创建app.miniapp.json文件
       echo "📄 创建app.miniapp.json文件..."
       cat > dist/app.miniapp.json << 'EOF'
{
  "version": "1.0.0",
  "name": "jobfirst-unified",
  "description": "JobFirst统一前端项目",
  "appid": "wx4d4cc8bf367e7c2b",
  "identityService": {
    "enabled": false,
    "config": {}
  },
  "permissions": {
    "userInfo": false,
    "userLocation": false,
    "camera": false,
    "microphone": false
  },
  "debug": true,
  "development": true
}
EOF
       echo "✅ 已创建app.miniapp.json文件"
    
    # 更新项目配置
    echo "🔧 更新项目配置..."
    sed -i '' 's/"urlCheck": true/"urlCheck": false/' dist/project.config.json
    sed -i '' 's/"es6": false/"es6": true/' dist/project.config.json
    sed -i '' 's/"enhance": false/"enhance": true/' dist/project.config.json
    sed -i '' 's/"compileHotReLoad": false/"compileHotReLoad": true/' dist/project.config.json
    sed -i '' 's/"postcss": false/"postcss": true/' dist/project.config.json
    
    echo "📁 构建文件位置: $(pwd)/dist/"
    echo "📱 微信开发者工具导入路径: $(pwd)/dist/"
    echo ""
    echo "🔧 微信开发者工具配置:"
    echo "   - 项目目录: $(pwd)/dist/"
    echo "   - AppID: wx4d4cc8bf367e7c2b"
    echo "   - 已配置权限声明和错误处理"
    echo ""
    echo "📋 构建文件列表:"
    ls -la dist/
    echo ""
    echo "⚠️  注意事项:"
    echo "   - 如果遇到权限错误，请检查微信开发者工具的权限设置"
    echo "   - SharedArrayBuffer警告是正常的，不影响功能"
    echo "   - 建议使用稳定的基础库版本"
else
    echo "❌ 构建失败！"
    exit 1
fi
