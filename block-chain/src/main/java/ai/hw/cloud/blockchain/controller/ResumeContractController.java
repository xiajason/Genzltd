package ai.hw.cloud.blockchain.controller;

import ai.hw.cloud.api.resume.model.category.ResumeModel;
import ai.hw.cloud.blockchain.service.ResumeContractService;
import ai.hw.cloud.common.core.response.R;
import ai.hw.cloud.common.log.Log;
import io.swagger.annotations.Api;
import io.swagger.annotations.ApiOperation;
import org.springframework.web.bind.annotation.*;

import javax.annotation.Resource;

/**
 * @author wuzhiyong (wzy@rsvptech.cn)
 * @since 2023/4/21
 */
@Api(value = "/contract/resume", tags = "区块链简历接口")
@RestController
@RequestMapping("/contract/resume")
@CrossOrigin
public class ResumeContractController {

  @Resource private ResumeContractService resumeContractService;

  @Log("查询用户的简历")
  @ApiOperation("查询用户的简历")
  @GetMapping
  public R<ResumeModel> queryUserResume(String resumeId) {
    return R.ok(resumeContractService.queryResume(resumeId));
  }

  @Log(value = "创建用户简历", response = true)
  @ApiOperation("创建用户简历")
  @PostMapping
  public R<String> createUserResume(@RequestParam("resumeId") String resumeId, @RequestBody ResumeModel resumeModel) {
    return R.ok(resumeContractService.insertResume(resumeId, resumeModel));
  }

  @Log("删除用户简历")
  @ApiOperation("删除用户简历")
  @DeleteMapping
  public R<String> deleteUserResume(String resumeId) {
    return R.ok(resumeContractService.deleteResume(resumeId));
  }
}
