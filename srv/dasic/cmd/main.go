package main

import (
	"flag"
	"fmt"
	"log"
	"net"
	"zhokao313/srv/dasic/config"
	"zhokao313/srv/dasic/inits"

	_ "zhokao313/srv/dasic/inits"
	"zhokao313/srv/handler/service"

	__ "zhokao313/proto"

	"google.golang.org/grpc"
)

var (
	port = flag.Int("port", 50051, "The server port")
)

func main() {
	if err := inits.ConsulInit(); err != nil {
		log.Fatalf("Consul初始化失败: %v", err)
	}
	log.Println("Consul初始化成功")
	services, err := inits.GetServiceWithLoadBalancer(config.Gen.Consul.ServiceName)
	if err != nil {
		log.Printf("获取用户服务失败: %v", err)
	} else {
		log.Printf("获取到用户服务: %s, 地址: %s:%d", services.Service, services.Address, services.Port)
	}

	flag.Parse()
	lis, err := net.Listen("tcp", fmt.Sprintf(":%d", *port))
	if err != nil {
		log.Fatalf("failed to listen: %v", err)
	}
	s := grpc.NewServer()
	__.RegisterOrderServer(s, &service.Server{})
	log.Printf("server listening at %v", lis.Addr())
	if err := s.Serve(lis); err != nil {
		log.Fatalf("failed to serve: %v", err)
	}
	err = inits.ConsulShutdown()
	if err != nil {
		return
	}
	fmt.Println("服务已退出")
}
