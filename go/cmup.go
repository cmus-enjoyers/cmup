package main

import (
	"fmt"
	"math"
	"math/cmplx"
	"math/rand"
)

var x complex128 = cmplx.Sqrt(-5 + 12i)

func Sqrt(x float64) float64 {
	z := 1.0

	for i := 0; i < 10; i++ {
		z -= (z*z - x) / (2 * z)
	}

	return z
}

func main() {
	fmt.Println(math.Abs(-1))

	const someThing = "my!lane"

	bestNumberInTheWorld := 14

	bestNumberInTheWorldFloat := float32(bestNumberInTheWorld) + 0.1

	fmt.Printf("xx %v %T\n ", bestNumberInTheWorldFloat, bestNumberInTheWorldFloat)

	fmt.Println(someThing, "constant", x)

	for i := 1000; i > 0; i -= 7 {
		fmt.Println("x", i-7)
	}

	if x := rand.Float32(); x > 0.5 {
		fmt.Println("random num is greater than 0.5", x)
	}

	fmt.Println(Sqrt(52))
}
