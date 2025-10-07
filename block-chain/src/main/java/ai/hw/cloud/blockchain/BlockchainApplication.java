package ai.hw.cloud.blockchain;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.cloud.netflix.eureka.EnableEurekaClient;
import org.springframework.transaction.annotation.EnableTransactionManagement;

/**
 * @author GaoYudong (gyd@rsvptech.cn)
 * @date 2023/03/03
 */
@EnableEurekaClient
@EnableTransactionManagement
@SpringBootApplication
public class BlockchainApplication {

  public static void main(String[] args) {
    SpringApplication.run(BlockchainApplication.class, args);
  }

}
