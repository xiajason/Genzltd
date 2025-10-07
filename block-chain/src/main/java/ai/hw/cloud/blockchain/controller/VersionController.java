package ai.hw.cloud.blockchain.controller;

import ai.hw.cloud.common.core.response.R;
import io.swagger.annotations.Api;
import io.swagger.annotations.ApiOperation;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.web.bind.annotation.CrossOrigin;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/**
 * @author GaoYudong (gyd@rsvptech.cn)
 * @date 2023/03/03
 */
@Api(value = "/version", tags = { "服务版本接口" })
@RestController
@RequestMapping("/version")
public class VersionController {

  @Value("${service.version}") private String version;

  @CrossOrigin
  @ApiOperation("当前服务版本号")
  @GetMapping("/")
  public R<String> version() {
    return R.ok(version);

  }
}
