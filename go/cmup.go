package main

import (
	"fmt"
)

type Playlist struct {
	name         string
	subPlaylists []*Playlist
}

func main() {
	var playlist = Playlist{name: "Test Playlist"}

	fmt.Println(playlist)
}
