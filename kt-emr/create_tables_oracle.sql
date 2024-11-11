-- 创建会诊类型表 Con_Dic_Type
CREATE TABLE Con_Dic_Type
(
    Con_Type       NUMBER(1) NOT NULL,
    Branch_Code    VARCHAR2(12) NOT NULL,
    Sub_Cht_Id     NUMBER(8) NOT NULL,
    Create_Empid   NUMBER(8) NOT NULL,
    Create_Time    DATE NOT NULL,
    Modify_Empid   NUMBER(8) NOT NULL,
    Modify_Time    DATE NOT NULL,
    Insert_Type    NUMBER(1) NOT NULL
);

COMMENT ON COLUMN Con_Dic_Type.Con_Type IS '会诊类型(0=科室会诊，1=院内大会诊，2=院外会诊,3=MDT会诊)';
COMMENT ON COLUMN Con_Dic_Type.Branch_Code IS '机构代码';
COMMENT ON COLUMN Con_Dic_Type.Sub_Cht_Id IS '会诊病程模板 ID';
COMMENT ON COLUMN Con_Dic_Type.Create_Empid IS '创建人员';
COMMENT ON COLUMN Con_Dic_Type.Create_Time IS '创建时间';
COMMENT ON COLUMN Con_Dic_Type.Modify_Empid IS '修改人员';
COMMENT ON COLUMN Con_Dic_Type.Modify_Time IS '修改时间';
COMMENT ON COLUMN Con_Dic_Type.Insert_Type IS '插入节点 1=发送，2=接收，3=完成';

COMMENT ON TABLE Con_Dic_Type IS '会诊类型表';

ALTER TABLE Con_Dic_Type ADD CONSTRAINT Pk_Con_Dic_Type PRIMARY KEY (Con_Type, Branch_Code);

-- 创建会诊分类明细表 Con_Dic_Type_Detail
CREATE TABLE Con_Dic_Type_Detail
(
    Con_Type          NUMBER(1) NOT NULL,
    Branch_Code       VARCHAR2(12) NOT NULL,
    Seq               NUMBER(4) NOT NULL,
    Name              VARCHAR2(32) NOT NULL,
    Create_Cht_Id     NUMBER(8),
    Summary_Cht_Id    NUMBER(8),
    Invite_Cht_Id     NUMBER(8),
    Is_Up_Sign        NUMBER(1),
    Is_Need_Audit     NUMBER(1),
    State             NUMBER(1),
    Create_Empid      NUMBER(8) NOT NULL,
    Create_Time       DATE NOT NULL,
    Modify_Empid      NUMBER(8) NOT NULL,
    Modify_Time       DATE NOT NULL,
    Default_Deptid    NUMBER(7)
);

COMMENT ON COLUMN Con_Dic_Type_Detail.Con_Type IS '会诊类型(0=科室会诊，1=院内大会诊，2=院外会诊,3=MDT会诊)';
COMMENT ON COLUMN Con_Dic_Type_Detail.Branch_Code IS '机构代码';
COMMENT ON COLUMN Con_Dic_Type_Detail.Seq IS '序号';
COMMENT ON COLUMN Con_Dic_Type_Detail.Name IS '模板名称';
COMMENT ON COLUMN Con_Dic_Type_Detail.Create_Cht_Id IS '主模板';
COMMENT ON COLUMN Con_Dic_Type_Detail.Summary_Cht_Id IS '总结模板';
COMMENT ON COLUMN Con_Dic_Type_Detail.Invite_Cht_Id IS '回复模板';
COMMENT ON COLUMN Con_Dic_Type_Detail.Is_Up_Sign IS '上级医生签名(1=是，0=否)';
COMMENT ON COLUMN Con_Dic_Type_Detail.Is_Need_Audit IS '医务科审核(1=是，0=否)';
COMMENT ON COLUMN Con_Dic_Type_Detail.State IS '状态(1=是，0=否)';
COMMENT ON COLUMN Con_Dic_Type_Detail.Create_Empid IS '创建人员';
COMMENT ON COLUMN Con_Dic_Type_Detail.Create_Time IS '创建时间';
COMMENT ON COLUMN Con_Dic_Type_Detail.Modify_Empid IS '修改人员';
COMMENT ON COLUMN Con_Dic_Type_Detail.Modify_Time IS '修改时间';
COMMENT ON COLUMN Con_Dic_Type_Detail.Default_Deptid IS '默认受邀科室';

COMMENT ON TABLE Con_Dic_Type_Detail IS '会诊分类明细表';

ALTER TABLE Con_Dic_Type_Detail ADD CONSTRAINT Pk_Con_Dic_Type_Detail PRIMARY KEY (Con_Type, Branch_Code, Seq);

-- 创建电子护理文书标准属性表 Enr_Dic_Classify_Info
CREATE TABLE Enr_Dic_Classify_Info
(
    Dic_Id         NUMBER(4) NOT NULL,
    Event_Code     VARCHAR2(12)
);

COMMENT ON COLUMN Enr_Dic_Classify_Info.Dic_Id IS '护理标准文书 ID';
COMMENT ON COLUMN Enr_Dic_Classify_Info.Event_Code IS '绑定的事件代码';

COMMENT ON TABLE Enr_Dic_Classify_Info IS '电子护理文书标准属性';

ALTER TABLE Enr_Dic_Classify_Info ADD CONSTRAINT Pk_Enr_Dic_Classify_Info PRIMARY KEY (Dic_Id);

-- 创建护理计划表 Enr_Event_Sub_Plan
CREATE TABLE Enr_Event_Sub_Plan
(
    Id                 NUMBER(15) NOT NULL,
    Reg_Id             NUMBER(14) NOT NULL,
    Source_Type        NUMBER(2) NOT NULL,
    Plan_Id            NUMBER(8),
    Plan_Name          VARCHAR2(64) DEFAULT '1',
    Is_Manual          NUMBER(1),
    Create_Empid       NUMBER(8),
    Create_Time        DATE,
    State              NUMBER(1),
    Finish_Time        DATE,
    Stop_Time          DATE,
    Stop_Empid         NUMBER(8),
    Event_Name         VARCHAR2(64),
    Event_Code         VARCHAR2(64)
);

COMMENT ON COLUMN Enr_Event_Sub_Plan.Id IS '序号';
COMMENT ON COLUMN Enr_Event_Sub_Plan.Reg_Id IS '就诊号';
COMMENT ON COLUMN Enr_Event_Sub_Plan.Source_Type IS '来源类型';
COMMENT ON COLUMN Enr_Event_Sub_Plan.Plan_Id IS '计划字典 ID';
COMMENT ON COLUMN Enr_Event_Sub_Plan.Plan_Name IS '计划名称';
COMMENT ON COLUMN Enr_Event_Sub_Plan.Is_Manual IS '是否手动添加';
COMMENT ON COLUMN Enr_Event_Sub_Plan.Create_Empid IS '创建人员';
COMMENT ON COLUMN Enr_Event_Sub_Plan.Create_Time IS '创建时间';
COMMENT ON COLUMN Enr_Event_Sub_Plan.State IS '状态';
COMMENT ON COLUMN Enr_Event_Sub_Plan.Finish_Time IS '结束时间';
COMMENT ON COLUMN Enr_Event_Sub_Plan.Stop_Time IS '停止人员';
COMMENT ON COLUMN Enr_Event_Sub_Plan.Stop_Empid IS '停止时间';
COMMENT ON COLUMN Enr_Event_Sub_Plan.Event_Name IS '事件名称';
COMMENT ON COLUMN Enr_Event_Sub_Plan.Event_Code IS '事件代码';

COMMENT ON TABLE Enr_Event_Sub_Plan IS '护理计划表';

ALTER TABLE Enr_Event_Sub_Plan ADD CONSTRAINT Pk_Enr_Event_Sub_Plan PRIMARY KEY (Id);

-- 创建护理计划任务表 Enr_Event_Sub_Plan_Detail
CREATE TABLE Enr_Event_Sub_Plan_Detail
(
    Plan_Id         NUMBER(15) NOT NULL,
    Seq             NUMBER(2) NOT NULL,
    Task_Code       VARCHAR2(16),
    Task_Freq_Type  NUMBER(1),
    Task_Freq       VARCHAR2(512) DEFAULT '1',
    Task_Freq_Name  VARCHAR2(64),
    Delay_Time      NUMBER(8),
    Plan_Stop       NUMBER(8),
    Description     VARCHAR2(64),
    State           NUMBER(1),
    Event_Condition VARCHAR2(256),
    Group_Id        VARCHAR2(256)
);

COMMENT ON COLUMN Enr_Event_Sub_Plan_Detail.Plan_Id IS '计划 ID,EMR_EVENT_SUB_PLAN.ID  3+6+6';
COMMENT ON COLUMN Enr_Event_Sub_Plan_Detail.Seq IS '序号';
COMMENT ON COLUMN Enr_Event_Sub_Plan_Detail.Task_Code IS '任务代码';
COMMENT ON COLUMN Enr_Event_Sub_Plan_Detail.Task_Freq_Type IS '频次类型';
COMMENT ON COLUMN Enr_Event_Sub_Plan_Detail.Task_Freq IS '任务频次,1=立即 =2临时 3=长期';
COMMENT ON COLUMN Enr_Event_Sub_Plan_Detail.Task_Freq_Name IS '频次显示文本';
COMMENT ON COLUMN Enr_Event_Sub_Plan_Detail.Delay_Time IS '延后时长(小时)';
COMMENT ON COLUMN Enr_Event_Sub_Plan_Detail.Plan_Stop IS '预停(次)';
COMMENT ON COLUMN Enr_Event_Sub_Plan_Detail.Description IS '任务描述';
COMMENT ON COLUMN Enr_Event_Sub_Plan_Detail.State IS '状态';
COMMENT ON COLUMN Enr_Event_Sub_Plan_Detail.Event_Condition IS '产生这个任务的事件因素';
COMMENT ON COLUMN Enr_Event_Sub_Plan_Detail.Group_Id IS '分组编码(同组的显示到一起)';

COMMENT ON TABLE Enr_Event_Sub_Plan_Detail IS '护理计划任务表';

ALTER TABLE Enr_Event_Sub_Plan_Detail ADD CONSTRAINT Pk_Enr_Event_Sub_Plan_Detail PRIMARY KEY (Plan_Id, Seq);

-- 创建护理执行项表 Enr_Event_Sub_Task
CREATE TABLE Enr_Event_Sub_Task
(
    Id                 NUMBER(15) NOT NULL,
    Reg_Id             NUMBER(14) NOT NULL,
    Source_Type        NUMBER(2) NOT NULL,
    Plan_Id            NUMBER(15),
    Seq                NUMBER(2),
    Task_Code          VARCHAR2(16),
    State              NUMBER(1),
    Task_Source        VARCHAR2(16),
    Task_Time_Point    DATE,
    Time_Point_Type    NUMBER(1),
    Limit_Time         DATE,
    Exec_Empid         NUMBER(8),
    Exec_Time          DATE,
    Stop_Empid         NUMBER(8),
    Stop_Time          DATE,
    Classify_Id        NUMBER(4),
    Chd_Id             NUMBER(15),
    Record_No          NUMBER(15),
    Time_Point         DATE,
    Create_Empid       NUMBER(8),
    Create_Time        DATE
);

COMMENT ON COLUMN Enr_Event_Sub_Task.Id IS '序号';
COMMENT ON COLUMN Enr_Event_Sub_Task.Reg_Id IS '就诊号';
COMMENT ON COLUMN Enr_Event_Sub_Task.Source_Type IS '来源类型';
COMMENT ON COLUMN Enr_Event_Sub_Task.Plan_Id IS '计划 ID,  3+6+6';
COMMENT ON COLUMN Enr_Event_Sub_Task.Seq IS '序号';
COMMENT ON COLUMN Enr_Event_Sub_Task.Task_Code IS '任务代码';
COMMENT ON COLUMN Enr_Event_Sub_Task.State IS '状态';
COMMENT ON COLUMN Enr_Event_Sub_Task.Task_Source IS '执行来源';
COMMENT ON COLUMN Enr_Event_Sub_Task.Task_Time_Point IS '计划时间点';
COMMENT ON COLUMN Enr_Event_Sub_Task.Time_Point_Type IS '时间点类型';
COMMENT ON COLUMN Enr_Event_Sub_Task.Limit_Time IS '截止时间';
COMMENT ON COLUMN Enr_Event_Sub_Task.Exec_Empid IS '执行人员 ID';
COMMENT ON COLUMN Enr_Event_Sub_Task.Exec_Time IS '执行时间';
COMMENT ON COLUMN Enr_Event_Sub_Task.Stop_Empid IS '停止人员 ID';
COMMENT ON COLUMN Enr_Event_Sub_Task.Stop_Time IS '停止时间';
COMMENT ON COLUMN Enr_Event_Sub_Task.Classify_Id IS '文书标准 ID';
COMMENT ON COLUMN Enr_Event_Sub_Task.Chd_Id IS '病历文档索引';
COMMENT ON COLUMN Enr_Event_Sub_Task.Record_No IS '护理记录单号';
COMMENT ON COLUMN Enr_Event_Sub_Task.Time_Point IS '护理记录单时间点';
COMMENT ON COLUMN Enr_Event_Sub_Task.Create_Empid IS '创建人员';
COMMENT ON COLUMN Enr_Event_Sub_Task.Create_Time IS '创建时间';

COMMENT ON TABLE Enr_Event_Sub_Task IS '护理执行项表';

ALTER TABLE Enr_Event_Sub_Task ADD CONSTRAINT Pk_Enr_Event_Sub_Task PRIMARY KEY (Id);

-- 创建病历诊断对应表 Emr_Case_History_Doc_Diagnosis
CREATE TABLE Emr_Case_History_Doc_Diagnosis
(
    Chd_Id   NUMBER(12) NOT NULL,
    Dia_Ids  VARCHAR2(200),
    Ill_Time DATE
);

COMMENT ON COLUMN Emr_Case_History_Doc_Diagnosis.Chd_Id IS '病历号';
COMMENT ON COLUMN Emr_Case_History_Doc_Diagnosis.Dia_Ids IS '诊断编号集';
COMMENT ON COLUMN Emr_Case_History_Doc_Diagnosis.Ill_Time IS '发病时间';

COMMENT ON TABLE Emr_Case_History_Doc_Diagnosis IS '病历诊断对应表';

ALTER TABLE Emr_Case_History_Doc_Diagnosis ADD CONSTRAINT Pk_Emr_Case_History_Doc_Diagnosis PRIMARY KEY (Chd_Id);

-- 创建病历包评分历史表 Emr_Ch_Doc_Pack_Score_State
CREATE TABLE Emr_Ch_Doc_Pack_Score_State
(
    Ch_Id      NUMBER(12) NOT NULL,
    Pack_Type  NUMBER(1) NOT NULL,
    Oper_Stage NUMBER(1) NOT NULL,
    Stage      NUMBER(1) NOT NULL,
    Qc_Emp     NUMBER(9),
    Qc_Count   NUMBER(3),
    Qc_Lev     NUMBER(1),
    Qc_Score   NUMBER(4,1),
    Qc_Time    DATE,
    Qc_Id      NUMBER(12) NOT NULL
);

COMMENT ON COLUMN Emr_Ch_Doc_Pack_Score_State.Ch_Id IS '病历编号';
COMMENT ON COLUMN Emr_Ch_Doc_Pack_Score_State.Pack_Type IS '病历包类型 1 医生 2 护士';
COMMENT ON COLUMN Emr_Ch_Doc_Pack_Score_State.Oper_Stage IS '评分级别 1 科室 2 质控 3 医生 4 龙头医院审核';
COMMENT ON COLUMN Emr_Ch_Doc_Pack_Score_State.Stage IS '评分阶段 1 环节 2 终末 3 自评 4 审核评分';
COMMENT ON COLUMN Emr_Ch_Doc_Pack_Score_State.Qc_Emp IS '评分人员工号';
COMMENT ON COLUMN Emr_Ch_Doc_Pack_Score_State.Qc_Count IS '评分次数';
COMMENT ON COLUMN Emr_Ch_Doc_Pack_Score_State.Qc_Lev IS '评分级别';
COMMENT ON COLUMN Emr_Ch_Doc_Pack_Score_State.Qc_Score IS '分数';
COMMENT ON COLUMN Emr_Ch_Doc_Pack_Score_State.Qc_Time IS '质控时间';
COMMENT ON COLUMN Emr_Ch_Doc_Pack_Score_State.Qc_Id IS '质控记录编号';

COMMENT ON TABLE Emr_Ch_Doc_Pack_Score_State IS '病历包评分历史表';

ALTER TABLE Emr_Ch_Doc_Pack_Score_State ADD CONSTRAINT Pk_Emr_Ch_Doc_Pack_Score_State PRIMARY KEY (Qc_Id);

-- 创建医生常用工具表 Emr_Common_Emp_Tool
CREATE TABLE Emr_Common_Emp_Tool
(
    Id        VARCHAR2(36) NOT NULL,
    Emp_Id    NUMBER(9) NOT NULL,
    Type      NUMBER(1) NOT NULL,
    Use_Num   NUMBER(3),
    Tool_Id   NUMBER(14) NOT NULL,
    Tool_Name VARCHAR2(256) NOT NULL
);

COMMENT ON COLUMN Emr_Common_Emp_Tool.Id IS 'ID';
COMMENT ON COLUMN Emr_Common_Emp_Tool.Emp_Id IS '医生 ID';
COMMENT ON COLUMN Emr_Common_Emp_Tool.Type IS '分类（1：图片；2：特殊字符；3：医学公式；4：计算公式）';
COMMENT ON COLUMN Emr_Common_Emp_Tool.Use_Num IS '使用次数';
COMMENT ON COLUMN Emr_Common_Emp_Tool.Tool_Id IS '工具 ID';
COMMENT ON COLUMN Emr_Common_Emp_Tool.Tool_Name IS '工具名称';

COMMENT ON TABLE Emr_Common_Emp_Tool IS '医生常用工具';

ALTER TABLE Emr_Common_Emp_Tool ADD CONSTRAINT Pk_Emr_Common_Emp_Tool PRIMARY KEY (Id);

CREATE INDEX Idx_Emp_Id ON Emr_Common_Emp_Tool (Emp_Id);

-- 创建病案归集目录配置表 Emr_Filing_Catalog_Config
CREATE TABLE Emr_Filing_Catalog_Config
(
    Id               NUMBER(5) NOT NULL,
    Catalog_Name     VARCHAR2(64) NOT NULL,
    Parent_Id        NUMBER(5) NOT NULL,
    Std_Dic_List     VARCHAR2(256),
    Key_Words        VARCHAR2(1024),
    No_Key_Words     VARCHAR2(256),
    Is_Show          NUMBER(1) DEFAULT 0,
    Other_Source     NUMBER(2) DEFAULT 0
);

COMMENT ON COLUMN Emr_Filing_Catalog_Config.Id IS 'ID';
COMMENT ON COLUMN Emr_Filing_Catalog_Config.Catalog_Name IS '分类名称';
COMMENT ON COLUMN Emr_Filing_Catalog_Config.Parent_Id IS '上级 id';
COMMENT ON COLUMN Emr_Filing_Catalog_Config.Std_Dic_List IS '相关标准模板分类 ID 集合';
COMMENT ON COLUMN Emr_Filing_Catalog_Config.Key_Words IS '包含关键字';
COMMENT ON COLUMN Emr_Filing_Catalog_Config.No_Key_Words IS '不包含的关键字';
COMMENT ON COLUMN Emr_Filing_Catalog_Config.Is_Show IS '是否必须显示(0:有文档时显示;1 显示)';
COMMENT ON COLUMN Emr_Filing_Catalog_Config.Other_Source IS '文档三方来源分类 ID(0.无,1.化验,2.检查,3.病理,4.住院医嘱,5.门诊处方,6.交接单,7.体温单,8.护理记录,9.手术麻醉,10.辅助检查,,99.其他)';

COMMENT ON TABLE Emr_Filing_Catalog_Config IS '病案归集目录配置表';

ALTER TABLE Emr_Filing_Catalog_Config ADD CONSTRAINT Pk_Emr_Filing_Catalog_Config PRIMARY KEY (Id);

-- 创建电子病历上传日志表 Emr_Home_Upload_Log
CREATE TABLE Emr_Home_Upload_Log
(
    Reg_Id         NUMBER(15) NOT NULL,
    Source_Type    NUMBER(2) NOT NULL,
    Upload_Type    VARCHAR2(8) NOT NULL,
    Upload_Time    DATE,
    Upload_Status  NUMBER(2),
    Upload_Reason  VARCHAR2(1000),
    Upload_Empid   NUMBER(9),
    T_Group        VARCHAR2(10)
);

COMMENT ON COLUMN Emr_Home_Upload_Log.Reg_Id IS '病人就医注册号';
COMMENT ON COLUMN Emr_Home_Upload_Log.Source_Type IS '病人就医类型，1=门诊，2=住院';
COMMENT ON COLUMN Emr_Home_Upload_Log.Upload_Type IS '上传类型，GXYBDRGS，广西医保 drgs 上传';
COMMENT ON COLUMN Emr_Home_Upload_Log.Upload_Time IS '上传时间';
COMMENT ON COLUMN Emr_Home_Upload_Log.Upload_Status IS '上传状态，0=未上传，1=已上传，99=上传失败';
COMMENT ON COLUMN Emr_Home_Upload_Log.Upload_Reason IS '上传错误信息';
COMMENT ON COLUMN Emr_Home_Upload_Log.Upload_Empid IS '上传人员';
COMMENT ON COLUMN Emr_Home_Upload_Log.T_Group IS 'T 组=10001，非 T 组=10002，空=0';

COMMENT ON TABLE Emr_Home_Upload_Log IS '电子病历上传日志表';


ALTER TABLE Emr_Home_Upload_Log ADD CONSTRAINT Pk_Emr_Home_Upload_Log PRIMARY KEY (Reg_Id, Source_Type, Upload_Type);

--创建云端病历缺陷表 Emr_Score_Defect_C

CREATE TABLE Emr_Score_Defect_C
(
    Sd_Id              NUMBER(12) NOT NULL,
    Si_Id              NUMBER(12) NOT NULL,
    Describe           VARCHAR2(1000) NOT NULL,
    Score_Method       VARCHAR2(50) NOT NULL,
    Statistical_Method NUMBER(1) NOT NULL,
    Monitor            VARCHAR2(50),
    Create_Emp_Id      NUMBER(9) NOT NULL,
    Create_Time        DATE NOT NULL,
    Change_Emp_Id      NUMBER(9),
    Change_Time        DATE,
    Enable             VARCHAR2(1) NOT NULL,
    Defect_Type        NUMBER(1),
    Valid_Item_Id      NUMBER(12),
    Inputcode1         VARCHAR2(12),
    Inputcode2         VARCHAR2(12),
    Max_Scores         NUMBER(4,1) DEFAULT 0.0,
    Stage              NUMBER(1),
    Normal_Dept_Code   VARCHAR2(1024) DEFAULT '*',
    Defect_Classify    NUMBER(1) DEFAULT 0,
    Items_Version      NUMBER(8),
    Tp_Id              VARCHAR2(16),
    Defect_Step        NUMBER(2) DEFAULT 0,
    Diag_Id            NUMBER(8),
    Start_Event        NUMBER(1),
    Time_Limit         NUMBER(3),
    Time_Limit_Unit    NUMBER(1),
    Doc_Std_Ids        NUMBER(6),
    Near_Time_Limit    NUMBER(3),
    Diag_Ids           VARCHAR2(1024),
    Display_Cond       VARCHAR2(64),
    Stage_New          VARCHAR2(32),
    Std_Catalog        NUMBER(8),
    Std_Classify       NUMBER(8) DEFAULT 0,
    Defect_Catalog     NUMBER(2) NOT NULL,
    Std_Base           VARCHAR2(64) NOT NULL,
    Min_Scores         NUMBER(4,1) DEFAULT 0.0,
    Sd_Id_C            NUMBER
);

COMMENT ON COLUMN Emr_Score_Defect_C.Sd_Id IS '评分项目';
COMMENT ON COLUMN Emr_Score_Defect_C.Si_Id IS '评分方案编号';
COMMENT ON COLUMN Emr_Score_Defect_C.Describe IS '评分项目描述';
COMMENT ON COLUMN Emr_Score_Defect_C.Score_Method IS '评分方式';
COMMENT ON COLUMN Emr_Score_Defect_C.Statistical_Method IS '分数统计方法(0:单次,1:累积)';
COMMENT ON COLUMN Emr_Score_Defect_C.Monitor IS '监控器';
COMMENT ON COLUMN Emr_Score_Defect_C.Create_Emp_Id IS '创建人员';
COMMENT ON COLUMN Emr_Score_Defect_C.Create_Time IS '创建时间';
COMMENT ON COLUMN Emr_Score_Defect_C.Change_Emp_Id IS '修改人员';
COMMENT ON COLUMN Emr_Score_Defect_C.Change_Time IS '变更时间';
COMMENT ON COLUMN Emr_Score_Defect_C.Enable IS '是否启用(Y/N)';
COMMENT ON COLUMN Emr_Score_Defect_C.Defect_Type IS '缺陷类型 0 缺省 1 按病人';
COMMENT ON COLUMN Emr_Score_Defect_C.Valid_Item_Id IS '验证元素 ID';
COMMENT ON COLUMN Emr_Score_Defect_C.Inputcode1 IS '拼音码';
COMMENT ON COLUMN Emr_Score_Defect_C.Inputcode2 IS '五笔码';
COMMENT ON COLUMN Emr_Score_Defect_C.Max_Scores IS '最大扣分值';
COMMENT ON COLUMN Emr_Score_Defect_C.Stage IS '适用评分环节(不再使用)';
COMMENT ON COLUMN Emr_Score_Defect_C.Normal_Dept_Code IS '标准科室代码';
COMMENT ON COLUMN Emr_Score_Defect_C.Defect_Classify IS '缺陷分类 默认 0 未分类 1 时效, 2.限时提醒';
COMMENT ON COLUMN Emr_Score_Defect_C.Items_Version IS '缺陷项目版本';
COMMENT ON COLUMN Emr_Score_Defect_C.Tp_Id IS '任务计划编号';
COMMENT ON COLUMN Emr_Score_Defect_C.Defect_Step IS '质控环节步骤 0 默认未分类 7 编码';
COMMENT ON COLUMN Emr_Score_Defect_C.Diag_Id IS '质控适用诊断 ID(停用)';
COMMENT ON COLUMN Emr_Score_Defect_C.Start_Event IS '关联事件，1=入院，2=出院，3=转科，4=手术，5=死亡，6=转床，7=抢救';
COMMENT ON COLUMN Emr_Score_Defect_C.Time_Limit IS '时限';
COMMENT ON COLUMN Emr_Score_Defect_C.Time_Limit_Unit IS '时限单位，1=小时，2=天';
COMMENT ON COLUMN Emr_Score_Defect_C.Doc_Std_Ids IS '文书标准 ID';
COMMENT ON COLUMN Emr_Score_Defect_C.Near_Time_Limit IS '近时提醒时间';
COMMENT ON COLUMN Emr_Score_Defect_C.Diag_Ids IS '质控适用多个诊断 ID';
COMMENT ON COLUMN Emr_Score_Defect_C.Display_Cond IS '数据显示条件 ID(多个)';
COMMENT ON COLUMN Emr_Score_Defect_C.Stage_New IS '适用评分环节多选(0 默认全部 1 环节 2 终末 3 自评 4 院级 5 交叉质控 6 首页质控 7 运行病历 8 病历完成 9 编码)';
COMMENT ON COLUMN Emr_Score_Defect_C.Std_Catalog IS '标准指控目录 ID';
COMMENT ON COLUMN Emr_Score_Defect_C.Std_Classify IS '关联病历标准分类(0 表示通用)';
COMMENT ON COLUMN Emr_Score_Defect_C.Defect_Catalog IS '缺陷类型 1=住院运行 2=住院病案 3=门诊病历';
COMMENT ON COLUMN Emr_Score_Defect_C.Std_Base IS '缺陷依据 浙江省/广东省住院运行质控字典';
COMMENT ON COLUMN Emr_Score_Defect_C.Min_Scores IS '最小扣分值';
COMMENT ON COLUMN Emr_Score_Defect_C.Sd_Id_C IS 'sd_id_c';

COMMENT ON TABLE Emr_Score_Defect_C IS '云端病历缺陷表';


ALTER TABLE Emr_Score_Defect_C ADD CONSTRAINT Pk_Emr_Score_Defect_C PRIMARY KEY (Std_Base, Defect_Catalog, Sd_Id);

--创建病历评分历史表 Emr_Score_Details_State
CREATE TABLE Emr_Score_Details_State
(
    Ch_Id         NUMBER(12) NOT NULL,
    Stage         NUMBER(1) NOT NULL,
    Sd_Id         NUMBER(12) NOT NULL,
    Defect_Count  NUMBER(8,2) NOT NULL,
    Scores        NUMBER(4,1) DEFAULT 0.0 NOT NULL,
    Review_Emp_Id NUMBER(9) NOT NULL,
    Review_Time   DATE NOT NULL,
    Items_Version NUMBER(8),
    Location      VARCHAR2(250),
    Chd_Id        NUMBER(12),
    Seq           NUMBER(3) DEFAULT 0,
    Si_Type       NUMBER(1) DEFAULT 0,
    Si_Id         NUMBER(12) DEFAULT 0 NOT NULL,
    State         NUMBER(1) DEFAULT 1,
    Oper_Stage    NUMBER(1),
    Describe      VARCHAR2(100),
    Control_Id    VARCHAR2(50),
    Qc_Id         NUMBER(12) NOT NULL
);

COMMENT ON COLUMN Emr_Score_Details_State.Ch_Id IS '病历编号';
COMMENT ON COLUMN Emr_Score_Details_State.Stage IS '评分阶段(1:环节评分;2:终末评分;3:自评或门诊评分 4:审核评分 5:交叉评分)';
COMMENT ON COLUMN Emr_Score_Details_State.Sd_Id IS '评分项目';
COMMENT ON COLUMN Emr_Score_Details_State.Defect_Count IS '缺陷数量';
COMMENT ON COLUMN Emr_Score_Details_State.Scores IS '扣掉的分数';
COMMENT ON COLUMN Emr_Score_Details_State.Review_Emp_Id IS '评审人员,-1:为系统定时评分';
COMMENT ON COLUMN Emr_Score_Details_State.Review_Time IS '评审时间';
COMMENT ON COLUMN Emr_Score_Details_State.Items_Version IS '缺陷方案版本';
COMMENT ON COLUMN Emr_Score_Details_State.Location IS '缺陷位置';
COMMENT ON COLUMN Emr_Score_Details_State.Chd_Id IS '病历文档编号';
COMMENT ON COLUMN Emr_Score_Details_State.Seq IS '序号';
COMMENT ON COLUMN Emr_Score_Details_State.Si_Type IS '评分类型 0 电子病历 1 电子护理 2 治疗师 3 住院电子病历 4 门诊电子病历 5 留观电子病历 21 非质控治疗师';
COMMENT ON COLUMN Emr_Score_Details_State.Si_Id IS '评分方案主键 ID';
COMMENT ON COLUMN Emr_Score_Details_State.State IS '状态 1 再用 0 已修复 2 已删除';
COMMENT ON COLUMN Emr_Score_Details_State.Oper_Stage IS '操作员评分阶段(1 科室 2 质控办病案室 3 医生 4 龙头医院审核)';
COMMENT ON COLUMN Emr_Score_Details_State.Describe IS '评分描述';
COMMENT ON COLUMN Emr_Score_Details_State.Control_Id IS '控件 id';
COMMENT ON COLUMN Emr_Score_Details_State.Qc_Id IS '质控记录编号';

COMMENT ON TABLE Emr_Score_Details_State IS '病历评分历史表';


ALTER TABLE Emr_Score_Details_State ADD CONSTRAINT Pk_Emr_Score_Details_State PRIMARY KEY (Ch_Id, Stage, Sd_Id, Si_Id, Qc_Id);
ALTER TABLE Emr_Score_Details_State ADD CONSTRAINT Emr_Score_Details_Pk UNIQUE (Ch_Id, Stage, Sd_Id, Si_Id, Qc_Id);

--创建质控目录表 Emr_Score_Item_Catalog
CREATE TABLE Emr_Score_Item_Catalog
(
    Id    NUMBER(12) NOT NULL,
    Title VARCHAR2(64) NOT NULL
);

COMMENT ON COLUMN Emr_Score_Item_Catalog.Id IS '目录编号';
COMMENT ON COLUMN Emr_Score_Item_Catalog.Title IS '标题';

COMMENT ON TABLE Emr_Score_Item_Catalog IS '质控目录表';


ALTER TABLE Emr_Score_Item_Catalog ADD CONSTRAINT Pk_Emr_Score_Item_Catalog PRIMARY KEY (Id);

--创建标准缺陷监控表 Emr_Std_Defect_Monitor
CREATE TABLE Emr_Std_Defect_Monitor
(
    Dm_Id NUMBER(12) NOT NULL,
    Name  VARCHAR2(256) NOT NULL,
    Tips  VARCHAR2(256)
);

COMMENT ON COLUMN Emr_Std_Defect_Monitor.Dm_Id IS '缺陷监控编号';
COMMENT ON COLUMN Emr_Std_Defect_Monitor.Name IS '缺陷名称';
COMMENT ON COLUMN Emr_Std_Defect_Monitor.Tips IS '提示内容';

COMMENT ON TABLE Emr_Std_Defect_Monitor IS '标准缺陷监控表';


ALTER TABLE Emr_Std_Defect_Monitor ADD CONSTRAINT Pk_Emr_Std_Defect_Monitor PRIMARY KEY (Dm_Id);

--交叉质控管理病历抽样详细信息 Emr_Sample_Cross_Detail
CREATE TABLE Emr_Sample_Cross_Detail
(
    Sample_Id    NUMBER(16) NOT NULL,
    Ch_Id        NUMBER(12) NOT NULL,
    Review_Empid NUMBER(9) DEFAULT 0,
    Scored_State NUMBER(2),
    Check_Empid  NUMBER(9)
);

COMMENT ON COLUMN Emr_Sample_Cross_Detail.Sample_Id IS '抽样编号';
COMMENT ON COLUMN Emr_Sample_Cross_Detail.Ch_Id IS '电子病历编号';
COMMENT ON COLUMN Emr_Sample_Cross_Detail.Review_Empid IS '评分人员 ID';
COMMENT ON COLUMN Emr_Sample_Cross_Detail.Scored_State IS '评分状态：0 未完成 1 评分完成';
COMMENT ON COLUMN Emr_Sample_Cross_Detail.Check_Empid IS '复核人员 ID';

COMMENT ON TABLE Emr_Sample_Cross_Detail IS '交叉质控管理病历抽样详细信息';

ALTER TABLE Emr_Sample_Cross_Detail ADD CONSTRAINT Pk_Emr_Sample_Cross_Detail PRIMARY KEY (Sample_Id, Ch_Id);