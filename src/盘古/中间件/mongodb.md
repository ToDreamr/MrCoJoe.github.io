# mongodb模块

> #### 如何使用

```
业务端引入模块
```

**xml**

```
<dependency>
  <groupId>com.kingtsoft.pangu</groupId>
  <artifactId>pangu-data-mongodb</artifactId>
</dependency>
```

**java**

```
package com.kingtsoft.pangu.data.mongodb.server.controller;

/**
 * Title: <br>
 * Description: <br>
 * Company: KingTang <br>
 *
 * @author 金炀
 * @version 1.0
 */
@RestController
@RequestMapping("/mongodb")
public class  MongoController {

private final   MongoBaseService<TestMongo> mongoMongoBaseService;

private final   MongoTemplate mongoTemplate;

publicMongoController(MongoTemplate mongoTemplate,
                           MongoBaseService<TestMongo> mongoMongoBaseService) {
this.mongoTemplate = mongoTemplate;
this.mongoMongoBaseService = mongoMongoBaseService;
    }

    @RequestMapping("/test")
public Object test(@RequestBody Map<String, Object> objectToSave) {
        TestMongo testMongo =newTestMongo();
        testMongo.setTestId(6);
        testMongo.setName("abc7");

        TestMongo testMongo2 =newTestMongo();
        testMongo2.setTestId(6);
        Query query = MongodbUtil.buildQuery(testMongo2);
        Update update = MongodbUtil.buildUpdate(testMongo);
//        long  ret = mongoMongoBaseService.upsert(query, update, TestMongo.class);

//        List<TestMongo> a = new ArrayList<>();
//        a.add(testMongo);
//        long  ret = mongoMongoBaseService.updateBatchById(a, TestMongo.class);
        MongoPage<TestMongo> page =new MongoPage<>(1, 2);
        MongoPage<TestMongo> ret = mongoMongoBaseService.findPage(page, null, TestMongo.class);

        TestMongo ret2 = mongoMongoBaseService.getById(2, TestMongo.class);

return JsonResult.create(ret);
    }

}
```

```
当然也可以直接注入MongoTemplate
```

**java**

```
public class  MongoBaseServiceImpl<T> implementsMongoBaseService<T> {

private final   MongoTemplate mongoTemplate;

publicMongoBaseServiceImpl(MongoTemplate mongoTemplate) {
this.mongoTemplate = mongoTemplate;
    }

    @Override
public T save(T entity) {
// mongodb中的_id统一自定义设置, 否则手动抛出异常
        Assert.isTrue(MongodbUtil.existDocumentId(entity), "请使用@Id标记文档ID键！");
return mongoTemplate.save(entity);
    }
}
```

```
无论哪种，泛型对象的定义，如果要使用根据主键相关的查询模式必须要有@Id注解，比如根据主键更新数据。
```

> #### 技术原理

```
其实就是造了mongodb增删改的轮子
规定了常用接口在MongoBaseService
```

**java**

```
package com.kingtsoft.pangu.data.mongodb;

import org.springframework.data.mongodb.core.query.Query;
import org.springframework.data.mongodb.core.query.Update;

import java.io.Serializable;
import java.util.Collection;
import java.util.List;

/**
 * Title: <br>
 * Description: <br>
 * Company: KingTang <br>
 *
 * @author 金炀
 * @version 1.0
 */
public interface  MongoBaseService<T> {

    /**
     * 单个插入 _id已存在会做覆盖,原本有值的字段可能会被置null
     *
     * @paramentity 实体
     * @return 全信息
     * @author 金炀
     */
    T save(T entity);

    /**
     * 批量插入 _id已存在会做覆盖,原本有值的字段可能会被置null
     *
     * @paramentityList 实体集合
     * @return 全信息
     * @author 金炀
     */
    List<T> insertBatch(Collection<T> entityList, Class<?> clazz);

    /**
     * 单个更新
     * 根据id进行更新
     * 没有任何一个字段做更新不做处理, 否则会将除_id外的字段都置null
     *
     * @paramentity 实体
     * @return 是否更新成功
     * @author 金炀
     */
boolean  updateById(T entity, Class<?> entityClass);

    /**
     * 批量更新
     * 根据id进行更新
     * 没有任何一个字段做更新不做处理, 否则会将除_id外的字段都置null
     *
     * @paramentityList  实体集合
     * @paramentityClass 实体类型
     * @return 更新数据条数
     * @author 金炀
     */
long updateBatchById(Collection<T> entityList, Class<?> entityClass);

    /**
     * 按条件更新
     * 自定义条件
     *
     * @paramquery       条件结构
     * @paramupdate      更新结构
     * @paramentityClass 实体类型
     * @return 更新数据条数
     * @author 金炀
     */
long update(Query query, Update update, Class<?> entityClass);

    /**
     * 插入或更新
     *
     * @paramquery       条件结构
     * @paramupdate      更新结构
     * @paramentityClass 实体类型
     * @return 更新数据条数
     * @author 金炀
     */
long upsert(Query query, Update update, Class<?> entityClass);

    /**
     * 删除 根据id进行删除
     *
     * @paramid          ID数据
     * @paramentityClass 实体类型
     * @return 是否成功
     * @author 金炀
     */
boolean  deleteById(Object id, Class<?> entityClass);

    /**
     * 删除 根据条件进行删除
     *
     * @paramt          条件数据
     * @paramentityClass 实体类型
     * @return 是否成功
     * @author 金炀
     */
long deleteByCondition(T t, Class<?> entityClass);

    /**
     * 批量删除 根据id进行删除
     *
     * @paramids         ID集合
     * @paramentityClass 实体类型
     * @return 作用条数
     * @author 金炀
     */
long deleteByIds(Collection<?extendsSerializable> ids, Class<?> entityClass);

    /**
     * 单个查询 根据id进行查询
     *
     * @paramid          ID数据
     * @paramentityClass 实体类型
     * @return 实体数据
     * @author 金炀
     */
    T getById(Object id, Class<T> entityClass);

    /**
     * 批量查询 根据id进行查询
     *
     * @paramids         ID集合
     * @paramentityClass 实体类型
     * @return 实体集合
     * @author 金炀
     */
    List<T> listByIds(Collection<?extendsSerializable> ids, Class<T> entityClass);

    /**
     * 按实体条件查询
     * 非空字段会组装成条件进行查询
     * 只支持(基本数据类型)字段=条件查询, 参考: MongodbUtil.isPrimitive
     * 不支持排序
     * 不支持分页
     *
     * @paramentity      实体对象（将组装成查询结构体）
     * @paramentityClass 实体类型
     * @return 实体信息
     * @author 金炀
     */
    List<T> query(T entity, Class<T> entityClass);

    /**
     * 条件查询
     * 自定义条件
     * 支持分页
     * 支持排序
     *
     * @paramquery       查询结构体
     * @paramentityClass 实体类型
     * @return 实体集合
     * @author 金炀
     */
    List<T> query(Query query, Class<T> entityClass);

    /**
     * 查询一条数据 自定义条件
     *
     * @paramquery       查询条件
     * @paramentityClass 实体类型
     * @return 实体数据
     * @author 金炀
     */
    T getOne(Query query, Class<T> entityClass);

    /**
     * 查询分页数据
     *
     * @parampage        分页数据
     * @paramquery       查询条件
     * @paramentityClass 实体类型
     * @return 实体数据
     * @author 金炀
     */
    MongoPage<T> findPage(MongoPage<T> page, Query query, Class<T> entityClass);

    /**
     * 查询分页数据
     *
     * @parampage        分页数据
     * @paramt           查询条件
     * @paramentityClass 实体类型
     * @return 实体数据
     * @author 金炀
     */
    MongoPage<T> findPageByCondition(MongoPage<T> page,T t, Class<T> entityClass);

    /**
     * 获取总数
     *
     * @paramquery       查询条件
     * @paramentityClass 实体类型
     * @return 实体数据
     * @author 金炀
     */
long count(Query query, Class<T> entityClass);
}
```

```
官网操作
```

[https://www.mongodb.com/docs/manual/reference/operator/query/](https://www.mongodb.com/docs/manual/reference/operator/query/)

```
参考文章
```

[https://www.cnblogs.com/luoxiao1104/p/15145686.html](https://www.cnblogs.com/luoxiao1104/p/15145686.html)
