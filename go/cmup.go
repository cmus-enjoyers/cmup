package main

import (
	"fmt"
	"os"
	"path"
	// "strings"
)

type Playlist struct {
	name         string
	subPlaylists []*Playlist
}

func (playlist Playlist) Print() {
	fmt.Println("Playlist", playlist.name, "len", len(playlist.subPlaylists))
}

func readPlaylist(dir os.DirEntry) {
	fmt.Println(dir.Name(), "dir")
}

func cmup(homePath string) []Playlist {
	dir, err := os.ReadDir(path.Join(homePath, "Music"))

	result := make([]Playlist, 0)

	if err == nil {
		for _, value := range dir {
			if value.IsDir() {
				readPlaylist(value)
			}
		}
	}

	return result
}

func main() {
	home, err := os.UserHomeDir()

	if err == nil {
		cmup(home)
	} else {
		fmt.Println(err, "error")
	}
}
