-- =====================================================
-- 秒杀活动电商订单系统数据库设计 - 优化版
-- MySQL 8.0 + InnoDB引擎
-- 优化内容：复合索引、分区策略
-- =====================================================

-- 设置字符集
SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

-- =====================================================
-- 1. 用户表
-- =====================================================
DROP TABLE IF EXISTS `user`;
CREATE TABLE `user` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '用户ID',
  `username` VARCHAR(50) NOT NULL COMMENT '用户名',
  `password` VARCHAR(255) NOT NULL COMMENT '密码（加密存储）',
  `phone` VARCHAR(20) DEFAULT NULL COMMENT '手机号',
  `email` VARCHAR(100) DEFAULT NULL COMMENT '邮箱',
  `nickname` VARCHAR(50) DEFAULT NULL COMMENT '昵称',
  `avatar` VARCHAR(255) DEFAULT NULL COMMENT '头像URL',
  `status` TINYINT NOT NULL DEFAULT 1 COMMENT '状态：0-禁用，1-正常',
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `deleted_at` DATETIME DEFAULT NULL COMMENT '删除时间（软删除）',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_username` (`username`),
  UNIQUE KEY `uk_phone` (`phone`),
  UNIQUE KEY `uk_email` (`email`),
  KEY `idx_status` (`status`),
  KEY `idx_created_at` (`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='用户表';

-- =====================================================
-- 2. 商品表
-- =====================================================
DROP TABLE IF EXISTS `product`;
CREATE TABLE `product` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '商品ID',
  `product_name` VARCHAR(200) NOT NULL COMMENT '商品名称',
  `product_code` VARCHAR(50) NOT NULL COMMENT '商品编码',
  `category_id` BIGINT UNSIGNED DEFAULT NULL COMMENT '分类ID',
  `brand` VARCHAR(100) DEFAULT NULL COMMENT '品牌',
  `main_image` VARCHAR(255) DEFAULT NULL COMMENT '主图URL',
  `description` TEXT COMMENT '商品描述',
  `price` DECIMAL(10,2) NOT NULL COMMENT '商品价格',
  `original_price` DECIMAL(10,2) DEFAULT NULL COMMENT '原价',
  `stock` INT UNSIGNED NOT NULL DEFAULT 0 COMMENT '库存数量',
  `sales` INT UNSIGNED NOT NULL DEFAULT 0 COMMENT '销量',
  `status` TINYINT NOT NULL DEFAULT 1 COMMENT '状态：0-下架，1-上架',
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `deleted_at` DATETIME DEFAULT NULL COMMENT '删除时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_product_code` (`product_code`),
  KEY `idx_category_id` (`category_id`),
  KEY `idx_status` (`status`),
  KEY `idx_created_at` (`created_at`),
  -- 【优化】复合索引：分类+状态+销量（用于分类商品列表排序）
  KEY `idx_category_status_sales` (`category_id`, `status`, `sales` DESC),
  -- 【优化】复合索引：状态+创建时间（用于后台商品管理）
  KEY `idx_status_created` (`status`, `created_at` DESC)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='商品表';

-- =====================================================
-- 3. 秒杀活动表
-- =====================================================
DROP TABLE IF EXISTS `seckill_activity`;
CREATE TABLE `seckill_activity` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '活动ID',
  `activity_name` VARCHAR(100) NOT NULL COMMENT '活动名称',
  `activity_code` VARCHAR(50) NOT NULL COMMENT '活动编码',
  `start_time` DATETIME NOT NULL COMMENT '开始时间',
  `end_time` DATETIME NOT NULL COMMENT '结束时间',
  `description` VARCHAR(500) DEFAULT NULL COMMENT '活动描述',
  `status` TINYINT NOT NULL DEFAULT 0 COMMENT '状态：0-未开始，1-进行中，2-已结束',
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `deleted_at` DATETIME DEFAULT NULL COMMENT '删除时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_activity_code` (`activity_code`),
  KEY `idx_start_time` (`start_time`),
  KEY `idx_end_time` (`end_time`),
  KEY `idx_status` (`status`),
  -- 【优化】复合索引：状态+开始时间（用于查询即将开始的活动）
  KEY `idx_status_start_time` (`status`, `start_time`),
  -- 【优化】复合索引：时间范围查询（用于后台活动管理）
  KEY `idx_time_range` (`start_time`, `end_time`, `status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='秒杀活动表';

-- =====================================================
-- 4. 秒杀商品关联表
-- =====================================================
DROP TABLE IF EXISTS `seckill_product`;
CREATE TABLE `seckill_product` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT 'ID',
  `activity_id` BIGINT UNSIGNED NOT NULL COMMENT '活动ID',
  `product_id` BIGINT UNSIGNED NOT NULL COMMENT '商品ID',
  `seckill_price` DECIMAL(10,2) NOT NULL COMMENT '秒杀价格',
  `seckill_stock` INT UNSIGNED NOT NULL COMMENT '秒杀库存总量',
  `limit_per_user` INT UNSIGNED NOT NULL DEFAULT 1 COMMENT '每用户限购数量',
  `sort_order` INT DEFAULT 0 COMMENT '排序权重',
  `status` TINYINT NOT NULL DEFAULT 1 COMMENT '状态：0-禁用，1-启用',
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_activity_product` (`activity_id`, `product_id`),
  KEY `idx_product_id` (`product_id`),
  KEY `idx_status` (`status`),
  -- 【优化】复合索引：活动+状态+排序（用于展示秒杀商品列表）
  KEY `idx_activity_status_sort` (`activity_id`, `status`, `sort_order` DESC),
  CONSTRAINT `fk_seckill_product_activity` FOREIGN KEY (`activity_id`) REFERENCES `seckill_activity` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_seckill_product_product` FOREIGN KEY (`product_id`) REFERENCES `product` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='秒杀商品关联表';

-- =====================================================
-- 5. 秒杀库存表（独立管理，优化并发性能）
-- =====================================================
DROP TABLE IF EXISTS `seckill_stock`;
CREATE TABLE `seckill_stock` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '库存ID',
  `seckill_product_id` BIGINT UNSIGNED NOT NULL COMMENT '秒杀商品ID',
  `stock` INT UNSIGNED NOT NULL COMMENT '当前库存',
  `initial_stock` INT UNSIGNED NOT NULL COMMENT '初始库存',
  `locked_stock` INT UNSIGNED NOT NULL DEFAULT 0 COMMENT '锁定库存（已下单未支付）',
  `version` INT UNSIGNED NOT NULL DEFAULT 0 COMMENT '乐观锁版本号',
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_seckill_product_id` (`seckill_product_id`),
  KEY `idx_stock` (`stock`),
  -- 【优化】复合索引：库存+锁定库存（用于库存预警查询）
  KEY `idx_stock_locked` (`stock`, `locked_stock`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='秒杀库存表';

-- =====================================================
-- 6. 订单主表（优化版 - 添加复合索引和分区）
-- =====================================================
-- 【分区说明】
-- 1. 使用 RANGE 分区，按 created_at 月份分区
-- 2. 分区优势：
--    - 历史订单归档：可以快速删除/归档旧分区
--    - 查询性能：时间范围查询只扫描相关分区
--    - 维护便捷：可以独立备份/恢复各分区
-- 3. 分区策略：保留最近24个月的数据，超过2年的订单可归档
--
-- 【索引优化说明】
-- 1. 复合索引设计原则：遵循最左前缀原则
-- 2. 索引顺序：选择性高的列在前，查询频率高的组合优先
-- 3. 避免冗余：移除被复合索引覆盖的单列索引

DROP TABLE IF EXISTS `order_info`;
CREATE TABLE `order_info` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '订单ID',
  `order_no` VARCHAR(64) NOT NULL COMMENT '订单编号',
  `user_id` BIGINT UNSIGNED NOT NULL COMMENT '用户ID',
  `activity_id` BIGINT UNSIGNED DEFAULT NULL COMMENT '秒杀活动ID（秒杀订单）',
  `total_amount` DECIMAL(10,2) NOT NULL COMMENT '订单总金额',
  `payment_amount` DECIMAL(10,2) DEFAULT NULL COMMENT '实付金额',
  `discount_amount` DECIMAL(10,2) DEFAULT 0.00 COMMENT '优惠金额',
  `status` TINYINT NOT NULL DEFAULT 0 COMMENT '订单状态：0-待支付，1-已支付，2-已发货，3-已完成，4-已取消，5-已退款',
  `payment_time` DATETIME DEFAULT NULL COMMENT '支付时间',
  `delivery_time` DATETIME DEFAULT NULL COMMENT '发货时间',
  `receive_time` DATETIME DEFAULT NULL COMMENT '收货时间',
  `cancel_time` DATETIME DEFAULT NULL COMMENT '取消时间',
  `expire_time` DATETIME DEFAULT NULL COMMENT '订单过期时间（秒杀订单15分钟）',
  `receiver_name` VARCHAR(50) DEFAULT NULL COMMENT '收货人姓名',
  `receiver_phone` VARCHAR(20) DEFAULT NULL COMMENT '收货人电话',
  `receiver_address` VARCHAR(255) DEFAULT NULL COMMENT '收货地址',
  `remark` VARCHAR(500) DEFAULT NULL COMMENT '订单备注',
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `deleted_at` DATETIME DEFAULT NULL COMMENT '删除时间',
  PRIMARY KEY (`id`, `created_at`),  -- 【重要】分区键必须包含在主键中
  UNIQUE KEY `uk_order_no` (`order_no`),
  
  -- ================== 复合索引优化 ================= --
  
  -- 【复合索引1】用户订单查询（最常见场景）
  -- 场景：用户查看自己的订单列表，按状态筛选，按时间倒序
  -- 查询：SELECT * FROM order_info WHERE user_id = ? AND status = ? ORDER BY created_at DESC
  -- 覆盖：user_id单列查询、user_id+status组合查询、user_id时间排序
  KEY `idx_user_status_time` (`user_id`, `status`, `created_at` DESC),
  
  -- 【复合索引2】用户订单时间查询
  -- 场景：用户查看历史订单，按时间范围查询
  -- 查询：SELECT * FROM order_info WHERE user_id = ? AND created_at BETWEEN ? AND ?
  KEY `idx_user_time` (`user_id`, `created_at` DESC),
  
  -- 【复合索引3】超时订单处理（定时任务）
  -- 场景：扫描待支付订单，检查是否超时
  -- 查询：SELECT * FROM order_info WHERE status = 0 AND expire_time < NOW()
  KEY `idx_status_expire` (`status`, `expire_time`),
  
  -- 【复合索引4】活动订单统计
  -- 场景：统计某活动的订单数量和金额
  -- 查询：SELECT * FROM order_info WHERE activity_id = ? AND status IN (...)
  KEY `idx_activity_status` (`activity_id`, `status`, `created_at` DESC),
  
  -- 【复合索引5】订单状态统计（后台管理）
  -- 场景：后台按状态统计订单数量，按时间筛选
  -- 查询：SELECT * FROM order_info WHERE status = ? AND created_at >= ?
  KEY `idx_status_time` (`status`, `created_at` DESC),
  
  -- 【复合索引6】支付时间统计（财务报表）
  -- 场景：统计某时间段内的支付订单
  -- 查询：SELECT * FROM order_info WHERE payment_time BETWEEN ? AND ?
  KEY `idx_payment_time` (`payment_time`, `status`),
  
  -- 【复合索引7】发货管理
  -- 场景：查询已支付待发货的订单
  -- 查询：SELECT * FROM order_info WHERE status = 1 ORDER BY payment_time
  KEY `idx_status_payment` (`status`, `payment_time`),
  
  -- 保留必要的单列索引（外键关联）
  KEY `idx_activity_id` (`activity_id`),
  
  -- ================== 移除的冗余索引 ================= --
  -- 移除 KEY `idx_user_id` - 被 idx_user_status_time 覆盖
  -- 移除 KEY `idx_status` - 被多个复合索引覆盖
  -- 移除 KEY `idx_created_at` - 被多个复合索引覆盖
  -- 移除 KEY `idx_expire_time` - 被 idx_status_expire 覆盖
  
  CONSTRAINT `fk_order_user` FOREIGN KEY (`user_id`) REFERENCES `user` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_order_activity` FOREIGN KEY (`activity_id`) REFERENCES `seckill_activity` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='订单主表（分区优化版）'
-- ================== 分区策略 ================= --
-- 按创建时间进行RANGE分区，每月一个分区
PARTITION BY RANGE (TO_DAYS(created_at)) (
  -- 历史数据分区（2024年1月前）
  PARTITION p_history VALUES LESS THAN (TO_DAYS('2024-01-01')) COMMENT='历史数据分区',
  
  -- 2024年分区
  PARTITION p202401 VALUES LESS THAN (TO_DAYS('2024-02-01')) COMMENT='2024年1月',
  PARTITION p202402 VALUES LESS THAN (TO_DAYS('2024-03-01')) COMMENT='2024年2月',
  PARTITION p202403 VALUES LESS THAN (TO_DAYS('2024-04-01')) COMMENT='2024年3月',
  PARTITION p202404 VALUES LESS THAN (TO_DAYS('2024-05-01')) COMMENT='2024年4月',
  PARTITION p202405 VALUES LESS THAN (TO_DAYS('2024-06-01')) COMMENT='2024年5月',
  PARTITION p202406 VALUES LESS THAN (TO_DAYS('2024-07-01')) COMMENT='2024年6月',
  PARTITION p202407 VALUES LESS THAN (TO_DAYS('2024-08-01')) COMMENT='2024年7月',
  PARTITION p202408 VALUES LESS THAN (TO_DAYS('2024-09-01')) COMMENT='2024年8月',
  PARTITION p202409 VALUES LESS THAN (TO_DAYS('2024-10-01')) COMMENT='2024年9月',
  PARTITION p202410 VALUES LESS THAN (TO_DAYS('2024-11-01')) COMMENT='2024年10月',
  PARTITION p202411 VALUES LESS THAN (TO_DAYS('2024-12-01')) COMMENT='2024年11月',
  PARTITION p202412 VALUES LESS THAN (TO_DAYS('2025-01-01')) COMMENT='2024年12月',
  
  -- 2025年分区
  PARTITION p202501 VALUES LESS THAN (TO_DAYS('2025-02-01')) COMMENT='2025年1月',
  PARTITION p202502 VALUES LESS THAN (TO_DAYS('2025-03-01')) COMMENT='2025年2月',
  PARTITION p202503 VALUES LESS THAN (TO_DAYS('2025-04-01')) COMMENT='2025年3月',
  PARTITION p202504 VALUES LESS THAN (TO_DAYS('2025-05-01')) COMMENT='2025年4月',
  PARTITION p202505 VALUES LESS THAN (TO_DAYS('2025-06-01')) COMMENT='2025年5月',
  PARTITION p202506 VALUES LESS THAN (TO_DAYS('2025-07-01')) COMMENT='2025年6月',
  PARTITION p202507 VALUES LESS THAN (TO_DAYS('2025-08-01')) COMMENT='2025年7月',
  PARTITION p202508 VALUES LESS THAN (TO_DAYS('2025-09-01')) COMMENT='2025年8月',
  PARTITION p202509 VALUES LESS THAN (TO_DAYS('2025-10-01')) COMMENT='2025年9月',
  PARTITION p202510 VALUES LESS THAN (TO_DAYS('2025-11-01')) COMMENT='2025年10月',
  PARTITION p202511 VALUES LESS THAN (TO_DAYS('2025-12-01')) COMMENT='2025年11月',
  PARTITION p202512 VALUES LESS THAN (TO_DAYS('2026-01-01')) COMMENT='2025年12月',
  
  -- MAXVALUE分区（兜底）
  PARTITION p_future VALUES LESS THAN MAXVALUE COMMENT='未来数据分区'
);

-- =====================================================
-- 7. 订单商品明细表（优化版）
-- =====================================================
DROP TABLE IF EXISTS `order_item`;
CREATE TABLE `order_item` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '订单商品ID',
  `order_id` BIGINT UNSIGNED NOT NULL COMMENT '订单ID',
  `product_id` BIGINT UNSIGNED NOT NULL COMMENT '商品ID',
  `seckill_product_id` BIGINT UNSIGNED DEFAULT NULL COMMENT '秒杀商品ID（秒杀订单）',
  `product_name` VARCHAR(200) NOT NULL COMMENT '商品名称',
  `product_image` VARCHAR(255) DEFAULT NULL COMMENT '商品图片',
  `price` DECIMAL(10,2) NOT NULL COMMENT '商品单价',
  `quantity` INT UNSIGNED NOT NULL COMMENT '购买数量',
  `total_amount` DECIMAL(10,2) NOT NULL COMMENT '小计金额',
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`),
  
  -- ================== 复合索引优化 ================= --
  
  -- 【复合索引1】订单明细查询（最常见场景）
  -- 场景：查询订单的所有商品明细
  -- 查询：SELECT * FROM order_item WHERE order_id = ?
  KEY `idx_order_id` (`order_id`),
  
  -- 【复合索引2】商品销量统计
  -- 场景：统计某商品的销售数量
  -- 查询：SELECT product_id, SUM(quantity) FROM order_item WHERE product_id = ?
  KEY `idx_product_created` (`product_id`, `created_at`),
  
  -- 【复合索引3】秒杀商品统计
  -- 场景：统计某秒杀商品的销售数量
  -- 查询：SELECT * FROM order_item WHERE seckill_product_id = ?
  KEY `idx_seckill_product_created` (`seckill_product_id`, `created_at`),
  
  -- 【优化提示】order_item 表数据量与 order_info 1:N 关系
  -- 如果数据量极大，可考虑按 order_id 进行 HASH 分区
  
  CONSTRAINT `fk_order_item_order` FOREIGN KEY (`order_id`) REFERENCES `order_info` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_order_item_product` FOREIGN KEY (`product_id`) REFERENCES `product` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_order_item_seckill_product` FOREIGN KEY (`seckill_product_id`) REFERENCES `seckill_product` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='订单商品明细表';

-- =====================================================
-- 8. 支付记录表（优化版 - 添加复合索引和分区）
-- =====================================================
DROP TABLE IF EXISTS `payment`;
CREATE TABLE `payment` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '支付ID',
  `payment_no` VARCHAR(64) NOT NULL COMMENT '支付流水号',
  `order_id` BIGINT UNSIGNED NOT NULL COMMENT '订单ID',
  `user_id` BIGINT UNSIGNED NOT NULL COMMENT '用户ID',
  `payment_method` TINYINT NOT NULL COMMENT '支付方式：1-微信，2-支付宝，3-银行卡',
  `payment_amount` DECIMAL(10,2) NOT NULL COMMENT '支付金额',
  `status` TINYINT NOT NULL DEFAULT 0 COMMENT '支付状态：0-待支付，1-支付成功，2-支付失败，3-已退款',
  `trade_no` VARCHAR(100) DEFAULT NULL COMMENT '第三方交易号',
  `payment_time` DATETIME DEFAULT NULL COMMENT '支付时间',
  `callback_time` DATETIME DEFAULT NULL COMMENT '回调时间',
  `callback_content` TEXT DEFAULT NULL COMMENT '回调内容',
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`, `created_at`),  -- 【重要】分区键必须包含在主键中
  UNIQUE KEY `uk_payment_no` (`payment_no`),
  
  -- ================== 复合索引优化 ================= --
  
  -- 【复合索引1】订单支付查询
  -- 场景：查询某订单的支付记录
  KEY `idx_order_status` (`order_id`, `status`),
  
  -- 【复合索引2】用户支付记录
  -- 场景：用户查看支付历史
  KEY `idx_user_time` (`user_id`, `created_at` DESC),
  
  -- 【复合索引3】支付状态处理（定时任务）
  -- 场景：扫描待支付记录
  KEY `idx_status_time` (`status`, `created_at` DESC),
  
  -- 【复合索引4】第三方交易号查询
  -- 场景：根据第三方交易号查询支付记录
  KEY `idx_trade_no` (`trade_no`),
  
  -- 【复合索引5】支付时间统计（财务报表）
  -- 场景：统计某时间段内的支付金额
  KEY `idx_payment_time_status` (`payment_time`, `status`, `payment_method`),
  
  -- 【复合索引6】支付方式统计
  -- 场景：按支付方式统计
  KEY `idx_method_status_time` (`payment_method`, `status`, `created_at` DESC),
  
  -- ================== 移除的冗余索引 ================= --
  -- 移除 KEY `idx_order_id` - 被 idx_order_status 覆盖
  -- 移除 KEY `idx_user_id` - 被 idx_user_time 覆盖
  -- 移除 KEY `idx_status` - 被多个复合索引覆盖
  -- 移除 KEY `idx_created_at` - 被多个复合索引覆盖
  
  CONSTRAINT `fk_payment_order` FOREIGN KEY (`order_id`) REFERENCES `order_info` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_payment_user` FOREIGN KEY (`user_id`) REFERENCES `user` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='支付记录表（分区优化版）'
-- ================== 分区策略 ================= --
PARTITION BY RANGE (TO_DAYS(created_at)) (
  PARTITION p_history VALUES LESS THAN (TO_DAYS('2024-01-01')),
  PARTITION p202401 VALUES LESS THAN (TO_DAYS('2024-02-01')),
  PARTITION p202402 VALUES LESS THAN (TO_DAYS('2024-03-01')),
  PARTITION p202403 VALUES LESS THAN (TO_DAYS('2024-04-01')),
  PARTITION p202404 VALUES LESS THAN (TO_DAYS('2024-05-01')),
  PARTITION p202405 VALUES LESS THAN (TO_DAYS('2024-06-01')),
  PARTITION p202406 VALUES LESS THAN (TO_DAYS('2024-07-01')),
  PARTITION p202407 VALUES LESS THAN (TO_DAYS('2024-08-01')),
  PARTITION p202408 VALUES LESS THAN (TO_DAYS('2024-09-01')),
  PARTITION p202409 VALUES LESS THAN (TO_DAYS('2024-10-01')),
  PARTITION p202410 VALUES LESS THAN (TO_DAYS('2024-11-01')),
  PARTITION p202411 VALUES LESS THAN (TO_DAYS('2024-12-01')),
  PARTITION p202412 VALUES LESS THAN (TO_DAYS('2025-01-01')),
  PARTITION p202501 VALUES LESS THAN (TO_DAYS('2025-02-01')),
  PARTITION p202502 VALUES LESS THAN (TO_DAYS('2025-03-01')),
  PARTITION p202503 VALUES LESS THAN (TO_DAYS('2025-04-01')),
  PARTITION p202504 VALUES LESS THAN (TO_DAYS('2025-05-01')),
  PARTITION p202505 VALUES LESS THAN (TO_DAYS('2025-06-01')),
  PARTITION p202506 VALUES LESS THAN (TO_DAYS('2025-07-01')),
  PARTITION p202507 VALUES LESS THAN (TO_DAYS('2025-08-01')),
  PARTITION p202508 VALUES LESS THAN (TO_DAYS('2025-09-01')),
  PARTITION p202509 VALUES LESS THAN (TO_DAYS('2025-10-01')),
  PARTITION p202510 VALUES LESS THAN (TO_DAYS('2025-11-01')),
  PARTITION p202511 VALUES LESS THAN (TO_DAYS('2025-12-01')),
  PARTITION p202512 VALUES LESS THAN (TO_DAYS('2026-01-01')),
  PARTITION p_future VALUES LESS THAN MAXVALUE
);

-- =====================================================
-- 9. 退款记录表（优化版 - 添加复合索引和分区）
-- =====================================================
DROP TABLE IF EXISTS `refund`;
CREATE TABLE `refund` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '退款ID',
  `refund_no` VARCHAR(64) NOT NULL COMMENT '退款流水号',
  `order_id` BIGINT UNSIGNED NOT NULL COMMENT '订单ID',
  `order_item_id` BIGINT UNSIGNED DEFAULT NULL COMMENT '订单商品ID（部分退款）',
  `user_id` BIGINT UNSIGNED NOT NULL COMMENT '用户ID',
  `payment_id` BIGINT UNSIGNED NOT NULL COMMENT '支付ID',
  `refund_amount` DECIMAL(10,2) NOT NULL COMMENT '退款金额',
  `refund_reason` VARCHAR(500) DEFAULT NULL COMMENT '退款原因',
  `status` TINYINT NOT NULL DEFAULT 0 COMMENT '退款状态：0-待处理，1-退款成功，2-退款失败',
  `refund_time` DATETIME DEFAULT NULL COMMENT '退款时间',
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`, `created_at`),  -- 【重要】分区键必须包含在主键中
  UNIQUE KEY `uk_refund_no` (`refund_no`),
  
  -- ================== 复合索引优化 ================= --
  
  -- 【复合索引1】订单退款查询
  KEY `idx_order_status` (`order_id`, `status`),
  
  -- 【复合索引2】用户退款记录
  KEY `idx_user_time` (`user_id`, `created_at` DESC),
  
  -- 【复合索引3】退款状态处理
  KEY `idx_status_time` (`status`, `created_at` DESC),
  
  -- 【复合索引4】支付退款关联
  KEY `idx_payment_status` (`payment_id`, `status`),
  
  -- 【复合索引5】退款时间统计
  KEY `idx_refund_time` (`refund_time`, `status`),
  
  -- ================== 移除的冗余索引 ================= --
  -- 移除 KEY `idx_order_id` - 被 idx_order_status 覆盖
  -- 移除 KEY `idx_user_id` - 被 idx_user_time 覆盖
  -- 移除 KEY `idx_payment_id` - 被 idx_payment_status 覆盖
  -- 移除 KEY `idx_status` - 被多个复合索引覆盖
  -- 移除 KEY `idx_created_at` - 被多个复合索引覆盖
  
  CONSTRAINT `fk_refund_order` FOREIGN KEY (`order_id`) REFERENCES `order_info` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_refund_order_item` FOREIGN KEY (`order_item_id`) REFERENCES `order_item` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_refund_user` FOREIGN KEY (`user_id`) REFERENCES `user` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_refund_payment` FOREIGN KEY (`payment_id`) REFERENCES `payment` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='退款记录表（分区优化版）'
PARTITION BY RANGE (TO_DAYS(created_at)) (
  PARTITION p_history VALUES LESS THAN (TO_DAYS('2024-01-01')),
  PARTITION p202401 VALUES LESS THAN (TO_DAYS('2024-02-01')),
  PARTITION p202402 VALUES LESS THAN (TO_DAYS('2024-03-01')),
  PARTITION p202403 VALUES LESS THAN (TO_DAYS('2024-04-01')),
  PARTITION p202404 VALUES LESS THAN (TO_DAYS('2024-05-01')),
  PARTITION p202405 VALUES LESS THAN (TO_DAYS('2024-06-01')),
  PARTITION p202406 VALUES LESS THAN (TO_DAYS('2024-07-01')),
  PARTITION p202407 VALUES LESS THAN (TO_DAYS('2024-08-01')),
  PARTITION p202408 VALUES LESS THAN (TO_DAYS('2024-09-01')),
  PARTITION p202409 VALUES LESS THAN (TO_DAYS('2024-10-01')),
  PARTITION p202410 VALUES LESS THAN (TO_DAYS('2024-11-01')),
  PARTITION p202411 VALUES LESS THAN (TO_DAYS('2024-12-01')),
  PARTITION p202412 VALUES LESS THAN (TO_DAYS('2025-01-01')),
  PARTITION p202501 VALUES LESS THAN (TO_DAYS('2025-02-01')),
  PARTITION p202502 VALUES LESS THAN (TO_DAYS('2025-03-01')),
  PARTITION p202503 VALUES LESS THAN (TO_DAYS('2025-04-01')),
  PARTITION p202504 VALUES LESS THAN (TO_DAYS('2025-05-01')),
  PARTITION p202505 VALUES LESS THAN (TO_DAYS('2025-06-01')),
  PARTITION p202506 VALUES LESS THAN (TO_DAYS('2025-07-01')),
  PARTITION p202507 VALUES LESS THAN (TO_DAYS('2025-08-01')),
  PARTITION p202508 VALUES LESS THAN (TO_DAYS('2025-09-01')),
  PARTITION p202509 VALUES LESS THAN (TO_DAYS('2025-10-01')),
  PARTITION p202510 VALUES LESS THAN (TO_DAYS('2025-11-01')),
  PARTITION p202511 VALUES LESS THAN (TO_DAYS('2025-12-01')),
  PARTITION p202512 VALUES LESS THAN (TO_DAYS('2026-01-01')),
  PARTITION p_future VALUES LESS THAN MAXVALUE
);

-- =====================================================
-- 10. 用户购买限制表（限购控制）
-- =====================================================
DROP TABLE IF EXISTS `user_purchase_limit`;
CREATE TABLE `user_purchase_limit` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT 'ID',
  `user_id` BIGINT UNSIGNED NOT NULL COMMENT '用户ID',
  `activity_id` BIGINT UNSIGNED NOT NULL COMMENT '活动ID',
  `product_id` BIGINT UNSIGNED NOT NULL COMMENT '商品ID',
  `purchase_count` INT UNSIGNED NOT NULL DEFAULT 0 COMMENT '已购买数量',
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_user_activity_product` (`user_id`, `activity_id`, `product_id`),
  KEY `idx_activity_id` (`activity_id`),
  KEY `idx_product_id` (`product_id`),
  -- 【优化】复合索引：活动+商品（用于统计商品限购情况）
  KEY `idx_activity_product` (`activity_id`, `product_id`),
  CONSTRAINT `fk_purchase_limit_user` FOREIGN KEY (`user_id`) REFERENCES `user` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_purchase_limit_activity` FOREIGN KEY (`activity_id`) REFERENCES `seckill_activity` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_purchase_limit_product` FOREIGN KEY (`product_id`) REFERENCES `product` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='用户购买限制表';

-- =====================================================
-- 11. 库存操作日志表（审计追踪）- 优化版
-- =====================================================
DROP TABLE IF EXISTS `stock_log`;
CREATE TABLE `stock_log` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '日志ID',
  `seckill_stock_id` BIGINT UNSIGNED NOT NULL COMMENT '秒杀库存ID',
  `order_id` BIGINT UNSIGNED DEFAULT NULL COMMENT '订单ID',
  `user_id` BIGINT UNSIGNED DEFAULT NULL COMMENT '用户ID',
  `operation_type` TINYINT NOT NULL COMMENT '操作类型：1-扣减库存，2-回滚库存，3-锁定库存，4-解锁库存',
  `quantity` INT NOT NULL COMMENT '操作数量',
  `before_stock` INT UNSIGNED NOT NULL COMMENT '操作前库存',
  `after_stock` INT UNSIGNED NOT NULL COMMENT '操作后库存',
  `remark` VARCHAR(500) DEFAULT NULL COMMENT '备注',
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  PRIMARY KEY (`id`, `created_at`),  -- 【重要】分区键必须包含在主键中
  
  -- ================== 复合索引优化 ================= --
  
  -- 【复合索引1】库存操作历史
  KEY `idx_stock_type_time` (`seckill_stock_id`, `operation_type`, `created_at` DESC),
  
  -- 【复合索引2】订单库存记录
  KEY `idx_order_time` (`order_id`, `created_at` DESC),
  
  -- 【复合索引3】用户库存操作
  KEY `idx_user_type_time` (`user_id`, `operation_type`, `created_at` DESC),
  
  -- 【复合索引4】操作类型统计
  KEY `idx_type_time` (`operation_type`, `created_at` DESC),
  
  -- ================== 移除的冗余索引 ================= --
  -- 移除 KEY `idx_seckill_stock_id` - 被 idx_stock_type_time 覆盖
  -- 移除 KEY `idx_order_id` - 被 idx_order_time 覆盖
  -- 移除 KEY `idx_user_id` - 被 idx_user_type_time 覆盖
  -- 移除 KEY `idx_operation_type` - 被 idx_type_time 覆盖
  -- 移除 KEY `idx_created_at` - 被多个复合索引覆盖
  
  CONSTRAINT `fk_stock_log_stock` FOREIGN KEY (`seckill_stock_id`) REFERENCES `seckill_stock` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_stock_log_order` FOREIGN KEY (`order_id`) REFERENCES `order_info` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_stock_log_user` FOREIGN KEY (`user_id`) REFERENCES `user` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='库存操作日志表（分区优化版）'
PARTITION BY RANGE (TO_DAYS(created_at)) (
  PARTITION p_history VALUES LESS THAN (TO_DAYS('2024-01-01')),
  PARTITION p202401 VALUES LESS THAN (TO_DAYS('2024-02-01')),
  PARTITION p202402 VALUES LESS THAN (TO_DAYS('2024-03-01')),
  PARTITION p202403 VALUES LESS THAN (TO_DAYS('2024-04-01')),
  PARTITION p202404 VALUES LESS THAN (TO_DAYS('2024-05-01')),
  PARTITION p202405 VALUES LESS THAN (TO_DAYS('2024-06-01')),
  PARTITION p202406 VALUES LESS THAN (TO_DAYS('2024-07-01')),
  PARTITION p202407 VALUES LESS THAN (TO_DAYS('2024-08-01')),
  PARTITION p202408 VALUES LESS THAN (TO_DAYS('2024-09-01')),
  PARTITION p202409 VALUES LESS THAN (TO_DAYS('2024-10-01')),
  PARTITION p202410 VALUES LESS THAN (TO_DAYS('2024-11-01')),
  PARTITION p202411 VALUES LESS THAN (TO_DAYS('2024-12-01')),
  PARTITION p202412 VALUES LESS THAN (TO_DAYS('2025-01-01')),
  PARTITION p202501 VALUES LESS THAN (TO_DAYS('2025-02-01')),
  PARTITION p202502 VALUES LESS THAN (TO_DAYS('2025-03-01')),
  PARTITION p202503 VALUES LESS THAN (TO_DAYS('2025-04-01')),
  PARTITION p202504 VALUES LESS THAN (TO_DAYS('2025-05-01')),
  PARTITION p202505 VALUES LESS THAN (TO_DAYS('2025-06-01')),
  PARTITION p202506 VALUES LESS THAN (TO_DAYS('2025-07-01')),
  PARTITION p202507 VALUES LESS THAN (TO_DAYS('2025-08-01')),
  PARTITION p202508 VALUES LESS THAN (TO_DAYS('2025-09-01')),
  PARTITION p202509 VALUES LESS THAN (TO_DAYS('2025-10-01')),
  PARTITION p202510 VALUES LESS THAN (TO_DAYS('2025-11-01')),
  PARTITION p202511 VALUES LESS THAN (TO_DAYS('2025-12-01')),
  PARTITION p202512 VALUES LESS THAN (TO_DAYS('2026-01-01')),
  PARTITION p_future VALUES LESS THAN MAXVALUE
);

-- =====================================================
-- 初始化示例数据（可选）
-- =====================================================

-- 插入测试用户
INSERT INTO `user` (`username`, `password`, `phone`, `email`, `nickname`) VALUES
('user001', '$2a$10$test_hash_password_001', '13800138001', 'user001@example.com', '测试用户1'),
('user002', '$2a$10$test_hash_password_002', '13800138002', 'user002@example.com', '测试用户2');

-- 插入测试商品
INSERT INTO `product` (`product_name`, `product_code`, `price`, `original_price`, `stock`, `status`) VALUES
('iPhone 15 Pro Max', 'IPHONE15PM-001', 9999.00, 10999.00, 1000, 1),
('MacBook Pro 16', 'MACBOOKPRO16-001', 19999.00, 21999.00, 500, 1),
('AirPods Pro 2', 'AIRPODSPRO2-001', 1899.00, 1999.00, 2000, 1);

-- 插入测试秒杀活动
INSERT INTO `seckill_activity` (`activity_name`, `activity_code`, `start_time`, `end_time`, `status`) VALUES
('618大促秒杀', '618-2024', '2024-06-18 00:00:00', '2024-06-18 23:59:59', 1),
('双11秒杀专场', 'DOUBLE11-2024', '2024-11-11 00:00:00', '2024-11-11 23:59:59', 0);

SET FOREIGN_KEY_CHECKS = 1;

-- =====================================================
-- 优化总结
-- =====================================================
-- 
-- 【一、复合索引优化】
-- 
-- 1. order_info 表（订单主表）：
--    - idx_user_status_time: 用户订单列表查询（按状态筛选、时间排序）
--    - idx_user_time: 用户历史订单查询（时间范围）
--    - idx_status_expire: 超时订单扫描（定时任务）
--    - idx_activity_status: 秒杀活动订单统计
--    - idx_status_time: 后台订单状态统计
--    - idx_payment_time: 财务支付统计报表
--    - idx_status_payment: 待发货订单管理
--    - 移除冗余索引：idx_user_id, idx_status, idx_created_at, idx_expire_time
--
-- 2. order_item 表（订单明细）：
--    - idx_product_created: 商品销量统计
--    - idx_seckill_product_created: 秒杀商品销量统计
--    - 建议后续按 order_id 进行 HASH 分区（数据量达到千万级时）
--
-- 3. payment 表（支付记录）：
--    - idx_order_status: 订单支付记录查询
--    - idx_user_time: 用户支付历史
--    - idx_status_time: 支付状态处理
--    - idx_payment_time_status: 支付时间统计
--    - idx_method_status_time: 支付方式统计
--    - 移除冗余索引：idx_order_id, idx_user_id, idx_status, idx_created_at
--
-- 4. refund 表（退款记录）：
--    - idx_order_status: 订单退款查询
--    - idx_user_time: 用户退款记录
--    - idx_status_time: 退款状态处理
--    - idx_payment_status: 支付退款关联
--    - idx_refund_time: 退款时间统计
--    - 移除冗余索引：idx_order_id, idx_user_id, idx_payment_id, idx_status, idx_created_at
--
-- 5. stock_log 表（库存日志）：
--    - idx_stock_type_time: 库存操作历史
--    - idx_order_time: 订单库存记录
--    - idx_user_type_time: 用户库存操作
--    - idx_type_time: 操作类型统计
--    - 移除冗余索引：idx_seckill_stock_id, idx_order_id, idx_user_id, idx_operation_type, idx_created_at
--
-- 【二、分区策略优化】
-- 
-- 1. 分区表选择：
--    - order_info: 核心订单表，按月分区
--    - payment: 支付记录表，按月分区
--    - refund: 退款记录表，按月分区
--    - stock_log: 日志表，按月分区
-- 
-- 2. 分区优势：
--    - 历史数据归档：可快速删除/归档旧分区
--    - 查询性能：时间范围查询只扫描相关分区
--    - 维护便捷：独立备份/恢复各分区
--    - 数据管理：超过2年的数据可迁移到历史表
--
-- 3. 分区维护脚本（需要定期执行）：
--    - 每月添加新分区
--    - 归档/删除旧分区
--    - 参见下方维护脚本
--
-- 【三、分区维护脚本示例】
-- 
-- 添加新月份分区（以2026年1月为例）：
-- ALTER TABLE order_info REORGANIZE PARTITION p_future INTO (
--     PARTITION p202601 VALUES LESS THAN (TO_DAYS('2026-02-01')),
--     PARTITION p_future VALUES LESS THAN MAXVALUE
-- );
--
-- 归档旧分区（将2024年1月数据归档到历史表）：
-- CREATE TABLE order_info_archive_202401 LIKE order_info;
-- ALTER TABLE order_info_archive_202401 REMOVE PARTITIONING;
-- INSERT INTO order_info_archive_202401 SELECT * FROM order_info PARTITION (p202401);
-- ALTER TABLE order_info DROP PARTITION p202401;
--
-- 【四、性能优化建议】
-- 
-- 1. 定期执行 ANALYZE TABLE 更新统计信息
-- 2. 监控索引使用情况，及时调整
-- 3. 大批量插入时考虑临时禁用索引
-- 4. 使用 EXPLAIN 分析慢查询
-- 5. 定期优化表（OPTIMIZE TABLE）
--
-- =====================================================