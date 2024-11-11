package com.kingtsoft.kingpower.ktemr.business;

import java.lang.reflect.Method;
import java.lang.reflect.Modifier;
import java.net.URL;
import java.net.URLClassLoader;
import java.util.ArrayList;
import java.util.Enumeration;
import java.util.List;
/**
 * WebControllerTest
 *
 * @author Cotton Eye Joe
 * @since 2024/11/5 17:19
 */
public class WebControllerTest {
    public static void main(String[] args) throws Exception {
        // 指定 controller 包所在的路径
        String packagePath = "D:\\kingpower-ktemr\\kingpower-ktemr-business\\src\\main\\java\\com\\kingtsoft\\kingpower\\ktemr\\business\\web\\controller\\qc";
        URL url = new URL("file://" + packagePath);
        URLClassLoader classLoader = new URLClassLoader(new URL[]{url});

        // 遍历包下的所有类
        for (String className : listClassesInPackage(packagePath)) {
            Class<?> clazz = classLoader.loadClass(className);
            // 判断是否是控制器类
            if (isControllerClass(clazz)) {
                // 获取类中的所有方法
                Method[] methods = clazz.getMethods();
                for (Method method : methods) {
                    // 判断方法是否是接口方法
                    if (isInterfaceMethod(method)) {
                        // 调用接口方法
                        Object instance = clazz.getConstructor().newInstance();
                        System.out.println(method.getName());
                        method.invoke(instance);
                    }
                }
            }
        }
    }

    // 判断一个类是否是控制器类
    private static boolean isControllerClass(Class<?> clazz) {
        // 可以根据特定的注解或命名规则来判断，这里只是一个简单的示例
        return clazz.getSimpleName().endsWith("Controller");
    }

    // 判断一个方法是否是接口方法
    private static boolean isInterfaceMethod(Method method) {
        return Modifier.isPublic(method.getModifiers());
    }

    // 列出指定包下的所有类名
    private static String[] listClassesInPackage(String packageName) throws Exception {
        URL url = new URL("file://" + packageName.replace('.', '/'));
        URLClassLoader classLoader = new URLClassLoader(new URL[]{url});
        Enumeration<URL> resources = classLoader.getResources("");
        List<String> classNames = new ArrayList<>();
        while (resources.hasMoreElements()) {
            URL resource = resources.nextElement();
            try {
                if (resource.getPath().endsWith(".class")) {
                    String path = resource.getPath();
                    int startIndex = path.indexOf(packageName);
                    if (startIndex!= -1) {
                        String className = path.substring(startIndex, path.length() - 6).replace('/', '.');
                        classNames.add(className);
                    }
                }
            } catch (Exception e) {
                throw new RuntimeException(e);
            }
        }
        return classNames.toArray(new String[0]);
    }
}
