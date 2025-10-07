package ai.hw.cloud.blockchain.service.impl;

import ai.hw.cloud.blockchain.config.BlockChainConfig;
import ai.hw.cloud.blockchain.service.BlockChainTxService;
import ai.hw.cloud.blockchain.utils.BlockUtil;
import ai.hw.cloud.blockchain.utils.TxUtil;
import com.huawei.wienerchain.SdkClient;
import com.huawei.wienerchain.proto.common.BlockOuterClass;
import com.huawei.wienerchain.proto.common.BlockOuterClass.Block;
import org.springframework.stereotype.Service;

import javax.annotation.Resource;

/**
 * @author wuzhiyong (wzy@rsvptech.cn)
 * @since 2023/5/9
 */
@Service
public class BlockChainTxServiceImpl implements BlockChainTxService {

  @Resource private SdkClient sdkClient;
  @Resource private BlockChainConfig blockChainConfig;

  @Override
  public String queryTxResult(String txId) {
    try {
      return TxUtil.queryTxResultByTxID(sdkClient, txId, blockChainConfig.getQueryNode(),
              blockChainConfig.getChainID());
    } catch (Exception e) {
      throw new RuntimeException(e);
    }
  }

  @Override
  public Block queryBlock(String txId) {
    try {
      return BlockUtil.queryBlockByTxID(sdkClient,txId,blockChainConfig.getQueryNode(),blockChainConfig.getChainID());
    } catch (Exception e) {
      throw new RuntimeException(e);
    }

  }
}
