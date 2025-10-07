package ai.hw.cloud.blockchain.service;

import ai.hw.cloud.blockchain.consts.BlockChainFuncs.NamedFunc;
import ai.hw.cloud.blockchain.model.BlockChainSendResp;

/**
 * @author wuzhiyong (wzy@rsvptech.cn)
 * @since 2023/4/21
 */
public interface ContractService {
  // 使用合约进行交易发送。数据修改类的操作使用此方法
  String send(NamedFunc func, String[] args) throws Exception;

  // 同步方式进行交易发送。数据修改类的操作使用此方法
  BlockChainSendResp sendSync(NamedFunc func, String[] args) throws Exception;

  // 使用合约进行交易查询。数据查询类的操作使用此方法
  String query(NamedFunc func, String[] args) throws Exception;
}
