package ai.hw.cloud.blockchain.model;

import lombok.Data;

/**
 * @author wuzhiyong (wzy@rsvptech.cn)
 * @since 2023/5/11
 */
@Data
public class BlockChainSendResp {
  /**
   * 交易id
   */
  private String txId;
  /**
   * 交易状态
   */
  private String status;
}
