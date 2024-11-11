# Swagger模块

```
    找了一圈，发现还是swagger正统点。使用的swagger3.0，抛弃了原先的springfox，
使用了springdoc代替，里面会彻底放弃swagger2.0的注解。
```

> #### 如何使用

引入模块

**xml**

```
<dependency>
  <artifactId>pangu-spring-swagger</artifactId>
  <groupId>com.kingtsoft.pangu</groupId>
</dependency>
```

案例如下

**java**

```
@Schema(name="BaseUserPlus", description="人员拓展信息")
@Data
public class  BaseUserPlusimplementsSerializable {

    /**
     * 标识
     */
    @Schema(description="标识")
private Integer userId;

    /**
     * 主题
     */
    @Schema(description="主题")
private String themeCode;

    /**
     * 头像
     */
    @Schema(description="背景图")
privatebyte[] backgroundImg;

    /**
     * 修改时间
     */
    @Schema(description="修改时间")
private LocalDateTime modifyTime;

    /**
     * 修改人员
     */
    @Schema(description="修改人员")
private Integer modifyBy;

    /**
     * 备注
     */
    @Schema(description="备注")
private String remark;

privatestaticfinallong  serialVersionUID =1L;
}
```

```
    注意有的时候，需要数据非必填，可以使用@RequestParam(required = false)，
默认都为必填内容，其他的注解不会生效。实体类的的model作为入参的话，如果类里面已经有
注解了，外部无需配置，外部配置会导致内部识别异常。
```

**java**

```
@Operation(
summary="获取机构列表数据",
parameters= {
                    @Parameter(
name="num",
description="最大数",
schema= @Schema(type="int", implementation= Integer.class)
                    ),
                    @Parameter(
name="module",
description="模块代码",
schema= @Schema(type="string", implementation= String.class)
                    ),
                    @Parameter(
name="ip",
description="ip地址",
schema= @Schema(type="string", implementation= String.class)
                    )
            },
responses= {
                    @ApiResponse(
description="机构信息",
content= {@Content(array= @ArraySchema(schema= @Schema(type="BranchReqVO", implementation= BranchReqVO.class)))}
                    )
            })
    @GetMapping(value="/getBranchReqData")
public Object getBranchReqData(@RequestParam(required=false) Integer num,
                                   @RequestParam(required=false) String module,
                                   @RequestParam(required=false) String ip) {
return JsonResult.create(homeService.getBranchReqData(num, module, ip));
    }
```

配置文件

**yaml**

```
pangu:
	swagger:
  	scan: "com.kingtsoft"
  	# 联系信息
		contactEmail: "cool@qq.com";
contactName: "金唐";
contactUrl: "https://www.kingtsoft.com/";
# 文档信息
infoTitle: "Swagger接口文档 DOC";
infoDescription: "更多请咨询服务开发者Jason";
infoVersion: "v1.0";
# 许可信息
licenseName: "MIT";
licenseUrl: "https://opensource.org/licenses/MIT";
# 拓展信息
extDocDescription: "外部文档";
extDocUrl: "https://www.google.com";
```

> #### 技术原理

```
    初始化默认配置，并开放部分属性自定义配置。并将扫描配置化。
```

**java**

```
package com.kingtsoft.pangu.spring.swagger;

/**
 * Title: <br>
 * Description: <br>
 * Company: KingTang <br>
 *
 * @author 金炀
 * @version 1.0
 */
@Import(SwaggerInterceptResponse.class)
@EnableConfigurationProperties(PgSwaggerProperties.class)
@Configuration
public class  Swagger3AutoConfiguration {

    @Bean
public OpenAPI springShopOpenApi(SpringDocConfigProperties springDocConfigProperties,
                                     PgSwaggerProperties pgSwaggerProperties) {
if (StringUtils.hasText(pgSwaggerProperties.getScan())) {
if (springDocConfigProperties.getPackagesToScan() ==null) {
                springDocConfigProperties.setPackagesToScan(List.of(pgSwaggerProperties.getScan()));
            } else {
                springDocConfigProperties.getPackagesToScan().add(pgSwaggerProperties.getScan());
            }
        }

returnnewOpenAPI()
                .info(info(pgSwaggerProperties))
// 添加对JWT对token的支持(本步骤可选) 在添加OpenApiConfig类上添加Components信息：然后在OpenApi中注册Components:
                .components(components())
                .externalDocs(externalDocumentation(pgSwaggerProperties));
    }

private License license() {
returnnewLicense()
                .name("MIT")
                .url("https://opensource.org/licenses/MIT");
    }

private Info info(PgSwaggerProperties pgSwaggerProperties) {
        Contact contact =newContact();
        contact.setEmail(pgSwaggerProperties.getContactEmail());
        contact.setName(pgSwaggerProperties.getContactName());
        contact.setUrl(pgSwaggerProperties.getContactUrl());
returnnewInfo()
                .title(pgSwaggerProperties.getInfoTitle())
                .description(pgSwaggerProperties.getInfoDescription())
                .contact(contact)
                .version(pgSwaggerProperties.getInfoVersion())
                .license(license());
    }

private ExternalDocumentation externalDocumentation(PgSwaggerProperties pgSwaggerProperties) {
returnnewExternalDocumentation()
                .description(pgSwaggerProperties.getExtDocDescription())
                .url(pgSwaggerProperties.getExtDocUrl());
    }

private Components components() {
returnnewComponents()
                .addSecuritySchemes(SwaggerConst.SECURITY_KEY,
newSecurityScheme()
                                .type(SecurityScheme.Type.HTTP)
                                .scheme("bearer")
                                .in(SecurityScheme.In.HEADER)
                                .name("Authorization")
                                .bearerFormat("JWT")
                );
    }

    @Bean
public OperationCustomizer addCustomGlobalHeader() {
return (Operation operation, HandlerMethod handlerMethod) -> {
            SecurityRequirement requirement =newSecurityRequirement().addList(SwaggerConst.SECURITY_KEY);
            operation.addSecurityItem(requirement);
return operation;
        };
    }
}
```

```
    SwaggerInterceptResponse，添加了自定义转换器。在不同编码环境中可能会使swagger
数据获取产生变动
```

**java**

```
package com.kingtsoft.pangu.spring.swagger;

/**
 * Title: <br>
 * Description: <br>
 * Company: KingTang <br>
 *
 * @author 金炀
 * @version 1.0
 */
@ConditionalOnProperty(value="pangu.swagger.api-convert", havingValue="true")
@ControllerAdvice(basePackages="org.springdoc.webmvc.api")
public class  SwaggerInterceptResponseimplementsResponseBodyAdvice<Object> {

    @Override
publicboolean  supports(@NonNull MethodParameter returnType,
                            @NonNull Class<?extends HttpMessageConverter<?>> converterType) {
returntrue;
    }

    @Override
public Object beforeBodyWrite(Object body,
                                  MethodParameter returnType,
                                  @NonNull MediaType selectedContentType,
                                  @NonNull Class<?extends HttpMessageConverter<?>> selectedConverterType,
                                  @NonNull ServerHttpRequest request,
                                  @NonNull ServerHttpResponse response) {
if (Objects.requireNonNull(returnType.getMethod()).getName().contains("openapiJson") &&
                selectedContentType.equals(MediaType.APPLICATION_JSON)) {
if (body instanceofbyte[]) {
return JsonUtil.jsonToMap(newString((byte[]) body, StandardCharsets.UTF_8));
            }
if (body instanceof String) {
return JsonUtil.jsonToMap(body.toString());
            }
        }
return body;
    }
}
```
