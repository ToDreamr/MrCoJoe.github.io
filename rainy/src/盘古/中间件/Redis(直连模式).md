# Redis模块（直连模式）

> #### 如何使用

```
引入模块
```

**xml**

```
<dependency>
  <groupId>com.kingtsoft.pangu</groupId>
  <artifactId>pangu-data-redis</artifactId>
  <version>${pangu.version}</version>
</dependency>
```

```
以下为使用案例
    accessSpeedLimit 			访问限定器
    DistributedLockTemplate 	分布式锁工具
    DistributedReentrantLock 	分布式重入锁工具
    SequenceTemplate 			序列生成工具
```

**java**

```
/**
 * Title: <br>
 * Description: <br>
 * Company: KingTang <br>
 *
 * @author 金炀
 * @version 1.0
 */
@Slf4j
@ExtendWith({SpringExtension.class})
@AutoConfigureMockMvc
@SpringBootTest(classes= {PanguBoot.class})
public class  RedisTest {

    @Autowired
private AccessSpeedLimit accessSpeedLimit;

    @Autowired
    @Qualifier("redisDefaultTemplate")
private RedisTemplate<String, Object> redisTemplate;

    @ParameterizedTest
    @ValueSource(strings= {"test"})
private void   testTran(String test) throws Exception {
        SimpleDateFormat sdf =newSimpleDateFormat(" mm:ss");
while (true) {
//10.0.0.1这个ip每1秒钟最多访问5次if块内代码
if (accessSpeedLimit.tryAccess("10.0.0.1", 1, 5)) {
                System.out.println("yes"+ sdf.format(newDate()));
            } else {
                System.out.println("no"+ sdf.format(newDate()));
            }
            Thread.sleep(100);
        }
    }

    @Autowired
private DistributedLockTemplate template;

    @ParameterizedTest
    @ValueSource(strings= {"test"})
private void   testLock(String test) {
//本类线程安全,可通过spring注入
//获取锁超时时间为5秒
        template.execute("订单流水号", 5000, newCallback() {
            @Override
public Object onGetLock() {
//TODO 获得锁后要做的事
returnnull;
            }

            @Override
public Object onTimeout() {
//TODO 获得锁超时后要做的事
returnnull;
            }
        });
    }

    @ParameterizedTest
    @ValueSource(strings= {"test"})
private void   testLock2(String test) {
        DistributedReentrantLock lock =newRedisReentrantLock(redisTemplate, "订单流水号");
try {
if (lock.tryLock(5000L, TimeUnit.MILLISECONDS)) {//获取锁超时时间为5秒
//TODO 获得锁后要做的事
                System.out.println("getLock");
            } else {
//TODO 获得锁超时后要做的事
            }
        } finally {
            lock.unlock();
        }
    }

    @Autowired
private SequenceTemplate sequenceTemplate;

    @ParameterizedTest
    @ValueSource(strings= {"test"})
private void   testSeq(String test) {
        long  ret = sequenceTemplate.sequence("cis_id", 10000L);
        System.out.println(ret);
    }
}
```

> PgRedisTemplate工具

**java**

```
package com.kingtsoft.pangu.data.redis;

import org.springframework.data.redis.core.*;

import java.util.*;
import java.util.concurrent.TimeUnit;

/**
 * Title: <br>
 * Description: <br>
 * Company: KingTang <br>
 *
 * @author 金炀
 * @version 1.0
 */
public class  PgRedisTemplate<K, V> extendsRedisTemplate<K, V> {

privatestaticfinal TimeUnit DEFAULT_TIME_UNIT = TimeUnit.SECONDS;

    /**
     * 根据key 获取过期时间
     *
     * @paramkey 键 不能为null
     * @return 时间(秒) 返回0代表为永久有效，-2代表键不存在
     */
publiclong getExpireTime(K key) {
        long  expire =this.getExpire(key, DEFAULT_TIME_UNIT);
if (expire !=null) {
return expire;
        }
return-2;
    }

    /**
     * 指定缓存失效时间
     *
     * @paramkey        键
     * @paramexpireTime 时间(秒)
     */
public boolean   setExpireTime(K key, long expireTime) {
if (expireTime >0) {
returnthis.expire(key, expireTime, DEFAULT_TIME_UNIT);
        }
thrownewRuntimeException("过期时间必须大于0");
    }

    /**
     * 移除指定 key 的过期时间
     *
     * @paramkey 键
     */
private void   removeExpireTime(K key) {
this.boundValueOps(key).persist();
    }

    /**
     * 设置分布式锁
     *
     * @paramkey    键，可以用用户主键
     * @paramvalue  值，可以传requestId，可以保证锁不会被其他请求释放，增加可靠性
     * @paramexpire 锁的时间(秒)
     * @return 设置成功为 true
     */
public boolean   setNx(K key, V value, long expire) {
returnthis.opsForValue().setIfAbsent(key, value, expire, DEFAULT_TIME_UNIT);
    }

    /**
     * 设置分布式锁，有等待时间
     *
     * @paramkey     键，可以用用户主键
     * @paramvalue   值，可以传requestId，可以保证锁不会被其他请求释放，增加可靠性
     * @paramexpire  锁的时间(秒)
     * @paramtimeout 在timeout时间内仍未获取到锁，则获取失败
     * @return 设置成功为 true
     */
public boolean   setNx(K key, V value, long expire, long timeout) {
long  start = System.currentTimeMillis();
//在一定时间内获取锁，超时则返回错误
for (; ; ) {
// 获取到锁，并设置过期时间返回true
if (boolean  .TRUE.equals(this.opsForValue().setIfAbsent(key, value, expire, DEFAULT_TIME_UNIT))) {
returntrue;
            }
//否则循环等待，在timeout时间内仍未获取到锁，则获取失败
if (System.currentTimeMillis() - start > timeout) {
returnfalse;
            }
        }
    }

    /**
     * 释放分布式锁
     *
     * @paramkey   锁
     * @paramvalue 值，可以传requestId，可以保证锁不会被其他请求释放，增加可靠性
     * @return 成功返回true, 失败返回false
     */
publicboolean  releaseNx(K key, V value) {
        Object currentValue =this.opsForValue().get(key);
if (String.valueOf(currentValue) !=null&& value.equals(currentValue)) {
return boolean  .TRUE.equals(this.opsForValue().getOperations().delete(key));
        }
returnfalse;
    }

    /**
     * 普通缓存放入
     *
     * @paramkey   键
     * @paramvalue 值
     */
private void   set(K key, V value) {
this.opsForValue().set(key, value);
    }

    /**
     * 普通缓存放入并设置时间
     *
     * @paramkey   键
     * @paramvalue 值
     * @paramtime  时间(秒) time要大于0 如果time小于等于0 将设置无限期
     */
private void   set(K key, V value, long time) {
if (time >0) {
this.opsForValue().set(key, value, time, DEFAULT_TIME_UNIT);
        } else {
this.opsForValue().set(key, value);
        }
    }

    /**
     * value增加值
     *
     * @paramkey    键
     * @paramnumber 增加的值
     * @return 返回增加后的值
     */
public long  incrBy(String key, long number) {
return (long ) this.execute((RedisCallback<Object>) connection -> connection.incrBy(key.getBytes(), number));
    }

    /**
     * value减少值
     *
     * @paramkey    键
     * @paramnumber 减少的值
     * @return 返回减少后的值
     */
public long  decrBy(String key, long number) {
return (long ) this.execute((RedisCallback<Object>) connection -> connection.decrBy(key.getBytes(), number));
    }

    /**
     * 根据key获取value
     *
     * @paramkey 键
     * @return 返回值
     */
public V get(K key) {
        BoundValueOperations<K, V> boundValueOperations =this.boundValueOps(key);
return boundValueOperations.get();
    }

// list 类型操作

    /**
     * 将value从右边放入缓存
     *
     * @paramkey   键
     * @paramvalue 值
     */
private void   listRightPush(K key, V value) {
        ListOperations<K, V> listOperations =this.opsForList();
//从队列右插入
        listOperations.rightPush(key, value);
    }

    /**
     * 将value从左边放入缓存
     *
     * @paramkey   键
     * @paramvalue 值
     */
private void   listLeftPush(K key, V value) {
        ListOperations<K, V> listOperations =this.opsForList();
//从队列右插入
        listOperations.leftPush(key, value);
    }

    /**
     * 将list从右边放入缓存
     *
     * @paramkey   键
     * @paramvalue 值
     */
public long  listRightPushAll(K key, List<V> value) {
returnthis.opsForList().rightPushAll(key, value);
    }

    /**
     * 将list从左边放入缓存
     *
     * @paramkey   键
     * @paramvalue 值
     */
public long  listLeftPushAll(K key, List<V> value) {
returnthis.opsForList().leftPushAll(key, value);
    }

    /**
     * 通过索引 获取list中的值
     *
     * @paramkey   键
     * @paramindex 索引 index>=0时， 0 表头，1 第二个元素，依次类推；index<0时，-1，表尾，-2倒数第二个元素，依次类推
     * @return 返回列表中的值
     */
public V listGetWithIndex(K key, long index) {
        ListOperations<K, V> listOperations =this.opsForList();
return listOperations.index(key, index);
    }

    /**
     * 从list左边弹出一条数据
     *
     * @paramkey 键
     * @return 队列中的值
     */
public V listLeftPop(K key) {
        ListOperations<K, V> listOperations =this.opsForList();
return listOperations.leftPop(key);
    }

    /**
     * 从list左边定时弹出一条
     *
     * @paramkey     键
     * @paramtimeout 弹出时间
     * @paramunit    时间单位
     * @return 队列中的值
     */
public V listLeftPop(K key, long timeout, TimeUnit unit) {
        ListOperations<K, V> listOperations =this.opsForList();
return listOperations.leftPop(key, timeout, unit);
    }

    /**
     * 从list右边弹出一条数据
     *
     * @paramkey 键
     * @return 队列中的值
     */
public V listRightPop(K key) {
        ListOperations<K, V> listOperations =this.opsForList();
return listOperations.rightPop(key);
    }

    /**
     * 从list左边定时弹出
     *
     * @paramkey     键
     * @paramtimeout 弹出时间
     * @paramunit    时间单位
     * @return 队列中的值
     */
public V listRightPop(K key, long timeout, TimeUnit unit) {
        ListOperations<K, V> listOperations =this.opsForList();
return listOperations.leftPop(key, timeout, unit);
    }

    /**
     * 获取list缓存的内容
     *
     * @paramkey   键
     * @paramstart 开始下标
     * @paramend   结束下标  0 到 -1 代表所有值
     * @return list内容
     */
public List<V> listRange(K key, long start, long end) {
        ListOperations<K, V> listOperations =this.opsForList();
return listOperations.range(key, start, end);
    }

    /**
     * 获取list缓存的长度
     *
     * @paramkey 键
     * @return list长度
     */
publiclong listSize(K key) {
        long  size =this.opsForList().size(key);
return Objects.requireNonNullElse(size, 0).long Value();
    }

    /**
     * 根据索引修改list中的某条数据
     *
     * @paramkey   键
     * @paramindex 下标
     * @paramvalue 值
     */
private void   listSet(K key, long index, V value) {
this.opsForList().set(key, index, value);
    }

    /**
     * 从lit中移除N个值为value的值
     *
     * @paramkey   键
     * @paramcount 移除多少个
     * @paramvalue 值
     * @return 移除的个数
     */
publiclong listRemove(K key, long count, V value) {
        long  count1 =this.opsForList().remove(key, count, value);
if (count1 !=null) {
return count1;
        }
return0;
    }

// hash 类型操作

    /**
     * 根据key和键获取value
     *
     * @paramkey  键 不能为null
     * @paramitem 项 不能为null
     * @return 值
     */
public <HK, HV> HV hashGet(K key, String item) {
        HashOperations<K, HK, HV> hashOperations =this.opsForHash();
return hashOperations.get(key, item);
    }

    /**
     * 获取key对应的所有键值
     *
     * @paramkey 键
     * @return 对应的多个键值
     */
public <HK, HV> Map<HK, HV> hashMultiGet(K key) {
        HashOperations<K, HK, HV> hashOperations =this.opsForHash();
return hashOperations.entries(key);
    }

    /**
     * 添加map到hash中
     *
     * @paramkey 键
     * @parammap 对应多个键值
     */
private void   hashMultiSet(K key, Map<String, Object> map) {
this.opsForHash().putAll(key, map);
    }

    /**
     * 添加map到hash中，并设置过期时间
     *
     * @paramkey        键
     * @parammap        对应多个键值
     * @paramexpireTime 时间(秒)
     */
private void   hashMultiSet(K key, Map<String, Object> map, long expireTime) {
this.opsForHash().putAll(key, map);
if (expireTime >0) {
this.expire(key, expireTime, DEFAULT_TIME_UNIT);
        }
    }

    /**
     * 向hash表中放入一个数据
     *
     * @paramkey   键
     * @paramhKey  map 的键
     * @paramvalue 值
     */
public <HK, HV> voidhashPut(K key, HK hKey, HV value) {
        HashOperations<K, HK, HV> hashOperations =this.opsForHash();
        hashOperations.put(key, hKey, value);
    }

    /**
     * 向hash表中放入一个数据，并设置过期时间
     *
     * @paramkey        键
     * @paramhKey       map 的键
     * @paramvalue      值
     * @paramexpireTime 时间(秒) 注意:如果已存在的hash表有时间,这里将会替换原有的时间
     */
public <HK, HV> voidhashPut(K key, HK hKey, HV value, long expireTime) {
this.opsForHash().put(key, hKey, value);
if (expireTime >0) {
this.expire(key, expireTime, DEFAULT_TIME_UNIT);
        }
    }

    /**
     * 判断hash表中是否有该项的值
     *
     * @paramkey  键 不能为null
     * @paramhKey map 的键 不能为null
     * @return true 存在 false不存在
     */
public <HK, HV> boolean  hashHasKey(K key, HK hKey) {
        HashOperations<K, HK, HV> hashOperations =this.opsForHash();
return hashOperations.hasKey(key, hKey);
    }

    /**
     * 取出所有 value
     *
     * @paramkey 键
     * @return map 中所有值
     */
public <HK, HV> List<HV> hashValues(K key) {
        HashOperations<K, HK, HV> hashOperations =this.opsForHash();
return hashOperations.values(key);
    }

    /**
     * 取出所有 hKey
     *
     * @paramkey 键
     * @return map 所有的键
     */
public <HK, HV> Set<HK> hashHKeys(K key) {
        HashOperations<K, HK, HV> hashOperations =this.opsForHash();
return hashOperations.keys(key);
    }

    /**
     * 删除hash表中的键值，并返回删除个数
     *
     * @paramkey      键
     * @paramhashKeys 要删除的值的键
     * @return 删除个数
     */
public <HK, HV> long  hashDelete(K key, Object... hashKeys) {
        HashOperations<K, HK, HV> hashOperations =this.opsForHash();
return hashOperations.delete(key, hashKeys);
    }

// set 类型操作

    /**
     * 将数据放入set缓存
     *
     * @paramkey    键
     * @paramvalues 值 可以是多个
     */
    @SafeVarargs
publicfinal long  setAdd(K key, V... values) {
returnthis.opsForSet().add(key, values);
    }

    /**
     * 将set数据放入缓存，并设置过期时间
     *
     * @paramkey        键
     * @paramexpireTime 时间(秒)
     * @paramvalues     值 可以是多个
     */
    @SafeVarargs
publicfinal long  setAdd(K key, long expireTime, V... values) {
        long  ret =this.opsForSet().add(key, values);
if (expireTime >0) {
this.expire(key, expireTime, DEFAULT_TIME_UNIT);
        }
return ret;
    }

    /**
     * 获取set缓存的长度
     *
     * @paramkey 键
     * @return set缓存的长度
     */
publiclong setSize(K key) {
        long  size =this.opsForSet().size(key);
if (size !=null) {
return size;
        }
return0;
    }

    /**
     * 根据key获取Set中的所有值
     *
     * @paramkey 键
     * @return Set中的所有值
     */
public Set<V> setValues(K key) {
        SetOperations<K, V> setOperations =this.opsForSet();
return setOperations.members(key);
    }

    /**
     * 根据value从一个set中查询,是否存在
     *
     * @paramkey   键
     * @paramvalue 要查询的值
     * @return true 存在 false不存在
     */
publicboolean  setHasKey(K key, V value) {
return boolean  .TRUE.equals(this.opsForSet().isMember(key, value));
    }

    /**
     * 根据value删除，并返回删除的个数
     *
     * @paramkey   键
     * @paramvalue 要删除的值
     * @return 删除的个数
     */
public long  setDelete(K key, Object... value) {
        SetOperations<K, V> setOperations =this.opsForSet();
return setOperations.remove(key, value);
    }

// zset 类型操作

    /**
     * 在 zset中插入一条数据
     *
     * @paramkey   键
     * @paramvalue 要插入的值
     * @paramscore 设置分数
     */
private void   zSetAdd(K key, V value, long score) {
        ZSetOperations<K, V> zSetOperations =this.opsForZSet();
        zSetOperations.add(key, value, score);
    }

    /**
     * 得到分数在 score1，score2 之间的值
     *
     * @paramkey    键
     * @paramscore1 起始分数
     * @paramscore2 终止分数
     * @return 范围内所有值
     */
public Set<V> zSetValuesRange(K key, long score1, long score2) {
        ZSetOperations<K, V> zSetOperations =this.opsForZSet();
return zSetOperations.range(key, score1, score2);
    }

    /**
     * 根据value删除，并返回删除个数
     *
     * @paramkey   键
     * @paramvalue 要删除的值，可传入多个
     * @return 删除个数
     */
public long  zSetDeleteByValue(K key, Object... value) {
        ZSetOperations<K, V> zSetOperations =this.opsForZSet();
return zSetOperations.remove(key, value);
    }

    /**
     * 根据下标范围删除，并返回删除个数
     *
     * @paramkey   键
     * @paramsize1 起始下标
     * @paramsize2 结束下标
     * @return 删除个数
     */
public long  zSetDeleteRange(K key, long size1, long size2) {
        ZSetOperations<K, V> zSetOperations =this.opsForZSet();
return zSetOperations.removeRange(key, size1, size2);
    }

    /**
     * 删除分数区间内元素，并返回删除个数
     *
     * @paramkey    键
     * @paramscore1 起始分数
     * @paramscore2 终止分数
     * @return 删除个数
     */
public long  zSetDeleteByScore(K key, long score1, long score2) {
        ZSetOperations<K, V> zSetOperations =this.opsForZSet();
return zSetOperations.removeRangeByScore(key, score1, score2);
    }
}
```

> 常用方法

**java**

```
redisTemplate.hasKey(key);				//判断是否有key所对应的值，有则返回true，没有则返回false
redisTemplate.opsForValue().get(key);	//有则取出key值所对应的值
redisTemplate.delete(key);				//删除单个key值
redisTemplate.delete(keys); 			//其中keys:Collection<K> keys
redisTemplate.dump(key);				//将当前传入的key值序列化为byte[]类型
redisTemplate.expire(key, timeout, unit);	//设置过期时间
redisTemplate.expireAt(key, date);		//设置过期时间
redisTemplate.keys(pattern);			//查找匹配的key值，返回一个Set集合类型
redisTemplate.rename(oldKey, newKey);	//返回传入key所存储的值的类型
redisTemplate.renameIfAbsent(oldKey, newKey);	//如果旧值存在时，将旧值改为新值
redisTemplate.randomKey();				//从redis中随机取出一个key
redisTemplate.getExpire(key);			//返回当前key所对应的剩余过期时间
redisTemplate.getExpire(key, unit);		//返回剩余过期时间并且指定时间单位
redisTemplate.persist(key);				//将key持久化保存
redisTemplate.move(key, dbIndex);		//将当前数据库的key移动到指定redis中数据库当中
```

> String类型

**java**

```
opsForValue.set(key, value);					//设置当前的key以及value值
opsForValue.set(key, value, offset);			//用 value 参数覆写给定 key 所储存的字符串值，从偏移量 offset 开始
opsForValue.set(key, value, timeout, unit);	 	//设置当前的key以及value值并且设置过期时间
opsForValue.setBit(key, offset, value);		 	//将二进制第offset位值变为value
opsForValue.setIfAbsent(key, value);			//重新设置key对应的值，如果存在返回false，否则返回true
opsForValue.get(key, start, end);				//返回key中字符串的子字符
opsForValue.getAndSet(key, value);				//将旧的key设置为value，并且返回旧的key
opsForValue.multiGet(keys);						//批量获取值
opsForValue.size(key);							//获取字符串的长度
opsForValue.append(key, value);					//在原有的值基础上新增字符串到末尾
opsForValue.increment(key,double increment);	//以增量的方式将double值存储在变量中
opsForValue.increment(key,long   increment);		//通过increment(K key, long  delta)方法以增量方式存储long 值（正值则自增，负值则自减）

Map valueMap =newHashMap();  
valueMap.put("valueMap1","map1");  
valueMap.put("valueMap2","map2");  
valueMap.put("valueMap3","map3");  
opsForValue.multiSetIfAbsent(valueMap); 		//如果对应的map集合名称不存在，则添加否则不做修改
opsForValue.multiSet(valueMap);					//设置map集合到redis
```

> Hash类型

**java**

```
opsForHash.get(key, field);				//获取变量中的指定map键是否有值,如果存在该map键则获取值，没有则返回null
opsForHash.entries(key);				//获取变量中的键值对
opsForHash.put(key, hashKey, value);	//新增hashMap值
opsForHash.putAll(key, maps);			//以map集合的形式添加键值对
opsForHash.putIfAbsent(key, hashKey, value);	//仅当hashKey不存在时才设置
opsForHash.delete(key, fields);			//删除一个或者多个hash表字段
opsForHash.hasKey(key, field);			//查看hash表中指定字段是否存在
opsForHash.increment(key, field, long  increment);	//给哈希表key中的指定字段的整数值加上增量increment
opsForHash.increment(key, field, double increment);	//给哈希表key中的指定字段的整数值加上增量increment
opsForHash.keys(key);					//获取所有hash表中字段
opsForHash.values(key);					//获取hash表中存在的所有的值
opsForHash.scan(key, options);			//匹配获取键值对，ScanOptions.NONE为获取全部键对
```

> List类型

**java**

```
opsForList.index(key, index);				//通过索引获取列表中的元素
opsForList.range(key, start, end);			//获取列表指定范围内的元素(start开始位置, 0是开始位置，end 结束位置, -1返回所有)
opsForList.leftPush(key, value);			//存储在list的头部，即添加一个就把它放在最前面的索引处
opsForList.leftPush(key, pivot, value);		//如果pivot处值存在则在pivot前面添加
opsForList.leftPushAll(key, value);			//把多个值存入List中(value可以是多个值，也可以是一个Collection value)
opsForList.leftPushIfPresent(key, value);	//List存在的时候再加入
opsForList.rightPush(key, value);			//按照先进先出的顺序来添加(value可以是多个值，或者是Collection var2)
opsForList.rightPushAll(key, value);		//在pivot元素的右边添加值
opsForList.set(key, index, value);			//设置指定索引处元素的值
opsForList.trim(key, start, end);			//将List列表进行剪裁
opsForList.size(key);						//获取当前key的List列表长度

//移除并获取列表中第一个元素(如果列表没有元素会阻塞列表直到等待超时或发现可弹出元素为止)
opsForList.leftPop(key);			
opsForList.leftPop(key, timeout, unit);

//移除并获取列表最后一个元素
opsForList.rightPop(key);
opsForList.rightPop(key, timeout, unit);

//从一个队列的右边弹出一个元素并将这个元素放入另一个指定队列的最左边
opsForList.rightPopAndLeftPush(sourceKey, destinationKey);
opsForList.rightPopAndLeftPush(sourceKey, destinationKey, timeout, unit);

//删除集合中值等于value的元素(index=0, 删除所有值等于value的元素; index>0, 从头部开始删除第一个值等于value的元素; index<0, 从尾部开始删除第一个值等于value的元素)
opsForList.remove(key, index, value);
```

> Set类型

**java**

```
opsForSet.add(key, values);			//添加元素
opsForSet.remove(key, values);		//移除元素(单个值、多个值)
opsForSet.pop(key);					//删除并且返回一个随机的元素
opsForSet.size(key);				//获取集合的大小
opsForSet.isMember(key, value);		//判断集合是否包含value
opsForSet.intersect(key, otherKey);	//获取两个集合的交集(key对应的无序集合与otherKey对应的无序集合求交集)
opsForSet.intersect(key, otherKeys);//获取多个集合的交集(Collection var2)
opsForSet.intersectAndStore(key, otherKey, destKey);	//key集合与otherKey集合的交集存储到destKey集合中(其中otherKey可以为单个值或者集合)
opsForSet.intersectAndStore(key, otherKeys, destKey);	//key集合与多个集合的交集存储到destKey无序集合中
opsForSet.union(key, otherKeys);	//获取两个或者多个集合的并集(otherKeys可以为单个值或者是集合)
opsForSet.unionAndStore(key, otherKey, destKey);	//key集合与otherKey集合的并集存储到destKey中(otherKeys可以为单个值或者是集合)
opsForSet.difference(key, otherKeys);	//获取两个或者多个集合的差集(otherKeys可以为单个值或者是集合)
opsForSet.differenceAndStore(key, otherKey, destKey);	//差集存储到destKey中(otherKeys可以为单个值或者集合)
opsForSet.randomMember(key);	//随机获取集合中的一个元素
opsForSet.members(key);			//获取集合中的所有元素
opsForSet.randomMembers(key, count);	//随机获取集合中count个元素
opsForSet.distinctRandomMembers(key, count);	//获取多个key无序集合中的元素（去重），count表示个数
opsForSet.scan(key, options);	//遍历set类似于Interator(ScanOptions.NONE为显示所有的)
```

> zSet类型

**java**

```
opsForZSet.add(key, value, score);				//添加元素(有序集合是按照元素的score值由小到大进行排列)
opsForZSet.remove(key, values);					//删除对应的value,value可以为多个值
opsForZSet.incrementScore(key, value, delta);	//增加元素的score值，并返回增加后的值
opsForZSet.rank(key, value);					//返回元素在集合的排名,有序集合是按照元素的score值由小到大排列
opsForZSet.reverseRank(key, value);				//返回元素在集合的排名,按元素的score值由大到小排列
opsForZSet.reverseRangeWithScores(key, start,end);	//获取集合中给定区间的元素(start 开始位置，end 结束位置, -1查询所有)
opsForZSet.reverseRangeByScore(key, min, max);	//按照Score值查询集合中的元素，结果从小到大排序
opsForZSet.reverseRangeByScoreWithScores(key, min, max);	//返回值为:Set<ZSetOperations.TypedTuple<V>>
opsForZSet.count(key, min, max);				//根据score值获取集合元素数量
opsForZSet.size(key);							//获取集合的大小
opsForZSet.zCard(key);							//获取集合的大小
opsForZSet.score(key, value);					//获取集合中key、value元素对应的score值
opsForZSet.removeRange(key, start, end);		//移除指定索引位置处的成员
opsForZSet.removeRangeByScore(key, min, max);	//移除指定score范围的集合成员
opsForZSet.unionAndStore(key, otherKey, destKey);//获取key和otherKey的并集并存储在destKey中（其中otherKeys可以为单个字符串或者字符串集合）
opsForZSet.intersectAndStore(key, otherKey, destKey);	//获取key和otherKey的交集并存储在destKey中（其中otherKeys可以为单个字符串或者字符串集合）
```

**注意**

```
    原生的redistemplate使用了jdk的序列化，需要对象实现Serializable接口。内置的PgRedisTemplate
是通过jackson序列化配置过的，可以在不实现Serializable接口的情况下操作对象。
```

**java**

```
if (defaultSerializer ==null) {

    defaultSerializer =newJdkSerializationRedisSerializer(
        classLoader !=null? classLoader :this.getClass().getClassLoader());
}

if (enableDefaultSerializer) {

if (keySerializer ==null) {
        keySerializer = defaultSerializer;
        defaultUsed =true;
    }
if (valueSerializer ==null) {
        valueSerializer = defaultSerializer;
        defaultUsed =true;
    }
if (hashKeySerializer ==null) {
        hashKeySerializer = defaultSerializer;
        defaultUsed =true;
    }
if (hashValueSerializer ==null) {
        hashValueSerializer = defaultSerializer;
        defaultUsed =true;
    }
}
```

> #### 技术原理

```
    首先是自动化配置类PgRedisAutoConfiguration
    主要是初始化了RedisTemplate工具及分布式锁、限制器的初始化。RedisTemplate使用了任意入参序列化的方式，
主要是值。这里的泛型配了Object，主要用于lua脚本的使用，直接使用字符串泛型会导致lua序列化生成多余引号。
```

**java**

```
package com.kingtsoft.pangu.data.redis;

/**
 * Title: <br>
 * Description: <br>
 * Company: KingTang <br>
 *
 * @author 金炀
 * @version 1.0
 */
@Configuration
public class  PgRedisAutoConfiguration {

    @Bean
public RedisTemplate<String, Object> redisDefaultTemplate(RedisConnectionFactory factory) {
        RedisTemplate<String, Object> template =new RedisTemplate<>();
        template.setConnectionFactory(factory);
        Jackson2JsonRedisSerializer<Object> jackson2JsonRedisSerializer =new Jackson2JsonRedisSerializer<>(Object.class);
        ObjectMapper om =newObjectMapper();
        om.setVisibility(PropertyAccessor.ALL, JsonAutoDetect.Visibility.ANY);
        om.activateDefaultTyping(om.getPolymorphicTypeValidator(), ObjectMapper.DefaultTyping.NON_FINAL);
        jackson2JsonRedisSerializer.setObjectMapper(om);
        StringRedisSerializer stringRedisSerializer =newStringRedisSerializer();
// key采用String的序列化方式
        template.setKeySerializer(stringRedisSerializer);
// hash的key也采用String的序列化方式
        template.setHashKeySerializer(stringRedisSerializer);
// value序列化方式采用jackson
        template.setValueSerializer(jackson2JsonRedisSerializer);
// hash的value序列化方式采用jackson
        template.setHashValueSerializer(jackson2JsonRedisSerializer);
        template.afterPropertiesSet();
return template;
    }

    @Bean
    @ConditionalOnMissingBean(SequenceTemplate.class)
public SequenceTemplate sequenceTemplate(@Qualifier("redisDefaultTemplate") RedisTemplate<String, Object> redisTemplate) {
returnnewRedisSequenceTemplate(redisTemplate);
    }

    @Bean
    @ConditionalOnMissingBean(AccessSpeedLimit.class)
public AccessSpeedLimit accessSpeedLimit(@Qualifier("redisDefaultTemplate") RedisTemplate<String, Object> redisTemplate) {
returnnewAccessSpeedLimit(redisTemplate);
    }

    @Bean
    @ConditionalOnMissingBean(DistributedLockTemplate.class)
public DistributedLockTemplate distributedLockTemplate(@Qualifier("redisDefaultTemplate") RedisTemplate<String, Object> redisTemplate) {
returnnewRedisDistributedLockTemplate(redisTemplate);
    }
}
```

```
限制单纯是脚本功能，通过入参LimitRule控制访问频率
```

**java**

```
publicboolean  tryAccess(String key, int seconds, int limitCount) {
        LimitRule limitRule =newLimitRule();
        limitRule.setLimitCount(limitCount);
        limitRule.setSeconds(seconds);
returntryAccess(key, limitRule);
    }

    /**
     * 针对资源key,每limitRule.seconds秒最多访问limitRule.limitCount,超过limitCount次返回false
     * 超过lockCount 锁定lockTime
     *
     * @paramkey
     * @paramlimitRule
     * @return
     */
publicboolean  tryAccess(String key, LimitRule limitRule) {
        String newKey ="Limit:"+ key;
        List<String> keys =new ArrayList<>();
        keys.add(newKey);
        List<Object> args =new ArrayList<>();
        args.add(Math.max(limitRule.getLimitCount(), limitRule.getLockCount()));
        args.add(limitRule.getSeconds());
        args.add(limitRule.getLockCount());
        args.add(limitRule.getLockTime());
        args.add(limitRule.enableLimitLock() ?1:0);

        long  ret = redisTemplate.execute(redisScript, keys, args.toArray());
if (ret ==null) {
thrownewRuntimeException("tryAccess异常");
        }
return ret <= limitRule.getLimitCount();
    }
```
