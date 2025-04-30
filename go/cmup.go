package main

import (
	"fmt"
	"os"
	"path"
	"strings"
)

type Playlist struct {
	name         string
	subPlaylists []*Playlist
}

func Pic(dx, dy int) [][]uint8 {
	var arry = make([][]uint8, dy)

	for y := range arry {
		arry[y] = make([]uint8, dx)

		for x := range arry[y] {
			arry[y][x] = uint8((x + y) / 2)
		}
	}

	return arry
}

func countWords(s string) map[string]int {
	fields := strings.Fields(s)

	result := map[string]int{}

	for _, value := range fields {
		result[value] += 1
	}

	return result
}

func main() {
	var playlist = Playlist{name: "Test Playlist"}

	var playlists = make([]Playlist, 0)

	var home, err = os.UserHomeDir()

	if err != nil {
		fmt.Println("Couldn't determine user home dir.")
		return
	}

	fmt.Println(playlist)

	fmt.Println(os.ReadDir(path.Join(home, "Music")))

	playlists = append(playlists, playlist)

	coolMap := make(map[string]int)

	coolMap["zxc"] = 1000 - 7

	coolMap["three"] = 3
	coolMap["two"] = 2

	delete(coolMap, "two")

	fmt.Println(countWords("I am learning Go! Go!"))
}
