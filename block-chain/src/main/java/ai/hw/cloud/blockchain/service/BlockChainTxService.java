package ai.hw.cloud.blockchain.service;

import com.huawei.wienerchain.proto.common.BlockOuterClass;

/**
 * @author wuzhiyong (wzy@rsvptech.cn)
 * @since 2023/5/9
 */
public interface BlockChainTxService {

  /**
   * 查询交易状态
   *
   * @param txId
   * @return
   */
  String queryTxResult(String txId);

  BlockOuterClass.Block queryBlock(String txId);
}
