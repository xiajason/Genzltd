package ai.hw.cloud.blockchain.component;

import ai.hw.cloud.blockchain.config.BlockChainConfig;
import com.huawei.wienerchain.SdkClient;
import com.huawei.wienerchain.exception.SdkException;
import com.huawei.wienerchain.proto.common.Message.RawMessage;
import com.huawei.wienerchain.proto.common.TransactionOuterClass.BlockResult;
import com.huawei.wienerchain.proto.common.TransactionOuterClass.TxResult;
import lombok.extern.slf4j.Slf4j;
import org.bouncycastle.util.encoders.Hex;
import org.springframework.stereotype.Component;

import java.io.IOException;
import java.security.cert.CertificateException;
import java.util.Iterator;
import java.util.concurrent.Executors;
import javax.annotation.PostConstruct;
import javax.annotation.Resource;

/**
 * @author wuzhiyong (wzy@rsvptech.cn)
 * @since 2023/4/21
 */
@Slf4j
@Component
public class BlockChainListener {

  @Resource private SdkClient sdkClient;
  @Resource BlockChainConfig config;

  @PostConstruct
  public void init() {
    Executors.newSingleThreadExecutor().execute(() -> {
      try {
        queryHash();
      } catch (IOException | CertificateException | SdkException e) {
        throw new RuntimeException(e);
      }
    });
  }

  private void queryHash() throws IOException, SdkException, CertificateException {
    Iterator<RawMessage> iterator =
            sdkClient.getWienerChainNode(config.getQueryNode()).getEventAction().listen(config.getChainID());
    while (iterator.hasNext()) {
      RawMessage rawMessage = iterator.next();
      BlockResult blockResult = BlockResult.parseFrom(rawMessage.getPayload());
      for (TxResult tx : blockResult.getTxResultsList()) {
        // 交易ID，即交易哈希
        String txId = Hex.toHexString(tx.getTxHash().toByteArray());
        // 交易结果
        String statusStr = tx.getStatus().toString();  // 只有 VALID 代表交易成功
        log.debug("交易哈希： " + txId + ", 执行结果: " + statusStr);
      }
    }
  }
}
