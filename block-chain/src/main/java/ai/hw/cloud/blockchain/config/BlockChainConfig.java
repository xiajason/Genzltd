package ai.hw.cloud.blockchain.config;

import com.huawei.wienerchain.SdkClient;
import com.huawei.wienerchain.exception.ConfigException;
import com.huawei.wienerchain.exception.CryptoException;
import lombok.Data;
import lombok.extern.slf4j.Slf4j;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.context.annotation.Bean;
import org.springframework.stereotype.Component;

import java.io.IOException;

/**
 * @author wuzhiyong (wzy@rsvptech.cn)
 * @since 2023/4/21
 */
@Slf4j
@Component
@ConfigurationProperties("hw.blockchain")
@Data
public class BlockChainConfig {
  // yaml格式配置文件的绝对路径，需要您手动输入
  private String configFilePath;

  // 合约名称，需要您手动输入
  private String contractName;

  // 共识节点，需要您手动输入
  private String consensusNode;

  // 背书节点，需要您手动输入。如果是多个节点，请用“,”隔开
  private String endorserNodes;

  // 查询数据所使用的节点，需要您手动输入
  private String queryNode;

  // 链名称，默认使用 default，不需要更改
  private String chainID;

  @Bean
  public SdkClient sdkClient() throws ConfigException, IOException, CryptoException {
    log.debug("init sdk client");
    SdkClient sdkClient = new SdkClient(configFilePath);
    log.debug("init sdk client success");
    return sdkClient;
  }
}
