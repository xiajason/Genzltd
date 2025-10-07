package ai.hw.cloud.blockchain.controller;

import ai.hw.cloud.blockchain.service.BlockChainTxService;
import ai.hw.cloud.common.core.response.R;
import ai.hw.cloud.common.log.Log;
import io.swagger.annotations.Api;
import io.swagger.annotations.ApiOperation;
import org.springframework.web.bind.annotation.CrossOrigin;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import javax.annotation.Resource;

/**
 * @author wuzhiyong (wzy@rsvptech.cn)
 * @since 2023/5/9
 */
@RestController
@RequestMapping("/blockchain/tx")
@CrossOrigin
@Api(value = "/blockchain/tx", tags = "区块链交易接口")
public class BlockChainTxController {

  @Resource private BlockChainTxService blockChainTxService;

  @Log("查询交易状态")
  @ApiOperation("查询交易状态")
  @GetMapping
  public R<String> queryTxStatus(String txId) {
    return R.ok(blockChainTxService.queryTxResult(txId));
  }
}
