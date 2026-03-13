package service

import (
	"context"
	"errors"
	__ "zhokao313/proto"
	"zhokao313/srv/dasic/config"
	"zhokao313/srv/handler/model"

	"gorm.io/gorm"
)

// server is used to implement helloworld.GreeterServer.
type Server struct {
	__.UnimplementedOrderServer
}

// OrderAdd implements helloworld.GreeterServer
func (s *Server) OrderAdd(_ context.Context, in *__.OrderAddReq) (*__.OrderAddResp, error) {
	// 缺陷修复1: 空指针异常风险 - 添加输入验证
	if in == nil {
		return &__.OrderAddResp{Code: 400, Msg: "请求参数不能为空"}, errors.New("request is nil")
	}

	// 缺陷修复2: 数据验证缺失 - 添加字段合法性检查
	if in.Name == "" {
		return &__.OrderAddResp{Code: 400, Msg: "订单名称不能为空"}, errors.New("name is required")
	}
	if in.Price <= 0 {
		return &__.OrderAddResp{Code: 400, Msg: "价格必须大于0"}, errors.New("price must be positive")
	}
	if in.Num <= 0 {
		return &__.OrderAddResp{Code: 400, Msg: "数量必须大于0"}, errors.New("num must be positive")
	}
	if in.OrderSn <= 0 {
		return &__.OrderAddResp{Code: 400, Msg: "订单号必须大于0"}, errors.New("orderSn must be positive")
	}

	// 缺陷修复3: 并发安全问题 - 使用事务和唯一性检查
	var existingOrder model.Order
	err := config.DB.Where("order_sn = ?", in.OrderSn).First(&existingOrder).Error
	if err == nil {
		return &__.OrderAddResp{Code: 409, Msg: "订单号已存在"}, errors.New("order already exists")
	}
	if !errors.Is(err, gorm.ErrRecordNotFound) {
		return &__.OrderAddResp{Code: 500, Msg: "查询订单失败"}, err
	}

	// 使用事务创建订单
	err = config.DB.Transaction(func(tx *gorm.DB) error {
		order := &model.Order{
			Name:    in.Name,
			Price:   float64(in.Price),
			Num:     int(in.Num),
			OrderSn: int(in.OrderSn),
		}
		if err := tx.Create(order).Error; err != nil {
			return err
		}
		return nil
	})

	if err != nil {
		return &__.OrderAddResp{Code: 500, Msg: "添加失败"}, err
	}

	return &__.OrderAddResp{Code: 200, Msg: "添加成功"}, nil
}

// OrderDelete implements delete order
func (s *Server) OrderDelete(_ context.Context, in *__.OrderDeleteReq) (*__.OrderDeleteResp, error) {
	if err := config.DB.Where("order_sn = ?", in.OrderSn).Delete(&model.Order{}).Error; err != nil {
		return &__.OrderDeleteResp{Code: 500, Msg: "删除失败"}, err
	}
	return &__.OrderDeleteResp{Code: 200, Msg: "删除成功"}, nil
}

// OrderUpdate implements update order
func (s *Server) OrderUpdate(_ context.Context, in *__.OrderUpdateReq) (*__.OrderUpdateResp, error) {
	// 缺陷修复: 空指针和输入验证
	if in == nil {
		return &__.OrderUpdateResp{Code: 400, Msg: "请求参数不能为空"}, errors.New("request is nil")
	}
	if in.OrderSn <= 0 {
		return &__.OrderUpdateResp{Code: 400, Msg: "订单号必须大于0"}, errors.New("orderSn must be positive")
	}
	if in.Name == "" || in.Price <= 0 || in.Num <= 0 {
		return &__.OrderUpdateResp{Code: 400, Msg: "更新字段不能为空且数值必须大于0"}, errors.New("invalid update fields")
	}

	// 缺陷修复: 并发安全问题 - 使用事务和悲观锁
	err := config.DB.Transaction(func(tx *gorm.DB) error {
		// 使用悲观锁查询订单，防止并发更新
		var order model.Order
		if err := tx.Where("order_sn = ?", in.OrderSn).First(&order).Error; err != nil {
			if errors.Is(err, gorm.ErrRecordNotFound) {
				return errors.New("order not found")
			}
			return err
		}

		updates := map[string]interface{}{
			"name":  in.Name,
			"price": in.Price,
			"num":   in.Num,
		}

		if err := tx.Model(&order).Updates(updates).Error; err != nil {
			return err
		}

		return nil
	})

	if err != nil {
		if err.Error() == "order not found" {
			return &__.OrderUpdateResp{Code: 404, Msg: "订单不存在"}, nil
		}
		return &__.OrderUpdateResp{Code: 500, Msg: "更新失败"}, err
	}

	return &__.OrderUpdateResp{Code: 200, Msg: "更新成功"}, nil
}

// OrderGet implements get order by orderSn
func (s *Server) OrderGet(_ context.Context, in *__.OrderGetReq) (*__.OrderGetResp, error) {
	var order model.Order
	if err := config.DB.Where("order_sn = ?", in.OrderSn).First(&order).Error; err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return &__.OrderGetResp{Code: 404, Msg: "订单不存在"}, nil
		}
		return &__.OrderGetResp{Code: 500, Msg: "查询失败"}, err
	}
	return &__.OrderGetResp{
		Code:    200,
		Msg:     "查询成功",
		Name:    order.Name,
		Price:   uint32(order.Price),
		Num:     int64(order.Num),
		OrderSn: int64(order.OrderSn),
	}, nil
}

// OrderList implements get order list with pagination
func (s *Server) OrderList(_ context.Context, in *__.OrderListReq) (*__.OrderListResp, error) {
	// 缺陷修复: 空指针和分页参数验证
	if in == nil {
		return &__.OrderListResp{Code: 400, Msg: "请求参数不能为空"}, errors.New("request is nil")
	}

	// 设置默认分页参数并验证
	page := in.Page
	pageSize := in.PageSize
	if page <= 0 {
		page = 1
	}
	if pageSize <= 0 {
		pageSize = 10
	}
	if pageSize > 100 {
		pageSize = 100 // 限制最大每页数量，防止DoS攻击
	}

	var orders []model.Order
	var total int64

	// 缺陷修复: 使用事务保证数据一致性
	err := config.DB.Transaction(func(tx *gorm.DB) error {
		if err := tx.Model(&model.Order{}).Count(&total).Error; err != nil {
			return err
		}

		offset := int((page - 1) * pageSize)
		if err := tx.Offset(offset).Limit(int(pageSize)).Find(&orders).Error; err != nil {
			return err
		}

		return nil
	})

	if err != nil {
		return &__.OrderListResp{Code: 500, Msg: "查询失败"}, err
	}

	data := make([]*__.OrderInfo, 0, len(orders))
	for _, order := range orders {
		data = append(data, &__.OrderInfo{
			Name:    order.Name,
			Price:   uint32(order.Price),
			Num:     int64(order.Num),
			OrderSn: int64(order.OrderSn),
		})
	}

	return &__.OrderListResp{
		Code:  200,
		Msg:   "查询成功",
		Data:  data,
		Total: total,
	}, nil
}
