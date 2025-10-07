package ai.hw.cloud.blockchain.service;

import ai.hw.cloud.api.blockchain.model.PointsTransactionHistory;
import ai.hw.cloud.api.blockchain.model.PointsTxSaveResp;

/**
 * @author wuzhiyong (wzy@rsvptech.cn)
 * @since 2023/5/11
 */
public interface PointTransactionService {

  /**
   * 保存积分交易记录到区块链
   *
   * @param tx
   * @return
   */
  PointsTxSaveResp saveTxRecord(PointsTransactionHistory tx);

  /**
   * 查询区块链积分交易记录
   *
   * @param transactionHistoryId
   * @return
   */
  PointsTransactionHistory queryTxRecord(String transactionHistoryId);
}
