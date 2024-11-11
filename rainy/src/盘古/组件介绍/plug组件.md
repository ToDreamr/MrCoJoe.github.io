# plug组件

```
设计目的是应对如果存在一个需求，是某个医院特有的，需要在原始公用业务代码上无感知做出调整。
```

> #### 如何使用

```
业务层引入如下包内容
```

**xml**

```
<dependency>
    <groupId>com.kingtsoft.pangu</groupId>
    <artifactId>pangu-spring-plug</artifactId>
</dependency>
```

```
新建一个Aspect 用来增强需要替换的类
```

**java**

```
package com.kingtsoft.kingwise.sys.hos.lhl.biz.config;

import org.aspectj.lang.JoinPoint;
import org.aspectj.lang.annotation.Aspect;
import org.aspectj.lang.annotation.Before;
import org.aspectj.lang.annotation.Pointcut;
import org.springframework.stereotype.Component;

/**
 * Title: <br>
 * Description: <br>
 * Company: KingTang <br>
 *
 * @author 金炀
 * @version 1.0
 */
@Aspect
@Component
public class  PluginAspect {

    @Pointcut("execution(public * com.kingtsoft.kingwise.sys.hos.biz.service..*.*(..))")
private void   plugin() {
    }

    @Before("plugin()")
private void   doBefore(JoinPoint joinPoint) {
    }
}
```

```
    业务类上加上注解@PlugTo，参数传入需要复写的内容。覆盖规则为，方法名+返回类型+入参类型
全一致，这样TestCallService中的方法就会动态替换TestService下的同方法。
```

**java**

```
@PlugTo(TestService.class)
@Service
public class  TestCallService {

// 覆盖的方法
    @DSTransactional
private void   testTran() {
// 覆盖内容
    }
}
```

> #### 技术原理

```
首先会自动化配置中会初始化PanguPlugTool 及 PlugMethodInterceptor拦截器
```

**java**

```
package com.kingtsoft.pangu.spring.plug;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.context.annotation.Import;

/**
 * Title: <br>
 * Description: <br>
 * Company: KingTang <br>
 *
 * @author 金炀
 * @version 1.0
 */
@Import(StartupPlugConfig.class)
@Configuration
public class  PlugAutoConfiguration {

    @Bean
public PanguPlugTool panguPlugTool() {
returnnewPanguPlugTool();
    }

    @Bean
public PlugMethodInterceptor plugMethodInterceptor(PanguPlugTool panguPlugTool) {
returnnewPlugMethodInterceptor(panguPlugTool);
    }

}
```

```
    然后会发现导入了一个StartupPlugConfig，会发现这个类主要是在应用准备完成后处理的。
首先List<PlugPojo> plugPojos = plugTool.initPlug();获取织入信息。然后执行
plugTool.registerAdvice(plugPojos);进行增强注册。
（这里为什么不直接在plugTool内部一次性处理完，是为了给以后预留外部附加功能添加的口子）
```

**java**

```
package com.kingtsoft.pangu.spring.plug;

import org.springframework.boot.ApplicationArguments;
import org.springframework.boot.ApplicationRunner;
import org.springframework.context.annotation.Configuration;

import java.util.List;

/**
 * Title: <br>
 * Description: <br>
 * Company: KingTang <br>
 *
 * @author 金炀
 * @version 1.0
 */
@Configuration
public class  StartupPlugConfigimplementsApplicationRunner {

private final   PanguPlugTool plugTool;

publicStartupPlugConfig(PanguPlugTool plugTool) {
this.plugTool = plugTool;
    }

    @Override
private void   run(ApplicationArguments args) {
        List<PlugPojo> plugPojos = plugTool.initPlug();
        plugTool.setPlugPojoList(plugPojos);
        plugTool.registerAdvice(plugPojos);
    }
}
```

```
PanguPlugTool工具
    这里看initPlug方法，目的是为了将所有标记@PlugTo的bean收集起来，并转换为结构化数据PlugPojo缓存，
主要是确定织入类与被织入类。然后就会去通过registerAdvice去注册。这里会去把原始bean获取出来，然后进行
Advised advised = (Advised) bean;转换，添加@Aspe进行扫描增强原始类就是为了这个，不然是无法转换的。
然后通过Advice advice = applicationContext.getBean(PlugMethodInterceptor.class); 
获取需要织入的对象（实现了MethodInterceptor的对象）。
最后通过 advised.addAdvice(advice); 把织入对象放入被织入对象。这样在执行原始方法之前就会进入此织
入对象的invoke方法。
```

**java**

```
package com.kingtsoft.pangu.spring.plug;

/**
 * Title: <br>
 * Description: <br>
 * Company: KingTang <br>
 *
 * @author 金炀
 * @version 1.0
 */
@Slf4j
public class  PanguPlugToolimplementsApplicationContextAware {

private ApplicationContext applicationContext;

    @Override
private void   setApplicationContext(ApplicationContext applicationContext) throws BeansException {
this.applicationContext = applicationContext;
    }

private List<PlugPojo> plugPojoList;

public List<PlugPojo> getPlugPojoList() {
return plugPojoList;
    }

private void   setPlugPojoList(List<PlugPojo> plugPojoList) {
this.plugPojoList = plugPojoList;
    }

public List<PlugPojo> initPlug() {
        List<PlugPojo> plugList =new ArrayList<>();
for (String beanDefinitionName : applicationContext.getBeanDefinitionNames()) {
            Object bean = applicationContext.getBean(beanDefinitionName);

            PlugTo plugTo = AnnotationUtils.findAnnotation(bean.getClass(), PlugTo.class);
if (plugTo ==null) {
continue;
            }

            PlugPojo plugPojo =newPlugPojo();
            plugPojo.setAdviceClass(bean.getClass());
            plugPojo.setAdvisedClass(plugTo.value());
            plugList.add(plugPojo);
        }

return plugList;
    }

private void   registerAdvice(List<PlugPojo> plugList) {
for (PlugPojo plugPojo : plugList) {
if (plugPojo.getAdvisedClass() ==null) {
continue;
            }

            Object bean = applicationContext.getBean(plugPojo.getAdvisedClass());
if (bean ==this||!(bean instanceof Advised)) {
continue;
            }

            Advised advised = (Advised) bean;

try {
                Advice advice = applicationContext.getBean(PlugMethodInterceptor.class);
                advised.addAdvice(advice);
            } catch (Exception e) {
                e.printStackTrace();
thrownewRuntimeException("插件激活失败！"+ plugPojo.getAdvisedClass().getName());
            }
        }
    }
}
```

```
    然后我们来看PlugMethodInterceptor, 其实内部就是注入了PanguPlugTool，调用了doBeanInvoke方法
```

**java**

```
package com.kingtsoft.pangu.spring.plug;

import lombok.AllArgsConstructor;
import org.aopalliance.intercept.MethodInterceptor;
import org.aopalliance.intercept.MethodInvocation;
import org.springframework.stereotype.Component;

import java.util.List;

/**
 * Title: <br>
 * Description: <br>
 * Company: KingTang <br>
 *
 * @author 金炀
 * @version 1.0
 */
@AllArgsConstructor
@Component
public class  PlugMethodInterceptorimplementsMethodInterceptor {

private final   PanguPlugTool panguPlugTool;

    @Override
public Object invoke(MethodInvocation invocation) throws Throwable {
return panguPlugTool.doBeanInvoke(invocation);
    }
}
```

```
来看com.kingtsoft.pangu.spring.plug.PanguPlugTool.doBeanInvoke
    这里是在实际执行方法时候进入的。methodInvocation.proceed();是执行了原始方法，
在发现覆盖类与被覆盖类一样或者缓存数据无法匹配时，则默认执行了原始方法。
然后匹配List<PlugPojo>这个缓存对象内的数据，没匹配自然也就默认执行原始方法。然后正常
情况下的可以获取覆盖bean的对象。然后根据出参入参加方法名匹配原始方法所对应的覆盖方法。
没找到自然也一样执行原始方法，匹配到了这里就会反射执行方法。并且跳过原始的方法。这里用到
了bean反射，所有执行可以保持spring的上下文。这样就可以无感知替换原始方法。
(使得新方法可以进行动态织入，以后需要改动的内容要抓住一个“变”来灵活抽取，最好抽取后额外
加个标记，例如特定方法名)
```

**java**

```
public Object doBeanInvoke(MethodInvocation methodInvocation) throws Throwable {
    List<PlugPojo> plugPojos =getPlugPojoList();
if (methodInvocation.getThis() ==null|| CollectionUtils.isEmpty(plugPojos)) {
return methodInvocation.proceed();
    }
    Optional<PlugPojo> plugPojo = plugPojos.stream().filter(
        plug -> plug.getAdvisedClass().equals(methodInvocation.getThis().getClass())
    ).findAny();

if (plugPojo.isEmpty()) {
return methodInvocation.proceed();
    }

    Class<?> beanClass = plugPojo.get().getAdviceClass();
    Object bean = applicationContext.getBean(beanClass);

    Optional<Method> method = Arrays.stream(beanClass.getMethods()).filter(
        m ->checkMethod(m, methodInvocation.getMethod())
    ).findAny();

if (method.isPresent()) {
        log.info("代码覆写:"+ method.get().getName());
return method.get().invoke(bean, methodInvocation.getArguments());
    }

return methodInvocation.proceed();
}

privateboolean  checkMethod(Method method, Method tarMethod) {
if (!method.getName().equals(tarMethod.getName())) {
returnfalse;
    }

if (method.getParameterCount() != tarMethod.getParameterCount()) {
returnfalse;
    }

if (!method.getReturnType().equals(tarMethod.getReturnType())) {
returnfalse;
    }

for (int i =0; i < method.getParameterTypes().length; i++) {
if (!method.getParameterTypes()[i].equals(tarMethod.getParameterTypes()[i])) {
returnfalse;
        }
    }

returntrue;
}
```
