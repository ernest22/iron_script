// main.go
package main

import (
    "fmt"
    "~/ceremonyclient/node/config" // replace with the actual path to your config package
)

func main() {
    version := config.GetVersionString()
    fmt.Println(version)
}