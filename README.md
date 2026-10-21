# 智能实验室预约系统（lab-agent）

基于 **FastAPI + Vue 3** 的前后端分离实验室预约管理平台，内置 **AI 智能助手（RAG + Agent）**：可检索实验室知识库、查询实时开放的实验室与设备，并在用户确认后协助提交预约。

## 项目简介

系统面向高校/机构实验室场景，提供以下核心能力：

- **用户体系**：注册 / 登录（JWT 鉴权，密码 bcrypt 加密存储），支持 `student`（学生）与 `admin`（管理员）两种角色；管理员可管理用户、禁用账号。

- **实验室管理**：实验室的增删改查、分页与关键字筛选、开放/关闭状态、开放时间段维护。

- **设备管理**：设备 CRUD，与实验室绑定，支持按实验室、按关键字、按状态（正常/维修）查询。

- **预约与审核**：学生按日期 / 时段预约实验室或单个设备，管理员审核（通过 / 拒绝）；含时段冲突检测、开放时间校验、实验室关闭校验、设备维修校验；后台每分钟自动扫描，将已过期的「待审核」预约置为「已取消」。

- **AI 智能助手**：基于 LangGraph 的 Agent 工作流，SSE 流式输出，可调用 5 个真实工具——知识库检索、开放实验室查询、实验室设备查询、创建预约（需用户确认）、获取今天日期。

- **知识库 RAG**：Chroma 向量库 + `BAAI/bge-small-zh-v1.5` 中文 Embedding 模型，知识源为 `backend/data/kb/*.md`，回答规则 / 安全 / 开放时间类问题时自动引用。

- **文件上传**：头像 / 封面图片等通用上传，100MB 上限，白名单扩展名，落盘到 `backend/uploads/` 并以 `/uploads/...` 静态访问。

- ![arch](./docs/images/arch.jpg)

- ##### 智能体流程

  ![agent_flow](./docs/images/agent_flow.png)
  
  ### 🧠 Agent 记忆体系的工程探索
  在实现智能体对话记忆时，调研了当前三类典型记忆实现方案，本项目采用**消息列表拼接**的实现方式，同时对比另外两种主流方案。
  
  1. **简单消息拼接记忆（本项目采用）**
  将用户与大模型完整对话历史维护在内存 `messages[]` 列表，每一轮请求把全部历史消息一并传给 LLM，配合 LangGraph 完成工具调用流转。
  - 优点：实现简单，不需要额外存储组件，工具调用链路稳定；
  - 缺点：服务重启、会话刷新记忆全部丢失；对话轮次越多上下文token持续膨胀；没有做记忆压缩、持久化存储。
  
  2. **基于框架的结构化记忆（LangGraph Checkpointer + Store，本项目未采用）**
  LangGraph 原生提供的记忆方案，`Checkpointer` 保存Agent每一步执行快照，`Store` 存放跨会话实体事实记忆，支持会话断点恢复、Human‑in‑the‑loop暂停等待人工输入。
  - 优点：原生适配LangGraph工作流，可以暂停、恢复Agent执行状态；
  - 缺点：引入额外持久化存储，增加系统复杂度；业务简单场景下属于过度设计。本项目优先保证业务链路稳定，因此没有接入该套持久记忆。
  
  3. **Claude‑Code 式应用层自治记忆（重点调研，本项目未落地）**
  这是一套很有启发性的**文件驱动的分层记忆架构**，不依赖框架内部状态存储，区分「会话瞬时工作记忆」和「磁盘长期记忆」。
  
  **完整工作流程：**
  - 会话内部：仍然使用普通 `messages[]` 作为瞬时工作记忆，承担本轮对话、工具调用；会话结束之后，这部分内存消息直接销毁，不会永久保存。
  - 后台提取子Agent：当对话token到达阈值，会启动独立的后台提取子Agent，只读取本轮新增对话内容，过滤掉代码、可从源码推导出来的信息，只提炼项目决策、用户偏好、业务约束、踩坑结论等关键信息，写入本地markdown记忆文件（`MEMORY.md`以及细分主题文档）。
  - 会话启动加载：开启新会话时，自动读取记忆文件头部限定大小的内容注入系统提示词；记忆文件存在大小上限，超过阈值会触发自动精简，把细节迁移到其他专题文件，保证启动加载不会爆上下文窗口[[(Claude Cod...)]](https://code.claude.com/docs/fr/memory?f_link_type=f_linkinlinenote&flow_extra=eyJkb2NfcG9zaXRpb24iOjAsImRvY19pZCI6ImRiMTk1NmVlNDdkZjY2YjAtZmE1YmY0MTQ3MWQzMzg0NCIsImlubGluZV9kaXNwbGF5X3Bvc2l0aW9uIjowfQ%3D%3D "[(Claude Cod...)]")。
  - 按需检索：不会把全部历史一股脑塞给模型；当任务需要，再读取对应的记忆文档，做到按需注入。
  
  **优势：**
  1. 和Agent框架解耦，不绑定LangGraph等特定框架，普通对话、工具调用Agent都可以复用这套记忆逻辑；
  2. 天然跨会话、跨进程，重启服务记忆不会丢失；
  3. 控制上下文窗口规模，避免消息无限累积带来token爆炸；
  4. 记忆全部落盘为可读Markdown，人可以直接阅读、编辑、删除记忆内容，可跟随Git版本管理。
  
  **缺点与工程难点：**
  1. 需要额外实现后台提取子Agent、记忆去重、过期记忆清理、文件大小管控；
  2. 记忆提取质量高度依赖提示词；存在漏记、错记、重复记录的风险；
  3. 记忆检索逻辑需要自己实现，增加业务开发成本。
  
  > 感悟：**不存在真正意义上的“AI原生记忆”，LLM 的记忆本质就是挑选一部分文本，在合适时机喂给大模型，区别只在于存储位置、触发时机、压缩策略。**
  > 本项目优先保证 Agent 工具调用、RAG知识库、预约确认业务链路稳定可用；会话记忆仅做内存消息拼接。
  > Claude‑Code这套文件式自治记忆是后续很有价值的迭代方向：后续可以在此项目之上增加记忆提取模块，把关键对话事实持久化，缓解上下文膨胀、会话重启丢失记忆的问题。
  

## 技术栈

### 后端（backend/）

| 类别 | 技术 |
| --- | --- |
| Web 框架 | FastAPI 0.115（Uvicorn 0.34 运行） |
| ORM / 数据库 | SQLAlchemy 2.0 + PyMySQL，MySQL 8 |
| 配置 | pydantic-settings（读取 `backend/.env`） |
| 认证 | PyJWT（HS256）+ OAuth2 Bearer |
| 密码 | bcrypt |
| AI | OpenAI SDK（兼容阿里云百炼 DashScope 接口）、langchain-openai 1.6、langgraph 1.2、langchain-core |
| 向量库 | chromadb 1.5、sentence-transformers 6.0（Embedding: BAAI/bge-small-zh-v1.5） |
| 文件 | python-multipart（流式写盘） |

### 前端（frontend/）

| 类别 | 技术 |
| --- | --- |
| 框架 | Vue 3.5 + Vite 8 |
| UI | Element Plus 2.14 + @element-plus/icons-vue |
| 路由 | Vue Router 5 |
| 请求 | axios（统一 Token 注入与 401 处理） |
| 其它 | marked + dompurify（Markdown 渲染）、prettier |
| Node 要求 | `^22.18.0` 或 `>=24.12.0`（见 frontend/package.json engines） |

### 其它

- **部署**：Docker（`docker-compose.yml` + `backend/Dockerfile`），Python 3.11 slim 镜像，国内镜像源（阿里 PyPI 镜像、hf-mirror）。
- **数据库脚本**：`sql/lab_agent.sql`（MySQL 8 导出，含 8 个实验室、32 个设备、示例用户的完整演示数据）。

## 目录结构

```
lab-agent
├── docker-compose.yml          # 后端 Docker 编排（host 网络模式）
├── sql/
│   └── lab_agent.sql           # MySQL 初始化脚本（建表 + 演示数据）
├── backend/                    # FastAPI 后端
│   ├── .env                    # 本地配置（含密钥，勿提交）
│   ├── Dockerfile              # Python 3.11 + uvicorn
│   ├── requirements.txt        # Python 依赖
│   ├── app/
│   │   ├── main.py             # 应用入口：CORS、异常处理、启动预热向量库、后台扫描任务
│   │   ├── config.py           # 环境变量定义、上传限制与白名单
│   │   ├── database.py         # SQLAlchemy engine / Session / Base
│   │   ├── api/                # 路由层（统一前缀 /api）
│   │   │   ├── auth.py         # 登录 / 注册
│   │   │   ├── user.py         # 用户信息、密码修改、用户管理
│   │   │   ├── lab.py          # 实验室管理
│   │   │   ├── equipment.py    # 设备管理
│   │   │   ├── reservation.py  # 预约列表 / 创建 / 取消 / 审核
│   │   │   ├── files.py        # 文件上传
│   │   │   └── ai.py           # AI 对话 SSE 流（/api/ai/chat/stream）
│   │   ├── models/             # SQLAlchemy 模型：user/lab/equipment/reservation
│   │   ├── schemas/            # Pydantic 请求 / 响应模型
│   │   ├── services/           # 业务逻辑层
│   │   │   ├── agent_service.py    # LangGraph Agent 工作流（流式）
│   │   │   ├── agent_tools.py      # Agent 工具：搜知识库/查实验室/查设备/提交预约/取日期
│   │   │   ├── ai_service.py       # 普通 OpenAI 对话 + 工具调用（未启用路由）
│   │   │   ├── kb_service.py       # Chroma 向量库：加载知识库、检索、启动预热
│   │   │   ├── reservation_service.py  # 预约校验 + 每分钟过期扫描任务
│   │   │   └── ...
│   │   ├── common/             # 统一响应封装、异常与异常处理器
│   │   ├── dependencies/       # JWT 鉴权依赖（get_current_user / get_current_admin）
│   │   └── utils/              # jwt、password 工具
│   ├── data/
│   │   ├── kb/                 # 知识库源文档（.md：预约规则/安全规范/开放时间/设备使用）
│   │   └── chroma/             # 向量库持久化目录（运行时生成）
│   └── uploads/                # 上传文件存储（运行时生成）
├── frontend/                   # Vue3 前端
│   ├── index.html
│   ├── vite.config.js          # /api、/uploads 代理到 127.0.0.1:8000
│   ├── .env.development        # VITE_API_BASE_URL
│   ├── package.json
│   └── src/
│       ├── main.js             # 入口（Element Plus 中文语言包）
│       ├── router/index.js     # 路由 + Token 守卫
│       ├── layouts/Layout.vue  # 主布局（侧边导航）
│       ├── views/              # 页面：Home/Lab/LabList/LabEquipment/Equipment/
│       │                       #   MyReservation/AuditReservation/AIChat/
│       │                       #   Profile/Password/User/Login/Register
│       ├── components/ReserveDialog.vue
│       ├── api/                # 各模块 axios 封装
│       └── utils/              # request（拦截器）/auth（Token）/user
└── deploy/                     # 服务器部署副本：backend.zip 及其解压内容
    └── backend/                # 与 backend/ 内容一致的打包副本
```

## 环境准备

1. **Python 3.11+**（后端）
2. **Node.js** `^22.18.0` 或 `>=24.12.0`（前端，见 `frontend/package.json` engines）
3. **MySQL 8**：创建数据库（脚本内默认库名 `lab_agent`），可导入 `sql/lab_agent.sql` 获得演示数据（含 8 个实验室、32 个设备、示例用户，其中包含 `admin` 管理员账号——正式使用前请修改默认密码）
4. **大模型 API**（AI 功能需要）：阿里云百炼 DashScope 的 **专有（专属）MaaS 节点**，提供兼容 OpenAI 格式的接口地址（`/compatible-mode/v1`）与 API Key。未配置时仅 AI 助手不可用，其余功能不受影响

## 安装 & 启动

### 方式一：本地开发

**① 配置后端环境变量**

```bash
cd backend
cp example.env .env      # Windows: copy example.env .env
# 编辑 .env，填入数据库连接与大模型配置（不要提交含密钥的 .env）
```

**② 启动后端**

```bash
cd backend
pip install -r requirements.txt -i https://pypi.tuna.tsinghua.edu.cn/simple
uvicorn app.main:app --host 127.0.0.1 --port 8000
```

启动说明：

- 首次运行会自动执行 `Base.metadata.create_all` 建表（需数据库已提前创建）；
- 启动阶段会预热向量库：加载 `BAAI/bge-small-zh-v1.5` Embedding 模型（首次需联网下载，约 15s，国内走 `hf-mirror`），并把 `data/kb/*.md` 写入 Chroma（仅向量库为空时导入）；
- 后台每分钟自动扫描过期预约。

**③ 启动前端**

```bash
cd frontend
npm install
npm run dev
```

访问 http://localhost:5173 ，前端已通过 Vite 代理将 `/api`、`/uploads` 转发到 `http://127.0.0.1:8000`。

也可在 VS Code 中直接运行 `.vscode/launch.json` 提供的 **"Python Debugger: FastAPI"** 调试配置启动后端。

### 方式二：Docker 部署后端

```bash
docker compose up -d --build
```

说明：

- 使用 `network_mode: host` 直连宿主机的 `127.0.0.1:3306` MySQL（**host 网络模式仅 Linux 可用**；Windows/Mac Desktop 不支持时请改用默认桥接网络映射端口）；
- 容器内环境变量以 `docker-compose.yml` 的 `environment` 为准（其优先级高于挂载进容器的 `.env`），部署前请替换其中示例的数据库账号密码；
- 自动挂载 `backend/.env`、`backend/uploads`、`backend/model-cache`（HuggingFace 模型缓存，避免每次重建后重新下载模型）；
- `HF_ENDPOINT=https://hf-mirror.com` 已内置，走国内镜像。

## 配置说明（环境变量）

> 模板见 `backend/example.env`（仅变量名，无真实值）。**任何真实密钥都只在本地 `.env` 中填写，不得提交到版本库。**

| 变量 | 说明 | 示例 / 备注 |
| --- | --- | --- |
| `DATABASE_URL` | MySQL 连接串 | `mysql+pymysql://<用户>:<密码>@127.0.0.1:3306/lab_agent` |
| `JWT_SECRET_KEY` | JWT 签名密钥 | 建议随机长字符串，如 `openssl rand -hex 32` |
| `JWT_ALGORITHM` | JWT 算法（默认 HS256） | 可选 |
| `JWT_EXPIRE_HOURS` | Token 有效期（小时，默认 24） | 可选 |
| `LLM_API_KEY` | 阿里云百炼 API Key | AI 功能必填 |
| `LLM_BASE_URL` | 兼容 OpenAI 格式的接口地址 | 如 `<专属节点>/compatible-mode/v1` |
| `LLM_MODEL` | 模型名 | 如 `qwen-plus` |

前端开发地址配置见 `frontend/.env.development`（`VITE_API_BASE_URL`）。

## API 概览

统一前缀 `/api`，除登录/注册外均需 `Authorization: Bearer <token>`；管理员专属接口需 `admin` 角色。响应统一格式：`{ "code": 200, "message": "...", "data": ... }`，分页数据为 `{ "list": [...], "total": n }`。

| 模块 | 方法 & 路径 | 说明 | 权限 |
| --- | --- | --- | --- |
| 认证 | `POST /api/auth/login` | 登录，返回 token + 用户信息 | 公开 |
| 认证 | `POST /api/auth/register` | 注册（默认 student 角色） | 公开 |
| 用户 | `GET /api/user/me` · `PUT /api/user/me` · `PUT /api/user/password` | 当前用户信息 / 修改 | 登录 |
| 用户 | `GET/POST /api/user/list` · `PUT/DELETE /api/user/{id}` | 用户管理 | 管理员 |
| 实验室 | `GET /api/lab/list?page&page_size&keywords&status` · `GET /api/lab/{id}` | 分页 / 详情 | 登录 |
| 实验室 | `POST /api/lab` · `PUT/DELETE /api/lab/{id}` | 增删改 | 管理员 |
| 设备 | `GET /api/equipment/list?page&page_size&keywords&lab_id` | 分页（可按实验室/关键字） | 登录 |
| 设备 | `POST /api/equipment` · `PUT/DELETE /api/equipment/{id}` | 增删改 | 管理员 |
| 预约 | `GET /api/reservation/list?page&page_size&status` | 我的预约（admin 看全部） | 登录 |
| 预约 | `POST /api/reservation` | 创建预约（含冲突检测） | 登录 |
| 预约 | `PUT /api/reservation/{id}/cancel` | 取消（仅待审核） | 登录 |
| 预约 | `PUT /api/reservation/{id}/audit` | 审核 通过(1)/拒绝(2) | 管理员 |
| 文件 | `POST /api/files/upload` | 上传（≤100MB） | 登录 |
| AI | `POST /api/ai/chat/stream` | Agent 对话（SSE 事件流） | 登录 |
| 静态 | `GET /uploads/{文件名}` | 访问上传的资源 | 公开 |
| 健康 | `GET /` | 服务探活 | 公开 |

预约状态约定：`0 待审核 · 1 已通过 · 2 已拒绝 · 3 已取消`。

## 注意事项

1. **密钥安全**：`backend/.env`、`docker-compose.yml` 中出现过密钥/密码等敏感占位，**不要**将其提交到版本库或写进文档；按 `backend/example.env` 模板在本地新建 `.env`。
2. **数据库需提前建库**：后端只在现有库上建表（`create_all`），不会创建数据库本身；建议直接导入 `sql/lab_agent.sql` 获得演示数据。
3. **首次启动会下载 Embedding 模型**：加载 `BAAI/bge-small-zh-v1.5` 需要网络（国内自动走 `https://hf-mirror.com`），耗时取决于网速；断网首次运行可能无法完成向量库预热（仅记日志，服务仍启动）。`.vscode/launch.json` 中预留了 `HF_HUB_OFFLINE=1` 以便在模型已缓存到 `~/.cache/huggingface` 后离线调试。
4. **知识库更新**：`data/kb/*.md` 只在向量库为空时导入一次。更新文档后如需生效，请删除 `backend/data/chroma/` 目录再重启（重新导入）。
5. **AI 功能限制**：未配置 `LLM_API_KEY` / `LLM_BASE_URL` 时 AI 助手不可用；Agent 只能查询与提交预约（须用户确认），不能越权修改数据；"日期"相关回答依赖 `get_today` 工具，请勿故意误导。
6. **Docker 部署**：`network_mode: host` 仅 Linux 有效；容器内 `environment.DATABASE_URL` 会覆盖挂载 `.env` 中的同名变量，部署前务必替换 `docker-compose.yml` 中的示例密码。
7. **前端版本要求**：Node 需 `^22.18.0` 或 `>=24.12.0`（`engines` 约束）；Vite 8 对 Node 版本有要求，版本过低无法启动。
8. **CORS 白名单**：后端仅放行 `http://localhost:5173` 与 `http://127.0.0.1:5173`，换端口/域名需同步修改 `backend/app/main.py` 的 `origins`。
9. **上传限制**：单文件最大 100MB，仅允许 `jpg/jpeg/png/gif/webp/pdf/doc/docx/xls/xlsx/zip`。
10. **默认账号**：初始 `admin` 管理员密码为 bcrypt 哈希存储于 `sql/lab_agent.sql`（无法明文还原）；首次部署请通过管理员后台重置密码，避免演示数据直接暴露在公网。
11. **deploy/ 目录**为服务器部署用的打包副本（`backend.zip`），内容与 `backend/` 一致，日常开发改 `backend/` 即可。