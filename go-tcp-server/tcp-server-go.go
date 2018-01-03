package main

import (
	"fmt"
	"net"
	"os"
)

const (
	CONN_HOST = ""
	CONN_PORT = "3333"
	CONN_TYPE = "tcp"
)

func main() {
	// Listen for incoming connections.
	l, err := net.Listen(CONN_TYPE, ":"+CONN_PORT)
	if err != nil {
		fmt.Println("Error listening:", err.Error())
		os.Exit(1)
	}
	// Close the listener when the application closes.
	defer l.Close()
	fmt.Println("Listening on " + CONN_HOST + ":" + CONN_PORT)

	// Listen for incoming connections.
	ll, err2 := net.Listen(CONN_TYPE, ":4444")
	if err2 != nil {
		fmt.Println("Error listening:", err2.Error())
		os.Exit(1)
	}
	// Close the listener when the application closes.
	defer ll.Close()
	fmt.Println("Listening on " + CONN_HOST + ":4444")
	counter := 0

	for {
		// Listen for an incoming connection.
		conn, err := l.Accept()
		if err != nil {
			fmt.Println("Error accepting: ", err.Error())
			os.Exit(1)
		}

		// Handle connections in a new goroutine.
		go handleRequest(conn)

		// Listen for an incoming connection.
		conn1, err1 := ll.Accept()
		counter++
		if err1 != nil {
			fmt.Println("Error accepting: ", err1.Error())
			os.Exit(1)
		}

		if counter == 10 {
			fmt.Printf("Stopping second server of port 4444 after 10 request.")
			ll.Close()
		}
		// Handle connections in a new goroutine.
		go handleRequest(conn1)
	}

}

// Handles incoming requests.
func handleRequest(conn net.Conn) {
	fmt.Printf("\nReceived message %s -> %s \n", conn.RemoteAddr(), conn.LocalAddr())
	// Make a buffer to hold incoming data.
	buf := make([]byte, 1024)
	// Read the incoming connection into the buffer.
	_, err := conn.Read(buf)
	if err != nil {
		fmt.Println("Error reading:", err.Error())
	}

	// Write the message in the connection channel.
	conn.Write([]byte("Hi there !"))
	// Close the connection when you're done with it.
	conn.Close()
}
