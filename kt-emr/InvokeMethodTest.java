package com.kingtsoft.kingpower.ktemr.business;

import com.kingtsoft.pangu.base.common.JsonResult;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.io.File;
import java.lang.reflect.InvocationTargetException;
import java.lang.reflect.Method;
import java.net.MalformedURLException;
import java.util.*;
import java.util.stream.Collectors;

/**
 * InvokeMethodTest
 *
 * @author Cotton Eye Joe
 * @since 2024/11/6 10:37
 */
@RestController
public class InvokeMethodTest {
    private static final  ClassLoader classLoader = Thread.currentThread().getContextClassLoader();

    @GetMapping("/testInterFace")
    public Object  testInterFace(@RequestParam String packName) throws ClassNotFoundException, InvocationTargetException, NoSuchMethodException, InstantiationException, IllegalAccessException {
        invokeControllerMethod(packName);
        return JsonResult.SUCCESS;
    }
    private static void invokeControllerMethod(String packagePath) throws ClassNotFoundException, NoSuchMethodException, InvocationTargetException, InstantiationException, IllegalAccessException {
        for (String className : listClassNameWithClass(packagePath)){
                Class<?> clazz = classLoader.loadClass(className);
                // 获取类中的所有方法
                Method[] methods = clazz.getMethods();
                String []objectMethodName = new String[]{"wait","equals","toString","hashCode","getClass","notify","notifyAll"};
                HashSet<String> collect = Arrays.stream(objectMethodName).collect(Collectors.toCollection(HashSet::new));
                for (Method method : methods) {
                    // 检查方法参数类型是否为字符串
                    if (!collect.contains(method.getName())) {
                        TestMethod instance = (TestMethod) clazz.getConstructor().newInstance();
                        method.invoke(instance, "传入参数");// 传入对应的参数
                    }
                }
        }
    }

    private static String[] listClassNameWithClass(String packName){
        File file = new File(packName);
        List<String> classNames = new ArrayList<>();

        if (file.isDirectory()){
            int index = packName.lastIndexOf("com");
            String substring = packName.substring(index);
            String packPath = substring.replace("\\", ".");
            StringBuilder builder = new StringBuilder(packPath);
            for (File file1: Objects.requireNonNull(file.listFiles())) {
                if (file1.isDirectory()){
                    builder.append(file1.getName());
                    getFileName(file1,packPath,classNames,builder);
                }
                else {
                    classNames.add(builder.append(file1.getName().replace(".java","")).toString());
                    builder.setLength(0);
                    builder.append(packPath);
                }
            }
        }
        return classNames.toArray(new String[0]);
    }
    private static void getFileName(File file,String basePack,List<String> classNames,StringBuilder builder){
        for (File listFile : Objects.requireNonNull(file.listFiles())) {
            classNames.add(builder.append(listFile.getName().replace(".java","")).toString());
            builder.setLength(0);
            builder.append(basePack).append(listFile.getName());
        }
    }
    public static void main(String[] args) throws MalformedURLException, ClassNotFoundException, InvocationTargetException, NoSuchMethodException, InstantiationException, IllegalAccessException {
//        String[] strings = listClassNameWithClass("D:\\kingpower-ktemr\\kingpower-ktemr-business\\src\\main\\java\\com\\kingtsoft\\kingpower\\ktemr\\business\\web\\controller\\defect.");
//        Arrays.stream(strings).forEach(System.out::println);
        invokeControllerMethod("D:\\kingpower-ktemr\\kingpower-ktemr-business\\src\\main\\java\\com\\kingtsoft\\kingpower\\ktemr\\business\\test.");
    }
}
