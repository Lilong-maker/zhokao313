package main

import (
	"log"
	"os"
	"os/signal"
	"syscall"

	"github.com/goherui/gospacex/web"
)

func main() {
	// 创建web服务工厂
	factory := web.NewWebServiceFactory()
	// 创建并启动所有四种服务
	services := []web.WebService{}
	// HTTP服务 (8080端口)
	httpService, err := factory.CreateService("http", 8080)
	if err != nil {
		log.Fatalf("创建HTTP服务失败: %v", err)
	}
	services = append(services, httpService)
	if err := httpService.Start(); err != nil {
		log.Fatalf("启动HTTP服务失败: %v", err)
	}
	// HTTPS服务 (8443端口)
	httpsService, err := factory.CreateService("https", 8443)
	if err != nil {
		log.Fatalf("创建HTTPS服务失败: %v", err)
	}
	services = append(services, httpsService)
	if err := httpsService.Start(); err != nil {
		log.Fatalf("启动HTTPS服务失败: %v", err)
	}
	// gRPC服务 (50051端口)
	grpcService, err := factory.CreateService("grpc", 50052)
	if err != nil {
		log.Fatalf("创建gRPC服务失败: %v", err)
	}
	services = append(services, grpcService)
	if err := grpcService.Start(); err != nil {
		log.Fatalf("启动gRPC服务失败: %v", err)
	}
	// WebSocket服务 (8081端口)
	websocketService, err := factory.CreateService("websocket", 8081)
	if err != nil {
		log.Fatalf("创建WebSocket服务失败: %v", err)
	}
	services = append(services, websocketService)
	if err := websocketService.Start(); err != nil {
		log.Fatalf("启动WebSocket服务失败: %v", err)
	}
	log.Println("所有服务已启动")
	// 等待系统信号
	quit := make(chan os.Signal, 1)
	signal.Notify(quit, syscall.SIGINT, syscall.SIGTERM)
	<-quit
	// 停止所有服务
	for _, service := range services {
		if err := service.Stop(); err != nil {
			log.Printf("停止服务失败: %v", err)
		}
	}
	log.Println("所有服务已停止")
}
