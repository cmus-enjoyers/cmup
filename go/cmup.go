package main

import (
	"fmt"
	"math"
	"math/cmplx"
)

var z complex128 = cmplx.Sqrt(-5 + 12i)

func main() {
	fmt.Println(math.Abs(-1))
	fmt.Println(z, "goida")

	bestNumberInTheWorld := 14

	bestNumberInTheWorldFloat := float32(bestNumberInTheWorld) + 0.1

	fmt.Printf("xx %v %T\n ", bestNumberInTheWorldFloat, bestNumberInTheWorldFloat)
}
