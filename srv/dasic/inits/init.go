package inits

import (
	"fmt"
	"time"

	"github.com/spf13/viper"
	"gorm.io/driver/mysql"
	"gorm.io/gorm"

	"zhokao313/srv/dasic/config"
	"zhokao313/srv/handler/model"
)

func init() {
	ViperInit()
	if err := NacosInit(); err != nil {
		fmt.Printf("Nacos 配置加载失败: %v\n", err)
	} else {
		fmt.Printf("Nacos 配置加载成功 (Group: %s)\n", config.Gen.Nacos.Group)
	}
	MysqlInit()
}

var err error

func MysqlInit() {
	MysqlConfig := config.Gen.Mysql
	// 参考 https://github.com/go-sql-driver/mysql#dsn-data-source-name 获取详情
	dsn := fmt.Sprintf("%s:%s@tcp(%s:%d)/%s?charset=utf8mb4&parseTime=True&loc=Local",
		MysqlConfig.User,
		MysqlConfig.Password,
		MysqlConfig.Host,
		MysqlConfig.Port,
		MysqlConfig.Database,
	)
	config.DB, err = gorm.Open(mysql.Open(dsn), &gorm.Config{})
	if err != nil {
		panic(err)
	}
	fmt.Println("数据库连接成功")
	err = config.DB.AutoMigrate(&model.Order{})
	if err != nil {
		return
	}
	fmt.Println("表迁移成功")

	sqlDB, _ := config.DB.DB()

	// SetMaxIdleConns 设置空闲连接池中连接的最大数量。
	sqlDB.SetMaxIdleConns(10)

	// SetMaxOpenConns 设置打开数据库连接的最大数量。
	sqlDB.SetMaxOpenConns(100)

	// SetConnMaxLifetime 设置了可以重新使用连接的最大时间。
	sqlDB.SetConnMaxLifetime(time.Hour)
}
func ViperInit() {
	viper.SetConfigFile("C:\\Users\\Lenovo\\Desktop\\zhokao313\\config.yml")
	err = viper.ReadInConfig()
	if err != nil {
		return
	}
	err = viper.Unmarshal(&config.Gen)
	if err != nil {
		return
	}
	fmt.Println("配置文件加载成功")
}
