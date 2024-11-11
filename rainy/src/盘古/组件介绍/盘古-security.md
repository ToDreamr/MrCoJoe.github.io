# Feign模块

> #### 如何使用

引用如下模块

**xml**

```
<dependency>
  <groupId>com.kingtsoft.pangu</groupId>
  <artifactId>pangu-springcloud-feign</artifactId>
  <version>${pangu.version}</version>
</dependency>
```

```
    定义feignClient(保证Client所在包中有api或者feign这个路径)，例如com.kingtsoft.pangu.frame.simple.test.api
com.kingtsoft.pangu.frame.simple.test.feign
必须要有PgFeignClient标记才会初始化为客户端
```

**java**

```
@FeignResultClient
@PgFeignClient(clientCode="pangu-frame-simple", basePath="pangu-xdev", url="https://127.0.0.1:10240/pangu-xdev", loadBalance=false)
public interface  TestCallAnoServiceApi {

    String SUF ="/pub/test";

    @RequestMapping(value= SUF +"/testAnoCall?a=1&b=3", method= RequestMethod.POST)
    String doSomething(@RequestBody OisRegSchedule abc);
}
```

```
    使用如下，直接注入TestCallAnoServiceApi
```

**java**

```
private void   testCall() {
    log.info("doCall");
    OisRegSchedule oisRegSchedule =newOisRegSchedule();
    oisRegSchedule.setScheduleSn(1L);
    String abc = testCallAnoServiceApi.doSomething( oisRegSchedule);
    System.out.println(abc);
    log.info("end");
}
```

**注解介绍**

```
PgFeignClient
    url：直接声明请求地址，若为域名，请把loadBalance标记为false，否则会把域名当
作负载标记去识别。并且支持使用${}的方式获取配置文件的配置。
    clientCode：客户端代码，最好唯一。在没有url的情况下，会作为负载标记前缀
    encoder：编码配置，默认SPRING自带模式，可选GSON及FORM模式
    (注意，根据feign机制，数据返回并不会使用这里配置的encoder，除非是异步feign客户端)
    configuration：配置自定义配置，支持feign客户端配置，拦截器配置，编码，解码等，如下为案例
    basePath：基础路径，在负载且不用网关的情况下。路径解析可能只到端口。使用此属性会在端口之后配置个基础路径。
    loadBalance：是否开启负载均衡模式
```

**java**

```
@Configuration
public class  FeignClientConfiguration {

public Feign.Builder pgFeignBuild() {
        Feign.Builder builder =getFeignBuildDefault();
buildInterceptors(builder);
        String wn = environment.getProperty("feign.write-nulls");
boolean   writeNulls = StringUtils.hasText(wn) && boolean  .parseboolean  (wn);
// 使用fastjson作为feign的消息转换器
        ObjectFactory<HttpMessageConverters> feignObjectFactory = PgFeignUtil.initFeignNewConverters(messageConverters, writeNulls);

return builder
        .contract(contract)
        .encoder(newSpringEncoder(feignObjectFactory))
        .decoder(newSpringDecoder(feignObjectFactory, customizers));
    }

public Feign.Builder pgFeignGsonBuild() {
        Feign.Builder builder =getFeignBuildDefault();
buildInterceptors(builder);
return builder
        .contract(contract)
        .encoder(newGsonEncoder())
        .decoder(newGsonDecoder());
    }

public Feign.Builder pgFeignFormBuild() {
        Feign.Builder builder =getFeignBuildDefault();
buildInterceptors(builder);
        String wn = environment.getProperty("feign.write-nulls");
boolean   writeNulls = StringUtils.hasText(wn) && boolean  .parseboolean  (wn);
// 使用fastjson作为feign的消息转换器
        ObjectFactory<HttpMessageConverters> feignObjectFactory = PgFeignUtil.initFeignNewConverters(messageConverters, writeNulls);

return builder
        .contract(contract)
        .encoder(newSpringFormEncoder(newSpringEncoder(feignObjectFactory)))
        .decoder(newSpringDecoder(feignObjectFactory, customizers));
    }

private Feign.Builder getFeignBuildDefault() {
// 因为scope为prototype，每次获取bean都会重新创建一个新对象
return beanFactory.getBean("feignBuilder", Feign.Builder.class);
    }
}
```

```
#此注解用于处理返回值信息
FeignResultClient：
    value：返回值处理器类
    coverMethod：处理器的方法
    postfix：只处理标记处理的后缀
此注解标记的类下的方法或者方法的返回值会经过处理类，奖处理类后的结果再返回给调用方，
这样feign定义就可以直接定义实际的值部分内容。
```

> #### 技术原理

```
    首先是feign客户端的扫描，通过自定义扫描，对路径带有api及feign的BeanDefinition
进行了扫描。再去这些BeanDefinition判断是否存在自定义的PgFeignClient注解
```

**java**

```
protected ClassPathScanningCandidateComponentProvider getScanner() {
returnnewClassPathScanningCandidateComponentProvider(false, this.environment) {
        @Override
protectedboolean  isCandidateComponent(@NonNull MetadataReader metadataReader) {
            Optional<String> target = metadataReader.getAnnotationMetadata().getAnnotationTypes().stream().filter(
                sn -> sn.equals(PgFeignClient.class.getName())
            ).findAny();
return target.isPresent();
        }

        @Override
protectedboolean  isCandidateComponent(@NonNull AnnotatedBeanDefinition beanDefinition) {
return beanDefinition.getMetadata().isInterface() &&!beanDefinition.getMetadata().isAnnotation();
        }
    };
}

ClassLoader classLoader = Thread.currentThread().getContextClassLoader();
ClassPathScanningCandidateComponentProvider scanner =getScanner();
scanner.setResourceLoader(this.resourceLoader);

Set<BeanDefinition> beanDefinitions =new LinkedHashSet<>();
for (String pkg : PKG_ARR) {
    Set<BeanDefinition> beanDefinitions2 = scanner.findCandidateComponents(pkg);
    beanDefinitions.addAll(beanDefinitions2);
}
```

```
    默认加入了对okhttp的支持，使用的okhttpclient作为调用客户端，拥有队列线程池，轻松写并发
拥有Interceptors等特性。并且根据注解配置，自动判断是否生成负载客户端。
    以下为自动化配置类初始化内容
```

**java**

```
package com.kingtsoft.pangu.springcloud.feign;

/**
 * Title: <br>
 * Description: <br>
 * Company: KingTang <br>
 *
 * @author 金炀
 * @version 1.0
 */
@Import({FeignClientsConfiguration.class, FeignConfiguration.class, PgFeignClientConfiguration.class })
@ConditionalOnClass(Feign.class)
@AutoConfigureBefore({org.springframework.cloud.openfeign.FeignAutoConfiguration.class})
@AutoConfigureAfter(name= {"com.kingtsoft.pangu.springcloud.nacos.NacosAutoConfiguration"})
@Configuration
public class  FeignAutoConfigurationimplementsEnvironmentAware {

    /** 由于引入PgFeignClientConfiguration的生命周期比预计的早，所以这里需要手动绑定，不然会发现注入的类无法被绑定 */
privatestatic PgFeignOkHttpProperties pgFeignOkHttpProperties =newPgFeignOkHttpProperties();

privatestatic LoadBalancerClientsProperties balancerClientsProperties =newLoadBalancerClientsProperties();

    @Bean
    @Scope("prototype")
public AsyncFeign.AsyncBuilder<?> asyncFeignBuilder(Retryer retryer) {
return AsyncFeign.asyncBuilder().retryer(retryer);
    }

    @Bean
    @ConditionalOnMissingBean(HttpMessageConverters.class)
public HttpMessageConverters messageConverters(ObjectProvider<HttpMessageConverter<?>> converters) {
returnnewHttpMessageConverters(converters.orderedStream().collect(Collectors.toList()));
    }

    @Bean
    @ConditionalOnMissingBean(FeignResultCoverRegister.class)
public FeignResultCoverRegister feignResultCoverRegister() {
returnnewFeignResultCoverRegister();
    }

    @Bean
public OkHttpLogInterceptor okHttpLogInterceptor() {
returnnewOkHttpLogInterceptor();
    }

    @Bean
public PgFeignProperties pgFeignProperties(Environment environment) {
        BindResult<PgFeignProperties> ret = Binder.get(environment)
                .bind(PgFeignProperties.PREFIX, PgFeignProperties.class);

        PgFeignProperties pgFeignProperties =newPgFeignProperties();
try {
if (ret.get() !=null) {
                pgFeignProperties = ret.get();
            }
        } catch (Exception ignore) {}
return pgFeignProperties;
    }

    @Bean
    @ConditionalOnWebApplication
    @ConditionalOnMissingBean(FeignRequestInterceptor.class)
public FeignRequestInterceptor feignRequestInterceptor(PgFeignProperties pgFeignProperties) {
returnnewFeignRequestInterceptor(pgFeignProperties);
    }

    @Bean
public OkHttpResultInterceptor okHttpResultInterceptor(FeignResultCoverRegister feignResultCoverRegister) {
returnnewOkHttpResultInterceptor(feignResultCoverRegister);
    }

    @Bean
public OkHttpCusUrlInterceptor okHttpCusUrlInterceptor() {
returnnewOkHttpCusUrlInterceptor();
    }

// 这个bean是为了兼容老的一些写法
    @Bean("pgFeignBuild")
    @Primary
public Feign.Builder pgFeignBuild(Contract contract,
                                      @Qualifier("feignBuilder") Feign.Builder builder,
                                      @Qualifier("okHttpFeignClient") Client okHttpClient,
                                      ObjectFactory<HttpMessageConverters> messageConverters,
                                      ObjectProvider<HttpMessageConverterCustomizer> customizers,
                                      Environment environment) {
        String wn = environment.getProperty("feign.write-nulls");
boolean   writeNulls = StringUtils.hasText(wn) && boolean  .parseboolean  (wn);
// 使用fastjson作为feign的消息转换器
        ObjectFactory<HttpMessageConverters> feignObjectFactory = PgFeignUtil.initFeignNewConverters(messageConverters, writeNulls);

return builder
                .client(okHttpClient)
                .contract(contract)
                .encoder(newSpringEncoder(feignObjectFactory))
                .decoder(newSpringDecoder(feignObjectFactory, customizers));
    }

    @Override
private void   setEnvironment(@NonNull Environment environment) {
        BindResult<PgFeignOkHttpProperties> ret = Binder.get(environment)
                .bind(PgFeignOkHttpProperties.PREFIX, PgFeignOkHttpProperties.class);
        BindResult<LoadBalancerClientsProperties> blRet = Binder.get(environment)
                .bind("spring.cloud.loadbalancer", LoadBalancerClientsProperties.class);

try {
if (ret.get() !=null) {
                pgFeignOkHttpProperties = ret.get();
            }
        } catch (Exception ignore) {}
try {
if (blRet.get() !=null) {
                balancerClientsProperties = blRet.get();
            }
        } catch (Exception ignore) {}
    }

    @Configuration(proxyBeanMethods=false)
    @ConditionalOnClass(OkHttpClient.class)
protectedstaticclassOkHttpFeignConfiguration {

private OkHttpClient okHttpClient;

        @Bean
        @ConditionalOnMissingBean(ConnectionPool.class)
public ConnectionPool httpClientConnectionPool(FeignHttpClientProperties httpClientProperties,
                                                       OkHttpClientConnectionPoolFactory connectionPoolFactory) {
int maxTotalConnections = httpClientProperties.getMaxConnections();
long  timeToLive = httpClientProperties.getTimeToLive();
            TimeUnit ttlUnit = httpClientProperties.getTimeToLiveUnit();
return connectionPoolFactory.create(maxTotalConnections, timeToLive, ttlUnit);
        }

        @Bean("okHttpLoadBalancerClient")
public Client okHttpLoadBalancerClient(OkHttpLogInterceptor okHttpLogInterceptor,
                                               OkHttpResultInterceptor okHttpResultInterceptor,
                                               OkHttpCusUrlInterceptor okHttpCusUrlInterceptor,
                                               LoadBalancerClient loadBalancerClient,
                                               LoadBalancerClientFactory loadBalancerClientFactory) {
if (this.okHttpClient ==null) {
this.okHttpClient =getOkhttp(okHttpLogInterceptor, okHttpResultInterceptor, okHttpCusUrlInterceptor);
            }

returnnewFeignBlockingLoadBalancerClient(this.okHttpClient, loadBalancerClient, loadBalancerClientFactory);
        }

        @ConditionalOnMissingBean
        @Bean
public LoadBalancerClientFactory loadBalancerClientFactory(ObjectProvider<List<LoadBalancerClientSpecification>> configurations) {
            LoadBalancerClientFactory clientFactory =newLoadBalancerClientFactory(balancerClientsProperties);
            clientFactory.setConfigurations(configurations.getIfAvailable(Collections::emptyList));
return clientFactory;
        }

        @Bean("okHttpFeignClient")
//        @ConditionalOnMissingBean(OkHttpClient.class)
public OkHttpClient okHttpFeignClient(OkHttpLogInterceptor okHttpLogInterceptor,
                                              OkHttpResultInterceptor okHttpResultInterceptor,
                                              OkHttpCusUrlInterceptor okHttpCusUrlInterceptor) {
if (this.okHttpClient ==null) {
this.okHttpClient =getOkhttp(
                        okHttpLogInterceptor, okHttpResultInterceptor, okHttpCusUrlInterceptor);
            }

returnthis.okHttpClient;
        }

private OkHttpClient getOkhttp(OkHttpLogInterceptor okHttpLogInterceptor,
                                       OkHttpResultInterceptor okHttpResultInterceptor,
                                       OkHttpCusUrlInterceptor okHttpCusUrlInterceptor) {
returnnewOkHttpClient(new okhttp3.OkHttpClient.Builder()
// 三次握手 + SSL建立耗时
                    .connectTimeout(pgFeignOkHttpProperties.getConnectTimeout(), TimeUnit.MILLISECONDS)
// 设置读超时
                    .readTimeout(pgFeignOkHttpProperties.getReadTimeout(), TimeUnit.MILLISECONDS)
// 从发起到结束的总时长
                    .callTimeout(pgFeignOkHttpProperties.getCallTimeout(), TimeUnit.MILLISECONDS)
// 设置写超时
                    .writeTimeout(pgFeignOkHttpProperties.getWriteTimeout(), TimeUnit.MILLISECONDS)
                    .sslSocketFactory(SslSocketClient.getSslSocketFactory(), SslSocketClient.getX509TrustManager())
                    .hostnameVerifier(SslSocketClient.getHostnameVerifier())
// 是否自动重连
                    .retryOnConnectionFailure(true)
                    .connectionPool(newConnectionPool())
                    .addInterceptor(okHttpCusUrlInterceptor)
                    .addInterceptor(okHttpLogInterceptor)
                    .addInterceptor(okHttpResultInterceptor)
// 构建OkHttpClient对象
                    .build());
        }

        @Bean
        @Primary
        @ConditionalOnBean(LoadBalancerClientFactory.class)
        @ConditionalOnMissingBean
public LoadBalancerClient blockingLoadBalancerClient(LoadBalancerClientFactory loadBalancerClientFactory) {
returnnewBlockingLoadBalancerClient(loadBalancerClientFactory);
        }
    }
}
```

```
    并且在registerBeanDefinitions生命周期中，实现对客户端注解的解析及配置相关解析，
最后对bean对象的自定义注入。(URL的解析会根据配置文件feign.gate-mode，是否整理成网关
地址)，具体逻辑如下
```

**java**

```
package com.kingtsoft.pangu.springcloud.feign;

/**
 * Title: <br>
 * Description: <br>
 * Company: KingTang <br>
 *
 * @author 金炀
 * @version 1.0
 */
@Slf4j
@Configuration
public class  PgFeignClientConfigurationimplementsEnvironmentAware, ResourceLoaderAware,
ImportBeanDefinitionRegistrar {

private DefaultListableBeanFactory beanFactory;

private final   List<RequestInterceptor> requestInterceptors =new ArrayList<>();

private Contract contract;

private ObjectFactory<HttpMessageConverters> messageConverters;

private ObjectProvider<HttpMessageConverterCustomizer> customizers;

private Client okHttpLoadBalancerClient;

private Client okHttpClient;

private Environment environment;

private ResourceLoader resourceLoader;

privatestaticfinal List<String> PKG_ARR =new ArrayList<>(Arrays.asList("**.feign", "**.api"));

private String centerUrl;

privateboolean   gateMode;

private OkHttpCusUrlInterceptor okHttpCusUrlInterceptor;

    @Override
private void   setResourceLoader(@NonNull ResourceLoader resourceLoader) {
this.resourceLoader = resourceLoader;
    }

    @Override
private void   setEnvironment(@NonNull Environment environment) {
this.environment = environment;
initGatewayUrl();
        String lbStr = environment.getProperty("feign.gate-mode");
this.gateMode = StringUtils.hasText(lbStr) && boolean  .parseboolean  (lbStr);
    }

private void  initGatewayUrl() {
this.centerUrl = System.getProperties().getProperty(HttpConst.CLIENT_ADDR_GATEWAY);
if (StringUtils.hasText(centerUrl)) {
return;
        }
this.centerUrl = System.getenv(HttpConst.CLIENT_ADDR_GATEWAY);
if (StringUtils.hasText(centerUrl)) {
return;
        }
this.centerUrl = environment.getProperty(HttpConst.CLIENT_ADDR_GATEWAY);
if (!StringUtils.hasText(centerUrl)) {
this.centerUrl ="http://localhost";
        }
    }

    @Override
private void   registerBeanDefinitions(@NonNull AnnotationMetadata importingClassMetadata,
                                        @NonNull BeanDefinitionRegistry registry) {
        beanFactory = (DefaultListableBeanFactory) registry;

        PgFeignProperties pgFeignProperties = beanFactory.getBean(PgFeignProperties.class);
        PKG_ARR.addAll(pgFeignProperties.getScans());

        contract = beanFactory.getBean(Contract.class);
        messageConverters = beanFactory.getBeanProvider(HttpMessageConverters.class);
        customizers = beanFactory.getBeanProvider(HttpMessageConverterCustomizer.class);

        okHttpLoadBalancerClient = (Client) beanFactory.getBean("okHttpLoadBalancerClient");
        okHttpClient = (Client) beanFactory.getBean("okHttpFeignClient");
        okHttpCusUrlInterceptor = beanFactory.getBean(OkHttpCusUrlInterceptor.class);

String[] interBeanNames = beanFactory.getBeanNamesForType(RequestInterceptor.class);
for (String beanName : interBeanNames) {
            RequestInterceptor interceptor = (RequestInterceptor) beanFactory.getBean(beanName);
            requestInterceptors.add(interceptor);
        }

registerPgFeignClient();
    }

private void   registerPgFeignClient() {
        ClassLoader classLoader = Thread.currentThread().getContextClassLoader();
        ClassPathScanningCandidateComponentProvider scanner =getScanner();
        scanner.setResourceLoader(this.resourceLoader);

        Set<BeanDefinition> beanDefinitions =new LinkedHashSet<>();
for (String pkg : PKG_ARR) {
            Set<BeanDefinition> beanDefinitions2 = scanner.findCandidateComponents(pkg);
            beanDefinitions.addAll(beanDefinitions2);
        }

for (BeanDefinition beanDefinition : beanDefinitions) {
if (beanDefinition.getBeanClassName() ==null) {
continue;
            }

try {
                beanFactory.getBean(Class.forName(beanDefinition.getBeanClassName()));
continue;
            } catch (Exception ignored) {
            }

try {
                Class<?> aClass = classLoader.loadClass(beanDefinition.getBeanClassName());
                PgFeignClient pgFeignClient = aClass.getAnnotation(PgFeignClient.class);
if (pgFeignClient ==null) {
continue;
                }

// 这里并未实际创建异步客户端，后续考虑升级
//                if (pgFeignClient.async()) {
//                    AsyncFeign.AsyncBuilder<?> asyncBuilder = beanFactory.getBean("asyncFeignBuilder", AsyncFeign.AsyncBuilder.class);
//                }

                Feign.Builder relBuild;
switch (pgFeignClient.encoder()) {
case GSON:
                        relBuild =pgFeignGsonBuild();
break;
case FORM:
                        relBuild =pgFeignFormBuild();
break;
default:
                        relBuild =pgFeignBuild();
                }

                String url;
if (StringUtils.hasText(pgFeignClient.url())) {
                    url = pgFeignClient.url();
if (url.contains("${") && url.contains("}")) {
                        url = environment.resolvePlaceholders(pgFeignClient.url());

if (url.equals(pgFeignClient.url())) {
                            url =getUrlByClientCode(pgFeignClient.clientCode(), pgFeignClient.basePath());
                        }
                    }
                } else {
                    url =getUrlByClientCode(pgFeignClient.clientCode(), pgFeignClient.basePath());
                }

// 指定
if (pgFeignClient.loadBalance()) {
                    relBuild.client(okHttpLoadBalancerClient);
                } else {
                    relBuild.client(okHttpClient);
                }

// 如果检测到地址是个IP，强制非负载方式
UrlCheck(relBuild, url);

if (!StringUtils.hasText(url)) {
                    url ="http://localhost";
                    log.warn("注意：{}客户端无法匹配具体url地址!", beanDefinition.getBeanClassName());
                }

                url = PgFeignUtil.doOptimization(url);

registerBeanDefinition(beanFactory, beanDefinition.getBeanClassName());
initConfiguration(relBuild, pgFeignClient.configuration(), pgFeignClient.clientCode());

                beanFactory.registerSingleton(beanDefinition.getBeanClassName(),
                        relBuild.target(aClass, url)
                );
            } catch (Exception e) {
                log.error("feign初始化异常", e);
            }
        }
    }

private void  UrlCheck(Feign.Builder relBuild, String url) {
try {
            URI uri = URI.create(url);
if (isIp(uri.getHost()) ||"localhost".equals(uri.getHost())) {
                relBuild.client(okHttpClient);
            }
        } catch (Exception ignore) {}
    }

publicstaticboolean  isIp(String addr) {
if (addr.length() <7|| addr.length() >15) {
returnfalse;
        }

        String rexp ="([1-9]|[1-9]\\d|1\\d{2}|2[0-4]\\d|25[0-5])(\\.(\\d|[1-9]\\d|1\\d{2}|2[0-4]\\d|25[0-5])){3}";
        Pattern pat = Pattern.compile(rexp);
        Matcher mat = pat.matcher(addr);
return mat.find();
    }

    @SneakyThrows
private void  initConfiguration(Feign.Builder relBuild, Class<?>[] configuration, String clientCode) {
for (Class<?> clazz : configuration) {
for (Method method : clazz.getMethods()) {
                Bean bean = AnnotatedElementUtils.findMergedAnnotation(method, Bean.class);
if (bean ==null) {
continue;
                }

                Object ret = bean.value().length ==0?
                        beanFactory.getBean(method.getName()) :
                        beanFactory.getBean(bean.value()[0]);

pkgFeignBuild(relBuild, method.getReturnType(), ret);

if (FeignUrlCusApi.class.isAssignableFrom(method.getReturnType())) {
if (StringUtils.hasText(clientCode)) {
                        okHttpCusUrlInterceptor.addFeignUrlCusApi(clientCode, (FeignUrlCusApi) ret);
                    }
                }
            }
        }
    }

private void  pkgFeignBuild(Feign.Builder relBuild, Class<?> returnType, Object ret) {
if (Encoder.class.isAssignableFrom(returnType)) {
            relBuild.encoder((Encoder) ret);
return;
        }
if (Decoder.class.isAssignableFrom(returnType)) {
            relBuild.decoder((Decoder) ret);
return;
        }
if (Contract.class.isAssignableFrom(returnType)) {
            relBuild.contract((Contract) ret);
return;
        }
if (Client.class.isAssignableFrom(returnType)) {
            relBuild.client((Client) ret);
return;
        }
if (Retryer.class.isAssignableFrom(returnType)) {
            relBuild.retryer((Retryer) ret);
return;
        }
if (Request.Options.class.isAssignableFrom(returnType)) {
            relBuild.options((Request.Options) ret);
return;
        }
if (RequestInterceptor.class.isAssignableFrom(returnType)) {
            relBuild.requestInterceptor((RequestInterceptor) ret);
        }
    }

private String getUrlByClientCode(String clientCode, String basePath) {
if (StringUtils.hasText(clientCode)) {
if (!this.gateMode) {
return"http://"+ clientCode + (StringUtils.hasText(basePath) ?"/"+ basePath :"");
            } else {
return centerUrl +"/"+ (StringUtils.hasText(basePath) ? basePath : clientCode);
            }
        }

return StringUtils.hasText(basePath) ? centerUrl +"/"+ basePath : centerUrl;
    }

protected ClassPathScanningCandidateComponentProvider getScanner() {
returnnewClassPathScanningCandidateComponentProvider(false, this.environment) {
            @Override
protectedboolean  isCandidateComponent(@NonNull MetadataReader metadataReader) {
                Optional<String> target = metadataReader.getAnnotationMetadata().getAnnotationTypes().stream().filter(
                        sn -> sn.equals(PgFeignClient.class.getName())
                ).findAny();
return target.isPresent();
            }

            @Override
protectedboolean  isCandidateComponent(@NonNull AnnotatedBeanDefinition beanDefinition) {
return beanDefinition.getMetadata().isInterface() &&!beanDefinition.getMetadata().isAnnotation();
            }
        };
    }

private void  registerBeanDefinition(DefaultListableBeanFactory beanFactory, String name) {
        BeanDefinitionBuilder beanDefinitionBuilder = BeanDefinitionBuilder.genericBeanDefinition(Binding.class);
        beanDefinitionBuilder.addPropertyReference(name, name);
        BeanDefinition beanDefinition = beanDefinitionBuilder.getRawBeanDefinition();
        beanFactory.registerBeanDefinition(name, beanDefinition);
    }

public Feign.Builder pgFeignBuild() {
        Feign.Builder builder =getFeignBuildDefault();
buildInterceptors(builder);
        String wn = environment.getProperty("feign.write-nulls");
boolean   writeNulls = StringUtils.hasText(wn) && boolean  .parseboolean  (wn);
// 使用fastjson作为feign的消息转换器
        ObjectFactory<HttpMessageConverters> feignObjectFactory = PgFeignUtil.initFeignNewConverters(messageConverters, writeNulls);

return builder
                .contract(contract)
                .encoder(newSpringEncoder(feignObjectFactory))
                .decoder(newSpringDecoder(feignObjectFactory, customizers));
    }

public Feign.Builder pgFeignGsonBuild() {
        Feign.Builder builder =getFeignBuildDefault();
buildInterceptors(builder);
return builder
                .contract(contract)
                .encoder(newGsonEncoder())
                .decoder(newGsonDecoder());
    }

public Feign.Builder pgFeignFormBuild() {
        Feign.Builder builder =getFeignBuildDefault();
buildInterceptors(builder);
        String wn = environment.getProperty("feign.write-nulls");
boolean   writeNulls = StringUtils.hasText(wn) && boolean  .parseboolean  (wn);
// 使用fastjson作为feign的消息转换器
        ObjectFactory<HttpMessageConverters> feignObjectFactory = PgFeignUtil.initFeignNewConverters(messageConverters, writeNulls);

return builder
                .contract(contract)
                .encoder(newSpringFormEncoder(newSpringEncoder(feignObjectFactory)))
                .decoder(newSpringDecoder(feignObjectFactory, customizers));
    }

private Feign.Builder getFeignBuildDefault() {
// 因为scope为prototype，每次获取bean都会重新创建一个新对象
return beanFactory.getBean("feignBuilder", Feign.Builder.class);
    }

private void  buildInterceptors(Feign.Builder builder) {
// 不直接使用builder.requestInterceptors方法的原因是这个方法会清空原有拦截器
for (RequestInterceptor requestInterceptor : requestInterceptors) {
            builder.requestInterceptor(requestInterceptor);
        }
    }
}
```

```
    主要给feign客户端配置了各类拦截编码及响应值解析所需缓存（因为feign的回调钩子
上下文中无法获取到执行的方法上下文，也就无法知道使用哪个值转换类，所以需要提前缓存好）。
主要使用了反射。此时客户端已经生成。
```

**java**

```
package com.kingtsoft.pangu.springcloud.feign;

import com.kingtsoft.pangu.springcloud.feign.annotation.FeignResultClient;
import com.kingtsoft.pangu.springcloud.feign.annotation.PgFeignClient;
import com.kingtsoft.pangu.springcloud.feign.utils.PgFeignUtil;
import org.springframework.beans.BeansException;
import org.springframework.context.ApplicationContext;
import org.springframework.context.ApplicationContextAware;
import org.springframework.core.annotation.AnnotatedElementUtils;
import org.springframework.lang.NonNull;
import org.springframework.stereotype.Component;
import org.springframework.util.StringUtils;
import org.springframework.web.bind.annotation.RequestMapping;

import java.lang.reflect.*;
import java.net.URI;
import java.util.HashMap;
import java.util.Map;

/**
 * Title: <br>
 * Description: <br>
 * Company: KingTang <br>
 *
 * @author 金炀
 * @version 1.0
 */
@Component
public class  FeignResultCoverRegisterimplementsApplicationContextAware {

private final   Map<String, FeignResultCover> feignResultCache =new HashMap<>();

private ApplicationContext applicationContext;

    @Override
private void   setApplicationContext(@NonNull ApplicationContext applicationContext) throws BeansException {
this.applicationContext = applicationContext;
    }

private void   registerFeignResultCover() {
        Map<String, Object> feignResultBeans = applicationContext.getBeansWithAnnotation(PgFeignClient.class);

        feignResultBeans.forEach(
                (beanName, bean) -> {
if (Proxy.isProxyClass(bean.getClass())) {
                        Object obj = Proxy.getInvocationHandler(bean);
try {
                            Field targetField = obj.getClass().getDeclaredField("target");
                            targetField.setAccessible(true);
                            Object target = targetField.get(obj);
if (target ==null) {
thrownewRuntimeException("代理 target属性缺失: "+ obj.getClass().getName());
                            }

                            Field urlField = target.getClass().getDeclaredField("url");
                            urlField.setAccessible(true);
                            String reqUrl = (String) urlField.get(target);
if (reqUrl ==null) {
                                reqUrl ="";
                            }

                            Field typeField = target.getClass().getDeclaredField("type");
                            typeField.setAccessible(true);
                            Class<?> type = (Class<?>) typeField.get(target);
if (type ==null) {
thrownewRuntimeException("type属性缺失: "+ target.getClass().getName());
                            }

                            PgFeignClient client = type.getAnnotation(PgFeignClient.class);
if (client !=null&&!StringUtils.hasText(reqUrl)) {
                                reqUrl = client.clientCode();
                            }

                            FeignResultClient parentAnnotation = type.getAnnotation(FeignResultClient.class);
                            FeignResultCover parentResultCover =null;
if (parentAnnotation !=null) {
                                parentResultCover =
newFeignResultCover(parentAnnotation.value(), parentAnnotation.coverMethod(), null);
                            }

String[] parentUrls =getMethodUrl(type);

Method[] methods = type.getDeclaredMethods();
for (Method method : methods) {
                                FeignResultClient annotation = method.getAnnotation(FeignResultClient.class);
                                FeignResultCover resultCover;
                                String postfix;

if (annotation !=null) {
                                    postfix = annotation.postfix();
                                    resultCover =newFeignResultCover(
                                            annotation.value(), annotation.coverMethod(), method.getReturnType());
                                } else {
                                    postfix ="";
if (parentResultCover ==null) {
continue;
                                    }
                                    resultCover =newFeignResultCover(
                                            parentResultCover.getCoverClazz(),
                                            parentResultCover.getCoverMethod(),
                                            method.getReturnType());
                                }

String[] urls =getMethodUrl(method);
if (method.getParameterTypes().length !=0&& method.getParameterTypes()[0].equals(URI.class)) {
if (urls !=null) {
for (String url : urls) {
                                            feignResultCache.put(PgFeignUtil.doOptimization("**/"+ url + postfix), resultCover);
                                        }
                                    } else {
                                        feignResultCache.put(PgFeignUtil.doOptimization("**/"+ postfix), resultCover);
                                    }
                                } else {
if (parentUrls ==null|| parentUrls.length ==0) {
if (urls !=null) {
for (String url : urls) {
                                                feignResultCache.put(PgFeignUtil.doOptimization(reqUrl + url + postfix), resultCover);
                                            }
                                        }
                                    } else {
for (String parentUrl : parentUrls) {
if (urls !=null) {
for (String url : urls) {
                                                    feignResultCache.put(PgFeignUtil.doOptimization(reqUrl + parentUrl + url + postfix), resultCover);
                                                }
                                            } else {
                                                feignResultCache.put(PgFeignUtil.doOptimization(reqUrl + parentUrl + postfix), resultCover);
                                            }
                                        }
                                    }
                                }
                            }
                        } catch (Exception e) {
                            e.printStackTrace();
                        }
                    }
                }
        );
    }

public Map<String, FeignResultCover> getFeignResultCache() {
returnthis.feignResultCache;
    }

privateString[] getMethodUrl(AnnotatedElement element) {
        RequestMapping requestMapping = AnnotatedElementUtils.findMergedAnnotation(element, RequestMapping.class);
if (requestMapping !=null) {
return requestMapping.value();
        }

returnnull;
    }
}
```

```
    通过缓存，加入了自动对jsonresult的数据解析及内容判定，在调用及定义的时候可以直接定义
结构体data内的数据，不需要每次都写显示的代码，对内容进行解析。当然并不是所有接口都一定需要
解析结构体，所以需要一个FeignResultClient注解，标记此类客户端(不同结构体的解析器是可以
自定义的，并配置到FeignResultClient中)。拦截器解析如下：
```

**java**

```
@Override
    @NonNull
public Response intercept(Chain chain) throws IOException {
//这个chain里面包含了request和response，所以你要什么都可以从这里拿
        Request request = chain.request();
//请求发起的时间
        Response response = chain.proceed(request);
if (response.code() >=400) {
            String msg = StringUtils.hasText(response.message()) ?
                    response.message() :
                    (response.body() ==null?"": response.body().string());
if (log.isDebugEnabled()) {
                log.debug("code: {} msg: {}", response.code(), msg);
            }
thrownewTipException(response.code(), msg);
        }
        ResponseBody body = response.body();
if (body ==null) {
return response;
        }

        FeignResultCover resultCover =getFeignResultCover(request.url().toString());
if (resultCover ==null) {
return response;
        }

        String ret = body.string();

        Class<?> clazz = resultCover.getCoverClazz();
        Method method;
        Object obj;

try {
            method = clazz.getMethod(resultCover.getCoverMethod(), Object.class);
            obj = method.invoke(clazz.getDeclaredConstructor().newInstance(), ret);
        } catch (InvocationTargetException e) {
if (log.isDebugEnabled()) {
                e.printStackTrace();
            }
            Throwable exception = e.getTargetException();
if (exception instanceof TipException) {
throw (TipException) exception;
            }
thrownewTipException(e.toString());
        } catch (NoSuchMethodException | IllegalAccessException | InstantiationException e) {
if (log.isDebugEnabled()) {
                e.printStackTrace();
            }
thrownewTipException(e.toString());
        }

        ResponseBody bodyNew;
        String bkObj;
if (obj ==null) {
            bkObj ="null";
        } elseif (obj.getClass().equals(String.class)) {
// 会使用消息转换器切换回来
            bkObj = JSON.toJSONString(obj);
        } else {
            bkObj = JSON.toJSONString(obj);
        }

        bodyNew = ResponseBody.create(body.contentType(), bkObj);


return response.newBuilder().body(bodyNew).build();
    }
```

```
    支持服务自定义代码返回地址（用于三方，可能需要数据库动态实时获取），原理是利用拦截器
对request进行地址截取并填充新数据。业务端实现FeignUrlCusApi接口，重写方法就行。
```

**java**

```
public class  OkHttpCusUrlInterceptorimplementsInterceptor {

private final   Map<String, FeignUrlCusApi> urlCusApis =new LinkedHashMap<>();

private void   addFeignUrlCusApi(String serviceId, FeignUrlCusApi feignUrlCusApi) {
this.urlCusApis.put(serviceId, feignUrlCusApi);
    }

    @NonNull
    @Override
public Response intercept(@NonNull Chain chain) throws IOException {
try {
            String path = chain.request().url().encodedPath();
            Request request = chain.request();
            FeignUrlCusApi urlCusApi = urlCusApis.get(request.url().host());
if (urlCusApi ==null) {
return chain.proceed(request);
            }

            String url = urlCusApi.getUrl();
if (!StringUtils.hasText(url)) {
return chain.proceed(request);
            }

            HttpUrl httpUrl = Objects.requireNonNull(request.url().newBuilder(url + path))
                    .query(request.url().query())
                    .encodedQuery(request.url().encodedQuery())
                    .fragment(request.url().fragment())
                    .encodedFragment(request.url().encodedFragment())
                    .build();
return chain.proceed(request.newBuilder().url(httpUrl).build());
        } catch (Exception e) {
            log.error(e.toString());
return chain.proceed(chain.request());
        }
    }
}
```

```
Feign-java调用兼容
    添加了feign API的spring bean判断，若当前接口中存在对应的实现，将不会对此接口进行
feign客户端的代理生成，常规的接口调用将变成进程内的直接调用【自然可以保持直接的事务一致】。
若不存在实现，则接口就会执行注解所示的feign调用。这个时候就会需要使用分布式事务。 接口所处
目录要么包名带feign，要么带api关键字
```

![image.png](http://pangu.kingtsoft.com/pangu-facade/assets/image1.8ca381d0.png)

```
负载均衡
    回到自动化配置类初始化内容FeignAutoConfiguration
    可以看到配置了
@AutoConfigureAfter(name = {"com.kingtsoft.pangu.springcloud.nacos.NacosAutoConfiguration"})，
    主要是结合nacos模块，由于需要引入自定义的loadbalance模块进行堵在均衡自定义算法执行。
所以需要在NacosAutoConfiguration配置负载客户端之后加载，因为是字符串引入，所以两个
模块不是强耦合的，如果没有LoadBalancerClientFactory 中的configurations只是没有
了自定义的负载实现，会走默认。NacosAutoConfiguration先执行就是为了让
LoadBalancerClientFactory可以提前往configurations注入自定义的实现。okHttp的负
载客户端这里直接默认使用了BlockingLoadBalancerClient，LoadBalancerClientFactory
的初始都参考源码内容。并且开放了集群标记配置，这样在没有网关的情况下，feign也能独立完成
流量的引导。
```
