package main

import (
	"fmt"
	"os"
	"path"
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

	for index, value := range playlists {
		fmt.Println(value.name, index)
	}

	fmt.Println(Pic(10, 10))

	coolMap := make(map[string]int)

	coolMap["zxc"] = 1000 - 7

	coolMap["three"] = 3
	coolMap["two"] = 2

	delete(coolMap, "two")

	fmt.Println(coolMap)
}
