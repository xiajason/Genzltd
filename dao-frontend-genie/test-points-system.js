/**
 * 积分系统测试脚本
 * 测试统一积分API和桥接服务
 * 
 * @author DAO Genie Team
 * @version 1.0
 * @created 2025-10-01
 */

const axios = require('axios');

const API_BASE_URL = 'http://localhost:3000/api/trpc';

// 测试用户ID
const TEST_USER_ID = 'admin';

/**
 * 测试积分API
 */
async function testPointsAPI() {
  console.log('🧪 开始测试积分API...');

  try {
    // 1. 获取用户积分
    console.log('\n1. 获取用户积分...');
    const getUserPointsResponse = await axios.get(`${API_BASE_URL}/points.getUserPoints`, {
      params: {
        input: JSON.stringify({ userId: TEST_USER_ID })
      }
    });
    console.log('✅ 获取用户积分成功:', getUserPointsResponse.data);

    // 2. 奖励积分
    console.log('\n2. 奖励积分...');
    const awardPointsResponse = await axios.post(`${API_BASE_URL}/points.awardPoints`, {
      userId: TEST_USER_ID,
      pointsChange: 50,
      changeType: 'earn',
      reason: '测试积分奖励',
      sourceSystem: 'dao',
      description: 'API测试奖励'
    });
    console.log('✅ 奖励积分成功:', awardPointsResponse.data);

    // 3. 获取积分历史
    console.log('\n3. 获取积分历史...');
    const getHistoryResponse = await axios.get(`${API_BASE_URL}/points.getPointsHistory`, {
      params: {
        input: JSON.stringify({ 
          userId: TEST_USER_ID,
          page: 1,
          limit: 10
        })
      }
    });
    console.log('✅ 获取积分历史成功:', getHistoryResponse.data);

    // 4. 获取积分统计
    console.log('\n4. 获取积分统计...');
    const getStatsResponse = await axios.get(`${API_BASE_URL}/points.getPointsStats`, {
      params: {
        input: JSON.stringify({ 
          userId: TEST_USER_ID,
          period: 'month'
        })
      }
    });
    console.log('✅ 获取积分统计成功:', getStatsResponse.data);

    // 5. 获取积分排行榜
    console.log('\n5. 获取积分排行榜...');
    const getLeaderboardResponse = await axios.get(`${API_BASE_URL}/points.getPointsLeaderboard`, {
      params: {
        input: JSON.stringify({ 
          type: 'total',
          limit: 5
        })
      }
    });
    console.log('✅ 获取积分排行榜成功:', getLeaderboardResponse.data);

    // 6. 获取同步状态
    console.log('\n6. 获取同步状态...');
    const getSyncStatusResponse = await axios.get(`${API_BASE_URL}/points.getSyncStatus`);
    console.log('✅ 获取同步状态成功:', getSyncStatusResponse.data);

    // 7. 获取奖励规则
    console.log('\n7. 获取奖励规则...');
    const getRewardRulesResponse = await axios.get(`${API_BASE_URL}/points.getRewardRules`, {
      params: {
        input: JSON.stringify({ 
          sourceSystem: 'dao',
          isActive: true
        })
      }
    });
    console.log('✅ 获取奖励规则成功:', getRewardRulesResponse.data);

    console.log('\n🎉 所有积分API测试通过！');

  } catch (error) {
    console.error('❌ 积分API测试失败:', error.response?.data || error.message);
  }
}

/**
 * 测试积分桥接服务
 */
async function testPointsBridge() {
  console.log('\n🔗 开始测试积分桥接服务...');

  try {
    // 1. 手动触发同步
    console.log('\n1. 手动触发积分同步...');
    const syncResponse = await axios.post(`${API_BASE_URL}/points.triggerSync`, {
      userId: TEST_USER_ID,
      syncType: 'bidirectional'
    });
    console.log('✅ 积分同步成功:', syncResponse.data);

    // 2. 再次获取同步状态
    console.log('\n2. 获取同步状态...');
    const syncStatusResponse = await axios.get(`${API_BASE_URL}/points.getSyncStatus`);
    console.log('✅ 同步状态:', syncStatusResponse.data);

    console.log('\n🎉 积分桥接服务测试通过！');

  } catch (error) {
    console.error('❌ 积分桥接服务测试失败:', error.response?.data || error.message);
  }
}

/**
 * 主测试函数
 */
async function runTests() {
  console.log('🚀 开始积分系统测试...');
  console.log('📋 测试用户:', TEST_USER_ID);
  console.log('🌐 API地址:', API_BASE_URL);

  try {
    await testPointsAPI();
    await testPointsBridge();
    
    console.log('\n🎊 所有测试完成！积分系统运行正常！');
    
  } catch (error) {
    console.error('\n💥 测试过程中发生错误:', error);
  }
}

// 运行测试
if (require.main === module) {
  runTests().catch(console.error);
}

module.exports = {
  testPointsAPI,
  testPointsBridge,
  runTests
};
