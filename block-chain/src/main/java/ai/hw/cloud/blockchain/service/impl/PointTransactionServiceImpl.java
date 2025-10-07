package ai.hw.cloud.blockchain.service.impl;

import ai.hw.cloud.api.blockchain.model.PointsTransactionHistory;
import ai.hw.cloud.api.blockchain.model.PointsTxSaveResp;
import ai.hw.cloud.blockchain.consts.BlockChainFuncs;
import ai.hw.cloud.blockchain.consts.BlockChainFuncs.TxRecord;
import ai.hw.cloud.blockchain.consts.ContractKeyEnum;
import ai.hw.cloud.blockchain.model.BlockChainSendResp;
import ai.hw.cloud.blockchain.service.ContractService;
import ai.hw.cloud.blockchain.service.PointTransactionService;
import ai.hw.cloud.common.core.constants.ErrorCode;
import ai.hw.cloud.common.exception.RsvpException;
import com.alibaba.fastjson2.JSON;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import javax.annotation.Resource;

/**
 * @author wuzhiyong (wzy@rsvptech.cn)
 * @since 2023/5/11
 */
@Service
@Slf4j
public class PointTransactionServiceImpl implements PointTransactionService {

  @Resource private ContractService contractService;

  @Override
  public PointsTxSaveResp saveTxRecord(PointsTransactionHistory tx) {
    String txHistoryId = tx.getTransactionHistoryId();
    String key = ContractKeyEnum.TxRecord.key(txHistoryId);
    try {
//      BlockChainSendResp resp = contractService.sendSync(BlockChainFuncs.TxRecord.insertTxRecord, new String[] {
//              key, JSON.toJSONString(tx)
//      });
      String txId = contractService.send(TxRecord.insertTxRecord, new String[] {
              key, JSON.toJSONString(tx)
      });

      PointsTxSaveResp pointsTxSaveResp = new PointsTxSaveResp();
//      pointsTxSaveResp.setTxId(resp.getTxId());
      pointsTxSaveResp.setTxId(txId);
//      pointsTxSaveResp.setSuccess("VALID".equals(resp.getStatus()));
      pointsTxSaveResp.setSuccess(true);
      return pointsTxSaveResp;
    } catch (Exception e) {
      log.error("区块链写入失败", e);
      throw new RsvpException(ErrorCode.BLOCKCHAIN_POINT_TX_RECORD_INSERT_ERROR);
    }
  }

  @Override
  public PointsTransactionHistory queryTxRecord(String transactionHistoryId) {
    String key = ContractKeyEnum.TxRecord.key(transactionHistoryId);
    try {
      String result = contractService.query(BlockChainFuncs.TxRecord.queryTxRecord, new String[] { key });
      return JSON.parseObject(result, PointsTransactionHistory.class);
    } catch (Exception e) {
      throw new RsvpException(ErrorCode.BLOCKCHAIN_POINT_TX_RECORD_QUERY_ERROR);
    }
  }
}
