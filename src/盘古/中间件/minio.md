# Minio模块

> #### 如何使用

```
文件系统也是中心端模式，所以要先部署pangu-storage-minio-server模块
server配置文件如下
```

**yaml**

```
server:
port: 7000
servlet:
context-path: /pangu-minio

pangu:
minio:
endpoint: http://10.1.50.231:9000
accessKey: panguo
secretKey: pango1235
#    bucketName: pangu
# 设置文件请求的最大大小
spring:
servlet:
multipart:
max-file-size: 500MB
max-request-size: 500MB
```

**业务端使用**

```
引入pangu-storage-minio包
```

**xml**

```
<dependency>
  <groupId>com.kingtsoft.pangu</groupId>
  <artifactId>pangu-storage-minio</artifactId>
</dependency>
```

```
    业务模块直接引用api依赖，执行如下图所示，可直接注入panguStorage，并且在业务模块所依附的启动器上引入
pangu-storage-minio模块（注意单纯的注入是没实体的，只是业务模块可以这么做,它无需关注具体实现，具体实现可
根据启动器引入的实现变化而变化），同理，若是在服务器上，则直接放入pangu-storage-minio 的pgr文件即可。
```

**java**

```
private final   PanguStorage panguStorage;

private void   testFile(MultipartFile file, String fileId) {
try {
int mode = FileConst.Mode.FILE_ID;
        fileId = panguStorage.saveFile(BKT_NAME, file.getOriginalFilename(), file.getInputStream(), mode);
        System.out.println("fileId:"+ fileId);
boolean   flag = panguStorage.checkExist(BKT_NAME, fileId);
        System.out.println("是否存在："+ flag);
//            String pre = panguStorage.getPreviewFileUrl(BKT_NAME, fileId);
//            System.out.println("预览地址：" + pre);
        FileStream fileByte = panguStorage.getFileStreamById(BKT_NAME, fileId, mode);
        System.out.println("获取："+ fileByte.getFileName());
boolean   delRet = panguStorage.delFile(BKT_NAME, fileId);
        System.out.println("删除："+ delRet);
boolean   flag2 = panguStorage.checkExist(BKT_NAME, fileId);
        System.out.println("是否存在："+ flag2);
//            String newFileId = panguStorage.copyFile(BKT_NAME, fileId, "test/a", "newname.jpg", mode);
//            boolean   flag3 = panguStorage.checkExist("test/a", newFileId);
//            System.out.println("是否存在：" + flag3);
        List<FileItem> rets = panguStorage.getFileNameList(BKT_NAME +"/fld");
        System.out.println(rets.size());
    } catch (Exception e) {
        e.printStackTrace();
    }
}
```

```
配置文件配置minio地址
```

**yaml**

```
pangu:
	minio:
# 手动指定路径情况下的minio地址
url: 'http://10.1.50.131:7000/pangu-minio/minio'
```

```
解释下几个参数
    bucketName：为桶，其实就是外层文件夹目录，可以根据模块或者项目区分，代码中可以定义在自己的常量内。支持多层目录，例如: test/a/b, 这种入参就会在test桶下创建a目录与b目录
    fileName：文件名称，例如xx.jpg
    fileId：文件ID，存储后会返回一个ID，可能等于fileName
    mode：存储模式   
    0 - id索引（存储的时候会生成8位随机码加上文件名拼接，这种情况下同名文件是可以重复上传的）  1 原始文件名存储，报错（存储时候的文件ID与文件名同名，此时若存储同名文件会报错）
    2 原始文件名存储覆盖（存储时候的文件ID与文件名同名，此时若存储同名文件会覆盖之前的文件）
```

> #### 技术原理

```
    业务模块引用的api为调用的门面接口，里面定义了可操作的行为。实际实现在启动器所依赖的pangu-storage-minio,
而案例截图的配置文件地址为minio的server端，是具体与minio做交互的服务， pangu-storage-minio的功能是通过内
部定义的接口与server端坐HTTP交互。好处是服务交互的服务本身不是集成在业务中，更加集中，且隔离性强。符合基础服务
下沉为公共设施的理念。
API的实现内容
```

**java**

```
@Component
public class  MinioHttpHandlerimplementsPanguStorage {

    @Autowired
private MinioClient minioClient;

    @Autowired
private MinioFileClient minioFileClient;

    @Override
public String saveFile(String bucketName, String fileName, byte[] fileBytes, intmode) {
        InputStream inputStream =newByteArrayInputStream(fileBytes);
        MultipartFile file = FileTool.getMultipartFile(inputStream, fileName);
return minioFileClient.saveFile(file, bucketName, mode);
    }

    @Override
public String saveFile(String bucketName, String fileName, InputStream fileStream, intmode) {
        MultipartFile file = FileTool.getMultipartFile(fileStream, fileName);
return minioFileClient.saveFile(file, bucketName, mode);
    }

    @Override
public FileByte getFileById(String bucketName, String fileId, intmode) {
        Response response = minioFileClient.getFileById(bucketName, fileId, mode);
        InputStream inputStream =null;
try {
            FileByte fileByte =newFileByte();
            fileByte.setFileId(fileId);
            fileByte.setFileName(getFileNameByHeader(response, fileId));

if (response.body() !=null) {
                inputStream = response.body().asInputStream();
                fileByte.setFileByte(inputStream.readAllBytes());
            }

return fileByte;
        } catch (IOException e) {
            e.printStackTrace();
thrownewTipException("文件获取失败！");
        } finally {
if (inputStream !=null) {
try {
                    inputStream.close();
                } catch (IOException e) {
                    e.printStackTrace();
                }
            }
        }
    }

    @Override
public FileStream getFileStreamById(String bucketName, String fileId, intmode) {
        Response response = minioFileClient.getFileById(bucketName, fileId, mode);
        InputStream inputStream;
try {
            FileStream fileStream =newFileStream();
            fileStream.setFileId(fileId);
            fileStream.setFileName(getFileNameByHeader(response, fileId));
if (response.body() !=null) {
                inputStream = response.body().asInputStream();
                fileStream.setStream(inputStream);
            }

return fileStream;
        } catch (IOException e) {
            e.printStackTrace();
thrownewTipException("文件获取失败！");
        }
    }

    @Override
publicboolean  checkExist(String bucketName, String fileId) {
return minioClient.checkExist(bucketName, fileId);
    }

    @Override
publicboolean  delFile(String bucketName, String fileId) {
return minioClient.delFile(bucketName, fileId);
    }

    @Override
public String copyFile(String sourceBucketName, String sourceFileId, String bucketName, String fileName, intmode) {
return minioClient.copyFile(sourceBucketName, sourceFileId, bucketName, fileName, mode);
    }

    @Override
public List<FileItem> getFileNameList(String bucketName) {
return minioClient.getFileNameList(bucketName);
    }

    @Override
public String getPreviewFileUrl(String bucketName, String fileId) {
return minioClient.getPreviewFileUrl(bucketName, fileId);
    }

private String getFileNameByHeader(Response response, String fileId) {
        Collection<String> rets = response.headers().get("content-disposition");
        String fileName;
if (rets.isEmpty()) {
            fileName = fileId;
        } else {
            Iterator<String> iterable = rets.iterator();
            String str = iterable.next();
String[] strArr = str.split(";", -1);
if (strArr.length <2) {
                fileName = fileId;
            } else {
                fileName = str.split(";", -1)[1].substring(9);
                fileName = URLDecoder.decode(fileName, StandardCharsets.UTF_8);
            }
        }

return fileName;
    }
}
```

```
HTTP客户端的定义
```

**java**

```
@FeignResultClient
@PgFeignClient(clientCode= HttpConst.CLIENT_CODE_MINIO, url="${pangu.minio.url}")
public interface  MinioClient {

    @RequestMapping(value="/checkExist/{fileId}")
boolean  checkExist(@RequestParam("bucketName") String bucketName,
                       @PathVariable("fileId") String fileId);

    @RequestMapping("/delFile/{fileId}")
boolean  delFile(@RequestParam("bucketName") String bucketName,
                    @PathVariable("fileId") String fileId);

    @RequestMapping("/copyFile")
    String copyFile(@RequestParam("sourceBucketName") String sourceBucketName,
                    @RequestParam("sourceFileId") String sourceFileId,
                    @RequestParam("bucketName") String bucketName,
                    @RequestParam("fileName") String fileName,
                    @RequestParam("mode") intmode);

    @RequestMapping("/getFileNameList")
    List<FileItem> getFileNameList(@RequestParam("bucketName") String bucketName);

    @RequestMapping("/getPreviewFileUrl/{fileId}")
    String getPreviewFileUrl(@RequestParam("bucketName") String bucketName,
                             @PathVariable("fileId") String fileId);
}
```

```
最后会进入server的实际调用方法(pangu-storage-minio-consumer模块，被SERVER引用的)
```

**java**

```
package com.kingtsoft.pangu.storage.minio.consumer;

import com.kingtsoft.pangu.base.exception.TipException;
import com.kingtsoft.pangu.storage.api.FileItem;
import io.minio.*;
import io.minio.http.Method;
import io.minio.messages.Item;
import org.springframework.stereotype.Component;

import java.io.ByteArrayInputStream;
import java.io.InputStream;
import java.util.ArrayList;
import java.util.List;

/**
 * Title: <br>
 * Description: <br>
 * Company: KingTang <br>
 *
 * @author 金炀
 * @version 1.0
 */
@Component
public class  MinioHandler {

private final   MinioClient minioClient;

publicMinioHandler(MinioClient minioClient) {
this.minioClient = minioClient;
    }

private void  createBucketIfNotExists(String bucketName) {
try {
if (!minioClient.bucketExists(BucketExistsArgs.builder().bucket(bucketName).build())) {
makeBucket(bucketName);
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    /**
     * 创建存储bucket
     *
     * @parambucketName 存储bucket名称
     * @return boolean  
     */
public boolean   makeBucket(String bucketName) {
try {
            minioClient.makeBucket(MakeBucketArgs.builder()
                    .bucket(bucketName)
                    .build());
        } catch (Exception e) {
            e.printStackTrace();
returnfalse;
        }
returntrue;
    }

    /**
     * 删除存储bucket
     *
     * @parambucketName 存储bucket名称
     * @return boolean  
     */
public boolean   removeBucket(String bucketName) {
try {
            minioClient.removeBucket(RemoveBucketArgs.builder()
                    .bucket(bucketName)
                    .build());
        } catch (Exception e) {
            e.printStackTrace();
returnfalse;
        }
returntrue;
    }

    /**
     * 上传文件
     *
     * @paramfileId  文件ID
     * @paramfileBytes
     * @author 金炀
     */
public String saveFile(String bucketName, String fileId, byte[] fileBytes) {
        InputStream inputStream =newByteArrayInputStream(fileBytes);
returnsaveFile(bucketName, fileId, inputStream);
    }

    /**
     * 上传保存文件流
     *
     * @paramfileId   文件ID
     * @paramfilestream 文件流
     * @author 吴艺杰
     */
public String saveFile(String bucketName, String fileId, InputStream filestream) {
try {
createBucketIfNotExists(bucketName);
//开始上传文件
            minioClient.putObject(
                    PutObjectArgs.builder()
                            .bucket(bucketName)
                            .object(fileId)
                            .stream(filestream, filestream.available(), -1)
                            .build());
//最后判断文件是否存在
return minioClient.statObject(StatObjectArgs.builder().bucket(bucketName)
                    .object(fileId).build()).object();
        } catch (Exception e) {
            e.printStackTrace();
thrownewTipException("文件上传失败！");
        }
    }

public InputStream getFileStreamById(String bucketName, String fileId) {
try {
return minioClient.getObject(
                    GetObjectArgs.builder()
                            .bucket(bucketName)
                            .object(fileId).build());
        } catch (Exception e) {
            e.printStackTrace();
thrownewTipException("获取文件失败！");
        }
    }

    /**
     * 查看文件对象
     * @parambucketName 存储bucket名称
     * @return 存储bucket内文件对象信息
     */
public List<FileItem> listObjects(String bucketName) {
        Iterable<Result<Item>> results = minioClient.listObjects(
                ListObjectsArgs.builder().bucket(bucketName).build());
        List<FileItem> objectItems =new ArrayList<>();
try {
for (Result<Item> result : results) {
                Item item = result.get();
                FileItem fileItem =newFileItem();
                fileItem.setFileName(item.objectName());
                fileItem.setSize(item.size());
                objectItems.add(fileItem);
            }
        } catch (Exception e) {
            e.printStackTrace();
returnnull;
        }
return objectItems;
    }

publicboolean  checkExist(String bucketName, String fileId) {
try {
            minioClient.statObject(
                    StatObjectArgs.builder().bucket(bucketName).object(fileId).build()
            );
        } catch (Exception e) {
returnfalse;
        }
returntrue;
    }

publicboolean  delFile(String bucketName, String fileId) {
try {
            minioClient.removeObject(
                    RemoveObjectArgs.builder()
                            .bucket(bucketName)
                            .object(fileId)
                            .build());
returntrue;
        } catch (Exception e) {
            e.printStackTrace();
thrownewTipException("文件删除失败！");
        }
    }

public String copyFile(String sourceBucketName, String sourceFileId, String bucketName, String fileId) {
try {
return minioClient.copyObject(
                    CopyObjectArgs.builder()
                            .bucket(bucketName)
                            .object(fileId)
                            .source(CopySource.builder()
                                            .bucket(sourceBucketName)
                                            .object(sourceFileId)
                                            .build())
                            .build()).object();
        } catch (Exception e) {
            e.printStackTrace();
thrownewTipException("复制失败！");
        }
    }

public StatObjectResponse getFileStat(String bucketName, String fileName) {
try {
return minioClient.statObject(StatObjectArgs.builder()
                    .bucket(bucketName)
                    .object(fileName).build());
        } catch (Exception e) {
thrownewTipException("文件信息获取失败！");
        }
    }

public List<FileItem> getFileNameList(String bucketName, String folderPath) {
try {
            List<FileItem> list =new ArrayList<>();
            Iterable<Result<Item>> results = minioClient.listObjects(ListObjectsArgs.builder()
                    .bucket(bucketName)
                    .prefix(folderPath).recursive(true).build());
for (Result<Item> itemResult : results) {
                FileItem fileItem =newFileItem();
if (folderPath ==null) {
                    fileItem.setFileName(itemResult.get().objectName());
                } else {
                    fileItem.setFileName(itemResult.get().objectName().substring(folderPath.length() +1));
                }
                fileItem.setSize(itemResult.get().size());
                fileItem.setFilepath(folderPath);
                list.add(fileItem);
            }
return list;
        } catch (Exception e) {
            e.printStackTrace();
thrownewTipException("文件目录获取失败！");
        }
    }

public String getPresignedObjectUrl(String bucketName, String fileId) {
try {
            GetPresignedObjectUrlArgs pre = GetPresignedObjectUrlArgs.builder()
                    .method(Method.GET)
                    .bucket(bucketName)
                    .object(fileId)
                    .build();
return minioClient.getPresignedObjectUrl(pre);
        } catch (Exception e) {
            e.printStackTrace();
thrownewTipException("文件预览数据获取错误！");
        }
    }
}
```
