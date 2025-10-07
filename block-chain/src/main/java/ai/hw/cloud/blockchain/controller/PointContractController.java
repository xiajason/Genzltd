package ai.hw.cloud.blockchain.controller;

import ai.hw.cloud.blockchain.service.PointContractService;
import ai.hw.cloud.common.core.response.R;
import ai.hw.cloud.common.log.Log;
import io.swagger.annotations.Api;
import io.swagger.annotations.ApiOperation;
import io.swagger.annotations.ApiParam;
import org.springframework.web.bind.annotation.*;

import javax.annotation.Resource;

/**
 * @author wuzhiyong (wzy@rsvptech.cn)
 * @since 2023/4/21
 */
@Deprecated
@RestController
@RequestMapping("/contract/point")
@CrossOrigin
@Api(value = "/contract/point", tags = "区块链积分接口")
public class PointContractController {
    @Resource
    private PointContractService pointContractService;


    @PutMapping("/set")
    @Log("设置用户积分")
    @ApiOperation("设置用户积分")
    public R<String> setPoint(String userId, long points) {
        return R.ok(pointContractService.setIntegral(userId, points));
    }

    @GetMapping
    @Log("查询积分")
    @ApiOperation("查询积分")
    public R<Long> queryPoint(@RequestParam("userId") String userId) {
        return R.ok(pointContractService.queryIntegral(userId));
    }

    @PutMapping("/transfer")
    @Log("交易积分")
    @ApiOperation("交易积分")
    public R<String> transferPoint(@ApiParam String fromUserId, String toUserId, long points) {

        return R.ok(pointContractService.transferIntegral(fromUserId, toUserId, points));
    }
}
