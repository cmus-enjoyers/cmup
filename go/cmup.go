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

func main() {
	var playlist = Playlist{name: "Test Playlist"}

	var home, err = os.UserHomeDir()

	if err != nil {
		fmt.Println("Couldn't determine user home dir.")
		return
	}

	fmt.Println(playlist)

	fmt.Println(os.ReadDir(path.Join(home, "Music")))
}
