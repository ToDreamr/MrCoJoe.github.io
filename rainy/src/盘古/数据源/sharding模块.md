# Shardingsphere模块

> #### 如何使用

```
引入pangu-data-shardingjdbc模块
```

**xml**

```
<dependency>
  <groupId>com.kingtsoft.pangu</groupId>
  <artifactId>pangu-data-shardingjdbc</artifactId>
</dependency>
```

```
业务代码如下
```

**java**

```
@DS("mysql")
@Transactional(rollbackFor= Exception.class)
@ShardingTransactionType(TransactionType.BASE)
public Object testSeata() {
    log.info("当前 XID: {}", RootContext.getXID());

// 读写分离分页测试
    Page<OisRegSchedulePool> page =new Page<>(3, 1);
    IPage<OisRegSchedulePool> oisRegSchedulePools2 = oisRegSchedulePoolMapper.selectListPageRel(page, 1);

    PageInfo<OisRegSchedulePool> oisRegSchedulePools = PageHelper.startPage(1, 1)
            .doSelectPageInfo(() -> oisRegSchedulePoolMapper.selectListRel(1));

// 多数据源+读写分离+分布式事务测试
doInsert(7L);
   PubUser pubUser =newPubUser();
   pubUser.setModifyBy(1L);
   pubUser.setUserCode("999");
   pubUser.setPwd("123");
   pubUser.setState(1);
int i = pubUserMapper.insert(pubUser);

returntrue;
}
```

```
配置如下
```

**yaml**

```
spring:
shardingsphere:
# 参数配置，显示sql
props:
sql.show: true
# 配置数据源
datasource:
# 给每个数据源取别名，sys*
names: sys1,sys2
# 给master-sys1每个数据源配置数据库连接信息
sys1:
# 配置hikari数据源
type: com.zaxxer.hikari.HikariDataSource
driverClassName: com.mysql.cj.jdbc.Driver
jdbcUrl: jdbc:mysql://10.11.50.111:3306/kw_sys?characterEncoding=utf8&serverTimezone=Asia/Shanghai&allowMultiQueries=true
username: root
password: xxx
maxPoolSize: 100
minPoolSize: 5
# 配置sys2-slave
sys2:
type: com.zaxxer.hikari.HikariDataSource
driverClassName: com.mysql.cj.jdbc.Driver
jdbcUrl: jdbc:mysql://10.11.50.111:3306/kw_sys?characterEncoding=utf8&serverTimezone=Asia/Shanghai&allowMultiQueries=true
username: root
password: xxx
maxPoolSize: 100
minPoolSize: 5
# 配置默认数据源ds1
sharding:
# 配置数据源的读写分离，但是数据库一定要做主从复制
master-slave-rules:
# 配置主从名称，可以任意取名字
ms:
# 配置主库master，负责数据的写入
master-data-source-name: sys1
# 配置从库slave节点
slave-data-source-names: sys2
# 配置slave节点的负载均衡均衡策略，采用轮询机制
load-balance-algorithm-type: round_robin
# 默认数据源，主要用于写，注意一定要配置读写分离 ,注意：如果不配置，那么就会把三个节点都当做从slave节点，新增，修改和删除会出错。
default-data-source-name: ms
# 配置分表的规则
tables:
ois_reg_schedule_pool:
actual-data-nodes: ms.ois_reg_schedule_pool_$->{1..2}
table-strategy:
standard:
shardingColumn: pool_sn
preciseAlgorithmClassName: com.kingtsoft.pangu.data.shardingjdbc.SnPreciseShardingAlgorithm
```

```
    若需要配置seata支持，则需要在resource目录下配置seata.conf文件(很坑是一点是源码中它只会
去识别这个文件内的seata配置，不存在其他地方的配置读取)
```

```
client {
    application.id = pangu-frame-simple-a
    transaction.service.group = pg_tx_group
}
```

> #### 技术原理

```
    因为数据源我么已经选择使用pangu-data-dynamic进行托管，所以我们是在动态数据源
基础上再添加shardingjdbc，让shardingjdbc的数据源也作为动态数据源之一进行托管。
保证数据切面等操作情况下还能保证数据源正常切换及分布式事务的保证，它默认有个seata
事务模块为sharding-transaction-base-seata-at可以通过引用
pangu-data-shardingjdbc-seata获取功能。(核心配置如下)
```

**java**

```
package com.kingtsoft.pangu.data.shardingjdbc;

import com.baomidou.dynamic.datasource.DynamicRoutingDataSource;
import com.baomidou.dynamic.datasource.provider.AbstractDataSourceProvider;
import com.baomidou.dynamic.datasource.provider.DynamicDataSourceProvider;
import com.baomidou.dynamic.datasource.spring.boot.autoconfigure.DataSourceProperty;
import com.baomidou.dynamic.datasource.spring.boot.autoconfigure.DynamicDataSourceAutoConfiguration;
import com.baomidou.dynamic.datasource.spring.boot.autoconfigure.DynamicDataSourceProperties;
import org.springframework.boot.SpringBootConfiguration;
import org.springframework.boot.autoconfigure.AutoConfigureBefore;
import org.springframework.boot.autoconfigure.condition.ConditionalOnClass;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.context.annotation.Primary;

import javax.annotation.Resource;
import javax.sql.DataSource;
import java.util.Map;

/**
 * Title: <br>
 * Description: <br>
 * Company: KingTang <br>
 *
 * @author 金炀
 * @version 1.0
 */
@Configuration
@ConditionalOnClass(DynamicRoutingDataSource.class)
@AutoConfigureBefore({DynamicDataSourceAutoConfiguration.class, SpringBootConfiguration.class})
public class  DataSourceAutoConfiguration {

    /**
     * 动态数据源配置项
     */
    @Resource
private DynamicDataSourceProperties dynamicDataSourceProperties;

    /**
     * shardingjdbc有四种数据源，需要根据业务注入不同的数据源
     *
     * <p>1. 未使用分片, 脱敏的名称(默认): shardingDataSource;
     * <p>2. 主从数据源: masterSlaveDataSource;
     * <p>3. 脱敏数据源：encryptDataSource;
     * <p>4. 影子数据源：shadowDataSource
     *
     * shardingjdbc默认就是shardingDataSource
     *  如果需要设置其他的可以使用
     * @Resource(value="") 设置
     */
    @Resource
    DataSource shardingDataSource;

    /**
     * 将shardingDataSource放到了多数据源（dataSourceMap）中
     * 注意有个版本的bug，3.1.1版本 不会进入loadDataSources 方法，这样就一直造成数据源注册失败
     *
     * @author 金炀
     */
    @Bean
public DynamicDataSourceProvider dynamicDataSourceProvider() {
        Map<String, DataSourceProperty> datasourceMap = dynamicDataSourceProperties.getDatasource();
returnnewAbstractDataSourceProvider() {
            @Override
public Map<String, DataSource> loadDataSources() {
                Map<String, DataSource> dataSourceMap =createDataSourceMap(datasourceMap);
// 将 shardingjdbc 管理的数据源也交给动态数据源管理
                dataSourceMap.put(ShardingConst.SHARDING_DATA_SOURCE_NAME, shardingDataSource);
return dataSourceMap;
            }
        };
    }

    /**
     * 将动态数据源设置为首选的
     * 当spring存在多个数据源时, 自动注入的是首选的对象
     * 设置为主要的数据源之后，就可以支持shardingjdbc原生的配置方式了
     *
     * @return sharding 数据源
     * @author 金炀
     */
    @Primary
    @Bean
public DataSource dataSource() {
        DynamicRoutingDataSource dataSource =newDynamicRoutingDataSource();
        dataSource.setPrimary(dynamicDataSourceProperties.getPrimary());
        dataSource.setStrict(dynamicDataSourceProperties.getStrict());
        dataSource.setStrategy(dynamicDataSourceProperties.getStrategy());
        dataSource.setP6spy(dynamicDataSourceProperties.getP6spy());
        dataSource.setSeata(dynamicDataSourceProperties.getSeata());
return dataSource;
    }
}
```

```
    preciseAlgorithmClassName配置为分片原则，可以仿造下面案例进行自定义，
比如 poolSn <= 100 ? "1" : "2";这里100为业务规则，1与2为表名规则，数据库
内分别有ois_reg_schedule_pool_1与ois_reg_schedule_pool_2表，可以根据
结果的1或2决定操作哪张表
```

**java**

```
package com.kingtsoft.pangu.data.shardingjdbc;

import lombok.extern.slf4j.Slf4j;
import org.apache.shardingsphere.api.sharding.standard.PreciseShardingAlgorithm;
import org.apache.shardingsphere.api.sharding.standard.PreciseShardingValue;

import java.text.NumberFormat;
import java.util.Calendar;
import java.util.Collection;
import java.util.Date;

/**
* Title: <br>
* Description: <br>
* Company: KingTang <br>
*
* @author 金炀
* @version 1.0
*/
@Slf4j
public class  SnPreciseShardingAlgorithmimplementsPreciseShardingAlgorithm<long > {

        @Override
public String doSharding(Collection<String> availableTargetNames, PreciseShardingValue<long > preciseShardingValue) {
            long  poolSn = preciseShardingValue.getValue();

// TODO
            String flag = poolSn <=100?"1":"2";
for (String tableName : availableTargetNames) {
                String tableSuffix = tableName.substring(tableName.lastIndexOf("_") +1);
if (tableSuffix.equals(flag)) {
return tableName;
                }
            }
thrownewIllegalArgumentException("未找到匹配的数据表");
        }

privatestatic String getSuffixByYearMonth(Date date) {
            NumberFormat nf = NumberFormat.getInstance();
            nf.setMinimumIntegerDigits(2);
            Calendar calendar = Calendar.getInstance();
            calendar.setTime(date);
return calendar.get(Calendar.YEAR)  +""+  nf.format((calendar.get(Calendar.MONTH) +1));
        }
    }
```
