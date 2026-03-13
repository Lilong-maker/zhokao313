-- =====================================================
-- 秒杀活动电商订单系统数据库设计
-- MySQL 8.0 + InnoDB引擎
-- 支持功能：库存扣减、订单创建、支付、退款、库存回滚、限购、防超卖
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
  KEY `idx_created_at` (`created_at`)
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
  KEY `idx_status` (`status`)
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
  CONSTRAINT `fk_seckill_stock_product` FOREIGN KEY (`seckill_product_id`) REFERENCES `seckill_product` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='秒杀库存表';

-- =====================================================
-- 6. 订单主表
-- =====================================================
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
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_order_no` (`order_no`),
  KEY `idx_user_id` (`user_id`),
  KEY `idx_activity_id` (`activity_id`),
  KEY `idx_status` (`status`),
  KEY `idx_created_at` (`created_at`),
  KEY `idx_expire_time` (`expire_time`),
  CONSTRAINT `fk_order_user` FOREIGN KEY (`user_id`) REFERENCES `user` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_order_activity` FOREIGN KEY (`activity_id`) REFERENCES `seckill_activity` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='订单主表';

-- =====================================================
-- 7. 订单商品明细表
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
  KEY `idx_order_id` (`order_id`),
  KEY `idx_product_id` (`product_id`),
  KEY `idx_seckill_product_id` (`seckill_product_id`),
  CONSTRAINT `fk_order_item_order` FOREIGN KEY (`order_id`) REFERENCES `order_info` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_order_item_product` FOREIGN KEY (`product_id`) REFERENCES `product` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_order_item_seckill_product` FOREIGN KEY (`seckill_product_id`) REFERENCES `seckill_product` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='订单商品明细表';

-- =====================================================
-- 8. 支付记录表
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
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_payment_no` (`payment_no`),
  KEY `idx_order_id` (`order_id`),
  KEY `idx_user_id` (`user_id`),
  KEY `idx_status` (`status`),
  KEY `idx_trade_no` (`trade_no`),
  KEY `idx_created_at` (`created_at`),
  CONSTRAINT `fk_payment_order` FOREIGN KEY (`order_id`) REFERENCES `order_info` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_payment_user` FOREIGN KEY (`user_id`) REFERENCES `user` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='支付记录表';

-- =====================================================
-- 9. 退款记录表
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
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_refund_no` (`refund_no`),
  KEY `idx_order_id` (`order_id`),
  KEY `idx_user_id` (`user_id`),
  KEY `idx_payment_id` (`payment_id`),
  KEY `idx_status` (`status`),
  KEY `idx_created_at` (`created_at`),
  CONSTRAINT `fk_refund_order` FOREIGN KEY (`order_id`) REFERENCES `order_info` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_refund_order_item` FOREIGN KEY (`order_item_id`) REFERENCES `order_item` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_refund_user` FOREIGN KEY (`user_id`) REFERENCES `user` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_refund_payment` FOREIGN KEY (`payment_id`) REFERENCES `payment` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='退款记录表';

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
  CONSTRAINT `fk_purchase_limit_user` FOREIGN KEY (`user_id`) REFERENCES `user` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_purchase_limit_activity` FOREIGN KEY (`activity_id`) REFERENCES `seckill_activity` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_purchase_limit_product` FOREIGN KEY (`product_id`) REFERENCES `product` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='用户购买限制表';

-- =====================================================
-- 11. 库存操作日志表（审计追踪）
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
  PRIMARY KEY (`id`),
  KEY `idx_seckill_stock_id` (`seckill_stock_id`),
  KEY `idx_order_id` (`order_id`),
  KEY `idx_user_id` (`user_id`),
  KEY `idx_operation_type` (`operation_type`),
  KEY `idx_created_at` (`created_at`),
  CONSTRAINT `fk_stock_log_stock` FOREIGN KEY (`seckill_stock_id`) REFERENCES `seckill_stock` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_stock_log_order` FOREIGN KEY (`order_id`) REFERENCES `order_info` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_stock_log_user` FOREIGN KEY (`user_id`) REFERENCES `user` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='库存操作日志表';

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
-- 设计说明
-- =====================================================
-- 
-- 核心设计要点：
-- 
-- 1. 防超卖机制：
--    - seckill_stock 表使用乐观锁（version字段）
--    - 扣减库存SQL示例：
--      UPDATE seckill_stock 
--      SET stock = stock - ?, version = version + 1 
--      WHERE seckill_product_id = ? AND stock >= ? AND version = ?
--
-- 2. 库存独立管理：
--    - 秒杀库存独立于商品库存，避免锁竞争
--    - 支持预扣减模式：下单时扣减，超时未支付自动回滚
--    - locked_stock 字段记录锁定库存
--
-- 3. 限购控制：
--    - user_purchase_limit 表记录用户购买次数
--    - 唯一索引 (user_id, activity_id, product_id) 防止重复购买
--
-- 4. 订单状态流转：
--    0-待支付 -> 1-已支付 -> 2-已发货 -> 3-已完成 -> 4-已取消 -> 5-已退款
--    - 秒杀订单15分钟未支付自动取消，回滚库存
--
-- 5. 性能优化：
--    - 所有表使用 utf8mb4 字符集
--    - 合理的索引设计
--    - 外键约束确保数据一致性
--    - 软删除（deleted_at）保留历史数据
--
-- 6. 审计追踪：
--    - stock_log 表记录所有库存操作
--    - 支持问题排查和数据恢复
-- 
-- =====================================================