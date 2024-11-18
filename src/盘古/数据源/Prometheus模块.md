# Prometheus模块

> #### 如何使用

```
业务模块引入
```

**xml**

```
<dependency>
  <groupId>com.kingtsoft.pangu</groupId>
  <artifactId>pangu-data-prometheus</artifactId>
</dependency>
```

```
配置文件
```

**yaml**

```
pangu:
prometheus:
url: 'http://10.1.50.65:9090'
```

```
    注入PrometheusClient，根据需求执行对应的内容即可, 入参都为统一的uri，
因为prometheus查询的构造，数据都在地址拼接，所有有统一的构造语句，又为了uri
配置的灵活性，所有都在外部配置。具体方法与prometheus语法的使用一致。篇幅缘故，
这里不作一一介绍。
```

**java**

```
public class  ServerService {

private final   PrometheusClient prometheusClient;

publicServerService(PrometheusClient prometheusClient,
                         PrometheusProperties prometheusProperties) {
this.targetServer = prometheusProperties.getUrl();
this.prometheusClient = prometheusClient;
    }

public List<MatrixData> getPrometheusMatrixData(String query, long startTime, long endTime, long stepTime) {
        RangeQueryBuilder rangeQueryBuilder =  QueryBuilderType.RangeQuery.newInstance(targetServer);
        URI targetUri = rangeQueryBuilder.withQuery(query)
                .withStartEpochTime(startTime)
                .withEndEpochTime(endTime)
                .withStepTime(stepTime +"s")
                .build();

return prometheusClient.queryRange(targetUri);
    }
}
```

> #### 技术原理

```
    首先prometheus的数据是通过http请求的，所以定义了统一的FeignClient，如下。
但是因为pro的查询，不同的查询返回结构体差别会比较大，每个结构体都会定位ConvertUtil
一个解析方法（解析过程是一个开源工具项目），根据这些解析方法，构造了不同的feign结果
解析器。然后配置到了下面的feign客户端。这样调用的代码块就可以无感知获取到解析后的数据。
```

**java**

```
package com.kingtsoft.pangu.data.prometheus.feign;

/**
 * Title: <br>
 * Description: <br>
 * Company: KingTang <br>
 *
 * @author 金炀
 * @version 1.0
 */
@PgFeignClient(clientCode= HttpConst.CLIENT_CODE_PROMETHEUS, url="${pangu.prometheus.url}")
public interface  PrometheusClient {

    /**
     * /api/v1/query
     *
     * @paramuri 请求数据
     * @return 度量数据
     * @author 金炀
     */
    @FeignResultClient(value= PrometheusQueryAllResultChecker.class, postfix="/api/v1/query")
    @RequestMapping(value="", method= RequestMethod.GET)
    List<?> query(URI uri);

    /**
     * /api/v1/query_range
     *
     * @paramuri 请求数据
     * @return 度量数据
     * @author 金炀
     */
    @FeignResultClient(value= PrometheusQueryResultChecker.class, postfix="/api/v1/query_range")
    @RequestMapping("")
    List<MatrixData> queryRange(URI uri);

    /**
     * /api/v1/series
     *
     * @paramuri 请求数据
     * @return 度量数据
     * @author 金炀
     */
    @FeignResultClient(value= PrometheusSeriesResultChecker.class, postfix="/api/v1/series")
    @RequestMapping("")
    List<SeriesResultItem> series(URI uri);

    /**
     * /api/v1/label/{labelName}/values
     *
     * @paramuri 请求数据
     * @return 度量数据
     * @author 金炀
     */
    @FeignResultClient(value= PrometheusLabelResultChecker.class, postfix="/api/v1/label")
    @RequestMapping("")
    List<String> labels(URI uri);

    /**
     * /api/v1/targets
     *
     * @paramuri 请求数据
     * @return 度量数据
     * @author 金炀
     */
    @FeignResultClient(value= PrometheusTargetResultChecker.class, postfix="/api/v1/targets")
    @RequestMapping("")
    List<TargetResultItem> targets(URI uri);

    /**
     * /api/v1/rules
     *
     * @paramuri 请求数据
     * @return 度量数据
     * @author 金炀
     */
    @FeignResultClient(value= PrometheusQueryResultChecker.class, postfix="/api/v1/rules")
    @RequestMapping("")
    String rules(URI uri);

    /**
     * /api/v1/alerts
     *
     * @paramuri 请求数据
     * @return 度量数据
     * @author 金炀
     */
    @FeignResultClient(value= PrometheusQueryResultChecker.class, postfix="/api/v1/alerts")
    @RequestMapping("")
    String alerts(URI uri);

    /**
     * /api/v1/targets/metadata
     *
     * @paramuri 请求数据
     * @return 度量数据
     * @author 金炀
     */
    @FeignResultClient(value= PrometheusTargetResultChecker.class, postfix="/api/v1/targets/metadata")
    @RequestMapping("")
    List<TargetResultItem> metadata(URI uri);

    /**
     * /api/v1/alertmanagers
     *
     * @paramuri 请求数据
     * @return 度量数据
     * @author 金炀
     */
    @FeignResultClient(value= PrometheusAlertManagerResultChecker.class, postfix="/api/v1/alertmanagers")
    @RequestMapping("")
    List<AlertManagerResultItem> alertmanagers(URI uri);

    /**
     * /api/v1/status/config
     *
     * @paramuri 请求数据
     * @return 度量数据
     * @author 金炀
     */
    @FeignResultClient(value= PrometheusQueryResultChecker.class, postfix="/api/v1/status/config")
    @RequestMapping("")
    String statusConfig(URI uri);

    /**
     * /api/v1/status/flags
     *
     * @paramuri 请求数据
     * @return 度量数据
     * @author 金炀
     */
    @FeignResultClient(value= PrometheusQueryResultChecker.class, postfix="/api/v1/status/flags")
    @RequestMapping("")
    String statusFlags(URI uri);

    /**
     * /api/v1/status/runtimeinfo
     *
     * @paramuri 请求数据
     * @return 度量数据
     * @author 金炀
     */
    @FeignResultClient(value= PrometheusQueryResultChecker.class, postfix="/api/v1/status/runtimeinfo")
    @RequestMapping("")
    String statusRuntimeinfo(URI uri);

}
```

```
如下为其中一个解析器
```

**java**

```
package com.kingtsoft.pangu.data.prometheus.feign.converter;

import com.kingtosft.pangu.base.inner.common.enums.PanguResCodeEnum;
import com.kingtsoft.pangu.base.exception.TipException;
import com.kingtsoft.pangu.data.prometheus.client.converter.ConvertUtil;
import com.kingtsoft.pangu.data.prometheus.client.converter.label.DefaultLabelResult;
import com.kingtsoft.pangu.data.prometheus.utils.PrometheusUtil;
import com.kingtsoft.pangu.springcloud.feign.FeignResponseChecker;

/**
* Title: <br>
* Description: <br>
* Company: KingTang <br>
*
* @author 金炀
* @version 1.0
*/
public class  PrometheusLabelResultCheckerimplementsFeignResponseChecker {

    @Override
public Object cover(Object param) {
try {
            PrometheusUtil.checkResult(param.toString());
            DefaultLabelResult result = ConvertUtil.convertLabelResultString(param.toString());

return result.getResult();
        } catch (Exception e) {
            e.printStackTrace();
thrownewTipException(PanguResCodeEnum.FEIGN_COVER_FAIL);
        }
    }
}
```

```
feign客户端方法注释上写明了接口对应的prometheus api，例如/api/v1/query_range
查询的用途可参考文章
```

[https://blog.51cto.com/u_15474913/5411753](https://blog.51cto.com/u_15474913/5411753)
