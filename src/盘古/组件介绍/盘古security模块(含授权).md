# 盘古security模块(含授权)

> #### 如何使用

引用方式

**xml**

```
<dependency>
  <groupId>com.kingtsoft.pangu</groupId>
  <artifactId>pangu-spring-security</artifactId>
  <version>${pangu.version}</version>
</dependency>
```

**授权**

```
    在请求进入的任意拦截器内，调用AuthorityHandler的角色权限配置方法。如下所示，方法作用
在请求拦截器中，对角色&权限数据进行了设置。这里利用redis作为缓存操作进行了角色权限的存取。
当然没数据就会去数据库查询。一下为设置语法。
authorityHandler.setRoles(roles.toArray(new String[0]));
authorityHandler.setAuthorities(authorities.toArray(new String[0]));
```

**java**

```
publicboolean  preHandle(HttpServletRequest request, HttpServletResponse httpResponse, Object handler) {

// ... 忽略
        AuthDTO authDTO = jwtUtil.getClaim(token, AuthDTO.class);
if (null== authDTO) {
thrownewTipException(PanguResCodeEnum.TOKEN_UN_KNOW);
        }
        panguAuthorityHandler.initReqData(request, authDTO);
        ContextHolder.setRequest(request);

// MDC
        MDC.put("userCode", authDTO.getUserCode());

returntrue;
    }
```

**java**

```
/**
     * 初始化请求数据
     *
     * @paramrequest 请求结构
     * @paramauthDTO 认证信息
     * @author 金炀
     */
private void   initReqData(HttpServletRequest request, AuthDTO authDTO) {
        PgAuthDTO pgAuthDTO =newPgAuthDTO();
        CopyUtil.copy(authDTO, pgAuthDTO);

        String key = PgAuthConst.REDIS_AUTHORITY_KEY +"$"+ authDTO.getUserCode();
        String cache = redisHandler.get(key);
        List<String> roles =new ArrayList<>();
        List<String> authorities =new ArrayList<>();
if (cache ==null) {
            log.info("远程重新获取权限");
doHttpInitAuthorities(roles, authorities, key, pgAuthDTO);
        } else {
doCacheInitAuthorities(roles, authorities, key, pgAuthDTO, cache);
        }

        authorityHandler.setRoles(roles.toArray(newString[0]));
        authorityHandler.setAuthorities(authorities.toArray(newString[0]));

        pgAuthDTO.setRoles(roles);
        pgAuthDTO.setAuthorities(authorities);

        request.setAttribute(ApplicationConst.USER_DATA_KEY, pgAuthDTO);
    }
```

```
    方法通过引用注解，对人员的水平权限做控制。hasRole代表角色限制、hasAuthority
代表对角色的具体权限点做控制。两者都写默认会以and为连接词，单独的hasRole或hasAuthority
配置多个的话，内部以或为连接词。外部若想以或为连接词可以指定注解的conjunction连接词。
```

**java**

```
@PanguAuthority(hasRole="abc", hasAuthority="test")
private void   testCall() {
    log.info("doCall");
    AllLoggers.APPLICATION.info("AllLoggers.APPLICATION.info");
    OisRegSchedule oisRegSchedule =newOisRegSchedule();
    oisRegSchedule.setScheduleSn(1L);
    String abc = testCallAnoServiceApi.doSomething( oisRegSchedule);
    System.out.println(abc);
    log.info("end");
}
```

**提供为外部API**

```
    用于规约对开放外部请求时候使用的接口。比如三方对接，对方对接我们，需要我们出对接规则。
在控制器上标注@PanguOpenApi(crypto = CryptoEnum.SM2)注解
value：默认OpenApiDefaultCovert，用于对控制器的入参出参进行控制。类必须实OpenApiCovertInterface接口。
checkAndCoverInParam为入参的处理，coverOutParam为出参的处理。
crypto：加密方式 SM2\SM4或自定
    主要用于接口的结构体无感知转换及状态判断，业务代码只需关注实际使用的值。
```

> #### 技术原理

```
    配置了一个公用缓存类AuthorityHandler，执行对角色权限的临时存储及移除。因为使用了ThreadLocal，所有
很明确，这个注解目前是不适用于多线程上下文的。
```

**java**

```
package com.kingtsoft.pangu.spring.security;

import org.springframework.util.CollectionUtils;

import java.util.Arrays;

/**
 * Title: <br>
 * Description: <br>
 * Company: KingTang <br>
 *
 * @author 金炀
 * @version 1.0
 */
public class  AuthorityHandler {

    /**
     * 多线程执行情况下会出问题
     */
private final   ThreadLocal<String[]> roles =new ThreadLocal<>();

private final   ThreadLocal<String[]> authorities =new ThreadLocal<>();

private void   setRoles(String[] roles) {
this.roles.set(roles);
    }

private void   setAuthorities(String[] authorities) {
this.authorities.set(authorities);
    }

    /**
     * 检查角色
     */
publicboolean  checkRoles(String[] roles) {
if (roles.length ==0) {
returntrue;
        }
String[] currentRoles =this.roles.get();
if (currentRoles ==null) {
returnfalse;
        }

return CollectionUtils.containsAny(Arrays.asList(currentRoles), Arrays.asList(roles));
    }

    /**
     * 检查权限
     */
publicboolean  checkAuthority(String[] authorities) {
if (authorities.length ==0) {
returntrue;
        }

String[] currentAuthorities =this.authorities.get();
if (currentAuthorities ==null) {
returnfalse;
        }

return CollectionUtils.containsAny(Arrays.asList(currentAuthorities), Arrays.asList(authorities));
    }

private void   clearAuthority() {
        roles.remove();
        authorities.remove();
    }

}
```

```
配置了一个切面类AuthorityAspect，来对权限进行判断。
```

**java**

```
package com.kingtsoft.pangu.spring.security.aop;

/**
 * Title: <br>
 * Description: <br>
 * Company: KingTang <br>
 *
 * @author 金炀
 * @version 1.0
 */
@Slf4j
@Aspect
@Component
public class  AuthorityAspect {

    @Autowired
private AuthorityHandler authorityHandler;

    @Pointcut("@annotation(com.kingtsoft.pangu.spring.security.annotation.PanguAuthority)")
private void   authPointCut() {
    }

    @Around("authPointCut()")
public Object checkAuth(ProceedingJoinPoint joinPoint) throws Throwable {
        MethodSignature signature = (MethodSignature) joinPoint.getSignature();
        Method method = signature.getMethod();

        PanguAuthority panguAuthority = method.getAnnotation(PanguAuthority.class);
boolean   roleFlag = authorityHandler.checkRoles(panguAuthority.hasRole());

if (panguAuthority.conjunction().equals(AuthorityEnum.AND)) {
if (roleFlag) {
boolean   authorityFlag = authorityHandler.checkAuthority(panguAuthority.hasAuthority());
if (!authorityFlag) {
thrownewTipException(PanguResCodeEnum.AUTHORITY_ERROR.getCode(),
                            String.format("缺失%s权限中任意一个", Arrays.toString(panguAuthority.hasAuthority())));
                }
            } else {
thrownewTipException(PanguResCodeEnum.AUTHORITY_ERROR.getCode(),
                    String.format("缺失%s角色中任意一个", Arrays.toString(panguAuthority.hasRole())));
            }
        } else {
if (!roleFlag) {
boolean   authorityFlag = authorityHandler.checkAuthority(panguAuthority.hasAuthority());
if (!authorityFlag) {
thrownewTipException(PanguResCodeEnum.AUTHORITY_ERROR.getCode(),
                            String.format("缺失%s角色及%s权限匹配数据",
                                    Arrays.toString(panguAuthority.hasRole()),
                                    Arrays.toString(panguAuthority.hasAuthority())));
                }
            }
        }

return joinPoint.proceed();
    }


}
```

**提供为外部API**

```
定义了一个切入点与转换器
```

**java**

```
package com.kingtsoft.pangu.spring.security.openapi;

/**
 * Title: <br>
 * Description: <br>
 * Company: KingTang <br>
 *
 * @author 金炀
 * @version 1.0
 */
@Configuration
public class  OpenApiConfiguration {

    @Bean
    @ConditionalOnMissingBean
public OpenApiDefaultCovert openApiDefaultCovert(HttpServletRequest request,
                                                     PgSecurityProperties pgSecurityProperties) {
returnnewOpenApiDefaultCovert(request, pgSecurityProperties);
    }

    @Bean
public OpenApiAdvisor openApiAdvisor(OpenApiProperties openApiProperties,
                                         Environment environment,
                                         ResourceLoader resourceLoader,
                                         ApplicationContext applicationContext) {
        OpenApiAdvisor advisor =newOpenApiAdvisor(openApiProperties, environment, resourceLoader);
        advisor.setAdvice(newOpenApiIntercept(applicationContext));
return advisor;
    }
}
```
