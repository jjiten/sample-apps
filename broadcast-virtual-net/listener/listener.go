package main

import (
	"fmt"
	"log"
	"net"
	"time"
)

func main() {
	addr, err := net.ResolveUDPAddr("udp", "255.255.255.255:6666")
	if err != nil {
		log.Fatal(err)
	}

	sock, err := net.ListenUDP("udp", addr)
	if err != nil {
		log.Fatal(err)
	}

	for {
		buf := make([]byte, 1024)

		n, _, err := sock.ReadFromUDP(buf)
		if err != nil {
			log.Println(err)
		}

		fmt.Printf("[%s] %s\n", time.Now(), string(buf[:n]))
	}
}
