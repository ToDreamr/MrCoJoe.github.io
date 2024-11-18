
# SQL跟踪模块

> #### 如何使用

业务项目引入

**xml**

```
<dependency>
  <groupId>com.kingtsoft.pangu</groupId>
  <artifactId>pangu-data-trace</artifactId>
</dependency>
```

> #### 技术原理

```
    支持mybatisplus与jdbcTemplate两种持久层框架
根据路径内置入一个拦截器去截获当前人员信息中的跟踪状态（目前模式需要有人员信息才给支持）
```

**java**

```
public class  TraceInfoInterceptimplementsHandlerInterceptor {

    @Override
publicboolean  preHandle(HttpServletRequest request, HttpServletResponse response, Object handler) {
        Object obj = request.getAttribute(ApplicationConst.USER_DATA_KEY);
if (obj ==null) {
returntrue;
        }

        JSONObject dataObj = JSON.parseObject(JSON.toJSONString(obj));
        Integer sqlTrace = dataObj.getInteger(TraceConst.SQL_TRACE);
if (sqlTrace ==null) {
returntrue;
        }
        request.setAttribute(TraceConst.SQL_TRACE, sqlTrace);

        String sqlTraceKey = dataObj.getString(TraceConst.SQL_TRACE_KEY);
if (sqlTraceKey ==null) {
returntrue;
        }
        request.setAttribute(TraceConst.SQL_TRACE_KEY, sqlTraceKey);

returntrue;
    }
}
```

```
    mybatisplus 使用自带的拦截器进行截获SQL
```

**java**

```
@Slf4j
@Component
@Intercepts({
        @Signature(type= Executor.class, method="query",
args= {MappedStatement.class, Object.class, RowBounds.class, ResultHandler.class}),
        @Signature(type= Executor.class, method="query",
args= {MappedStatement.class, Object.class, RowBounds.class, ResultHandler.class, CacheKey.class, BoundSql.class}),
        @Signature(type= Executor.class, method="update", args= {MappedStatement.class, Object.class})
})
public class  MbSqlInterceptimplementsInterceptor {

private final   RedisHandler<String, String> redisHandler;

private final   HttpServletRequest request;

privatestaticfinallong  TIMEOUT = ExpTimeUtil.getExpTimeout(60);

private final  String[] conNodes = { "Filter", "Single-row" };

    @Override
public Object intercept(Invocation invocation) throws Throwable {
        String reqUrl =null;
        String url =null;
        Integer flag =null;
        Integer explain =null;
try {
            DatabaseMetaData databaseMetaData = ((Executor) invocation.getTarget()).getTransaction().getConnection().getMetaData();
            url = databaseMetaData.getURL();
            flag = (Integer) request.getAttribute(TraceConst.SQL_TRACE);
// 是否解析SQL执行计划（默认不解析，因为会耗费性能）
            explain = (Integer) request.getAttribute(TraceConst.SQL_EXPLAIN);
            reqUrl = request.getRequestURI();
        } catch (Exception ignore) {
        }

if (flag ==null|| flag !=1) {
// 非跟踪模式
return invocation.proceed();
        }

Object[] args = invocation.getArgs();
// 植入标记
        MappedStatement ms = (MappedStatement) invocation.getArgs()[0];
if (ms.getSqlCommandType() != SqlCommandType.UPDATE
&& ms.getSqlCommandType() != SqlCommandType.SELECT
&& ms.getSqlCommandType() != SqlCommandType.INSERT
&& ms.getSqlCommandType() != SqlCommandType.DELETE) {
return invocation.proceed();
        }

        BoundSql boundSql;
        Object parameter = args[1];
if (args.length ==2|| args.length ==4) {
            boundSql = ms.getBoundSql(parameter);
        } else {
            boundSql = (BoundSql) args[5];
        }

        String uuid = UUID.randomUUID().toString().replaceAll("-", "");
// 跟踪模式, oracle需要植入标记
if (url.contains("oracle") && ms.getSqlCommandType() == SqlCommandType.SELECT) {
            String oracleFlag ="/*"+ uuid +"*/";
            String sql = boundSql.getSql();
int idx = sql.toLowerCase().indexOf("select");
// 理论永远真
if (idx >=0) {
                sql = sql.substring(0, idx) +"select "+ oracleFlag + sql.substring(idx +6);
                Field field = boundSql.getClass().getDeclaredField("sql");
                field.setAccessible(true);
                field.set(boundSql, sql);
            }
        }

long  start = System.currentTimeMillis();
        LocalDateTime now = LocalDateTime.now();
        Object ret = invocation.proceed();
long  cost = System.currentTimeMillis() - start;
try {
doExProceed(
                    invocation,
                    boundSql,
newBigDecimal(cost).divide(newBigDecimal("1000"), 4, RoundingMode.HALF_UP),
                    now,
                    uuid,
                    explain,
                    reqUrl);
        } catch (Exception e) {
            log.error("解释错误！", e);
        }
return ret;
    }
```

```
    JdbcTemplate 使用AOP进行切面
```

**java**

```
@Pointcut("execution(* org.springframework.jdbc.core.JdbcTemplate.query*(String, ..)) "+
"|| execution(* org.springframework.jdbc.core.JdbcTemplate.update(String, ..))"+
"|| execution(* org.springframework.jdbc.core.JdbcTemplate.execute(String, ..))")
private void   jdbcTemplatePointCut() {
    }

    @Around("jdbcTemplatePointCut()")
public Object beforeMethod(ProceedingJoinPoint joinPoint) throws Throwable {
if (CHECK_FLAG.get() !=null&& CHECK_FLAG.get()) {
return joinPoint.proceed();
        }
long  startTime = System.currentTimeMillis();
        LocalDateTime now = LocalDateTime.now();
        Object ret = joinPoint.proceed();
long  end = System.currentTimeMillis();
long  cost = end - startTime;
try {
doExProceed(
                    joinPoint,
newBigDecimal(cost).divide(newBigDecimal("1000"), 4, RoundingMode.HALF_UP),
                    now);
        } catch (Exception e) {
            log.error("解释错误！", e);
        }
return ret;
    }
```

```
    兼容了oracle、mysql、tidb的执行计划自动生成
```

**java**

```
/**
     * 执行额外的SQL操作
     *
     * @paraminvocation 拦截信息
     * @author 金炀
     */
private void  doExProceed(Invocation invocation,
                             BoundSql boundSql,
                             BigDecimal cost,
                             LocalDateTime now,
                             String uuid,
                             Integer explain,
                             String reqUrl) {
        String dataKey;
try {
            dataKey = (String) request.getAttribute(TraceConst.SQL_TRACE_KEY);
        } catch (Exception e) {
return;
        }

if (dataKey ==null) {
return;
        }

        Object target = invocation.getTarget();
if (!(target instanceof Executor)) {
return;
        }

        MappedStatement ms = (MappedStatement) invocation.getArgs()[0];
///        RowBounds rowBounds = (RowBounds) args[2];
//        ResultHandler resultHandler = (ResultHandler) args[3];
        String sql =getSql(boundSql, ms);

        JSONObject jsonObject =newJSONObject()
                .fluentPut("reqUrl", reqUrl)
                .fluentPut("sql", sql)
                .fluentPut("cost", cost)
                .fluentPut("method", ms.getId())
                .fluentPut("position", SqlTraceUtil.getStackTrace(ms.getId(), "com.sun.proxy"))
                .fluentPut("time", now.format(ApplicationConst.DATETIME_FORMAT));

        String url;
try {
            DatabaseMetaData databaseMetaData = ((Executor) target).getTransaction().getConnection().getMetaData();
            url = databaseMetaData.getURL();
        } catch (SQLException e) {
thrownewRuntimeException(e);
        }

if (url.contains("type=tidb")) {
            jsonObject.fluentPut("type", "tidb");
        } elseif (url.contains("oracle")) {
            jsonObject.fluentPut("type", "oracle");
        }

if (ms.getSqlCommandType() != SqlCommandType.SELECT || explain ==null|| explain !=1) {
            redisHandler.listLeftPush(dataKey, jsonObject.fluentPut("explain", null));
            redisHandler.setExpireTime(dataKey, TIMEOUT, TimeUnit.MINUTES);
return;
        }

getExplainWithType((Executor) target, sql, jsonObject, uuid);

        redisHandler.listLeftPush(dataKey, jsonObject);
        redisHandler.setExpireTime(dataKey, TIMEOUT, TimeUnit.MINUTES);
    }

private void  getExplainWithType(Executor target, String sql, JSONObject jsonObject, String uuid) {
        String type = jsonObject.getString("type");
if (type !=null&&"tidb".equals(type)) {
            jsonObject.fluentPut("analyzeInfo", getTidbExplainAnalyzeInfo(target, sql));
        } elseif (type !=null&&"oracle".equals(type)) {
            jsonObject.fluentPut("analyzeInfo", getOracleExplainAnalyzeInfo(target, sql, uuid))
                    .fluentPut("explain", null);
        } else {
            List<QueryBlock> explainJsonResultList =getExplainInfo(target, sql);
if (log.isDebugEnabled()) {
                SqlTraceUtil.printExplain(explainJsonResultList);
            }

            jsonObject.fluentPut("analyzeInfo", getExplainAnalyzeInfo(target, sql))
                    .fluentPut("explain", explainJsonResultList);
        }
    }
```

```
    跟踪模块并非只解析SQL，会对mysql风格的数据进行执行计划处理，这样就
可以非常直观查看慢SQL导致变慢的语句节点是啥，甚至提出一些优化建议。
```

**java**

```
private List<QueryBlock>getExplainInfo(String sql, Object[] params) {
        CHECK_FLAG.set(true);
        List<QueryBlock> explainJsonResultList =new ArrayList<>();

        String exSql ="EXPLAIN FORMAT=JSON "+ sql;
try {
            Map<String, Object> ret = jdbcTemplate.queryForMap(exSql, params);
            String exp = ret.get("EXPLAIN").toString();
            JSONObject jsonObject = JSON.parseObject(exp);
            explainJsonResultList.add(TraceCover.getQueryBlock(jsonObject.getString("query_block")));
        } catch (Throwable e) {
            e.printStackTrace();
        } finally {
            CHECK_FLAG.remove();
        }
return explainJsonResultList;
    }

private List<ExplainTreeNode>getExplainAnalyzeInfo(String sql, Object[] params) {
        CHECK_FLAG.set(true);
        String exSql ="EXPLAIN ANALYZE "+ sql;
try {
            Map<String, Object> ret = jdbcTemplate.queryForMap(exSql, params);
            String json = ret.get("EXPLAIN").toString();
return SqlTraceUtil.getExplainAnalyze(json);
        } catch (Throwable e) {
            e.printStackTrace();
        } finally {
            CHECK_FLAG.remove();
        }
returnnull;
    }
```

```
    如下为自定的解析类(因为mysql8的解释内容是字符串返回，需要自己解析成
结构化数据，此方法还需要根据实际SQL跟踪进行拓展，可能存在不兼容的语句情况)
```

**java**

```
@Slf4j
public class  SqlTraceUtil {

    /**
     * 括号内数据替换的键的字典（因为需要分割空格，而默认返回的key中会包含空格）
     */
privatestaticfinal Map<String, String> KEY_DIC =new HashMap<>() {
        {
put("actual time", "actual_time");
        }
    };

    /**
     * 参数字典
     */
privatestaticfinalString[] DIC_EXP_PARAMS = { "actual_time", "rows", "loops", "cost" };

    /**
     * 获取执行方法
     *
     * @return 执行方法
     * @author 金炀
     */
publicstatic String getStackTrace(String method, String className) {
StackTraceElement[] stackTrace = Thread.currentThread().getStackTrace();
for (int i =0; i < stackTrace.length; i++) {
            StackTraceElement traceElement = stackTrace[i];
if (method.contains(traceElement.getMethodName())
&& traceElement.getClassName().contains(className)
&& i < stackTrace.length -1
&&!"java.base".equals(stackTrace[i +1].getModuleName())
&&!stackTrace[i +1].getClassName().startsWith("org.apache.ibatis")
&&!stackTrace[i +1].getClassName().startsWith("org.mybatis")) {
return stackTrace[i +1].toString();
            }
        }

returnnull;
    }

    /**
     * 获取执行方法
     *
     * @return 执行方法
     * @author 金炀
     */
publicstatic Map<String, String> getDaoByStackTrace() {
StackTraceElement[] stackTrace = Thread.currentThread().getStackTrace();
        String method =null;
        String position =null;

        String suffix =null;

boolean   serviceCheck =false;
for (StackTraceElement traceElement : stackTrace) {
if (traceElement.toString().contains("$$")) {
continue;
            }

if (!serviceCheck) {
                Class<?> tarClazz;
try {
                    tarClazz = Class.forName(traceElement.getClassName());
                } catch (ClassNotFoundException e) {
continue;
                }
                Repository repository = tarClazz.getAnnotation(org.springframework.stereotype.Repository.class);
if (repository !=null) {
                    method = traceElement.getClassName() +"."+ traceElement.getMethodName();
                    serviceCheck =true;

String[] parts = method.split("\\.");
if (parts.length >=3) {
                        suffix = String.format("%s.%s.%s", parts[0], parts[1], parts[2]);
                    }

continue;
                }
            }

if (serviceCheck) {
if (suffix ==null) {
break;
                }
if (traceElement.toString().contains(suffix)) {
                    position = traceElement.toString();
break;
                }
            }
        }

        Map<String, String> retMap =new HashMap<>(4);
        retMap.put("method", method);
        retMap.put("position", position);

return retMap;
    }

    /**
     * 获取解释信息
     *
     * @paramjson      解释信息
     * @return 解释信息
     * @author 金炀
     */
publicstatic List<ExplainTreeNode> getExplainAnalyze(String json) {
String[] arr = json.split("\\r?\\n");
        Map<Integer, List<ExplainTreeNodeDetail>> allData =pkgAllDetail(arr);

        List<ExplainTreeNodeDetail> rootNodes = allData.get(0);
if (rootNodes ==null) {
returnnull;
        }

        List<ExplainTreeNode> treeNodes =new ArrayList<>();
setNode(allData, rootNodes, treeNodes, null, 0, null);

return treeNodes;
    }

privatestaticvoidsetNode(Map<Integer, List<ExplainTreeNodeDetail>> allData,
                                List<ExplainTreeNodeDetail> currentNodes,
                                List<ExplainTreeNode> treeNodes,
                                ExplainTreeNode parent, intclassifyId, Integer endIdx) {
int i =0;
for (ExplainTreeNodeDetail rootNode : currentNodes) {
            ExplainTreeNode treeNode =newExplainTreeNode();
            treeNode.setExpInfo(rootNode.getDetail());
            Integer nexIdx;

if (i <= currentNodes.size() -2) {
                nexIdx = currentNodes.get(i +1).getIndex();
            } else {
                nexIdx = endIdx;
            }
pkgNodeInfo(treeNode, rootNode, allData, treeNodes, classifyId, nexIdx);
            i++;
        }

if (parent !=null) {
            parent.setChildren(treeNodes);
        }
    }

privatestaticvoidpkgNodeInfo(ExplainTreeNode treeNode,
                                    ExplainTreeNodeDetail rootNode,
                                    Map<Integer, List<ExplainTreeNodeDetail>> allData,
                                    List<ExplainTreeNode> treeNodes,
intclassifyId,
                                    Integer endIndex) {
        List<String> params =new ArrayList<>();
getBracketsInfo(params, rootNode.getDetail());
        treeNode.setExpHeadInfo(treeNode.getExpInfo());
        params = params.stream().filter(
                param -> param.contains("=")
        ).collect(Collectors.toCollection(ArrayList::new));
//        Optional<String> ret = Arrays.stream(conNodes).filter(
//                name -> rootNode.getDetail().contains(name)
//        ).findAny();
//        if (i + flag == 0) {
//            treeNode.setCondition(params.get(0));
//            continue;
//        }
pkgKeyValueDetail(treeNode, params);

        List<ExplainTreeNodeDetail> treeNodeDetails = allData.get(classifyId +1);
if (treeNodeDetails !=null) {
            treeNodeDetails = treeNodeDetails.stream().filter(
                    d -> {
if (endIndex !=null) {
return rootNode.getIndex() < d.getIndex() && d.getIndex() < endIndex;
                        }
return rootNode.getIndex() < d.getIndex();
                    }
            ).collect(Collectors.toCollection(ArrayList::new));
if (treeNodeDetails.size() >0) {
                List<ExplainTreeNode> newNodes =new ArrayList<>();
setNode(allData, treeNodeDetails, newNodes, treeNode, classifyId +1, endIndex);
            }
        }

        treeNodes.add(treeNode);
    }

    /**
     * 括号详细信息处理
     *
     * @paramtreeNode 树状节点
     * @paramparams   原始查询信息数组
     * @author 金炀
     */
privatestaticvoidpkgKeyValueDetail(ExplainTreeNode treeNode, List<String> params) {
if (params.size() ==0) {
return;
        }
int paramIndex =0;

        JSONObject object =newJSONObject();
for (String param : params) {
finalString[] str = {param};
            KEY_DIC.forEach((key, value) -> str[0] = str[0].replaceAll(key, value));

String[] kvs = str[0].split(" ");
boolean   actFlag =false;
for (String kv : kvs) {
String[] data = kv.split("=");
if (data.length ==0) {
continue;
                }
if (!Arrays.asList(DIC_EXP_PARAMS).contains(data[0])) {
continue;
                }

if (paramIndex ==0) {
                    paramIndex = treeNode.getExpInfo().indexOf(param) -1;
                }

if (kv.contains("actual_time")) {
                    actFlag =true;
                }

if (actFlag) {
                    object.fluentPut(data[0], data[1]);
                } else {
                    object.fluentPut("pre_"+ data[0], data[1]);
                }
            }
        }

if (paramIndex !=0) {
            treeNode.setExpHeadInfo(treeNode.getExpInfo().substring(0, paramIndex));
        }

        treeNode.setPreCost(object.getString("pre_cost"));
        treeNode.setPreRows(object.getInteger("pre_rows"));

        treeNode.setRows(object.getInteger("rows"));
        treeNode.setActualTime(object.getString("actual_time"));
        treeNode.setLoops(object.getInteger("loops"));
    }

    /**
     * 通过提供的数据获取括号内容
     *
     * @paramparams 需要返回的括号信息
     * @paramtarStr 提供的信息
     * @author 金炀
     */
privatestaticvoidgetBracketsInfo(List<String> params, String tarStr) {
        List<Integer> idxArr =new ArrayList<>();
for (int i =0; i < tarStr.length(); i++) {
char a = tarStr.charAt(i);
if (a ==')') {
                idxArr.add(-1* i);
            }
if (a =='(') {
                idxArr.add(i);
            }
        }

        List<Integer> rows = idxArr.stream().filter(i -> i >=0).collect(Collectors.toCollection(ArrayList::new));
for (Integer row : rows) {
int endIdx =0;

int flag =1;
for (Integer integer : idxArr) {
if (Math.abs(integer) > Math.abs(row)) {
if (integer >=0) {
                        flag++;
                    } else {
                        flag--;
                    }
                }

if (flag ==0) {
                    endIdx = Math.abs(integer);
break;
                }
            }

if (endIdx >0) {
                params.add(tarStr.substring(row +1, endIdx));
            }
        }
    }

privatestatic Map<Integer, List<ExplainTreeNodeDetail>> pkgAllDetail(String[] arr) {
        Map<Integer, List<ExplainTreeNodeDetail>> allData =new HashMap<>(8);

int indent =4;
int i =1;
for (String exRow : arr) {
            String row = exRow.substring(exRow.indexOf("->") +3);
int idx = exRow.indexOf("->") / indent;
if (allData.get(idx) ==null) {
int finalI = i;
                List<ExplainTreeNodeDetail> strings =new ArrayList<>() {
                    { add(newExplainTreeNodeDetail(finalI, row)); }
                };
                allData.put(idx, strings);
            } else {
                allData.get(idx).add(newExplainTreeNodeDetail(i, row));
            }

            i++;
        }

return allData;
    }

    /**
     * 打印解释信息
     *
     * @paramexplainJsonResultList 解释信息
     * @author 金炀
     */
publicstaticvoidprintExplain(List<QueryBlock> explainJsonResultList) {
        log.info("*************************** 解释结果 ***************************");

for (QueryBlock queryBlock : explainJsonResultList) {
            log.info(JSON.toJSONString(queryBlock, PrettyFormat));
        }

        log.info("***************************************************************");
    }

}
```

```
    由于数据是保存在redis之中，设计了额外的工具，让缓存在对应的节点
批量失效，而非实时都有缓存在失效。如下所示，15表示一个块，一小时会有4个15分钟 ，
也就是4个节点，设置一小时会根据此时的时间推一小时，并且计算距离一小时后的时刻与哪
个节点近，然后计算出实际坐落节点内的时间，并配置到缓存失效内。缓存内的跟踪数据过于
离散的问题（其实redis内部有自己的失效机制，不用我们操心）。
```

**java**

```
privatestaticfinallong  TIMEOUT = ExpTimeUtil.getExpTimeout(60);

List<QueryBlock> explainJsonResultList =getExplainInfo((Executor) target, sql);
SqlTraceUtil.printExplain(explainJsonResultList);

if (url.contains("type=tidb")) {
    jsonObject.fluentPut("type", "tidb");
} elseif (url.contains("oracle")) {
    jsonObject.fluentPut("type", "oracle");
}

if (ms.getSqlCommandType() != SqlCommandType.SELECT || explain ==null|| explain !=1) {
    redisHandler.listLeftPush(dataKey, jsonObject.fluentPut("explain", null));
    redisHandler.setExpireTime(dataKey, TIMEOUT, TimeUnit.MINUTES);
return;
}

getExplainWithType((Executor) target, sql, jsonObject, uuid);

redisHandler.listLeftPush(dataKey, jsonObject);
redisHandler.setExpireTime(dataKey, TIMEOUT, TimeUnit.MINUTES);
```

**java**

```
publicstaticlong getExpTimeout(LocalDateTime startTime, long  timeout, int blockTime, TimeUnit unit) {
    Integer timeAll = TIME_ALL.get(unit);
if (timeAll ==null) {
thrownewRuntimeException("不支持的时间单位计算");
    }
if (blockTime > timeAll) {
thrownewRuntimeException("请使用小于等于60的解释数据");
    }
long  b = timeAll / blockTime;

int target;
if (TimeUnit.HOURS.equals(unit)) {
        target = startTime.plusHours(timeout).getHour();
    } elseif (TimeUnit.SECONDS.equals(unit)) {
        target = startTime.plusSeconds(timeout).getSecond();
    } else {
        target = startTime.plusMinutes(timeout).getMinute();
    }
int min = target;
for (int i =0; i < b; i++) {
int now = target - (i +1) * blockTime;
if (Math.abs(now) < Math.abs(min)) {
            min = now;
        }
    }

return timeout - min;
}
```

```
    效果如下
```

![image.png](http://pangu.kingtsoft.com/pangu-facade/assets/image1.73414522.png)
