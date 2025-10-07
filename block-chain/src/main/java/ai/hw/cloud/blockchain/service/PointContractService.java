package ai.hw.cloud.blockchain.service;

import ai.hw.cloud.api.blockchain.model.PointsTransactionHistory;
import ai.hw.cloud.api.blockchain.model.PointsTxSaveResp;

/**
 * @author wuzhiyong (wzy@rsvptech.cn)
 * @since 2023/4/21
 */
@Deprecated
public interface PointContractService {

  /**
   * 更新积分
   *
   * @param userId 用户id
   * @param points 新增的积分数值
   * @return tx id
   */
//  String updateIntegral(String userId, long points);

  /**
   * 查询用户积分
   *
   * @param userId 用户id
   * @return 积分值
   */
  Long queryIntegral(String userId);

  /**
   * 积分转账
   *
   * @param fromUserId 转出用户
   * @param toUserId   转入用户
   * @param points     转账的积分数值
   * @return tx id
   */
  String transferIntegral(String fromUserId, String toUserId, long points);

  /**
   * 设置用户积分
   *
   * @param userId
   * @param points
   * @return
   */
  String setIntegral(String userId, long points);


}
