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
}
