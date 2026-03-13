# 秒杀活动电商订单系统 - ER图

## 数据库实体关系图

```mermaid
erDiagram
    %% 用户与商品基础模块
    USER ||--o{ ORDER_INFO : "下单"
    USER ||--o{ PAYMENT : "支付"
    USER ||--o{ REFUND : "退款"
    USER ||--o{ USER_PURCHASE_LIMIT : "限购记录"
    USER ||--o{ STOCK_LOG : "库存操作"
    
    PRODUCT ||--o{ SECKILL_PRODUCT : "参与秒杀"
    PRODUCT ||--o{ ORDER_ITEM : "订单商品"
    PRODUCT ||--o{ USER_PURCHASE_LIMIT : "限购商品"
    
    %% 秒杀核心模块
    SECKILL_ACTIVITY ||--o{ SECKILL_PRODUCT : "包含商品"
    SECKILL_ACTIVITY ||--o{ ORDER_INFO : "秒杀订单"
    SECKILL_ACTIVITY ||--o{ USER_PURCHASE_LIMIT : "限购活动"
    
    SECKILL_PRODUCT ||--|| SECKILL_STOCK : "库存管理"
    SECKILL_PRODUCT ||--o{ ORDER_ITEM : "秒杀订单商品"
    SECKILL_STOCK ||--o{ STOCK_LOG : "库存日志"
    
    %% 订单交易模块
    ORDER_INFO ||--o{ ORDER_ITEM : "包含商品"
    ORDER_INFO ||--o{ PAYMENT : "支付记录"
    ORDER_INFO ||--o{ REFUND : "退款记录"
    ORDER_INFO ||--o{ STOCK_LOG : "库存关联"
    
    PAYMENT ||--o{ REFUND : "退款来源"
    
    %% 表字段定义 - 用户表
    USER {
        BIGINT id PK "用户ID"
        VARCHAR username UK "用户名"
        VARCHAR password "密码"
        VARCHAR phone UK "手机号"
        VARCHAR email UK "邮箱"
        VARCHAR nickname "昵称"
        VARCHAR avatar "头像"
        TINYINT status "状态"
        DATETIME created_at "创建时间"
        DATETIME updated_at "更新时间"
        DATETIME deleted_at "删除时间"
    }
    
    %% 表字段定义 - 商品表
    PRODUCT {
        BIGINT id PK "商品ID"
        VARCHAR product_name "商品名称"
        VARCHAR product_code UK "商品编码"
        BIGINT category_id FK "分类ID"
        VARCHAR brand "品牌"
        VARCHAR main_image "主图"
        TEXT description "描述"
        DECIMAL price "价格"
        DECIMAL original_price "原价"
        INT stock "库存"
        INT sales "销量"
        TINYINT status "状态"
        DATETIME created_at "创建时间"
        DATETIME updated_at "更新时间"
        DATETIME deleted_at "删除时间"
    }
    
    %% 表字段定义 - 秒杀活动表
    SECKILL_ACTIVITY {
        BIGINT id PK "活动ID"
        VARCHAR activity_name "活动名称"
        VARCHAR activity_code UK "活动编码"
        DATETIME start_time "开始时间"
        DATETIME end_time "结束时间"
        VARCHAR description "描述"
        TINYINT status "状态"
        DATETIME created_at "创建时间"
        DATETIME updated_at "更新时间"
        DATETIME deleted_at "删除时间"
    }
    
    %% 表字段定义 - 秒杀商品关联表
    SECKILL_PRODUCT {
        BIGINT id PK "ID"
        BIGINT activity_id FK "活动ID"
        BIGINT product_id FK "商品ID"
        DECIMAL seckill_price "秒杀价"
        INT seckill_stock "库存总量"
        INT limit_per_user "限购数量"
        INT sort_order "排序"
        TINYINT status "状态"
        DATETIME created_at "创建时间"
        DATETIME updated_at "更新时间"
    }
    
    %% 表字段定义 - 秒杀库存表
    SECKILL_STOCK {
        BIGINT id PK "库存ID"
        BIGINT seckill_product_id FK,UK "秒杀商品ID"
        INT stock "当前库存"
        INT initial_stock "初始库存"
        INT locked_stock "锁定库存"
        INT version "乐观锁版本"
        DATETIME created_at "创建时间"
        DATETIME updated_at "更新时间"
    }
    
    %% 表字段定义 - 订单主表
    ORDER_INFO {
        BIGINT id PK "订单ID"
        VARCHAR order_no UK "订单编号"
        BIGINT user_id FK "用户ID"
        BIGINT activity_id FK "活动ID"
        DECIMAL total_amount "总金额"
        DECIMAL payment_amount "实付金额"
        DECIMAL discount_amount "优惠金额"
        TINYINT status "订单状态"
        DATETIME payment_time "支付时间"
        DATETIME delivery_time "发货时间"
        DATETIME receive_time "收货时间"
        DATETIME cancel_time "取消时间"
        DATETIME expire_time "过期时间"
        VARCHAR receiver_name "收货人"
        VARCHAR receiver_phone "收货电话"
        VARCHAR receiver_address "收货地址"
        VARCHAR remark "备注"
        DATETIME created_at "创建时间"
        DATETIME updated_at "更新时间"
        DATETIME deleted_at "删除时间"
    }
    
    %% 表字段定义 - 订单商品明细表
    ORDER_ITEM {
        BIGINT id PK "订单商品ID"
        BIGINT order_id FK "订单ID"
        BIGINT product_id FK "商品ID"
        BIGINT seckill_product_id FK "秒杀商品ID"
        VARCHAR product_name "商品名称"
        VARCHAR product_image "商品图片"
        DECIMAL price "单价"
        INT quantity "数量"
        DECIMAL total_amount "小计"
        DATETIME created_at "创建时间"
        DATETIME updated_at "更新时间"
    }
    
    %% 表字段定义 - 支付记录表
    PAYMENT {
        BIGINT id PK "支付ID"
        VARCHAR payment_no UK "支付流水号"
        BIGINT order_id FK "订单ID"
        BIGINT user_id FK "用户ID"
        TINYINT payment_method "支付方式"
        DECIMAL payment_amount "支付金额"
        TINYINT status "支付状态"
        VARCHAR trade_no "第三方交易号"
        DATETIME payment_time "支付时间"
        DATETIME callback_time "回调时间"
        TEXT callback_content "回调内容"
        DATETIME created_at "创建时间"
        DATETIME updated_at "更新时间"
    }
    
    %% 表字段定义 - 退款记录表
    REFUND {
        BIGINT id PK "退款ID"
        VARCHAR refund_no UK "退款流水号"
        BIGINT order_id FK "订单ID"
        BIGINT order_item_id FK "订单商品ID"
        BIGINT user_id FK "用户ID"
        BIGINT payment_id FK "支付ID"
        DECIMAL refund_amount "退款金额"
        VARCHAR refund_reason "退款原因"
        TINYINT status "退款状态"
        DATETIME refund_time "退款时间"
        DATETIME created_at "创建时间"
        DATETIME updated_at "更新时间"
    }
    
    %% 表字段定义 - 用户购买限制表
    USER_PURCHASE_LIMIT {
        BIGINT id PK "ID"
        BIGINT user_id FK,UK "用户ID"
        BIGINT activity_id FK,UK "活动ID"
        BIGINT product_id FK,UK "商品ID"
        INT purchase_count "已购数量"
        DATETIME created_at "创建时间"
        DATETIME updated_at "更新时间"
    }
    
    %% 表字段定义 - 库存操作日志表
    STOCK_LOG {
        BIGINT id PK "日志ID"
        BIGINT seckill_stock_id FK "秒杀库存ID"
        BIGINT order_id FK "订单ID"
        BIGINT user_id FK "用户ID"
        TINYINT operation_type "操作类型"
        INT quantity "操作数量"
        INT before_stock "操作前库存"
        INT after_stock "操作后库存"
        VARCHAR remark "备注"
        DATETIME created_at "创建时间"
    }
```

## 表关系说明

### 核心关系链

1. **用户 → 订单 → 支付 → 退款**
   - 用户可以创建多个订单
   - 每个订单可以有多个支付记录（支付失败重试）
   - 每个支付可以发起多次退款

2. **活动 → 秒杀商品 → 库存 → 订单商品**
   - 一个秒杀活动包含多个秒杀商品
   - 每个秒杀商品有独立的库存管理
   - 订单商品关联秒杀商品（秒杀订单）

3. **用户 → 购买限制 → 活动+商品**
   - 唯一索引 (user_id, activity_id, product_id) 确保限购

### 防超卖机制

```sql
-- 扣减库存（乐观锁）
UPDATE seckill_stock 
SET stock = stock - ?, version = version + 1 
WHERE seckill_product_id = ? 
  AND stock >= ? 
  AND version = ?;

-- 如果影响行数为0，说明：
-- 1. 库存不足
-- 2. 版本号不匹配（并发冲突）
```

### 订单状态流转

```
0-待支付 → 1-已支付 → 2-已发货 → 3-已完成
    ↓          ↓
4-已取消   5-已退款
```

### 索引设计原则

1. **主键索引**：所有表使用 `BIGINT UNSIGNED AUTO_INCREMENT`
2. **唯一索引**：订单号、支付流水号、退款流水号等业务主键
3. **外键索引**：所有外键字段自动创建索引
4. **查询优化**：status、created_at 等高频查询字段
5. **联合索引**：user_id + activity_id + product_id（限购控制）

## 在线预览

### 方式1：Mermaid Live Editor
访问 [Mermaid Live Editor](https://mermaid.live)，粘贴上面的代码即可查看交互式ER图。

### 方式2：VS Code
安装 "Markdown Preview Mermaid Support" 插件，在Markdown预览中查看。

### 方式3：GitHub/GitLab
直接在Markdown文件中使用 `mermaid` 代码块，平台会自动渲染。

## 数据库连接信息

- **Host**: 115.190.43.83
- **Port**: 3306
- **Database**: p2308a
- **Username**: root
- **Charset**: utf8mb4

## 建表SQL文件

完整建表脚本：`database/seckill_schema.sql`