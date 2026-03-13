package model

import "gorm.io/gorm"

type Order struct {
	gorm.Model
	Name    string  `gorm:"type:varchar(30)"`
	Price   float64 `gorm:"type:decimal(10,2)"`
	Num     int     `gorm:"type:type:int(11)"`
	OrderSn int     `gorm:"type:type:int(11)"`
}
