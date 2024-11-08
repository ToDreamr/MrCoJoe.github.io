alter table CON_REQUEST add STATE INTEGER(1);

comment on column CON_REQUEST.STATE is '使用状态(0=停用,1=在用,2=删除)';

alter table CON_SCHEDULE add ID NUMBER(15);

comment on column CON_SCHEDULE.ID is '序号，3+6+6';

alter table PUB_ELEMENT add ALLOW_CUSTOM_INPUT INTEGER(1);

comment on column PUB_ELEMENT.ALLOW_CUSTOM_INPUT is '下拉框是否允许自定义输入：0-不允许，1-允许';

alter table PUB_ELEMENT add DEAL_INCOMING_ELEMENT NUMBER(12);

comment on column PUB_ELEMENT.DEAL_INCOMING_ELEMENT is '代入处置措施元素 ID';

alter table ENR_DIC_HANDOVER_OF_DEPT add type INTEGER(1);

comment on column ENR_DIC_HANDOVER_OF_DEPT.type is '类型（1=护理交班类型，2=医生交班类型） ';

alter table ENR_DIC_TEMPERATURE_CHART_CONF add 'WARD_IDS ' BLOB;

comment on column ENR_DIC_TEMPERATURE_CHART_CONF.'WARD_IDS ' is '适用病区 ';

alter table ENR_NURSING_RECORD_DETAIL add 'REF_CHD_ID ' NUMBER(12);

comment on column ENR_NURSING_RECORD_DETAIL.'REF_CHD_ID ' is '关联病历 ';

alter table ENR_NURSING_RECORD_DETAIL add 'REF_RECORD_NO ' NUMBER(15);

comment on column ENR_NURSING_RECORD_DETAIL.'REF_RECORD_NO ' is '关联护理单 ';

alter table ENR_NURSING_RECORD_DETAIL add 'REF_TIME_POINT ' DATE;

comment on column ENR_NURSING_RECORD_DETAIL.'REF_TIME_POINT ' is '关联护理单时间点 ';

alter table ENR_DIC_NURSING_PLAN add 'OBSERVE ' BLOB;

comment on column ENR_DIC_NURSING_PLAN.'OBSERVE ' is '观察';

alter table ENR_DIC_NURSING_PLAN add 'DETERMINE ' BLOB;

comment on column ENR_DIC_NURSING_PLAN.'DETERMINE ' is '诊断依据';

alter table ENR_DIC_NURSING_PLAN add 'DETERIOR_MEASURE ' BLOB;

comment on column ENR_DIC_NURSING_PLAN.'DETERIOR_MEASURE ' is '恶化措施 ';

alter table ENR_DIC_NURSING_PLAN add 'DEPT_ID ' NUMBER(10);

comment on column ENR_DIC_NURSING_PLAN.'DEPT_ID ' is '适用科室';

alter table ENR_DIC_NURSING_PLAN add 'BRANCH_CODE ' VARCHAR2(10);

comment on column ENR_DIC_NURSING_PLAN.'BRANCH_CODE ' is '适用机构 ';

alter table ENR_DIC_NURSING_PLAN add 'EVALUATE ' blob;

comment on column ENR_DIC_NURSING_PLAN.'EVALUATE ' is '效果评价 ';

alter table ENR_DIC_NURSING_PLAN add 'EVALUATE_TIME ' DATE;

comment on column ENR_DIC_NURSING_PLAN.'EVALUATE_TIME ' is '评价时间 ';

alter table ENR_DIC_NURSING_PLAN add 'EVALUATE_EMPID ' NUMBER(10);

comment on column ENR_DIC_NURSING_PLAN.'EVALUATE_EMPID ' is '评价时间 ';

alter table ENR_NURSING_HANDOVER_RECORD add STATE NUMBER(3) default 1;

comment on column ENR_NURSING_HANDOVER_RECORD.STATE is '状态 1：在用 2：删除';

alter table EMR_APPLY add 'CLASSIFY_ID ' NUMBER(3);

comment on column EMR_APPLY.'CLASSIFY_ID ' is '模板分类id,用于限制新增编辑申请';

alter table EMR_DEFECT_NOTICE_DETAILS add 'APPEAL ' VARCHAR2(1000);

comment on column EMR_DEFECT_NOTICE_DETAILS.'APPEAL ' is '申诉内容';

alter table EMR_DEFECT_NOTICE_DETAILS add 'CONFIRM_STATE ' NUMBER(3);

comment on column EMR_DEFECT_NOTICE_DETAILS.'CONFIRM_STATE ' is '医生确认状态 0待确认 1已确认';

alter table EMR_PARAGRAPH_TEMPLATE add 'DIAG_LIST ' VARCHAR2(128);

comment on column EMR_PARAGRAPH_TEMPLATE.'DIAG_LIST ' is '门诊诊断列表,隔开';

alter table EMR_PARAGRAPH_TEMPLATE add 'SYMPTOM_CODES ' VARCHAR2(64);

comment on column EMR_PARAGRAPH_TEMPLATE.'SYMPTOM_CODES ' is '症状id,隔开';

alter table EMR_PARAGRAPH_TEMPLATE add 'SYMPTOM_NAMES ' VARCHAR2(64);

comment on column EMR_PARAGRAPH_TEMPLATE.'SYMPTOM_NAMES ' is '症状名称,隔开';

alter table EMR_PAT_PRINT_INFO add 'APPLY_WORK_UNIT ' VARCHAR2(20);

comment on column EMR_PAT_PRINT_INFO.'APPLY_WORK_UNIT ' is '申请人工作单位 ';

alter table EMR_PAT_PRINT_INFO add 'APPLY_PHONE ' VARCHAR2(20);

comment on column EMR_PAT_PRINT_INFO.'APPLY_PHONE ' is '申请人联系电话 ';

alter table EMR_PAT_PRINT_INFO add 'FILE_NAME ' VARCHAR2(20);

comment on column EMR_PAT_PRINT_INFO.'FILE_NAME ' is '文件名称';

alter table EMR_RESOURCE add 'INPUTCODE1 ' VARCHAR2(12);

comment on column EMR_RESOURCE.'INPUTCODE1 ' is '拼音码';

alter table EMR_RESOURCE add INPUTCODE2 VARCHAR2(12);

comment on column EMR_RESOURCE.INPUTCODE2 is '五笔码 ';

alter table EMR_RESOURCE_CATALOG add 'INPUTCODE1 ' VARCHAR2(12);

comment on column EMR_RESOURCE.'INPUTCODE1 ' is '拼音码';

alter table EMR_RESOURCE_CATALOG add INPUTCODE2 VARCHAR2(12);

comment on column EMR_RESOURCE.INPUTCODE2 is '五笔码 ';

alter table EMR_SAMPLE_INFO add NAME VARCHAR2(100);

comment on column EMR_SAMPLE_INFO.NAME is '抽样任务名称';

alter table EMR_SAMPLE_INFO add TYPE NUMBER(3);

comment on column EMR_SAMPLE_INFO.TYPE is '类型(1=门诊质控管理，2=交叉质控管理)';

alter table EMR_SCORE_DEFECT add 'DEFECT_CATALOG ' NUMBER(10);

comment on column EMR_SCORE_DEFECT.'DEFECT_CATALOG ' is '缺陷类型 1=住院运行 2=住院病案 3=门诊病历';

alter table EMR_SCORE_DEFECT add 'STD_BASE ' VARCHAR2(64);

comment on column EMR_SCORE_DEFECT.'STD_BASE ' is '缺陷依据 浙江省广东省住院运行质控字典 ';

alter table EMR_SCORE_DEFECT add 'SD_ID_C ' NUMBER(12);

comment on column EMR_SCORE_DEFECT.'SD_ID_C ' is '云端病历缺陷表id ';

alter table EMR_SCORE_DEFECT add 'MIN_SCORES ' NUMBER(4, 1) default 0.0;

comment on column EMR_SCORE_DEFECT.'MIN_SCORES ' is '最小扣分值';

alter table EMR_SCORE_DETAILS add CONTROL_ID VARCHAR2(50);

comment on column EMR_SCORE_DETAILS.CONTROL_ID is '控件id';

alter table EMR_SCORE_ITEMS add ORD NUMBER(10);

comment on column EMR_SCORE_ITEMS.ORD is '排序码';

alter table EMR_SPECIAL_KNOWLEDGE_BASE add 'IS_LAST ' NUMBER(3);

comment on column EMR_SPECIAL_KNOWLEDGE_BASE.'IS_LAST ' is '否末级 0=否 1=';

alter table EMR_WORK_HANDOVER_CONFIG add 'TYPE ' NUMBER(3);

comment on column EMR_WORK_HANDOVER_CONFIG.'TYPE ' is '类型（1=入院，2=出院，3=转入，4=转出，5=病危，6=手术，7=分娩，8=死亡，9=其他，10=护理等级，11=转床，12=气切） ';

alter table EMR_WORK_HANDOVER_CONFIG add 'STATS_RULE ' VARCHAR2(256);

comment on column EMR_WORK_HANDOVER_CONFIG.'STATS_RULE ' is '统计规则(pub_dictionary.type = HANDOVER_STATS_RULE) ';

alter table EMR_WORK_HANDOVER_CONFIG add 'IS_STATS ' NUMBER(3);

comment on column EMR_WORK_HANDOVER_CONFIG.'IS_STATS ' is '是否统计该状态患者，1=是，0=否 ';

alter table EMR_WORK_HANDOVER_CONFIG add 'IS_OPTIONAL ' NUMBER(3);

comment on column EMR_WORK_HANDOVER_CONFIG.'IS_OPTIONAL ' is '是否患者类型可选，1=是，0=否 ';

alter table EMR_WORK_HANDOVER_DETAIL add 'TYPE ' NUMBER(3);

comment on column EMR_WORK_HANDOVER_DETAIL.'TYPE ' is '类型';

alter table EMR_WORK_HANDOVER_DETAIL add 'CONFIG_ID ' VARCHAR2(256);

comment on column EMR_WORK_HANDOVER_DETAIL.'CONFIG_ID ' is '配置表id(emr_work_handover_config.id) ';