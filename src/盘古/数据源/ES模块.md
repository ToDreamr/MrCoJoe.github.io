# Es模块

> #### 如何使用

```
业务端引入
```

**xml**

```
<dependency>
  <groupId>com.kingtsoft.pangu</groupId>
  <artifactId>pangu-data-es</artifactId>
</dependency>
```

```
    使用伪代码如下, 自带会有个IndexService及DocumentService封装，用于基本的CRUD操作，
而又相对较多定制化的，可以直接使用elasticsearchClient进行调用。
```

**java**

```
public class  ServService {

private final   IndexService indexService;

private final   ElasticsearchClient elasticsearchClient;

private final   DocumentService<NginxMessage> documentService;

publicServService(ElasticsearchClient elasticsearchClient,
                       IndexService indexService,
                      DocumentService<NginxMessage> documentService) {
this.elasticsearchClient = elasticsearchClient;
this.indexService = indexService;
this.documentService = documentService;
    }

	/**
     * 设置对应日期的索引
     *
     * @paramlocalDate 日期
     * @paramindexList 索引列表
     * @author 金炀
     */
private void   setTargetDateIndex(LocalDate localDate, List<String> indexList) {
        String idx = LogMessageUtil.getLogIdx(localDate, OpsLogConst.LogIndex.NGINX_LOG);
boolean   exists = indexService.indexExists(idx);
if (exists) {
            indexList.add(idx);
        }
    }

private void   doNginxLogSave(String msg, String key) {
for (String record : records) {
            NginxMessage nginxMessage =newNginxMessage();
if (!getNginxMessage(nginxMessage, record)) {
continue;
            }
if (idx ==null&& nginxMessage.getRecordTime() !=null) {
                idx = LogMessageUtil.getLogIdx(nginxMessage.getRecordTime().toLocalDate(), prefix);
// 持久层索引
if (!indexService.indexExists(idx)) {
                    indexService.createIndex(idx);
                }
            }
if (idx !=null) {
                IndexResponse response = documentService.saveOrUpdateDocument(idx, key +"-"+ (i++), nginxMessage);
if (log.isDebugEnabled()) {
                    log.debug("es保存完成："+ response.id());
                }
            }
        }
    }

    @SneakyThrows
public ServiceDetailVO getServiceInfo(ServiceRequest serviceRequest) {
        ServiceDetailVO detailVO =newServiceDetailVO();
        List<String> indexList =new ArrayList<>();

        LocalDateTime stdTime = LocalDateTime.now();
setTargetDateIndex(stdTime.toLocalDate(), indexList);

        LocalDateTime startTime = stdTime.plusSeconds(-1*24*60*60);
if (!startTime.toLocalDate().equals(stdTime.toLocalDate())) {
setTargetDateIndex(stdTime.toLocalDate(), indexList);
        }

if (indexList.size() ==0) {
            detailVO.setRps(BigDecimal.ZERO);
            detailVO.setReqAvgConst(BigDecimal.ZERO);
            detailVO.setReqDailyNum(BigDecimal.ZERO);
return detailVO;
        }

        Query moduleTerm = QueryBuilders.term(k -> k.field("module.keyword").value(serviceRequest.getModule()));
        Query ipTerm = QueryBuilders.term(k -> k.field("upstreamAddr.keyword").value(serviceRequest.getIp()));
        Query ipPre = QueryBuilders.prefix(k -> k.field("upstreamAddr.keyword").value(serviceRequest.getIp() +":"));
        Query dtBuilder = PgEsUtil.getDtQuery(startTime, stdTime, "recordTimelong ");
        Query queryBuilder = QueryBuilders.bool(b -> b.must(moduleTerm, dtBuilder).must(s -> s.bool(v -> v.should(ipTerm).should(ipPre))));

// 平均响应时间
        SearchResponse<NginxMessage> searchResponse = elasticsearchClient.search(
                builder -> builder
                        .index(indexList)
                        .query(queryBuilder)
                        .aggregations("avgCost", a -> a.avg(ag -> ag.field("requestCost"))),
                NginxMessage.class
        );
        detailVO.setReqAvgConst(BigDecimal.valueOf(searchResponse.aggregations().get("avgCost").avg().value() *1000).setScale(SCALE, RoundingMode.HALF_UP));
//24 请求总数
        CountResponse countResponse = elasticsearchClient.count(
                builder -> builder.index(indexList).query(queryBuilder)
        );
        detailVO.setReqDailyNum(newBigDecimal(countResponse.count()));
//24 qps
        detailVO.setRps(detailVO.getReqDailyNum().divide(newBigDecimal(24*60*60), SCALE, RoundingMode.HALF_UP));

return detailVO;
    }
}
```

> #### 技术原理

```
主要用类EsAutoConfiguration对es进行了配置，配置了序列化规则及rest客户端。同时完成ES客户端的生成，以供业务使用。
```

**java**

```
package com.kingtsoft.pangu.data.es;

/**
 * Title: <br>
 * Description: <br>
 * Company: KingTang <br>
 *
 * @author 金炀
 * @version 1.0
 */
@Slf4j
@EnableConfigurationProperties(EsProperties.class)
@Configuration
public class  EsAutoConfiguration {

    @Bean
public JacksonJsonpMapper jacksonJsonpMapper() {
        ObjectMapper objectMapper =newObjectMapper();
        objectMapper.configure(JsonParser.Feature.ALLOW_COMMENTS, true);
        objectMapper.configure(JsonParser.Feature.ALLOW_UNQUOTED_FIELD_NAMES, true);
        objectMapper.configure(JsonParser.Feature.ALLOW_SINGLE_QUOTES, true);
        objectMapper.configure(SerializationFeature.WRITE_DATES_AS_TIMESTAMPS, false);
        JavaTimeModule module =newJavaTimeModule();
        objectMapper.registerModule(module);
returnnewJacksonJsonpMapper(objectMapper);
    }

    @Bean
public RestClient restClient(EsProperties esProperties) {
return RestClient.builder(toHttpHost(esProperties.getHosts())).setRequestConfigCallback(requestConfigBuilder -> {
//设置连接超时时间
            requestConfigBuilder.setConnectTimeout(esProperties.getConnectionTimeout());
            requestConfigBuilder.setSocketTimeout(esProperties.getSocketTimeout());
            requestConfigBuilder.setConnectionRequestTimeout(esProperties.getConnectionRequestTimeout());
return requestConfigBuilder;
        }).setFailureListener(new RestClient.FailureListener() {
//某节点失败,这里可以做一些告警
            @Override
private void   onFailure(Node node) {
                log.error("{}", node);
            }
        }).setHttpClientConfigCallback(httpClientBuilder -> {
            httpClientBuilder.disableAuthCaching();
//设置账密
returngetHttpAsyncClientBuilder(httpClientBuilder, esProperties);
        }).build();
    }

private HttpAsyncClientBuilder getHttpAsyncClientBuilder(HttpAsyncClientBuilder httpClientBuilder,
                                                             EsProperties esProperties) {
if (!StringUtils.hasText(esProperties.getUsername()) ||!StringUtils.hasText(esProperties.getPassword())) {
return httpClientBuilder;
        }
//账密设置
        CredentialsProvider credentialsProvider =newBasicCredentialsProvider();
//es账号密码（一般使用,用户elastic）
        credentialsProvider.setCredentials(AuthScope.ANY,
newUsernamePasswordCredentials(esProperties.getUsername(), esProperties.getPassword()));
        httpClientBuilder.setDefaultCredentialsProvider(credentialsProvider);
return httpClientBuilder;
    }

    /**
     * 同步方式
     */
    @Bean
public ElasticsearchClient elasticsearchClient(RestClient restClient, JacksonJsonpMapper jacksonJsonpMapper) {
        ElasticsearchTransport transport =newRestClientTransport(restClient, jacksonJsonpMapper);

returnnewElasticsearchClient(transport);
    }

    /**
     * 异步方式
     */
    @Bean
public ElasticsearchAsyncClient elasticsearchAsyncClient(RestClient restClient,
                                                             JacksonJsonpMapper jacksonJsonpMapper) {
        ElasticsearchTransport transport =newRestClientTransport(restClient, jacksonJsonpMapper);
returnnewElasticsearchAsyncClient(transport);
    }

    /**
     * 解析配置的字符串hosts，转为HttpHost对象数组
     */
privateHttpHost[] toHttpHost(String hosts) {
if (!StringUtils.hasLength(hosts)) {
thrownewRuntimeException("无效的 elasticsearch 配置. hosts不能为空！");
        }

// 多个IP逗号隔开
String[] hostArr = hosts.split(",");
HttpHost[] httpHosts =newHttpHost[hostArr.length];
for (int i =0; i < httpHosts.length; i++) {
            String host = hostArr[i];
            host = host.replaceAll("http://", "").replaceAll("https://", "");
            Assert.isTrue(host.contains(":"), String.format("your host %s format error , Please refer to [ 127.0.0.1:9200 ] ", host));
            httpHosts[i] =newHttpHost(host.split(":")[0], Integer.parseInt(host.split(":")[1]), "http");
        }

return httpHosts;
    }

    @Bean
    @ConditionalOnMissingBean(IndexService.class)
public IndexService indexService() {
returnnewIndexServiceImpl();
    }

    @Bean
    @ConditionalOnMissingBean(DocumentService.class)
public DocumentService<?> documentService() {
returnnew DocumentServiceImpl<>();
    }
}
```

```
请求客户端可以配置的参数EsProperties
```

**java**

```
package com.kingtsoft.pangu.data.es;

import lombok.Data;
import lombok.experimental.Accessors;
import org.springframework.boot.context.properties.ConfigurationProperties;

import java.io.Serializable;

/**
 * Title: <br>
 * Description: <br>
 * Company: KingTang <br>
 *
 * @author 金炀
 * @version 1.0
 */
@Accessors(chain=true)
@ConfigurationProperties(prefix= EsProperties.PREFIX)
@Data
public class  EsPropertiesimplementsSerializable {

publicstaticfinal String PREFIX ="pangu.elasticsearch";

private String hosts;

privateint connectionTimeout =-1;

privateint socketTimeout =-1;

privateint connectionRequestTimeout =-1;

//es账号密码（一般使用,用户elastic）
private String username;

private String password;
}
```

```
使用参考文档
```

[https://blog.csdn.net/weixin_43407520/article/details/127351598](https://blog.csdn.net/weixin_43407520/article/details/127351598)[https://www.elastic.co/guide/en/elasticsearch/client/java-api-client/master/searching.html](https://www.elastic.co/guide/en/elasticsearch/client/java-api-client/master/searching.html)
