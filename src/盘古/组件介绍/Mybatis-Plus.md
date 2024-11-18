# MybatisPlus模块

> #### 如何使用

**逆向工具**

```
官方有个逆向项目，提供逆向文件的生成、下载
官方网址：
```

[https://github.com/baomidou/generator](https://github.com/baomidou/generatorhttp://pangu.jasonandhank.cn/mybatisplus-generator/#/)

```
公司地址：
```

[http://pangu.jasonandhank.cn/mybatisplus-generator/#/](https://github.com/baomidou/generatorhttp://pangu.jasonandhank.cn/mybatisplus-generator/#/)（支持lombok，且逆向swagger文件中，实体为3.0规范）

**业务引用**

```
引入业务包
```

**xml**

```
<dependency>
  <groupId>com.kingtsoft.pangu</groupId>
  <artifactId>pangu-data-mybatisplus</artifactId>
  <version>${pangu.version}</version>
</dependency>
```

```
   按照以前常规DAO的形式引入mapper，然后内部需要自定义方法的时候，可以利用接口默认实
现的方式，在里面完成查询逻辑的撰写组装，避免查询逻辑与业务逻辑混淆 注意若要使用类似
deleteById 之类的方法，需要在实体内通过@TableId指定Key才行。(此包会自动打印
info级别的SQL日志)
```

**java**

```
private final   OisRegSchedulePoolMapper oisRegSchedulePoolMapper;

@DSTransactional
public Object testMybatis() {
    List<OisRegSchedulePool> oisRegSchedulePools = oisRegSchedulePoolMapper.testXml(1);
    List<long > snList = oisRegSchedulePoolMapper.testXml2(1);
    OisRegSchedulePool oisRegSchedulePool =newOisRegSchedulePool();
    oisRegSchedulePool.setPoolSn(1L);
    oisRegSchedulePool.setPoolCode("010");
    oisRegSchedulePoolMapper.updateAuto(oisRegSchedulePool);
return123;
}
```

```
    mapper如下兼容xml的使用及java语法组织的形式执行SQL，若使用xml请确保xml可以被编译保留。
```

**java**

```
package com.kingtsoft.pangu.frame.simple.test.mapper;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.core.conditions.update.LambdaUpdateWrapper;
import  com.kingtsoft.pangu.data.mybatisplus.PgBaseMapper;
import com.baomidou.mybatisplus.core.metadata.IPage;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.kingtsoft.pangu.frame.simple.test.model.OisRegSchedulePool;
import org.apache.ibatis.annotations.Param;

import java.util.List;

/**
* Title: <br>
* Description: <br>
* Company: KingTang <br>
*
* @author 金炀
* @version 1.0
*/
public interface  OisRegSchedulePoolMapperextendsPgBaseMapper<OisRegSchedulePool> {

default List<OisRegSchedulePool> selectListRel(Integer state) {
returnthis.selectList(new LambdaQueryWrapper<OisRegSchedulePool>()
                               .eq(OisRegSchedulePool::getState, state)
                               .exists("select 1 from ois_reg_schedule where state = 1 ")
                              );
    }

default IPage<OisRegSchedulePool> selectListPageRel(Page<OisRegSchedulePool> page, Integer state) {
returnthis.selectPage(page, new LambdaQueryWrapper<OisRegSchedulePool>()
                               .eq(OisRegSchedulePool::getState, state));
    }

    List<OisRegSchedulePool> testXml(@Param("state") Integer state);

    List<long > testXml2(@Param("state") Integer state);

defaultintupdateAuto(OisRegSchedulePool oisRegSchedulePool) {
returnthis.update(oisRegSchedulePool, new LambdaUpdateWrapper<OisRegSchedulePool>()
                           .eq(OisRegSchedulePool::getPoolSn, oisRegSchedulePool.getPoolSn()));
    }
}
```

```
    pom如下配置，src下的xml将保留，不然会被去除掉。
```

**java**

```
<build>
<resources>
<resource>
<directory>src/main/java</directory>
<includes>
<include>**/*.xml</include>
            </includes>
        </resource>
    </resources>
</build>
```

```
    扫描以如下配置文件的形式配置（当然也可以使用注解），xml与mapper放一起，xml扫描可以不加
```

**yaml**

```
pangu:
mybatis-plus:
# 扫描路径
mapper-scanner: 'com.kingtsoft.**.mapper*'


mybatis-plus:
	# mapper.xml文件位置，如果与mapper在同一目录也不需要加，如果没有映射文件，请注释掉。
mapper-locations: classpath:com/kingtsoft/**/mapper/*.xml
```

> #### 技术原理

```
   根据源码的扫描实现，因为默认是通过注解的形式进行扫描的，而注解会基于类，而pangu启
动器无法统一类信息，不能做到通用性，所有对路径的扫描改为了配置文件。
```

**java**

```
publicstaticclassMapperScannerRegistrarimplementsImportBeanDefinitionRegistrar, EnvironmentAware, Ordered {

private Environment environment;

        @Override
private void   registerBeanDefinitions(AnnotationMetadata importingClassMetadata, BeanDefinitionRegistry registry) {
            String packages = environment.getProperty("pangu.mybatis-plus.mapper-scanner");
if (!StringUtils.hasText(packages)) {
return;
            }

            BeanDefinitionBuilder builder = BeanDefinitionBuilder.genericBeanDefinition(MapperScannerConfigurer.class);
            builder.addPropertyValue("processPropertyPlaceHolders", true);
            builder.addPropertyValue("basePackage", packages);
            BeanWrapper beanWrapper =newBeanWrapperImpl(MapperScannerConfigurer.class);
            Set<String> propertyNames = Stream.of(beanWrapper.getPropertyDescriptors()).map(PropertyDescriptor::getName)
                    .collect(Collectors.toSet());
if (propertyNames.contains("lazyInitialization")) {
// Need to mybatis-spring 2.0.2+
// TODO 兼容了mybatis.lazy-initialization配置
                builder.addPropertyValue("lazyInitialization", "${mybatis-plus.lazy-initialization:${mybatis.lazy-initialization:false}}");
            }
if (propertyNames.contains("defaultScope")) {
// Need to mybatis-spring 2.0.6+
                builder.addPropertyValue("defaultScope", "${mybatis-plus.mapper-default-scope:}");
            }
            registry.registerBeanDefinition(MapperScannerConfigurer.class.getName(), builder.getBeanDefinition());
        }

        @Override
private void   setEnvironment(Environment environment) {
this.environment = environment;
        }

        @Override
publicintgetOrder() {
return Ordered.HIGHEST_PRECEDENCE +9;
        }
    }
```

```
    默认的语法中还缺少了对数据的批量操作，所以通过mybatisplus的AbstractSqlInjector
注入器，可以预先通过方法配置的方式，动态生成xml文件内容，并且设计了PgBaseMapper作为方法
载体进行了拓展，并且可以根据方言配置兼容oracle与mysql版本。
```

**java**

```
public class  EasySqlInjectorextendsDefaultSqlInjector {

private final   MybatisPlusProperties mybatisPlusProperties;

publicEasySqlInjector(MybatisPlusProperties mybatisPlusProperties) {
this.mybatisPlusProperties = mybatisPlusProperties;
    }

    @Override
public List<AbstractMethod> getMethodList(Class<?> mapperClass, TableInfo tableInfo) {
        List<AbstractMethod> methodList =super.getMethodList(mapperClass, tableInfo);
        String dbType = mybatisPlusProperties.getDbType();
if (StringUtils.hasText(dbType) && DbType.ORACLE.equals(DbType.getDbType(dbType))) {
            methodList.add(newOracleInsertBatchMethod());
            methodList.add(newOracleUpdateBatchMethod());
        } else {
            methodList.add(newInsertBatchSomeColumn());
            methodList.add(newUpdateBatchMethod());
        }

        methodList.add(newLogicDeleteBatchByIds());
        methodList.add(newAlwaysUpdateSomeColumnById());
return methodList;
    }
}

public interface  PgBaseMapper<T> extendsBaseMapper<T> {

    /**
     * 批量插入
     *
     * @paramcollection 数据集合
     * @return 插入条数
     * @author 金炀
     */
intinsertBatchSomeColumn(Collection<T> collection);

    /**
     * 批量插入
     *
     * @paramcollection 数据集合
     * @paramnum        每组个数
     * @author 金炀
     */
defaultvoidinsertBatchSomeColumnAverage(Collection<T> collection, intnum) {
if (num <=0) {
thrownewRuntimeException("每组个数必须大于0!");
        }
        List<List<T>> subSets =averageAssign(new ArrayList<>(collection), num);
for (int i =0; i < subSets.size(); i++) {
int i2 =insertBatchSomeColumn(subSets.get(i));
if (i2 != subSets.get(i).size()) {
thrownewRuntimeException("批量更新失败! 组号: "+ i);
            }
        }
    }

    /**
     * 批量更新
     *
     * @paramcollection 数据集合
     * @return 是否成功
     * @author 金炀
     */
intupdateBatch(@Param("collection") Collection<T> collection);

    /**
     * 批量更新
     *
     * @paramcollection 数据集合
     * @paramnum        每组个数
     * @author 金炀
     */
defaultvoidupdateBatchAverage(Collection<T> collection, intnum) {
if (num <=0) {
thrownewRuntimeException("每组个数必须大于0!");
        }
        List<List<T>> subSets =averageAssign(new ArrayList<>(collection), num);
for (int i =0; i < subSets.size(); i++) {
int i2 =updateBatch(subSets.get(i));
if (i2 !=1) {
thrownewRuntimeException("批量更新失败! 组号: "+ i);
            }
        }
    }

    /**
     * 更新可置空
     *
     * @paramentity 更新实体
     * @return 是否成功
     * @author 金炀
     */
intalwaysUpdateSomeColumnById(@Param("et") T entity);

    /**
     * 集合分组
     *
     * @paramsource       源集合
     * @paramsplitItemNum 每组个数
     * @return 分组后集合
     * @author 金炀
     */
private <T> List<List<T>> averageAssign(List<T> source, intsplitItemNum) {
        List<List<T>> result =new ArrayList<>();

if (source !=null&& source.size() >0&& splitItemNum >0) {
if (source.size() <= splitItemNum) {
// 源List元素数量小于等于目标分组数量
                result.add(source);
            } else {
// 计算拆分后list数量
int splitNum = (source.size() % splitItemNum ==0) ? (source.size() / splitItemNum) : (source.size() / splitItemNum +1);

                List<T> value;
for (int i =0; i < splitNum; i++) {
if (i < splitNum -1) {
                        value = source.subList(i * splitItemNum, (i +1) * splitItemNum);
                    } else {
// 最后一组
                        value = source.subList(i * splitItemNum, source.size());
                    }
                    result.add(value);
                }
            }
        }
return result;
    }
}
```

```
   mybatis自身还支持了org.apache.ibatis.plugin.Interceptor 拦截器配置，
通过此配置，将任何持久层操作都可以进行拦截，并且根据结构体转译成实际SQL，并进行
打印或者跟踪。
```
