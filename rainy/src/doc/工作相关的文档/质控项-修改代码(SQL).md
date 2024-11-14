# 质控项-修改代码（SQL）

![1731404853178](image/质控项-修改代码(SQL)/1731404853178.png)

本地提交共三次修改了

1. emrQc包下的部分Mapper.xml中的错误SQL并进行了适配
2. 为方便进行质控的断点调试，修改了部分代理方法的异常抛出和日志打印

#### EmrDefectBaseMapper.xml

getInPatBaseInfo

```SQL
<select id="getInPatBaseInfo" resultType="map">
        SELECT A.NAME,A.SEX,B.VISIT_NO,
               case sex when 1 then '男' when 2 then '女' else '其他' end as SEX_NAME,
               DATE_FORMAT(A.DATE_OF_BIRTH, '%Y-%m-%d %H:%i:%s') DATE_OF_BIRTH,
               (EXTRACT(YEAR FROM B.WARD_IN_TIME) - EXTRACT(YEAR FROM A.DATE_OF_BIRTH)) AS AGE,
               <if test="_databaseId == 'mysql'">
                COALESCE(DATEDIFF(B.CLN_OUT_TIME, B.WARD_IN_TIME), 1) IN_DAY,
               </if>
               <if test="_databaseId == 'oracle'">
                NVL(B.CLN_OUT_TIME - B.WARD_IN_TIME, 1) IN_DAY,
               </if>
               DATE_FORMAT(B.WARD_IN_TIME, '%Y-%m-%d %H') WARD_IN_TIME,
               B.OUT_WAY,
               B.STATE,
               B.DEPT_ID,
               (SELECT NAME FROM PUB_EMP WHERE ID = B.CHIEF_DOCTOR) CHIEF_DOCTOR_NAME,
               (SELECT NAME FROM PUB_DEPT WHERE ID = B.DEPT_ID) AS DEPT_NAME,
               (SELECT NAME FROM PUB_WARD WHERE ID = B.WARD_ID) AS WARD_NAME,
               (SELECT NAME FROM PUB_WARD_BED WHERE ID = B.BED_ID) AS BED_NAME,
               date_format(B.CLN_OUT_TIME, '%Y-%m-%d %H:%i:%s') CLN_OUT_TIME,
               (SELECT ${@com.kingtsoft.kingpower.frame.utils.core.DBUtil@strConcat()}(T1.DIAG_NAME) FROM CIS_IN_PAT_DIAG T1,CIS_DIC_DIAGNOSE_TYPE T2
               WHERE T1.DIAG_TYPE  = T2.ID AND T1.VISIT_ID = B.VISIT_ID
               AND T1.DEL_TIME IS NULL AND T2.STD_ID  = 6) AS OUT_DIAG,
        (SELECT ${@com.kingtsoft.kingpower.frame.utils.core.DBUtil@strConcat()}(DIAG_ICD) FROM CIS_IN_PAT_DIAG_MRHP WHERE MRHP_DIAG_TYPE = 1 AND VISIT_ID= B.VISIT_ID
        AND DIAG_ICD IS NOT NULL AND DIAG_NAME IS NOT NULL
        AND IS_TCM = 0 AND STATUS = 0 AND DEL_TIME IS NULL) DIAG_CODE
        FROM PAT_REGISTER A,CIS_IN_PAT_REG B WHERE A.REG_ID=B.VISIT_ID AND A.REG_ID=#{regId} AND A.SOURCE_TYPE=2
    </select>
```

getStructDataList

```sql
 <select id="getStructDataList" resultType="com.kingtsoft.kingpower.ktemr.business.model.dto.qualitycontrol.EmrCaseHistoryStructDataDTO">
        SELECT A.CHD_ID, A.ED_CODE, A.ED_VERSION, A.NO,
            <if test="_databaseId == 'mysql'">
                A.VALUE,
            </if>
            <if test="_databaseId == 'oracle'">
               CAST(A.VALUE AS VARCHAR2(255)) AS VALUE,
            </if>
               A.CODE, A.ED_ID, A.UNIT, A.CONTROL_ID,
            <if test="_databaseId == 'mysql'">
            A.OBJ_TYPE
            </if>
            <if test="_databaseId == 'oracle'">
                CAST(A.OBJ_TYPE AS VARCHAR2(255)) AS OBJ_TYPE,
            </if> A.DIC_ED_ID,
        B.ch_id, b.cht_id, case when E.dic_id is null then 0 else E.DIC_ID END AS STD_CLASSIFYID, B.TITLE
        FROM EMR_CASE_HISTORY_STRUCT_DATA A
        INNER JOIN EMR_CASE_HISTORY_DOCUMENT B ON A.CHD_ID = B.chd_id
        INNER JOIN EMR_CASE_HISTORY_INFO C ON B.CH_ID = C.CH_ID
        LEFT JOIN EMR_CASE_HISTORY_TEMPLATE D ON B.CHT_ID = D.CHT_ID
        LEFT JOIN EMR_TEMPLATE_CLASSIFY E ON D.classify_id = E.ID
        WHERE C.source_type = #{sourceType} AND C.reg_id = #{regId}
        UNION
        SELECT A.CHD_ID, A.ED_CODE, A.ED_VERSION, A.NO,
        <if test="_databaseId == 'mysql'">
            A.VALUE,
        </if>
        <if test="_databaseId == 'oracle'">
            CAST(A.VALUE AS VARCHAR2(255)) AS VALUE,
        </if>
               A.CODE, A.ED_ID, A.UNIT, A.CONTROL_ID,
        <if test="_databaseId == 'mysql'">
        A.OBJ_TYPE
        </if>
        <if test="_databaseId == 'oracle'">
            CAST(A.OBJ_TYPE AS VARCHAR2(255)) AS OBJ_TYPE,
        </if>A.DIC_ED_ID,
        B.ch_id, b.cht_id, E.dic_id AS STD_CLASSIFYID, B.TITLE
        FROM EMR_CASE_HISTORY_STRUCT_DATA_B A
        INNER JOIN EMR_CASE_HISTORY_DOCUMENT B ON A.CHD_ID = B.chd_id
        INNER JOIN EMR_CASE_HISTORY_INFO C ON B.CH_ID = C.CH_ID
        LEFT JOIN EMR_CASE_HISTORY_TEMPLATE D ON B.CHT_ID = D.CHT_ID
        LEFT JOIN EMR_TEMPLATE_CLASSIFY E ON D.classify_id = E.ID
        WHERE C.source_type = #{sourceType} AND C.reg_id = #{regId}
    </select>
```


CisBizMapper.xml

GetExamReportData

```sql
   <select id="GetExamReportData" resultMap="CisBizInfoMap">
        SELECT R.REPORT_NO BIZ_NO,T.REQ_DOCTOR,T.INPUT_TIME,
        T.ORDER_NAME || ',报告时间:' || DATE_FORMAT(R.REPORT_TIME,'%Y/%m/%d %H:%i') CONTENT
        FROM CIS_EXAM_REPORT R,
        (SELECT B.REPORT_NO,MIN(A.REQ_DOCTOR) REQ_DOCTOR,MIN(A.INPUT_TIME) INPUT_TIME,GROUP_CONCAT((SELECT NAME FROM CIS_DIC_ORDER WHERE ID = B.ORDER_ID)) ORDER_NAME
        FROM CIS_EXAM_REQUEST A,CIS_EXAM_REQUEST_ORDER B
        WHERE A.REQUEST_NO = B.REQUEST_NO
        AND A.ORDER_TYPE IN (${orderType})
        AND A.REG_ID = #{regId} AND A.SOURCE_TYPE = #{sourceType}
        AND B.REPORT_NO IS NOT NULL
        AND B.REPORT_NO NOT IN (SELECT BIZ_NO FROM EMR_BIZ_RELATION WHERE STD_CLASSIFY_ID=#{classifyId} AND REG_ID=#{regId} AND SOURCE_TYPE =#{sourceType})
        GROUP BY B.REPORT_NO) T
        WHERE R.REPORT_NO = T.REPORT_NO
    </select>
```

GetOpsRecord

```sql
 <select id="GetOpsRecord" resultMap="CisBizInfoMap">
        SELECT REQUEST_NO BIZ_NO,A.REQ_DOCTOR,A.INPUT_TIME,
        CONCAT((SELECT GROUP_CONCAT(OPS_NAME) FROM CIS_OPS_REQUEST_ITEM WHERE REQUEST_NO = A.REQUEST_NO) ,
        '主刀:' , (SELECT NAME FROM PUB_EMP WHERE ID = A.SURGEON_DOCTOR)) CONTENT
        FROM CIS_OPS_REQUEST A
        WHERE 2=#{sourceType} AND REG_ID=#{regId}
        AND INVALID_TIME IS NULL
        AND CANCEL_TIME IS NULL
        AND REQUEST_NO NOT IN (SELECT BIZ_NO FROM EMR_BIZ_RELATION WHERE STD_CLASSIFY_ID=#{classifyId}
        AND REG_ID=#{regId} AND SOURCE_TYPE =#{sourceType})
        ORDER BY REQUEST_NO
    </select>
```

GetBloodRecord


```sql
<select id="GetBloodRecord" resultMap="CisBizInfoMap">
        SELECT REQUEST_NO BIZ_NO,A.REQ_DOCTOR,A.INPUT_TIME,
        (SELECT GROUP_CONCAT(S.NAME) FROM CIS_BLOOD_REQ_ORDER T,CIS_DIC_BLOOD_ORDER S
        WHERE T.BLOOD_ORDER = S.ID AND T.REQUEST_NO = A.REQUEST_NO) CONTENT
        FROM CIS_BLOOD_REQUEST A
        WHERE 2=#{sourceType} AND REG_ID=#{regId}
        AND STATE >35 AND IS_EME = 0
        AND INVALID_TIME IS NULL
        AND REQUEST_NO NOT IN (SELECT BIZ_NO FROM EMR_BIZ_RELATION WHERE STD_CLASSIFY_ID=#{classifyId}
        AND REG_ID=#{regId} AND SOURCE_TYPE =#{sourceType})
        ORDER BY REQUEST_NO
    </select>
```

CisCollectionDataMapper.xml

getInPatBaseInfo

```sql
    <select id="getInPatBaseInfo" resultType="java.util.Map">
        SELECT A.REG_ID,A.SOURCE_TYPE,A.PAT_ID,A.BRANCH_CODE,A.NAME,A.SEX,A.DATE_OF_BIRTH,IFNULL(A.MOBILE_PHONE,A.TELE_PHONE) PHONE,
        A.ID_CARD_TYPE,A.ID_CARD,A.ADDR,B.VISIT_NO,B.WARD_IN_TIME,B.CLN_OUT_TIME,B.WARD_OUT_TIME,B.WARD_ID,B.DEPT_ID,B.OUT_WAY,
        B.WORK_GROUP_ID,B.PRIMARY_NURSE,B.RESIDENT_DOCTOR,B.ATTENDING_DOCTOR,B.CHIEF_DOCTOR,B.RESPONSIBILITY_DOCTOR,
        (SELECT MR_NO FROM EMR_HOME_PAGE WHERE VISIT_ID = B.VISIT_ID) MR_NO,
        (SELECT NAME FROM PUB_WARD_BED WHERE ID = B.BED_ID) BED_NAME,
        (SELECT NAME FROM PUB_WARD WHERE ID = B.WARD_ID) WARD_NAME,
        (SELECT NAME FROM PUB_DEPT WHERE ID = B.DEPT_ID) DEPT_NAME,
        (IF((SELECT COUNT(*) FROM EMR_CASE_HISTORY_INFO WHERE REG_ID = A.REG_ID AND SOURCE_TYPE = A.SOURCE_TYPE AND STATUS IN (4,5)) = 0, 0, 1)) FILING_STATE
        FROM PAT_REGISTER A,CIS_IN_PAT_REG B
        WHERE A.SOURCE_TYPE = 2
        AND A.REG_ID = B.VISIT_ID
        AND B.WARD_OUT_TIME BETWEEN #{startDate} AND #{endDate}
        AND B.STATE > 4
        AND (B.IS_INVALID IS NULL OR B.IS_INVALID=0)
        AND (B.MASTER_ID IS NULL OR B.MASTER_ID=0)
    </select>
```

getEmrHomePageOps

```sql
 <select id="getEmrHomePageOps" resultType="java.util.Map">
        SELECT OPS_ID,OPS_INCISION,ANES_GRADE,OPER_TYPE,FROM_TYPE,OPS_HOURS,IS_AMBULATORY_SURGERY,SURGEON_EMPID,FIRST_EMPID,SECOND_EMPID,ANES_EMPID,
        STATUS,REG_ID,SEQ,OPS_ICD,OPS_GRADE,OPS_TIME,OPS_NAME,OPS_HEAL_GRADE,SURGEON_DOCTOR,FIRST_ASSISTANT,SECOND_ASSISTANT,ANES_WAY,ANES_OPERATOR
        FROM EMR_FIRST_PAGE_OPER
        WHERE REG_ID=#{visitId} AND OPS_TIME > (SELECT WARD_IN_TIME FROM CIS_IN_PAT_REG WHERE VISIT_ID = #{visitId})
</select>
```

getCisOpsInfo

```sql
  <select id="getCisOpsInfo" resultType="java.util.Map">
        SELECT A.REQUEST_NO,
        (SELECT NAME FROM CIS_DIC_OPS_PARTS WHERE ID = A.OPS_PARTS) AS OPS_PARTS,
        (SELECT NAME FROM CIS_DIC_OPS_INCISION WHERE ID = A.OPS_INCISION) AS OPS_INCISION,
        (SELECT GROUP_CONCAT(OPS_NAME) FROM CIS_OPS_REQUEST_ITEM WHERE REQUEST_NO = A.REQUEST_NO) OPS_NAME,
        (SELECT GROUP_CONCAT(PARTICI_NAME) FROM CIS_OPS_REQUEST_PARTICI WHERE REQUEST_NO = A.REQUEST_NO AND TYPE_OF_WORK = 1) MAIN_DOCTOR,
        (SELECT GROUP_CONCAT(PARTICI_NAME) FROM CIS_OPS_REQUEST_PARTICI WHERE REQUEST_NO = A.REQUEST_NO AND TYPE_OF_WORK = 2) HELP_DOCTOR,
        (SELECT GROUP_CONCAT(ANES_WAY_NAME) FROM CIS_ANES_REQUEST_ANES_WAY WHERE REQUEST_NO = B.REQUEST_NO) ANES_WAY_NAME,
        B.BEGIN_TIME ANES_BEGIN_TIME,B.END_TIME ANES_END_TIME,A.ARRANGE_OPS_TIME,A.BEGIN_TIME OPS_BEGIN_TIME,A.END_TIME OPS_END_TIME
        FROM CIS_OPS_REQUEST A
        LEFT JOIN CIS_ANES_REQUEST B ON A.ANES_REQUEST_NO = B.REQUEST_NO
        WHERE A.STATE IN (60,80)
        AND A.REG_ID = #{regId} AND A.SOURCE_TYPE = #{sourceType}
        AND A.INVALID_TIME IS NULL
        AND A.CANCEL_TIME IS NULL
        ORDER BY A.REQUEST_NO DESC
    </select>
```

EmrCatalogDoc.xml

getDocInfoByPat

```sql
<select id="getDocInfoByPat" resultMap="EmrDocument">
        SELECT B.CHD_ID,B.CHT_ID,B.TITLE,B.FILE_NAME,B.CREATE_TIME,
        IFNULL((SELECT DISTINCT T2.DIC_ID FROM EMR_CASE_HISTORY_TEMPLATE T1,EMR_TEMPLATE_CLASSIFY T2
        WHERE T1.CLASSIFY_ID = T2.ID AND T1.CHT_ID = B.CHT_ID),-1) STD_CLASSIFY_ID
        FROM EMR_CASE_HISTORY_INFO A,EMR_CASE_HISTORY_DOCUMENT B
        WHERE A.CH_ID = B.CH_ID
        AND A.SOURCE_TYPE = #{sourceType} AND A.REG_ID = #{regId}
        ORDER BY B.CHD_ID
</select>
```

EmrDefectQCMapper.xml

checkEmrHomePageMainDiag

```sql
<select id="checkEmrHomePageMainDiag" resultType="java.lang.Integer">
        SELECT (IF(COUNT(1) = 1, 1, 0))
        FROM CIS_IN_PAT_DIAG_MRHP
        WHERE MRHP_DIAG_TYPE = 1 AND VISIT_ID= #{regId}
        AND DIAG_ICD IS NOT NULL AND DIAG_NAME IS NOT NULL
        AND IS_TCM = 0 AND DEL_TIME IS NULL
</select>
```

checkEmrHomePageOtherDiag
```sql
<select id="checkEmrHomePageOtherDiag" resultType="java.lang.Integer">
        SELECT SUM(f1) FROM (
        SELECT IF(COUNT(1) = 0,0,1) f1
        FROM CIS_IN_PAT_DIAG_MRHP
        WHERE MRHP_DIAG_TYPE != 1 AND VISIT_ID = #{regId} AND DEL_EMPID IS NULL
        UNION ALL
        SELECT IF(COUNT(1) = 0,1,0) f1
        FROM CIS_IN_PAT_DIAG_MRHP
        WHERE MRHP_DIAG_TYPE != 1 AND VISIT_ID = #{regId} AND (DIAG_ICD IS NULL OR LENGTH(DIAG_ICD) <![CDATA[ < ]]> 3) AND DEL_EMPID IS NULL
        ) T
</select>
```