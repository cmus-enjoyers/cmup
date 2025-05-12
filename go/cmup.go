package main

import (
	"errors"
	"fmt"
	"os"
	"path"
	// "strings"
)

type Playlist struct {
	name         string
	content      []string
	subPlaylists []*Playlist
}

func (playlist Playlist) Print() {
	fmt.Println("Playlist", playlist.name, "len", len(playlist.subPlaylists))
}

func readPlaylist(dir os.DirEntry, dirPath string) (Playlist, error) {
	if !dir.IsDir() {
		return Playlist{dir.Name(), make([]string, 0), make([]*Playlist, 0)}, errors.New("Dir isn't a dir")
	}

	content, err := os.ReadDir(dirPath)

	if err == nil {
		result := make([]string, 0)

		for _, value := range content {
			result = append(result, path.Join(dirPath, value.Name()))
		}

		return Playlist{dir.Name(), result, make([]*Playlist, 0)}, nil
	}

	return Playlist{dir.Name(), make([]string, 0), make([]*Playlist, 0)}, err
}

func cmup(homePath string) ([]Playlist, error) {
	dir, err := os.ReadDir(path.Join(homePath, "Music"))

	result := make([]Playlist, 0)

	if err == nil {
		for _, value := range dir {
			if value.IsDir() {
				playlist, err := readPlaylist(value, path.Join(homePath, "Music", value.Name()))

				if err == nil {
					result = append(result, playlist)
				} else {
					fmt.Println(err, "in cmup")
				}
			}
		}

		return result, nil
	}

	return make([]Playlist, 0), err
}

func main() {
	home, err := os.UserHomeDir()

	if err == nil {
		result, err := cmup(home)

		if err == nil {
			fmt.Println(result)
		} else {
			fmt.Println("Gmup errored :(", err)
		}
	} else {
		fmt.Println(err, "error")
	}
}
