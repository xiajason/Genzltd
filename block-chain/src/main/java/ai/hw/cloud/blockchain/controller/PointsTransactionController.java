package ai.hw.cloud.blockchain.controller;

import ai.hw.cloud.api.blockchain.model.PointsTransactionHistory;
import ai.hw.cloud.api.blockchain.model.PointsTxSaveResp;
import ai.hw.cloud.blockchain.service.PointTransactionService;
import ai.hw.cloud.common.core.response.R;
import ai.hw.cloud.common.log.Log;
import io.swagger.annotations.Api;
import io.swagger.annotations.ApiOperation;
import org.springframework.web.bind.annotation.CrossOrigin;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import javax.annotation.Resource;

/**
 * @author wuzhiyong (wzy@rsvptech.cn)
 * @since 2023/5/11
 */

@RestController
@RequestMapping("/contract/point/tx")
@CrossOrigin
@Api(value = "/contract/point/tx", tags = "区块链积分交易记录接口")
public class PointsTransactionController {
  @Resource private PointTransactionService pointTransactionService;

  @GetMapping
  @Log("查询积分交易记录")
  @ApiOperation("查询积分交易记录")
  public R<PointsTransactionHistory> queryTxRecord(@RequestParam("transactionHistoryId") String transactionHistoryId) {
    return R.ok(pointTransactionService.queryTxRecord(transactionHistoryId));
  }

  @PostMapping
  @Log("写入积分交易记录")
  @ApiOperation("写入积分交易记录")
  public R<PointsTxSaveResp> saveTxRecord(@RequestBody PointsTransactionHistory txHistory) {
    return R.ok(pointTransactionService.saveTxRecord(txHistory));
  }
}
